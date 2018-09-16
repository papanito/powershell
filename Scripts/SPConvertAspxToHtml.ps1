<# 
 .Synopsis
  Extracts aspx files from Sharepoint and converts them to html files

 .Description
  Extracts aspx files from Sharepoint and converts them to html files in a format that they can be imported in confluence via "Space Tools > Content Tools > Import".
  
  This solution does not require SharepointPS snippets nor do we need to have firewall ports open for collaboration
  https://docs.microsoft.com/en-us/powershell/module/microsoft.powershell.management/new-psdrive?view=powershell-6

 .Example
  .\ConvertAspxToHtml.ps1 -SourceUrl https://sp.intra/test/team1 -TargetDir D:\temp\team1
  .\ConvertAspxToHtml.ps1 -SourceUrl https://sp.intra/test/team1  -TargetDir D:\temp\team1 -Debug -Verbose -FilePattern "Home"
#>
Param(
    [Parameter(
        Mandatory=$true,
        ValueFromPipeline=$true,
        HelpMessage="Provide url for sharepoint site which shall be converted"
        )]
    [ValidatePattern("https://sp.intra/.*")]
    [string] $SourceUrl = "https://sp.intra/test/team1",

    [Parameter(
        Mandatory=$false,
        ValueFromPipeline=$false,
        HelpMessage="Provide target directory for exported html pages"
    )]
    [string] $TargetDir = "D:",
	
    [Parameter(
        Mandatory=$false,
        ValueFromPipeline=$false,
        HelpMessage="Prefix for output files"
    )]
    [string] $Prefix = "",
	
	[Parameter(
        Mandatory=$false,
        ValueFromPipeline=$false,
        HelpMessage="File patterns to restrict parsing to certain files only"
    )]
    [string] $FilePattern = "",
	
	[Parameter(
        Mandatory=$false,
        HelpMessage="[EXPERIMENTAL] Converts links to confluence references "
    )]
    [switch] $ConvertLinks
)

Function convertUrlToWebDav($url) {
	$uri = @{}
    $uri.Add("Path", $($url -replace "https`:`/`/sp.intra", ""))
    $uri.Add("Base", $($url -replace "https`:`/`/sp.intra", "\\sp.intra@SSL\DavWWWRoot" -replace "/", "\"))
    return $uri
}

Function ReplacePattern($String, $Pattern) {
    $regex    = $Pattern.Regex
    $replace  = $Pattern.Replace
    $helptext = $Pattern.Help

    Write-Verbose "*** $helptext ***"
    Write-Verbose "$regex"
	if (!$regex) {
		Write-Host "[WARNING] Regex '$regex' is empty, skipping ...."
		return $String
	}
    While ($String -match $regex) 
    {
        Write-Verbose "Match $regex"
        $String = $($String -replace $regex, $replace)
    }
    return $String
}

Function ConvertAspxToHtml($file) {
    Write-Host "File name: $($file.FullName)"
	if ($file.FullName -match $FilePattern) {
		Write-Debug "[DEBUG] File pattern matched, parsing of file starts...."
		$parent = $(Split-Path -Path $file.FullName).Substring($Source.Base.length).Replace('\','')

		$uri = $file.FullName -replace "\\\\sp.intra@SSL\\DavWWWRoot", "https`:`/`/sp.intra"
		$uri = $uri -replace "\\", "/"
		Write-Verbose "Uri:      $uri"
		
		# avoid overwriting in case same page name exists in a subfolder
		$filename = $file.BaseName
		if ($parent) {
			$filename = "$($parent)_$($filename)"
		}

		$Input = (Invoke-WebRequest -Uri $uri -Credential $cred).Content.Trim()
		
		# save original content (may be useful for debugging)
		$Input | Set-Content "$TargetDir\original\$filename.html"

		$Patterns = [ordered]@{}
		$Patterns.Add(("05"),(@{
			"Regex"   = "[\u200B]"
			"Replace" = ""
			"Help"    = "Remove special characters"
		}))
		$Patterns.Add(("10"),(@{
			"Regex"   = "`r`n"
			"Replace" = "`n"
			"Help"    = "Change line ending to LF only"
		}))
		$Patterns.Add(("12"),(@{
			"Regex"   = "`t"
			"Replace" = ""
			"Help"    = "Remove all tabs"
		}))
		$Patterns.Add(("15"),(@{
			"Regex"   = "<head>(.|\s)*?<a.*name=`"mainContent`" tabindex=`"-1`"></a>"
			"Replace" = "<body>"
			"Help"    = "Remove all content between <head> and <a name=`"mainContent`" tabindex=`"-1`"></a>."
		}))
		$Patterns.Add(("30"),(@{
			"Regex"   = "<script(.|`s)*?script>`n"
			"Replace" = ""
			"Help"    = "Remove all <script>..</script> sections"
		}))
		$Patterns.Add(("32"),(@{
			"Regex"   = "<menu(.|\s)*?menu>"
			"Replace" = ""
			"Help"    = "Remove <menu>..</menu>"
		}))
		$Patterns.Add(("34"),(@{
			"Regex"   = "<script type=`"text/javascript`">(`n|.)*?<\/script>`n"
			"Replace" = ""
			"Help"    = "Remove all <script>..</script> sections"
		}))
		$Patterns.Add(("40"),(@{
			"Regex"   = "<input(.|`s)*?>`n"
			"Replace" = ""
			"Help"    = "Remove all <input> fields"
		}))
		$Patterns.Add(("50"),(@{
			"Regex"   = "<noscript>.*?`/noscript>`n"
			"Replace" = ""
			"Help"    = "Remove all <noscript> sections"
		}))
		$Patterns.Add(("60"),(@{
			"Regex"   = " *(a|id|class|style|role|(aria-[a-zA-Z]+))=('|`")[a-zA-Z0-9.,_:;&#% -]*?('|`")"
			"Replace" = ""
			"Help"    = "Remove all ids, classes and styles"
		}))
		$Patterns.Add(("120"),(@{
			"Regex"   = "<div *>( |`n)*?<`/div>"
			"Replace" = ""
			"Help"    = "Remove empty divs"
		}))
		$Patterns.Add(("130"),(@{
			"Regex"   = "<span *>( |`n)*?<`/span>"
			"Replace" = ""
			"Help"    = "Remove empty span"
		}))
		$Patterns.Add(("180"),(@{
			"Regex"   = "\x3F"
			"Replace" = ""
			"Help"    = "Remove \x003F (wrongly converted special characters)"
		}))
		$Patterns.Add(("190"),(@{
			"Regex"   = "<table><tbody><tr><td><div><div( aria`-`w+=`"`w+`")*>"
			"Replace" = ""
			"Help"    = "Remove outer table which surrounds the content"
		}))
		$Patterns.Add(("195"),(@{
			"Regex"   = "<`/td><`/tr><`/tbody><`/table>(<span>false,false,1<`/span>)+"
			"Replace" = ""
			"Help"    = "Remove outer table which surrounds the content"
		}))
		$Patterns.Add(("200"),(@{
			"Regex"   = "<body>`n+<span>`n+.*`n+<`/span>`n"
			"Replace" = "<body>"
			"Help"    = "Remove Wiki page title from content"
		}))
		$Patterns.Add(("205"),(@{
			"Regex"   = "<span>`s+<div id = `"helppanelCntdiv`">`s+<`/div>`s+<`/span>`n+"
			"Replace" = ""
			"Help"    = "Remove some leftover"
		}))
		$Patterns.Add(("206"),(@{
			"Regex"   = "<`/form>`n"
			"Replace" = ""
			"Help"    = "Remove some leftover"
		}))
		$Patterns.Add(("210"),(@{
			"Regex"   = "`&`#160;"
			"Replace" = " "
			"Help"    = "Remove special characters from html"
		}))

		$Patterns.Add(("300"),(@{
			"Regex"   = "<br><"
			"Replace" = "<"
			"Help"    = "Remove unnecessary tags"
		}))
		$Patterns.Add(("310"),(@{
			"Regex"   = "<p><br> *<`/p>"
			"Replace" = ""
			"Help"    = "Remove unnecessary tags"
		}))
		$Patterns.Add(("320"),(@{
			"Regex"   = "<(strong|div|blockquote|p|h`d)>(<br>)* *<`/(strong|div|blockquote|p|h`d)>"
			"Replace" = ""
			"Help"    = "Remove unnecessary tags"
		}))
		$Patterns.Add(("330"),(@{
			"Regex"   = "<`/?blockquote>"
			"Replace" = ""
			"Help"    = "Remove unnecessary tags"
		}))
		$Patterns.Add(("999"),(@{
			"Regex"   = "`n`n"
			"Replace" = "`n"
			"Help"    = "Replace all multiple line feeds with a single one"
		}))
		
		$href = $($Source.Path -replace "/","`/")
		#$Patterns.Add(("900"),(@{
		#	"Regex"   = "<a.*?$href.*?>.*?<`/a>"
		#	"Replace" = "<ac:link><ri:page ri:space-key=`"SM`" ri:content-title=`"$filename`" /><ac:plain-text-link-body><![CDATA[$filename]]></ac:plain-text-link-body></ac:link>"
		#	"Help"    = "Replace Sharepoint URL with Confluence"
		#}))
		
		# Multiple patterns are required to replace links as $matches is not populated
		if ($ConvertLinks) {
			Write-Host "[EXPERIMENTAL] Converting links to confluence references"
			$Patterns.Add(("900"),(@{
				"Regex"   = "<a.*?$href`/"
				"Replace" = "<ac:link><ri:page ri:space-key=`"SM`" ri:content-title=`""
				"Help"    = "Replace Sharepoint URL with Confluence - 1st part"
			}))
			$Patterns.Add(("910"),(@{
				"Regex"   = ".aspx`">"
				"Replace" = "`" /><ac:plain-text-link-body><![CDATA["
				"Help"    = "Replace Sharepoint URL with Confluence - 2st part"
			}))
			$Patterns.Add(("920"),(@{
				"Regex"   = "<`/a>"
				"Replace" = "]]></ac:plain-text-link-body></ac:link>"
				"Help"    = "Replace Sharepoint URL with Confluence - 3rd part"
			}))
			$Patterns.Add(("930"),(@{
				"Regex"   = "%20"
				"Replace" = " "
				"Help"    = "Replace Sharepoint URL with Confluence - %20 with spaces"
			}))
		}

		foreach($Pattern in $Patterns.Values)
		{
			$Input = ReplacePattern $Input $Pattern
		}
		
		$Input | Set-Content "$TargetDir\$Prefix$filename.html" -Encoding ASCII
	}
}

if (!$cred) {
	$cred = Get-Credential
}

if (!$Prefix) {
	$Prefix = "$Prefix_"
}

if(!(Test-Path -Path $TargetDir )){
    New-Item -ItemType directory -Path $TargetDir
}

$Source = convertUrlToWebDav($SourceUrl)

$drive = New-PSDrive -Name $DriveName -PSProvider "FileSystem" -Root $Source.Base  -ErrorAction SilentlyContinue
[System.IO.DriveInfo]::GetDrives() | Format-Table

# Exclude Sharepoint Lists and pages which are currently not working
# Not working means: Scripts stucks and does not continue
Get-ChildItem "$($DriveName):\"  -File -Recurse | 
Where-Object { ($_.Extension -eq '.aspx') -and ($_.FullName -Notlike "*Lists*") -and ($_.FullName -Notlike "*TSYS Services*") } |
    ForEach-Object {
        ConvertAspxToHtml $_
    }

Remove-PSDrive $DriveName  -ErrorAction SilentlyContinue
