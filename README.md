# powershell

Collection o arbitrary PowerShell scripts and snippets

## Scripts

Contains usable scripts, see more info in [README](./Scripts/README.md)

## Modules

Contains powershell modules, see more info in [README](./Modules/README.md)

## Snippets

Below I collected some useful snippets

### Credentials

```powershell
# Source: https://blogs.msdn.microsoft.com/koteshb/2010/02/12/powershell-how-to-create-a-pscredential-object/
$mycredentials = Get-Credential
# When you have to provide credentials in non-interactive mode, you can create a PSCredential object in the following way.

$secpasswd = ConvertTo-SecureString "PlainTextPassword" -AsPlainText -Force
$mycreds = New-Object System.Management.Automation.PSCredential ("username", $secpasswd)

#You can now pass $mycreds to any -PSCredential input parameter
```

### Usage of Parameters

```powershell
[CmdletBinding(DefaultParametersetName='None')] 
Param (
    [Parameter(
        Mandatory=$false, 
        HelpMessage="Enter target path")]
    [ValidatePattern("[c-d]\:\\[0-9a-z]*")] 
    [string] $Basedir = "D:\Dev",
    
    [Parameter(
        Mandatory=$false, 
        HelpMessage="Enter source location for sw packages")]
    [string] $baseurl= "https://myserver/tools",

    [parameter(
        ParameterSetName="SilentInstall",
        Mandatory=$false,
        HelpMessage="Component to be installed, use 'all' to install all, use -Show to show all components")]
        [Switch]$Silent,

    [parameter(
        Mandatory=$false,
        HelpMessage="Show all installable components")]
        [Switch]$Show,

    [parameter(ParameterSetName="SilentInstall", Mandatory=$true)]
    [string] $component
)
```

### Show Certificates

Display Certitifactes from Certificates store in Windows

```powershell
Set-Location Cert:\CurrentUser\My                           
Get-ChildItem | Format-Table Subject, FriendlyName, Thumbprint -AutoSize
```

### Resize Partition

```powershell
$part=Get-Partition
$size=Get-PartitionSupportedSize -InputObject $part
Write-Host "Resizing partition to size: $($size.SizeMax)"
Resize-Partition -InputObject $part -Size $size.SizeMax
```a