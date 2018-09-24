# SwissPowershell Merge Optimize and Clean Registry
Powershell Function to merge optimize and clean registry file(s)

## Merge-RegistryFiles Function
### -InputFile
File to merge / optimize location 
### -InputPath
Path location containing registry files to merge
### -OutputPath
Output Path (Default ScriptDir\Out)
### -OutputFileName
Output File Name (Default MergedRegistry.Reg)
### -OutputFormat
Registry File output Format (Version 4 or 5)
### -NoDeletion
Ignore key and keypair deletion

*  *[-HKEY_...]* Will be ignored

*  *"Name"=-* Will be ignored
### -NoKeyDeletion
Ignore key deletion

*  *[-HKEY_...]* Will be ignored
### -NoValueDeletion
Ignore value keypair deletion

*  *"Name"=-* Will be ignored
### -NoEmptyKey
Ignore Key having no KeyPair (Ignore key full tree declaration)

### -NoFiltering
Only merge the different registry as is without filtering

### -ErrorOnMultiDeclaration
Return an error if a KeyPair is declared more than once

### -ErrorOnConflicts
Return an error if a KeyPair is declared more than once with different values (will ignore by default)

### -ErrorOnUnreadableFile
Return an error if input file is not readable

### -NoProgress
Hide progress bar to enhance performances on big registry files

### -NoWarning
Hide all warnings

## Example
     $RegistryFile = Merge-RegistryFiles -InputPath 'C:\...\TESTFILES\REGISTRY_TESTIN' -OutputPath 'C:\...\TESTFILES\REGISTRY_OUT' -NoDeletion -OutputFileName "MergedRegistryCoherence.Reg" -NoProgress -ErrorOnConflicts
	 
	 $RegistryFile = Merge-RegistryFiles -InputPath 'C:\...\TESTFILES\REGISTRY_TESTIN' -OutputPath 'C:\...\TESTFILES\REGISTRY_OUT' -NoDeletion -NoEmptyKey -OutputFileName "MergedRegistry.Reg" -NoProgress -NoWarning
	 
	 $RegistryFile = Merge-RegistryFiles -InputPath 'C:\...\TESTFILES\REGISTRY_TESTIN' -OutputPath 'C:\...\TESTFILES\REGISTRY_OUT' -NoDeletion -NoEmptyKey -ErrorOnUnreadableFile -NoProgress -OutputFileName "Registry.Reg"
