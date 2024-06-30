# Module SPS-MergeRegistry
Powershell Module to help dealing with registry files 
* Get-SPSRegistryContent
* Merge-SPSRegistryContent

## Usage

To use this module, follow these steps:

1. Install the module by running the following command:
    ```powershell
    Install-Module -Name SPS-MergeRegistry -Scope CurrentUser
    ```

2. Import the module by running the following command:
    ```powershell
    Import-Module -Name SPS-MergeRegistry
    ```

3. Use the available cmdlets to interact with registry files:
    - `Get-SPSRegistryContent`: Retrieves the content of a registry file.
    - `Merge-SPSRegistryContent`: Merges the content of multiple registry files.

For detailed information on each cmdlet, refer to the [Cmdlet Documentation](./CmdletDocumentation.md).

## Examples

### Example 1: Get registry content
```powershell
Get-SPSRegistryContent -Path 'C:\Registry\File.reg'
```

This command retrieves the content of the registry file located at `C:\Registry\File.reg`.

### Example 2: Merge registry content
```powershell
Merge-SPSRegistryContent -Path 'C:\Registry' -OutputPath 'C:\Merged\' -OutputFileName 'Merged.reg'
```

This command merges all registry file present in `C:\Registry` into a new registry file named `Merged.reg` and located at `C:\Merged\`.

