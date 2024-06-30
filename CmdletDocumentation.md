## Cmdlet Documentation

### Get-SPSRegistryContent

#### Description
The `Get-SPSRegistryContent` cmdlet retrieves the content of a registry file.

#### Syntax
```powershell
Get-SPSRegistryContent -Path <string>
```

#### Mandatory Parameters
- `Path`: \<System.IO.FileInfo\> Specifies the path to the registry file. This can be a local file path or a UNC path.

#### Optional Parameters
- `Strict`: \<switch\> throw error if malformated content if found

#### Example
```powershell
Get-SPSRegistryContent -Path 'C:\Registry\File.reg'
```

This command retrieves the content of the registry file located at `C:\Registry\File.reg`.

### Merge-SPSRegistryContent

#### Description
The `Merge-SPSRegistryContent` cmdlet merges the content of multiple registry files into a new registry file.

#### Syntax
```powershell
Merge-SPSRegistryContent -Path <string[]>

Merge-SPSRegistryContent -InputObject <Registry[]>
```

#### Mandatory Parameters
- `Path`: \<string\> Specifies a path containing registry files to merge.
- `InputObject`: \<registry\> Specifies an array of Registry Object to the registry files to be merged. ParameterSet ByRegistry.

#### Optional Parameters
- `OutputPath`: \<string\> Specifies the path where the merged registry file will be saved.
- `OutputFileName`: \<string\> Specifies the name of the merged registry file.
- `Strict`: \<switch\> throw error if malformated content if found.
- `OutputFormat`: \<int\> 4 or 5 depending the version of registry you want as output.
- `NoDeletion`: \<switch\> any deletion in the input will be ignored.
- `NoKeyDeletion`: \<switch\> any key deletion in the input will be ignored.
- `NoValueDeletion`: \<switch\> any value deletion in the input will be ignored.
- `MultiDeclarationWarning`: \<switch\> if a key or a value is declared more than once a warning will be thrown.
- `IgnoreConflicts`: \<switch\> does not throw and error if a key or a value has conflictual value or conflicting deletion status .

#### Example
```powershell
Merge-SPSRegistryContent -Path 'C:\Registry' -OutputPath 'C:\Merged\' -OutputFileName 'Merged.reg'
```

This command merges all registry file present in `C:\Registry` into a new registry file named `Merged.reg` and located at `C:\Merged\`.