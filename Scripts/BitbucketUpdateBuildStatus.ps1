<# 
 .Synopsis
  Updates build status to "SUCCESSFUL"

 .Description
  Build status of Jenkins build in Bitbucket may stay "In Progress" even so it succeeded, thus blocking merge of PR.
  This script takes a commit-id and updates all builds which are "In Progress" to "Successful"

  Details can be found at https://docu.sc.intra/pages/viewpage.action?pageId=88934117

 .Example
  .\Bitbucket.Pass.Build.ps1 -CommitID 52f43d788fb552135d2d852869d9c67d3d2b4297
#>
Param(
    [Parameter(
        Mandatory=$true,
        ValueFromPipeline=$true,
        HelpMessage="Commit id for which the build status has to be corrected"
        )]
    [ValidatePattern("[0-9a-zA-Z]{5,40}")]
    [string] $CommitID,
    [Parameter(
        Mandatory=$false,
        ValueFromPipeline=$true,
        HelpMessage='Bearer token used to access bitbucket rest api, uses $env:BITBUCKET_TOKEN per default'
        )]
    [string] $Token = $env:BITBUCKET_TOKEN
)

$baseUrl = "https://bitbucket.intra"
$urlRestApi = "$baseUrl/rest/build-status/1.0/commits"

# get credentials if not set
if (!$Token) {
    Write-Host "Please provide a bearer token via -Token or \$env:BITBUCKET_TOKEN"
    Exit
}

$headers = @{}
$headers.Add("Authorization","Bearer $Token")

$urlQuery = "$urlRestApi/$CommitID"
Write-Host "Get $urlQuery"
$Response = Invoke-WebRequest -Uri "$urlQuery" -Headers $headers -ContentType "application/json" -Method 'GET' | ConvertFrom-Json

$Response  | ConvertTo-Json

$statusToFix = "INPROGRESS"
$statusToSet = "SUCCESSFUL"

foreach ($data in $Response.values) {

    if ($data.state -eq $statusToFix) {
        $key = $data.key
        $name = $data.name
        $url = $data.url
        Write-Host "Fix the status of the following build: ${key}"
        $name = $name.Replace("??", "»")

        $json = @"
{
    "state": "$statusToSet",
    "key": "$key",
    "name": "$name",
    "url": "$url",
    "description": "Changed manually"
} 
"@
        Write-Host "Write $urlQuery"
        Write-Host $json
        Invoke-WebRequest -Uri "$urlQuery" -Headers $headers -ContentType "application/json" -Method 'POST' -Body $json
    }
}