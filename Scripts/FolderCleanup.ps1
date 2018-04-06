<# 
 .Synopsis
  Cleanup of files in a directory

 .Description
  Scans a given directory and deletes all files bigger than a certain size. Per default the script only runs in a dry run means nothing is deleted. 
  To force deletion provide parameter -Run

 .EXAMPLE
  .\FolderCleaner.ps1 -Pattern "Example*" 
  Performing some security checks for folder 'C:\temp' and Pattern '*Example*'
  ---------------- DRY RUN ----------------
  Start cleanup of 'C:\temp'
  keep   - Example1.txt (0.01 MB)
  delete - Example2.txt (960.12 MB)
  keep   - Example3.txt (16.98 MB)
  keep   - Example4.txt (5.30 MB)
  keep   - Example5.txt (6.12 MB)
  keep   - Example6.txt (1.00 MB)
  -----------------------------------------
  Total space freed: 0.00MB (2704.67MB vs 2704.67MB)

  .EXAMPLE
  .\FolderCleaner.ps1 -Pattern "Example*" -Run
  Performing some security checks for folder 'C:\temp' and Pattern '*Example*'
  ---------------- DRY RUN ----------------
  keep   - Example1.txt (0.01 MB)
  delete - Example2.txt (960.12 MB)
  keep   - Example3.txt (16.98 MB)
  keep   - Example4.txt (5.30 MB)
  keep   - Example5.txt (6.12 MB)
  keep   - Example6.txt (1.00 MB)
  -----------------------------------------
  Total space freed: 960.12MB (1744.55MB vs 2704.67MB)    
#>

[cmdletbinding()]
param(
    [switch] $Run,
    [Parameter(Mandatory = $false)]
    [Alias('Path')]
    [String]
    $FolderToClean = 'C:\temp',
    [Parameter(Mandatory = $false)]
    [Alias('Size')]
    [int]
    $Threshold = 500,
    [Parameter(Mandatory = $false)]
    [Alias('Filter')]
    [String]
    $Pattern = "*" 
)
function FolderSize($folder) {
    return (Get-ChildItem $folder -Recurse | Measure-Object -Property Length -Sum -ErrorAction Stop).Sum
}

function SecurityChecks($folder, $pattern)
{
   Write-Host "Performing some security checks for folder '$folder' and Pattern '$pattern'"
   if ($folder -match '^\w\:\\$') {
       Write-Warning "No directory provided"
       Exit
   } 
   if ($pattern -match '^[*]*$') {
      Write-Warning "Invalid pattern '$Pattern', be more concrete"
      Exit
  } 
}

SecurityChecks $FolderToClean $Pattern
if (!$Run) {
    Write-Host "---------------- DRY RUN ----------------"
}

Write-Host "Start cleanup of '$FolderToClean'"

$folderSizeBefore = FolderSize($FolderToClean)

foreach ($item in (Get-ChildItem $FolderToClean -recurse -Filter $Pattern -Directory))
{
    $folderSize = FolderSize($item.FullName)
    $folderSizeInMB = "{0:N2} MB" -f ($folderSize / 1MB) 

    if ($folderSize -gt ($Threshold * 1MB)) {
        if ($Run) {
            Remove-Item $item.FullName -Recurse -Force
        }
        Write-Host "delete - $($item.FullName) ($folderSizeInMB)"
    } 
    else 
    {
        Write-Host "keep   - $($item.FullName) ($folderSizeInMB)"
    }
}
$folderSizeAfter = FolderSize($FolderToClean)
$output = "Total space freed: {0:N2}MB ({1:N2}MB vs {2:N2}MB)" -f (($folderSizeBefore - $folderSizeAfter) / 1MB), ($folderSizeBefore / 1MB), ($folderSizeAfter / 1MB)

Write-Host "--------------------------------------"
Write-Host $output