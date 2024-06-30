# File to test the SPS-MergeRegistry module
this file should be detected as a non registry File
a warning message should be thrown while trying to read it using Get-SPSRegistryContent
an error message should be thrown while trying to read it using the new method of [Registry]

## Classic.reg (safe to merge)
- This reg file contains some value to be tested.

## ClassicV4.reg (safe to merge)
- This reg file contains some more value for "classic.reg" in a REGEDIT4 format
- This reg file should generate warning if **-MultiDeclarationWarning** switch is set to true

## CommentedClassic.reg (safe to merge)
- This reg file is "Classic.reg" with some valid comment in it.
- This reg file should generate warning if **-MultiDeclarationWarning** switch is set to true

## Classic.txt (safe to merge)
- This reg file the "classic.reg" keys but it's extension is .txt.

## BadlyFormated.reg (safe to merge)
- This reg file is some of the "Classic.reg" but with realy bad formated lines.

## Conflict_KeyDeletion.reg (error on merge)
- This reg file contains some Key deletion conflict against "Classic.reg".
- This reg file should generate errors has it will delete key set in "Classic.reg"

## Conflict_ValueDeletion.reg (error on merge)
- This reg file contains some value deletion conflict against "Classic.reg".
- This reg file should generate errors has it will value set in "Classic.reg"

## Conflict_ValueConflict.reg (error on merge)
- This reg file contains some value conflict against "Classic.reg".
- This reg file should generate errors has it has value different than in "Classic.reg"

## Error_MalFormated.reg (error on merge if -strict otherwyse safe to merge)
- This reg contains mal formated lines and innexistant hive in it.
- If the switch **-Strict** is set this reg file should generate errors has it is malformated. otherwyse malformated line will just be ignored as regedit do.
