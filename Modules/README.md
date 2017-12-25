# Scripts and Powershell Modules

Something I find very interesting with Powershell is the option to provide modules which are served via Powershell Galleries
see https://msdn.microsoft.com/en-us/library/dd878324(v=vs.85).aspx​

In your company environment you most probably will setup your private repositories perhaps also with user authentication. This repository has to be registered as follows in order to use it:

```
Register-PSRepository -Name Wyssmann -SourceLocation https://nexus.wyssmann.com/repository/nuget-group/ -PublishLocation https://nexus.wyssmann.com/repository/nuget-psg/ -PackageManagementProvider nuget -InstallationPolicy Trusted​ -Credential $cred
```

The "Nuget-group" is a group which contains the public powershell gallery (proxy repo) and your private powershell gallery (nuget-psg). 

## Publish Artifacts

To publishing artifacts into the PS Gallery you need 

1. "​Nuget API-Key Realm" is active
2. Grab the NugetApi Key from your Nexus profile

Then you can publish similar to this where Papanitos.psd1 is the module manifest:

```
Publish-Module -Name .\Papanitos.psd1 -Repository Wyssmann -Verbose  -NugetApiKey "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxx​"​
Authentication​
```

## User Modules

If the module is uploaded and the gallery is registeren then you can install the module from the Gallery:

```
Install-Module -Name Papanitos -Repository Wyssmann
```

You can get the available functions as follows

```
Get-Command -Module Papanitos
 
CommandType     Name                                               Version    Source
-----------     ----                                               -------    ------
Function        Example                                            0.0.1      Papanitos
```
​
For information on about the module type Get-Help <Command>

```
Get-Help Example
 
NAME
    Example
 
SYNOPSIS
    Example module with no functionality
 
 
SYNTAX
    Example [-Param1 <String>] [-Param2 <String>] [-Show] [<CommonParameters>]
 
 
DESCRIPTION
    Example module with no functionality; Some more words about the function
 
 
RELATED LINKS
 
REMARKS
    To see the examples, type: "get-help Examples -examples".
    For more information, type: "get-help Examples -detailed".
    For technical information, type: "get-help Examples -full".​
```