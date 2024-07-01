# Module SPS-MergeRegistry
Powershell Module to help dealing with registry files 
* Get-SPSRegistryContent
* Merge-SPSRegistryContent

> [!IMPORTANT]  
> Your registry will **never** be altered with these function.
> it will only output Reg files or [Registry] object.

> [!WARNING]  
> While files under **\TestFiles\\** are safe to import, Altering the registry can have unintended consequences. It's recommended to proceed with caution and ensure you have a backup before making changes.
> Never import a registry file without knowing it's content.

> [!NOTE]  
> Files under **\TestFiles\\** will only create key under [HKEY_CURRENT_USER\SOFTWARE\SPS-MergeRegistry].

## The story behind this project
As a packager, I often receive many registry files from my beloved developers. During my CI/CD project, I had to pass these registry files into the WiX Packaging tool to generate the MSI file that I then use. There were several problems:

- I needed to run the WiX registry parser for each file, which slowed down the process.
- Due to the quality of the delivered registry files, some were rejected by WiX.
- Since the final goal was to create an MSI package, registry deletions, key deletions, and comments were useless in my situation.
- Moreover, sometimes keys/values were overlapping and conflicting. There was no solution to detect value conflicts.

I can't count all the calls I had with developers.

**Dev** : You did not put the right value despite I delivered it. It should have been true !
**Me** : Yes indeed you are right, one of your file was setting it to true but 3 others where setting it to false. depending wich you import first the result will be different.

I needed a reliable tool to read, validate, and ultimately merge the delivered registry files into a single file. Additionally, it was crucial to identify and report any conflicting values to halt the process before delivery.

I needed to mock importing files one by one without impacting my own registry.

This necessity led me to develop this module.

It has significantly simplified my workflow and served as a valuable resource for enhancing my Regex skills. I hope it can assist others struggling with registry files.

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
    - `Get-SPSRegistryContent`: Convert a registry file into a Registry Object.
    - `Merge-SPSRegistryContent`: Merges the content of multiple Registry files / Objects.

4. This module also expose the [Registry] class:
    - `[Registry]::New('PATH\RegistryFile.reg')`

## Test the module

This module include a set of registry file located under `\TestFiles\` you can try the function with these registry files.

### Using the debug files 

Build an object per registry file present in the `TestFiles` folder. Use :

```powershell
.\Debug-Get-SPSRegistryContent.ps1
````
Merge several different .reg (and non .reg) files together. Testing and showing some behavior I wanted my module to have.

```powershell
.\Debug-Merge-SPSRegistryContent.ps1
````

Debug the module <u>while beeing in the module folder</u>. It force import the module and measure the execution of both Debug-*.ps1 scripts in a "production" environment. This script will not run while in an another location than the `$Env:PSModulePath` aside of the .psm1 and .psd1 files.

```powershell
.\ModuleDebug.ps1
````


For detailed information on each cmdlet, refer to the [Cmdlet Documentation](./CmdletDocumentation.md).