Enum RegistryVersion {
    V4 = 4
    V5 = 5
}
Enum RegistryHive {
    HKEY_CLASSES_ROOT
    HKEY_CURRENT_USER
    HKEY_LOCAL_MACHINE
    HKEY_USERS
    HKEY_CURRENT_CONFIG
    HKEY_PERFORMANCE_DATA
    HKEY_DYN_DATA
}
# MARK: RegistryValue Class
Class RegistryValue {
    [System.Collections.Generic.List[System.IO.FileInfo]]   ${File} = [System.Collections.Generic.List[System.IO.FileInfo]]::New()
    [String]                                                ${ParentHive} = ''
    [String]                                                ${ParentKey} = ''
    [String]                                                ${Name} = ''
    [String]                                                ${Value} = ''
    [Boolean]                                               ${Delete} = $False
    RegistryValue(){}
    RegistryValue([RegistryValue] $Value){
        $this.ParentHive = $Value.ParentHive
        $this.ParentKey = $Value.ParentKey
        $this.Name = $Value.Name
        $this.Delete = $Value.Delete
        $this.Value = $Value.Value
    }
    RegistryValue([System.IO.FileInfo[]] $File, [String]$ParentKey,[String]$ParentHive,[String]$Name,[String]$Value) {
        if ($Value -eq '-'){
            $this.Value = $Value.Trim()
            $this.Delete = $True
        }Else{
            $this.Value = $Value.Trim()
        }
        $this.File = $File
        $this.ParentKey = $ParentKey
        $this.ParentHive = $ParentHive
        $this.Name = $Name
    }
    [String] ToString() {
        if ($This.Name -eq '@') {
            $Str = "$($this.Name)=$($this.Value)"
        }Else{
            $Str = "`"$($this.Name)`"=$($this.Value)"
        }
        Return $Str
    }
}
# MARK: RegistryKey Class
Class RegistryKey {
    [System.Collections.Generic.List[System.IO.FileInfo]]   ${File} = [System.Collections.Generic.List[System.IO.FileInfo]]::New()
    [String]                                                ${Key} = ''
    [String]                                                ${Hive} = ''
    [String]                                                ${KeyPath} = ''
    [System.Collections.Generic.List[RegistryValue]]        ${Values} = [System.Collections.Generic.List[RegistryValue]]::New()
    [System.Collections.Generic.List[String]]               ${Comments} = [System.Collections.Generic.List[String]]::New()
    [System.Collections.Generic.List[String]]               ${UnknowLines} = [System.Collections.Generic.List[String]]::New()
    [Boolean]                                               ${Delete} = $False
    Hidden [String]                                         ${__content} = ''
    RegistryKey(){}
    RegistryKey([RegistryKey] $RegKey) {
        $This.Key = $RegKey.Key
        $this.hive = $RegKey.Hive
        $this.KeyPath = $RegKey.KeyPath
    }
    RegistryKey([System.IO.FileInfo[]] $File, [String] $Key, [String] $Hive,[String] $KeyPath,[String] $Content,[Boolean] $IsDeletion) {
        $This.File = $File
        $This.Hive = $Hive
        $This.Key = $Key
        $This.KeyPath = $KeyPath
        $This.__content = $Content
        $This.Delete = $IsDeletion
        $This.__convertContent()
    }
    hidden [Void] __convertContent() {
        [Regex] $RegexValueKeyPair = '[\t ]*("(?<Name>.+)"|(?<Default>@))[\t ]*=[\t ]*(?<Value>"(?:[^"\\]|\\.)*"|[^"]+)'
        [Regex] $CommentRegex = '^(?<CommentLine>[\t ]*;.*)$'
        $ValuesResult = Select-String -InputObject $This.__content -Pattern $RegexValueKeyPair -AllMatches
        $RemainingContent = $This.__content
        if ($ValuesResult) {
            ForEach ($Match in $ValuesResult.Matches) {
                $Groups = $Match.Groups
                $RemainingContent = $RemainingContent.replace($Match.Value,'')
                if (($Groups | Where-Object Name -eq 'Default' | Select-Object -ExpandProperty 'Value') -eq '@') {
                    $Name = '@'
                }Else{
                    $Name = $Groups | Where-Object Name -eq 'Name' | Select-Object -ExpandProperty 'Value'
                }
                $Value = $Groups | Where-Object Name -eq 'Value' | Select-Object -ExpandProperty 'Value'
                $ValueList = @($Value -split '\r\n' | Where-Object {$_.trim()})
                if ($ValueList.count -gt 1) {
                    # Its a multiline value check if there is no "comment" or badly formated line in it
                    [Regex] $HexValue = '^hex(\(.*\))*:'
                    [Regex] $DwordValue = '^dword(\(.*\))*:'
                    if ($Value -match $HexValue) {
                        # First line should be ok testing the next line
                        $NewValueList = [System.Collections.Generic.List[String]]::New()
                        $NewValueList.Add($($ValueList[0])) | out-null
                        $isHexValue = $false
                        For($i = 1;$i -lt $ValueList.Count;$i++) {
                            if ($isHexValue) {
                                if (($ValueList[$i] -match '^\s*([0-9a-fA-F]{2},)+\\?') -or ($ValueList[$i] -match '^\s*([0-9a-fA-F]{2})')) {
                                    # this line is part of the multiline
                                    $NewValueList.Add($($ValueList[$i])) | out-null
                                } else {
                                    # Reached the end of hex value
                                    $isHexValue = $false
                                    $ValueKeyPair = [RegistryValue]::New($This.File, $This.Key, $This.Hive, $Name, $NewValueList -join "`r`n")
                                    $This.Values.Add($ValueKeyPair)
                                    $i-- # Revisit the current line in the next iteration
                                }
                            } elseif (($ValueList[$i] -match '^\s*([0-9a-fA-F]{2},)+\\?') -or ($ValueList[$i] -match '^\s*([0-9a-fA-F]{2})')) {
                                # Start of hex value
                                $isHexValue = $true
                                $NewValueList.Add($($ValueList[$i]))
                            } elseif ($ValueList[$i] -match $CommentRegex) {
                                # this line is a comment
                                $This.Comments.add($($ValueList[$i])) | out-null
                            } else {
                                # Reached an unknown line it can surely not be an hex value line
                                $This.UnknowLines.add($($ValueList[$i..($ValueList.Count - 1)])) | out-null
                                BREAK
                            }
                            if ($i -eq ($ValueList.Count - 1)) {
                                # Reached the end of the value
                                $ValueKeyPair = [RegistryValue]::New($This.File, $This.Key, $This.Hive, $Name, $NewValueList -join "`r`n")
                                $This.Values.Add($ValueKeyPair)
                            }
                        }
                    }ElseIf($Value -match $DwordValue) {
                        # a DWORD Value cannot be multiline...
                        $GoodValue = $ValueList[0]
                        $ValueKeyPair = [RegistryValue]::New($This.File,$This.Key,$This.Hive,$Name,$GoodValue)
                        $This.Values.Add($ValueKeyPair)
                        $BadLines = $ValueList | Where-Object {$_ -notlike $GoodValue} | Where-Object {$_.trim()} | Where-Object {$_ -notmatch $CommentRegex}
                        $BadLines | ForEach-Object {$this.UnknowLines.Add($_) | out-null}
                    }Else{
                        # Unhandled for now
                        Write-Warning 'A multiline with a unknown format'
                        $ValueKeyPair = [RegistryValue]::New($This.File,$This.Key,$This.Hive,$Name,$Value)
                        $This.Values.Add($ValueKeyPair)
                    }
                    
                }Else{
                    if (($Name -notlike '') -and ($Value -notlike '')){
                        $ValueKeyPair = [RegistryValue]::New($This.File,$This.Key,$This.Hive,$Name,$Value)
                        $This.Values.Add($ValueKeyPair)
                    }
                }                
            }
        }
    }
    [string] ToString() {
        $String = $This.Key
        if ($This.Delete -eq $True) {
            $String = "-$String"
        }
        $String = "[$String]"
        ForEach ($Value in $This.Values) {
            $String = @"
$String
$($Value.ToString())
"@
        }
        Return $String
    }
}
# MARK: Registry Class
Class Registry {
    [System.Collections.Generic.List[System.IO.FileInfo]]   ${File} = [System.Collections.Generic.List[System.IO.FileInfo]]::New()
    [System.Text.Encoding]                                  ${Encoding} = [System.Text.Encoding]::Default
    [RegistryVersion]                                       ${Version} = [RegistryVersion]::V5
    [System.Collections.Generic.List[RegistryKey]]          ${Keys} = [System.Collections.Generic.List[RegistryKey]]::New()
    [System.Collections.Generic.List[String]]               ${Comments} = [System.Collections.Generic.List[String]]::New()
    [System.Collections.Generic.List[String]]               ${UnknownLines} = [System.Collections.Generic.List[String]]::New()
    Hidden [String]                                         ${__rawContent} = ''
    Hidden [String]                                         ${__content} = ''
    Hidden [System.Collections.Generic.List[String]]        ${__lines} = [System.Collections.Generic.List[String]]::New()
    Registry(){}
    Registry([System.IO.FileInfo] $File) { # Create a Registry object from a file
        $this.__BuildObject($File, $False)
    }
    Registry([System.IO.FileInfo] $File, [Boolean] $Strict) { # Create a Registry object from a file
        $this.__BuildObject($File, $Strict)
    }
    hidden [void] __BuildObject([System.IO.FileInfo] $File, [Boolean] $Strict) {
        Write-Verbose "`t Reading file: $($File.Name)"
        $EncodingList = @([System.Text.Encoding]::Default,[System.Text.Encoding]::Unicode,[System.Text.Encoding]::ASCII,[System.Text.Encoding]::BigEndianUnicode,[System.Text.Encoding]::UTF32,[System.Text.Encoding]::UTF7,[System.Text.Encoding]::UTF8)
        # A registry file can be in two format REGEDIT4 or Windows Registry Editor Version 5.00, it's always the first line and it's always followed by an empty line
        [REGEX] $Registry5Regex = '^Windows Registry Editor Version 5\.00\r\n\r\n'
        [REGEX] $Registry4Regex = '^REGEDIT4\r\n\r\n'
        $FoundEncoding = $False
        # try to find the encoding by detecting the first line
        ForEach ($EncodingType in $EncodingList) {
            $This.__rawContent = Get-Content -Path $File -Raw -Encoding $EncodingType -WarningAction SilentlyContinue -ErrorAction SilentlyContinue
            if (($This.__rawContent -Match $Registry4Regex) -or ($This.__rawContent -match $Registry5Regex)) {
                if ($This.__rawContent -match $Registry4Regex) {$This.Version = [RegistryVersion]::V4}
                # This encoding match do not search for an another one
                # Write-Verbose "Encoding for file is [$($EncodingType)]"
                $FoundEncoding = $True
                $This.Encoding = $EncodingType
                $This.__content = $This.__rawContent -Replace $Matches.Values
                $This.__lines = $This.__content -split '\r\n'
                BREAK
            }
        }
        if ($FoundEncoding -eq $True) {
            $This.File.Add($File)
            $This.__convertContent()
        }Else{
            # Write-Warning 'This file cannot be read'
            $Message = "'$($File.Name)' is not a valid registry file."
            $ErrorRecord = [System.Management.Automation.ErrorRecord]::new(
                [System.IO.FileFormatException]::new($Message),
                'InvalidRegistryFile',
                [System.Management.Automation.ErrorCategory]::InvalidData,
                $File.Name
            )
            Throw $ErrorRecord
        }
        if ($Strict) {
            if($this.UnknownLines.Count -gt 0){
                $Message = "'$($File.Name)' contains $($this.UnknownLines.Count) unknown line(s)."
                $ErrorRecord = [System.Management.Automation.ErrorRecord]::new(
                    [System.FormatException]::new($Message),
                    'InvalidRegistryContent',
                    [System.Management.Automation.ErrorCategory]::InvalidData,
                    $File.Name
                )
                Throw $ErrorRecord
            }
        }
    }
    hidden [Void] __convertContent(){
        $HivePattern = [RegistryHive]::GetNames([RegistryHive]) -join '|'
        # [Regex] $RegexKey = "(?<FullKey>([\t ]*\[(?<KeyDeletion>-)?(?<Key>(?<Hive>$($HivePattern))(?<KeyPath>.*))\]))"
        # [Regex] $KeyLike = "(?<FullKey>([\t ]*\[(?<KeyDeletion>-)?(?<Key>(?<Hive>.*)(?<KeyPath>\\.*))\]))" # To handle malformated keys
        [Regex] $RegexKey = "(\n|^)(?<FullKey>([\t ]*\[(?<KeyDeletion>-)?(?<Key>(?<Hive>$($HivePattern))(?<KeyPath>.*))\]))"
        [Regex] $KeyLike = "(\n|^)(?<FullKey>([\t ]*\[(?<KeyDeletion>-)?(?<Key>(?<Hive>.*)(?<KeyPath>\\.*))\]))"
        # Search all Key in the content 
        $KeyResult = Select-String -InputObject $This.__content -Pattern $KeyLike -AllMatches
        # init the remaining content
        $RemainingContent = ''
        if ($KeyResult) {
            # Get the number of key to analyse
            $MatchCount = $KeyResult.Matches.Count
            For($i = 0;$i -lt $MatchCount;$i ++){
                $Match = $KeyResult.Matches[$i]
                $Groups = $Match.Groups
                $StartPos = $Match.Index + $Match.Length
                If ($i -eq 0){
                    #Get the remaining content, remove empty lines
                    $RemainingContent = ($This.__content.Substring(0,$Match.Index) -Split '\r\n') | Where-Object {$_.Trim()}
                }
                if ($i -eq ($MatchCount - 1)){
                    #LastMatch take the remaining content
                    $ValuesContent = $This.__content.Substring($StartPos)
                }Else{
                    $EndPos = ($KeyResult.Matches[$i + 1] | Select-Object -ExpandProperty 'Index') - 1
                    $Length = $EndPos - $StartPos
                    # everything between the key and the next key are the values
                    $ValuesContent = $This.__content.Substring($StartPos,$Length)
                }
                $FullKey = $Groups | Where-Object {$_.Name -eq 'FullKey'} | Select-Object -ExpandProperty 'Value'
                # Check that the detected key is really a key and not a malformed key
                if ($FullKey -match $RegexKey) {
                    $Hive = $Groups | Where-Object {$_.Name -eq 'Hive'} | Select-Object -ExpandProperty 'Value'
                    $KeyPath = $Groups | Where-Object {$_.Name -eq 'KeyPath'} | Select-Object -ExpandProperty 'Value'
                    $RegKey = $Groups | Where-Object {$_.Name -eq 'Key'} | Select-Object -ExpandProperty 'Value'
                    $KeyDeletion = ($Groups | Where-Object {$_.Name -eq 'KeyDeletion'} | Select-Object -ExpandProperty 'Value') -eq '-'
                    $Key = [RegistryKey]::New($this.File,$RegKey,$Hive,$KeyPath,$ValuesContent,$KeyDeletion)
                    $This.Keys.Add($Key)
                }Else{
                    # A Malformated key has been found store what 'Seems' to be part of it as remaining content
                    # Write-Warning "Malformated key found: $FullKey"
                    $RemainingContent = $RemainingContent + $FullKey + $ValuesContent.Trim()
                }
            }
            # handle anything found before the first key
            # it can only contains empty line or comment lines
            [Regex] $CommentRegex = '^(?<CommentLine>[\t ]*;.*)$'
            $This.Comments = $RemainingContent | Where-Object {$_ -match $CommentRegex} | Where-Object {$_.trim() -notlike ''}
            $This.UnknownLines = $RemainingContent | Where-Object {$_ -notmatch $CommentRegex} | Where-Object {$_.trim() -notlike ''}
        }
    }
    [String] ToString() {
        $String = ''
        if ($This.Version -eq [RegistryVersion]::V4) {
            $String = 'REGEDIT4'
        }Else{
            $String = 'Windows Registry Editor Version 5.00'
        }
        $String = @"
$String
"@
        ForEach ($Key in $This.Keys) {
            $String = @"
$String

$($Key.ToString())
"@
        }
        Return $String
    }
}
# MARK: Get-SPSRegistryContent
Function Get-SPSRegistryContent {
    [CMDLetBinding()]
    <#
    .SYNOPSIS
    Read a registry file and convert it to a Registry object.
    .DESCRIPTION
    This function read a registry file and convert it to a Registry object.
    .PARAMETER File
    The path to the registry file to read.
    .PARAMETER Strict
    Set the strict mode for the function.
    .EXAMPLE
    Get-SPSRegistryContent -File 'C:\Temp\test.reg'
    Read the file 'C:\Temp\test.reg' and convert it to a Registry object.
    .EXAMPLE
    Get-SPSRegistryContent -File (Get-ChildItem -Path 'C:\Temp' -Filter '*.reg')
    Read all the registry files in the folder 'C:\Temp' and convert them to Registry objects.
    .INPUTS
    [System.IO.FileInfo[]]
    .OUTPUTS
    [Registry]
    .NOTES
    File Name      : Get-SPSRegistryContent
    Author         : Swiss Powershell
    Prerequisite   : PowerShell V5
    #>
    Param(
        [Parameter(
            Position = 1,
            Mandatory = $True,
            ValueFromPipeline = $True,
            ValueFromPipelineByPropertyName = $True,
            HelpMessage = 'The path to the registry file to read'
        )]
        [Alias('FullName')]
        [ValidateScript({Test-Path $_ -PathType Leaf},ErrorMessage="The input should be an existing file")]
        [System.IO.FileInfo[]] $File,
        [Parameter(
            Position = 2,
            Mandatory = $False,
            HelpMessage = 'Set the strict mode for the function'
        )]
        [Switch] ${Strict}
    )
    BEGIN {
        #region Function initialisation DO NOT REMOVE
        [DateTime] ${FunctionEnterTime} = [DateTime]::Now ; Write-Verbose "Entering : $($MyInvocation.MyCommand)"
        #endregion Function initialisation DO NOT REMOVE
    }
    PROCESS {
        #region Function Processing DO NOT REMOVE
        Write-Verbose "Processing : $($MyInvocation.MyCommand)"
        #endregion Function Processing DO NOT REMOVE
        ForEach($SingleFile in $File){
            try {
                [Registry]::New($SingleFile,$Strict)
            } catch [System.IO.FileFormatException] {
                Write-Warning "$($_.Exception.Message) file will be ignored."
            } catch [System.FormatException] {
                if ($Strict) {
                    throw $_
                }Else{
                    Write-Warning "$($_.Exception.Message) line(s) will be ignored. Review the file to prevent this message."
                }
            } catch {
                Write-Warning "An error occured while converting the file: $($_.Exception.Message)"
            }
        }
    }
    END {
        $TimeSpentinFunc = New-TimeSpan -Start $FunctionEnterTime -Verbose:$False -ErrorAction SilentlyContinue;$TimeUnits = [ORDERED] @{TotalDays = "$($TimeSpentinFunc.TotalDays) D.";TotalHours = "$($TimeSpentinFunc.TotalHours) h.";TotalMinutes = "$($TimeSpentinFunc.TotalMinutes) min.";TotalSeconds = "$($TimeSpentinFunc.TotalSeconds) s.";TotalMilliseconds = "$($TimeSpentinFunc.TotalMilliseconds) ms."}
        ForEach ($Unit in $TimeUnits.GetEnumerator()) {if ($TimeSpentinFunc.($Unit.Key) -gt 1) {$TimeSpentString = $Unit.Value;break}};if (-not $TimeSpentString) {$TimeSpentString = "$($TimeSpentinFunc.Ticks) Ticks"}
        Write-Verbose "Ending : $($MyInvocation.MyCommand) - TimeSpent : $($TimeSpentString)"
        #endregion Function closing DO NOT REMOVE
    }
}
# MARK: Merge-SPSRegistryContent
Function Merge-SPSRegistryContent {
    [CMDLetBinding(DefaultParameterSetName = 'byRegistry')]
    <#
    .SYNOPSIS
    Merge multiple registry objects into a single registry object.
    .DESCRIPTION
    This function merge multiple registry objects into a single registry object.
    .PARAMETER InputObject
    The registry object to merge.
    .PARAMETER Path
    The path containing registry files to merge.
    .PARAMETER Strict
    Set the strict mode for the function.
    .PARAMETER OutputPath
    Output path for the merged registry file.
    .PARAMETER OutputFileName
    Output file name for the merged registry file.
    .PARAMETER OutputFormat
    Output format for the merged registry file (4 for REGEDIT4, 5 for Windows Registry Editor Version 5.00).
    .PARAMETER NoDeletion
    Exclude all deletion from the merged registry file.
    .PARAMETER NoKeyDeletion
    Exclude Key deletion from the merged registry file.
    .PARAMETER NoValueDeletion
    Exclude Value deletion from the merged registry file.
    .PARAMETER MultiDeclarationWarning
    Throw a warning message on multi declaration.
    .PARAMETER IgnoreConflicts
    Ignore conflicts if this switch is set no error will be thrown for conflicting values.
    .EXAMPLE
    $Reg1 = Get-SPSRegistryContent -File 'C:\Temp\test1.reg'
    $Reg2 = Get-SPSRegistryContent -File 'C:\Temp\test2.reg'
    Merge-SPSRegistryContent -InputObject $Reg1,$Reg2
    Merge the two registry objects into a single registry object.
    .EXAMPLE
    Merge-SPSRegistryContent -Path 'C:\Temp'
    Merge all the registry files in the folder 'C:\Temp' into a single registry object.
    .INPUTS
    [Registry[]]
    .OUTPUTS
    [Registry]
    .NOTES
    File Name      : Merge-SPSRegistryContent
    Author         : Swiss Powershell
    Prerequisite   : PowerShell V5
    #>
    Param(
        [Parameter(
            Position = 1,
            Mandatory = $True,
            ParameterSetName = 'byRegistry',
            HelpMessage = 'The registry object to merge.'
        )]
        [Registry[]] $InputObject,
        [Parameter(
            Position = 1,
            Mandatory = $True,
            ParameterSetName = 'byPath',
            HelpMessage = 'The path containing registry files to merge.'
        )]
        [Alias('FullName')]
        [ValidateScript({Test-Path $_ -PathType Container},ErrorMessage="The input should be an existing folder")]
        [System.IO.FileInfo[]] $Path,
        [Parameter(
            Position = 2,
            Mandatory = $False,
            ParameterSetName = 'byPath',
            HelpMessage = 'Set the strict mode for the function.'
        )]
        [Switch] ${Strict},
        [Parameter(
            Position = 3,
            ParameterSetName='__AllParameterSets',
            HelpMessage='Output path for the merged registry file.'
        )]
        [String] ${OutputPath}="$($PSScriptRoot)\output",
        [Parameter(
            Position = 4,
            ParameterSetName='__AllParameterSets',
            HelpMessage='Output file name for the merged registry file.'
        )]
        [String] ${OutputFileName}='MergedRegistry.reg',
        [Parameter(
            Position = 5,
            ParameterSetName='__AllParameterSets',
            HelpMessage='Output format for the merged registry file (4 for REGEDIT4, 5 for Windows Registry Editor Version 5.00).'
        )]
        [ValidateSet(4,5)]
        [Int32] ${OutputFormat}=5,
        [Parameter(
            Position = 6,
            ParameterSetName='__AllParameterSets',
            HelpMessage='Exclude all deletion from the merged registry file.'
        )]
        [Switch] ${NoDeletion},
        [Parameter(
            Position = 7,
            ParameterSetName='__AllParameterSets',
            HelpMessage='Exclude Key deletion from the merged registry file.'
        )]
        [Switch] ${NoKeyDeletion},
        [Parameter(
            Position = 8,
            ParameterSetName='__AllParameterSets',
            HelpMessage='Exclude Value deletion from the merged registry file.'
        )]
        [Switch] ${NoValueDeletion},
        [Parameter(
            Position = 9,
            ParameterSetName='__AllParameterSets',
            HelpMessage='Throw a warning message on multi declaration.'
        )]
        [Switch] ${MultiDeclarationWarning},
        [Parameter(
            Position = 10,
            ParameterSetName='__AllParameterSets',
            HelpMessage='Ignore conflicts if this switch is set no error will be thrown for conflicting values.')]
        [Switch] ${IgnoreConflicts},
        [Parameter(
            Position = 11,
            ParameterSetName='__AllParameterSets',
            HelpMessage='Return the merged registry object.')]
        [Switch] ${Passthru}
    )
    BEGIN {
        #region Function initialisation DO NOT REMOVE
        [DateTime] ${FunctionEnterTime} = [DateTime]::Now ; Write-Verbose "Entering : $($MyInvocation.MyCommand)"
        #endregion Function initialisation DO NOT REMOVE
        # Handle Deletion choice
        if ($NoDeletion) {
            $NoKeyDeletion = $True
            $NoValueDeletion = $True
        }

        # handle the input if it's a path
        if ($PSCmdlet.ParameterSetName -eq 'byPath') {
            $InputObject = Get-ChildItem -Path $Path -File | Get-SPSRegistryContent -Strict:$Strict
        }
        # Create the output object to store the merged registry
        $OutputRegistry = [Registry]::New()
        if ($OutputFormat -eq 4) {
            $OutputRegistry.Version = [RegistryVersion]::V4
        }Else{
            $OutputRegistry.Version = [RegistryVersion]::V5
        }
        $OutputRegistry.File = $InputObject.File | Select-Object -Unique
        $OutputRegistry.Comments = $InputObject.Comments
    }
    PROCESS {
        #region Function Processing DO NOT REMOVE
        Write-Verbose "Processing : $($MyInvocation.MyCommand)"
        #endregion Function Processing DO NOT REMOVE
        # Group the registry keys by key
        $GroupedKeys = $InputObject | Select-Object -ExpandProperty 'Keys' | Group-Object -Property 'Key'
        # Handle the grouped keys
        ForEach ($Key in $GroupedKeys) {
            $KeyGroup = $Key.Group
            $KeyObject = [RegistryKey]::New()
            $KeyObject.File = $KeyGroup.File | Select-Object -Unique
            $KeyObject.Key = $KeyGroup[0].Key
            $KeyObject.Hive = $KeyGroup[0].Hive
            $KeyObject.KeyPath = $KeyGroup[0].KeyPath
            $KeyObject.Delete = $KeyGroup[0].Delete
            $KeyObject.Comments = $KeyGroup | Select-Object -ExpandProperty 'Comments'
            if ($NoKeyDeletion) {
                $KeyGroup = $KeyGroup | Where-Object Delete -eq $false
            }Else{
                # Search for deletion conflicts
                forEach ($RegKey in $KeyGroup) {
                    if ($RegKey.Delete -ne $KeyObject.Delete ) {
                        if ($IgnoreConflicts) {
                            Write-Warning "Deletion conflict detected for key $($RegKey.Key)."
                        }Else{
                            $Message = "Deletion conflict detected for key $($RegKey.Key)."
                            $ErrorRecord = [System.Management.Automation.ErrorRecord]::new(
                                [System.InvalidOperationException]::new($Message),
                                'KeyConflict',
                                [System.Management.Automation.ErrorCategory]::InvalidOperation,
                                $RegKey.Key
                            )
                            Throw $ErrorRecord
                        }
                    }
                }
            }
            # Handle the values
            $GroupedValues = $KeyGroup | Select-Object -ExpandProperty 'Values' | Group-Object -Property 'Name'
            if ($NoValueDeletion) {
                $GroupedValues = $GroupedValues | Where-Object delete -eq $false
            }
            ForEach ($RegValue in $GroupedValues) {
                $RegValueGroup = $RegValue.Group
                $ValueObject = [RegistryValue]::New()
                $ValueObject.File = $RegValueGroup.File | Select-Object -Unique
                $ValueObject.Name = $RegValueGroup[0].Name
                $ValueObject.ParentHive = $RegValueGroup[0].ParentHive
                $ValueObject.ParentKey = $RegValueGroup[0].ParentKey
                $ValueObject.Delete = $RegValueGroup[0].Delete
                $ValueObject.Value = $RegValueGroup[0].Value
                if ($MultiDeclarationWarning) {
                    if ($RegValue.Count -gt 1) {
                        Write-Warning "($($RegValue.Count)) declarations detected for value $($ValueObject.Name) in key $($ValueObject.ParentKey)."
                    }
                }
                ForEach ($RegVal in $RegValueGroup) {
                    # Search for Deletion conflicts
                    if ($RegVal.Delete -ne $ValueObject.Delete) {
                        if ($IgnoreConflicts) {
                            Write-Warning "Deletion conflict detected for value $($RegVal.Name) in key $($RegVal.ParentKey)."
                        }Else{
                            $Message = "Deletion conflict detected for value $($RegVal.Name) in key $($RegVal.ParentKey)."
                            $ErrorRecord = [System.Management.Automation.ErrorRecord]::new(
                                [System.InvalidOperationException]::new($Message),
                                'ValueConflict',
                                [System.Management.Automation.ErrorCategory]::InvalidOperation,
                                $RegVal.Name
                            )
                            Throw $ErrorRecord
                        }
                    }
                    # Search for conflicting Value
                    if ($RegVal.Value -ne $ValueObject.Value) {
                        if ($IgnoreConflicts) {
                            Write-Warning "Value conflict detected for $($RegVal.Name) in [$($RegVal.ParentKey)]. $($RegVal.Value) <> $($ValueObject.Value)."
                        }Else{
                            $Message = "Value conflict detected for value $($RegVal.Name) in [$($RegVal.ParentKey)]. $($RegVal.Value) <> $($ValueObject.Value)."
                            $ErrorRecord = [System.Management.Automation.ErrorRecord]::new(
                                [System.InvalidOperationException]::new($Message),
                                'ValueConflict',
                                [System.Management.Automation.ErrorCategory]::InvalidOperation,
                                $RegVal.Name
                            )
                            Throw $ErrorRecord
                        }
                    }
                }
                $KeyObject.Values.Add($ValueObject)
            }
            $OutputRegistry.Keys.Add($KeyObject)
        }
    }
    END {
        $TimeSpentinFunc = New-TimeSpan -Start $FunctionEnterTime -Verbose:$False -ErrorAction SilentlyContinue;$TimeUnits = [ORDERED] @{TotalDays = "$($TimeSpentinFunc.TotalDays) D.";TotalHours = "$($TimeSpentinFunc.TotalHours) h.";TotalMinutes = "$($TimeSpentinFunc.TotalMinutes) min.";TotalSeconds = "$($TimeSpentinFunc.TotalSeconds) s.";TotalMilliseconds = "$($TimeSpentinFunc.TotalMilliseconds) ms."}
        ForEach ($Unit in $TimeUnits.GetEnumerator()) {if ($TimeSpentinFunc.($Unit.Key) -gt 1) {$TimeSpentString = $Unit.Value;break}};if (-not $TimeSpentString) {$TimeSpentString = "$($TimeSpentinFunc.Ticks) Ticks"}
        Write-Verbose "Ending : $($MyInvocation.MyCommand) - TimeSpent : $($TimeSpentString)"
        #endregion Function closing DO NOT REMOVE
        #region outputing
        if ($Passthru) {
            Write-Output $OutputRegistry
        }else{
            # Create the output folder if not exist
            if (-not (Test-Path -Path $OutputPath -PathType Container)) {
                New-Item -Path $OutputPath -ItemType Directory | out-null
            }
            # Check for the output file and remove if exist
            $OutputFile = Join-Path -Path $OutputPath -ChildPath $OutputFileName
            if (Test-Path -Path $OutputFile -PathType Leaf) {
                Remove-Item -Path $OutputFile -Force | out-null
            }
            $OutputRegistry.ToString() | Out-File -FilePath $OutputFile -Encoding UTF8
        }
        #endregion outputing
    }
}
#region Expose the types and enums to the session as type accelerators. (thanks to Gael Colas for the heads up on this approach)
$ExportableTypes =@([Registry],[RegistryHive],[RegistryKey],[RegistryValue],[RegistryVersion])
# Get the internal TypeAccelerators class to use its static methods.
$TypeAcceleratorsClass = [PSObject].Assembly.GetType('System.Management.Automation.TypeAccelerators')
# Ensure none of the types would clobber an existing type accelerator.
# If a type accelerator with the same name exists, throw an exception.
$ExistingTypeAccelerators = $TypeAcceleratorsClass::Get
ForEach ($Type in $ExportableTypes) {
    if ($Type.FullName -in $ExistingTypeAccelerators.Keys) {
        $Message = @(
            "Unable to register type accelerator '$($Type.FullName)'"
            'Accelerator already exists.'
        ) -join ' - '
        $ErrorRecord = [System.Management.Automation.ErrorRecord]::new(
            [System.InvalidOperationException]::new($Message),
            'TypeAcceleratorAlreadyExists',
            [System.Management.Automation.ErrorCategory]::InvalidOperation,
            $Type.FullName
        )
        throw $ErrorRecord
    }
}
# Add type accelerators for every exportable type.
ForEach ($Type in $ExportableTypes) {
    $TypeAcceleratorsClass::Add($Type.FullName, $Type) | out-null
}
# Remove type accelerators when the module is removed.
$MyInvocation.MyCommand.ScriptBlock.Module.OnRemove = {
    ForEach ($Type in $ExportableTypes) {
        $TypeAcceleratorsClass::Remove($Type.FullName)
    }
}.GetNewClosure() | out-null
#endregion Export the types to the session as type accelerators.
