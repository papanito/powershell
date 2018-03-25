<# 
 .Synopsis
  Extracts aspx files from Sharepoint and converts them to html files

 .Description
  Extracts aspx files from Sharepoint and converts them to html files in a format that they can be imported in confluence via "Space Tools > Content Tools > Import".
  
  This solution does not require SharepointPS snippets 
  https://docs.microsoft.com/en-us/powershell/module/microsoft.powershell.management/new-psdrive?view=powershell-6

 .Example
  ConvertAspxToHtml -SourceUrl https://sharepoint.intra/sitea
#>
Param(
    [Parameter(
        Mandatory=$true,
        ValueFromPipeline=$true,
        HelpMessage="Provide url for sharepoint site which shall be converted"
        )]
    [ValidatePattern("https://sharepoint.intra/.*")]
    [string] $SourceUrl = "https://sharepoint.intra/sitea",

    [Parameter(
        Mandatory=$false,
        ValueFromPipeline=$false,
        HelpMessage="Provide target directory for exported html pages"
    )]
    [string] $TargetDir = "H:"
)

Function convertUrlToWebDav($url) {
    $uri = $url -replace "https`:`/`/sharepoint.intra", "\\sharepoint.intra@SSL\DavWWWRoot"
    $uri = $uri -replace "/", "\"
    return $uri
}

Function ConvertAspxToHtml($file) {
    Write-Host "Filename: $($file.FullName)"
    $uri = $file.FullName -replace "\\\\sharepoint.intra@SSL\\DavWWWRoot", "https`:`/`/sharepoint.intra"
    $uri = $uri -replace "\\", "/"
    #$uri = $file -replace "\\\\sharepoint.intra@SSL", "https"
    Write-Host "Uri:      $uri"

    $filename = $file.BaseName

    $aspxpage = Invoke-WebRequest -Uri $uri -Credential $cred

    #Write-Host $aspxpage.Content
    $string = $aspxpage.Content
    #$string = Get-Content $uri
    $string | Foreach-Object {
	    $_ -replace "<meta.*\/>", "" `
	       -replace "`r`n", "`n" `
	       -replace "<head(.|`s)*?`/head>`n", '' `
           -replace "<link(.|`s)*?`/>", '' `
	       -replace "<script(.|`s)*?`/script>`n", '' `
	       -replace "<script type=`"text/javascript`">(`n|.)*?<\/script>`n", '' `
	       -replace "<div id=`"imgPrefetch`"(.|`n)*?`/div>", "" `
	       -replace "<div (.|`n)*?accessible(.|`n)*?`/div>", "" `
	       -replace "<div class=`"aspNetHidden`"(.|`n)*?`/div>", "" `
	       -replace "<div WebPartID(.|`n)*?`/div>", "" `
	       -replace "<menu(.|`n)*?`/menu>", "" `
	       -replace "<input.*?`/>", '' `
	       -replace "(id|class)=`".*?`" ?", '' `
	       -replace "<noscript.*`/noscript>", '' `
	       -replace "\?", "" `
           -replace "<body", "<p" `
           -replace "ci-tools/bitbucket/", "scm.sc.intra" `
           -replace "`t+", "" `
           -replace "<a.*img.*<`/a>", "" `
           -replace "<a.*((?!href).)*<\/a>", "" `
           -replace "<div.*?>(\s|<\/?div *>)*<\/div>", "" `
	       -replace "`n+", "`n"
    } | Set-Content "$TargetDir\$filename.html"
}

if (!$cred) {
	$cred = Get-Credential
}

if(!(Test-Path -Path $TargetDir )){
    New-Item -ItemType directory -Path $TargetDir
}


$DriveName = "sharepoint"

$drive = New-PSDrive -Name $DriveName -PSProvider "FileSystem" -Root $(convertUrlToWebDav($SourceUrl))  -ErrorAction SilentlyContinue
[System.IO.DriveInfo]::GetDrives() | Format-Table

Get-ChildItem "$($DriveName):\"  -File -Recurse | 
Where-Object { ($_.Extension -eq '.aspx') -and ($_.FullName -Notlike "*Lists*") } |
    ForEach-Object {
    ConvertAspxToHtml $_
}

Remove-PSDrive $DriveName  -ErrorAction SilentlyContinue