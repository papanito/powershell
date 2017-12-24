<# 
 .Synopsis
  Extracts authors from svn and creates an Authors file for git
 .Description
  Migration from svn to git required a list of authors (user id in svn) mapped to git users (name, email)
  Details https://alastaircrabtree.com/converting-an-svn-repository-to-git-on-windows/
  Script has to be run in an svn local repo.
 .Example
   # Get-SVN-Authors
#>
Add-WindowsFeature RSAT-AD-PowerShell

$Authors = $((((svn log --xml --quiet | Select-String -Pattern "author")|Out-String ) -replace '<\/?author>', '').trim()).split("`r`n") | ? {$_.trim() -ne "" } | sort | Get-Unique
[System.Collections.ArrayList]$AuthorsNew = @{}

foreach ($author in $Authors) 
{
    Write-Host "Query user '$author'"
    $AdUser = Get-ADUser -Filter "SamAccountName -eq '$author'" -Properties *

    Write-Host "MAIL $($AdUser.mail)"
    if ($AdUser -eq $null) {
        Write-Host "User not found in AD using"
        $author = "$author = $author <$author@test.com>"
    }
    else {
        $author = "$author = $($AdUser.Name) <$($AdUser.EmailAddress)>"
        Write-Host "User found: $author"
    }
    $AuthorsNew.Add($author)
}
Set-Content -Value $AuthorsNew -Path "Authors.txt"