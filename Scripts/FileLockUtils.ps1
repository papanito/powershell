<#

#>
function TestFileLock {
    param ([string]$lockedFile )
    Get-Process | foreach{$processVar = $_;$_.Modules | foreach{if($_.FileName -eq $lockedFile){$processVar.Name + " PID:" + $processVar.id}}}
}
<# 
  Attempts to open a file and trap the resulting error if the file is already open/locked
  Remarks: 
  - This indicates whether the file is locked or not, but doesn't give the application that's locking the file.
  - It will actually create a new file if it doesn't already exist
  Source: https://stackoverflow.com/questions/958123/powershell-script-to-check-an-application-thats-locking-a-file/13508676#13508676
#>
function IsFileLocked 
    param ([string]$filePath )
    $filelocked = $false
    $fileInfo = New-Object System.IO.FileInfo $filePath
    trap {
        Set-Variable -name Filelocked -value $true -scope 1
        continue
    }
    $fileStream = $fileInfo.Open( [System.IO.FileMode]::OpenOrCreate, [System.IO.FileAccess]::ReadWrite, [System.IO.FileShare]::None )
    if ($fileStream) {
        $fileStream.Close()
    }
    $filelocked
}
