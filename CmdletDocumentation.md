
## Get-SPSRegistryContent
### Syntax
```powershell
Get-SPSRegistryContent
    -File <System.IO.FileInfo>
    [-Strict]
    [<CommonParameters>]
```
### Description
the `Get-SPSRegistryContent` cmdlets get the content of the item at the location specified by the file parameter. If the file comply with the registry format it will be converted to a `Registry` object.

### Examples
#### Example 1: Get registry content
```powershell
Get-SPSRegistryContent -Path 'C:\Registry\File.reg'
```

This command retrieves the content of the registry file located at `C:\Registry\File.reg`.

### Parameters
**\-File**

    The File <System.IO.FileInfo[]> specifies the location of the registry file.
    This can come as a <string[]> or a <System.IO.FileInfo[]> object.
    This parameter also accept pipeline.

| <!-- -->               | <!-- -->             |
|:-----------------------|:---------------------|
| Type :                 | System.io.FileInfo[] |
| Position :             | 1                    |
| Alias :                | FullName             |
| Default value:         | None                 |
| Required:              | True                 |
| Accept pipeline input: | True                 |
| <!-- -->               | <!-- -->             |



**\-Strict**

    the Strict <Switch> parameter define if the function should allow malformed lines in the registry file. other wyse these line as stored in an UnknownLines parameter in the outputed Registry Object.

| <!-- -->               | <!-- -->           |
|:-----------------------|:-------------------|
| Type :                 | Switch             |
| Position :             | 2                  |
| Default value:         | false              |
| Required:              | false              |
| Accept pipeline input: | false              |
| <!-- -->               | <!-- -->           |

## Merge-SPSRegistryContent
### Syntax
```powershell
Merge-SPSRegistryContent
    -InputObject <Registry>
    [-Strict]
    [-OutputPath <String>]
    [-OutputFileName <String>]
    [-OutputFormat <int32>]
    [-NoDeletion]
    [-NoKeyDeletion]
    [-NoValueDeletion]
    [-MultiDeclarationWarning]
    [-IgnoreConflicts]
    [-Passthru]
    [<CommonParameters>]
```

```powershell
Merge-SPSRegistryContent
    -Path <System.IO.FileInfo>
    [-Strict]
    [-OutputPath <String>]
    [-OutputFileName <String>]
    [-OutputFormat <int32>]
    [-NoDeletion]
    [-NoKeyDeletion]
    [-NoValueDeletion]
    [-MultiDeclarationWarning]
    [-IgnoreConflicts]
    [-Passthru]
    [<CommonParameters>]
```
### Description
the `Merge-SPSRegistryContent` cmdlets will merge a set of `Registry` object or the content of a `path` into a single `registry` object.

### Examples

### Example 1: Merge registry content from a `System.IO.FileInfo` path
```powershell
Merge-SPSRegistryContent -Path 'C:\Registry' -OutputPath 'C:\Merged\' -OutputFileName 'Merged.reg'
```

This command merges all registry file present in `C:\Registry` into a new registry file named `Merged.reg` and located at `C:\Merged\`.

### Example 2: Merge from `Registry` object
```powershell
$Registries = Get-ChildItem 'C:\Registry' -file
Merge-SPSRegistryContent -InputObject $Registries
```

This command retrieve all registry file present in `C:\Registry` and convert them into 'Registry' Object. It then create a new registry file named `Merged.reg` and located at `C:\Merged\`.

### Parameters

**\-InputObject**

    the InputObject <Registry[]> Parameter define a set of <Registry> object to be merged.

| <!-- -->               | <!-- -->           |
|:-----------------------|:-------------------|
| Type :                 | Registry []        |
| Position :             | 1                  |
| Default value:         | None               |
| Required:              | True               |
| Accept pipeline input: | False              |
| <!-- -->               | <!-- -->           |

**\-Path**

    the Path <String> Parameter define the location containing the registry file to merge

| <!-- -->               | <!-- -->           |
|:-----------------------|:-------------------|
| Type :                 | System.IO.FileInfo |
| Position :             | 1                  |
| Alias :                | FullName           |
| Default value:         | None               |
| Required:              | True               |
| Accept pipeline input: | False              |
| <!-- -->               | <!-- -->           |

**\-Strict**

    the Strict <Switch> parameter define if the function should allow malformed lines in the registry file. 
    Otherwyse these lines as stored in an UnknownLines parameter in the outputed <Registry> Object / registry file.

| <!-- -->               | <!-- -->           |
|:-----------------------|:-------------------|
| Type :                 | Switch             |
| Position :             | 2                  |
| Default value:         | false              |
| Required:              | false              |
| Accept pipeline input: | false              |
| <!-- -->               | <!-- -->           |

**\-OutputPath**
    
    (Default Value: "$PSScriptRoot\Output" )
    the OutputPath <String> parameter define the output folder where the merged registry will be written.

| <!-- -->               | <!-- -->           |
|:-----------------------|:-------------------|
| Type :                 | String             |
| Position :             | 3                  |
| Default value:         | .\Output\          |
| Required:              | false              |
| Accept pipeline input: | false              |
| <!-- -->               | <!-- -->           |

**\-OutputFileName**

    (Default Value: "MergedRegistry.reg" )
    the OutputFileName <String> parameter define the name of the merged registry output file. 

| <!-- -->               | <!-- -->           |
|:-----------------------|:-------------------|
| Type :                 | String             |
| Position :             | 4                  |
| Default value:         | MergedRegistry.reg |
| Required:              | false              |
| Accept pipeline input: | false              |
| <!-- -->               | <!-- -->           |

**\-OutputFormat**

    (Default Value: 5)
    (Allowed Value: 4,5)
    the OutputFormat <Switch> parameter define the registry format for the outputed registry file. 

| <!-- -->               | <!-- -->           |
|:-----------------------|:-------------------|
| Type :                 | Int                |
| Position :             | 5                  |
| Default value:         | 5                  |
| Accepted value:        | 4,5                |
| Required:              | false              |
| Accept pipeline input: | false              |
| <!-- -->               | <!-- -->           |

**\-NoDeletion**

    the NoDeletion <Switch> parameter define if deletion present in inputed <registry> files or objects should be ignored.
    Settings NoDeletion will set the NoKeyDeletion and NoValueDeletion <switch> to $true

| <!-- -->               | <!-- -->           |
|:-----------------------|:-------------------|
| Type :                 | Switch             |
| Position :             | 6                  |
| Default value:         | false              |
| Required:              | false              |
| Accept pipeline input: | false              |
| <!-- -->               | <!-- -->           |

**\-NoKeyDeletion**

    the NoKeyDeletion <Switch> parameter define if key deletion present in inputed <registry> files or objects should be ignored.

| <!-- -->               | <!-- -->           |
|:-----------------------|:-------------------|
| Type :                 | Switch             |
| Position :             | 7                  |
| Default value:         | false              |
| Required:              | false              |
| Accept pipeline input: | false              |
| <!-- -->               | <!-- -->           |

**\-NoValueDeletion**

    the NoValueDeletion <Switch> parameter define if value deletion present in inputed <registry> files or objects should be ignored.

| <!-- -->               | <!-- -->           |
|:-----------------------|:-------------------|
| Type :                 | Switch             |
| Position :             | 8                  |
| Default value:         | false              |
| Required:              | false              |
| Accept pipeline input: | false              |
| <!-- -->               | <!-- -->           |

**\-MultiDeclarationWarning**

    the MultiDeclarationWarning <Switch> parameter define if a warning should be thrown if a value is declared more than once.

| <!-- -->               | <!-- -->           |
|:-----------------------|:-------------------|
| Type :                 | Switch             |
| Position :             | 9                  |
| Default value:         | false              |
| Required:              | false              |
| Accept pipeline input: | false              |
| <!-- -->               | <!-- -->           |

**\-IgnoreConflicts**

    the IgnoreConflicts <Switch> parameter define if a warning should be thrown when a registry name is set with different value. 
    If ommited registry name with different value will throw an error.

| <!-- -->               | <!-- -->           |
|:-----------------------|:-------------------|
| Type :                 | Switch             |
| Position :             | 10                 |
| Default value:         | false              |
| Required:              | false              |
| Accept pipeline input: | false              |
| <!-- -->               | <!-- -->           |

**\-Passthru**

    the Passthru <Switch> parameter define if the output should be a file (defined by OutputPath and OutputFileName) or a <Registry> object

| <!-- -->               | <!-- -->           |
|:-----------------------|:-------------------|
| Type :                 | Switch             |
| Position :             | 11                 |
| Default value:         | false              |
| Required:              | false              |
| Accept pipeline input: | false              |
| <!-- -->               | <!-- -->           |

