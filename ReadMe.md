# Module SPS-MergeRegistry
Powershell Module to help dealing with registry files 
* Get-SPSRegistryContent
* Merge-SPSRegistryContent

> [!NOTE]  
> file under **\TestFiles\\** will only create key under [HKEY_CURRENT_USER\SOFTWARE\SPS-MergeRegistry].

> [!WARNING]  
> While file under **\TestFiles\\** are safe to merge in your registry, altering your own registry may be done with cautious never import a registry file without knowing it's content.

> [!IMPORTANT]  
> Your registry will **never** be altered with these function. it will only output Reg files or [Registry] object.

## Usage

To use this module, follow these steps:

1. Copy the to a local directory.
2. if you want to make it available in your module folder Execute ImportInModuleFolder.ps1 :
    ```powershell
    .\ImportInModuleFolder.ps1
    ```

1. Copy the to a local directory
2. import the module using the SPS-MergeRegistry.psd1
    ```powershell
    Import-Module -path PATHTODIR\SPS-MergeRegistry.psd1
    ````

3. Use the available cmdlets to interact with registry files:
    - `Get-SPSRegistryContent`: Conver a registry file into a Registry Object.
    - `Merge-SPSRegistryContent`: Merges the content of multiple registry files / Objects.

4. This module also expose a set of class:
    - `[Registry]::New('PATH\RegistryFile.reg')`

## Test the module

This module include a set of registry file located under `\TestFiles\` you can try the function with these registry files.

### using the debug files 

```powershell
.\Debug-Get-SPSRegistryContent.ps1
````
This script will build an object per registry file present in the `TestFiles` folder.

```powershell
.\Debug-Merge-SPSRegistryContent.ps1
````
This script will merge the registry using several approach showing what can happen.

```powershell
.\ModuleDebug.ps1
````
This script help debugging the module while beeing in the module folder. It force import the module and measure the execution of both Debug-*.ps1 scripts. this script will not run while in an another location than the `$Env:PSModulePath`.

For detailed information on each cmdlet, refer to the [Cmdlet Documentation](./CmdletDocumentation.md).