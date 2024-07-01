# Module SPS-MergeRegistry
Powershell Module to help dealing with registry files 
* Get-SPSRegistryContent
* Merge-SPSRegistryContent

> [!NOTE]  
> Files under **\TestFiles\\** will only create key under [HKEY_CURRENT_USER\SOFTWARE\SPS-MergeRegistry].

> [!WARNING]  
> While files under **\TestFiles\\** are safe to import, altering your own registry may be done with precaution.
> Never import a registry file without knowing it's content.

> [!IMPORTANT]  
> Your registry will **never** be altered with these function.
> it will only output Reg files or [Registry] object.

## The story behind this project
As a packager I often receive many reg files from my loved devs.
While doing my CI/CD project I had to pass theses refistry files into Wix Packaging tool to generate the MSI file that i then use.
there was deveral problem:

- I need to run the wix registry parser for each file wich slow down the process
- Due to quality of delivered reg files, some where rejected by wix.
- As the final goal was to create an msi package, registry deletion, key deletion and comments where useless in my situation.
- And none the less sometime key/value where overlapping and conflictin. There was no solution do detect value conflict.

I can't count all call i had from dev saying "you did not put the right value despite I delivered it" (yes you gave me one time true and one time false)

I needed something solid to read, merge and validate the delivered registry files.
I also needed to return error if some value where conflicting.

This lead me to this module.

It make my life easy and I used it to train my Regex.
I hope it can help other people strugling with registry files.



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