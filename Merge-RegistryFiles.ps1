Function Merge-RegistryFiles {
<#
    .SYNOPSIS
        Merge registry files
    .DESCRIPTION
        Merge filter and optimize registry files export to a registry file
    .EXAMPLE by file
        Merge-RegistryFile -InputFile c:\Temp\MyRegFile.reg
    .EXAMPLE by path
        Merge-RegistryFile -Inputpath c:\Temp\InputRegPath
    .PARAMETER InputFile
        Registry Input File path
    .PARAMETER InputPath
        Registry Input Path
    .PARAMETER OutputPath
        Output Registry Path (Default scriptdir\Out)
    .PARAMETER OutputFileName
        Output Registry FileName (Default MergedRegistry.reg)
    .PARAMETER OutputFormat
        Output Format for registry (Version 4 or 5)
    .PARAMETER NoDeletion
        Ignore Key and Value deletion
    .PARAMETER NoKeyDeletion
        Ignore Key Deletion
    .PARAMETER NoValueDeletion
        Ignore Value Deletion
    .PARAMETER NoEmptyKey
        Ignore Key without value(s)
    .PARAMETER NoFiltering
        The registry will only be merged without any filtering
    .PARAMETER ErrorOnMultiDeclaration
        Error when a Value is declared more than once
    .PARAMETER ErrorOnConflicts
        Error when a Value is declared more than once with different values
    .PARAMETER ErrorOnUnreadableFile
        Error if an input file is unreadable
    .PARAMETER NoProgress
        Hide progress bar
    .PARAMETER NoWarning
        Hide warnings
    .INPUTS
        File or path
    .OUTPUTS
        Registry File
    .LINK
    .NOTES
        Written by Yann Girardet
    .FUNCTIONALITY
        To merge the registry file
    .FORWARDHELPTARGETNAME <Get-Content>
#>
    [CmdletBinding(DefaultParameterSetName='ByPath')]
    Param(
        [Parameter(
            Mandatory=$True,
            ParameterSetName='ByFile'
            )]
        [ValidateScript({Test-Path $_ -PathType Leaf})]
        [String]
            ${InputFile},
        [Parameter(
            Mandatory=$True,
            ParameterSetName='ByPath'
            )]
        [ValidateScript({Test-Path $_ -PathType Container})]
        [String]
            ${InputPath},
        [String]
            ${OutputPath},
        [String]
            ${OutputFileName}="MergedRegistry.reg",
        [ValidateSet(4,5)]
        [Int32]
            ${OutputFormat}=5,
        [Switch]
            ${NoDeletion},
        [Switch]
            ${NoKeyDeletion},
        [Switch]
            ${NoValueDeletion},
        [Switch]
            ${NoEmptyKey},
        [Switch]
            ${NoFiltering},
        [Switch]
            ${ErrorOnMultiDeclaration},
        [Switch]
            ${ErrorOnConflicts},
        [Switch]
            ${ErrorOnUnreadableFile},
        [Switch]
            ${NoProgress},
        [Switch]
            ${NoWarning}
        )
    Begin {
        #Classes
        Class RegInfo_Value {
            hidden [String] $ExtractedValue
            hidden [String] $ExtractedParent
            [String] $ParentHive
            [String] $ParentKey
            [String] $Name
            [String] $Value
            [Boolean] $Delete = $false
        }
        Class RegInfo_Key {
            hidden [String] $ExtractedValue
            [String] $Hive
            [String] $Key
            [System.Collections.Generic.List[RegInfo_Value]] $Values
            [Boolean] $Delete = $False
        }
        #Progress and warning
        if ($NoProgress){
            $ProgressPreference = 'SilentlyContinue'
        }
        if ($NoWarning){
            $WarningPreference = 'SilentlyContinue'
        }
        #Function
        Function Get-RegFileContent {
            Param (
                [Array]
                    ${FileList},
                [Switch]
                    ${ErrorOnUnreadableFile}
            )
            Begin {
                Write-Progress -Activity 'Reading File Content...' -Status 'Initialize...' -PercentComplete 0
                $Max = $FileList.Count
                $Percent = 100 / $Max
                $PercentCompleted = 0
                $EncodingList = @([System.Text.Encoding]::Default,[System.Text.Encoding]::Unicode,[System.Text.Encoding]::ASCII,[System.Text.Encoding]::BigEndianUnicode,[System.Text.Encoding]::UTF32,[System.Text.Encoding]::UTF7,[System.Text.Encoding]::UTF8)
            }
            Process {
                #Append all reg files into one big list of string (remove reg declaration on top)
                $Content = New-Object System.Collections.Generic.List[System.String]
                ForEach($File in $FileList) {
                    $PercentCompleted = $PercentCompleted + $Percent
                    Write-Progress -Activity 'Reading File Content...' -Status 'Reading' -PercentComplete $PercentCompleted -CurrentOperation $File.Name
                    #Search for a good encoding by searching for Regedit4 or Windows Registry Editor in first line and an empty second line (definition from microsoft)
                    $FoundGoodEncoding = $False
                    ForEach ($Encoding in $EncodingList) {
                        if ($FoundGoodEncoding -eq $False){
                            $StreamReader = New-Object System.IO.StreamReader($File.FullName,$Encoding)
                            $FirstLine = $StreamReader.ReadLine().Trim()
                            $SecondLine = $StreamReader.ReadLine().Trim()
                            #ECM Bug correction sometimes when DEV put reg files on different format a ? appear as first char
                            If ($FirstLine.Length -gt 0) {if ($FirstLine.Substring(0,1) -eq '?'){
                                Write-Warning 'First char is a ? mean the registry output from linux like system and can be corrupted. This problem can occurs when a set of registry files are exported by ecm have did not have the same format'
                                $FirstLine = $FirstLine.Substring(1,$FirstLine.Length - 1)}
                            }
                            if ((($FirstLine -eq 'REGEDIT4') -or ($FirstLine -like 'Windows Registry Editor Version*'))-and($SecondLine -like $null)){
                                Write-Verbose "Encoding for file ($($File)) is $($Encoding)"
                                $FoundGoodEncoding = $True
                                While (($Line = $StreamReader.ReadLine()) -ne $Null) {
                                    $Line = $Line.Trim()
                                    if ($Line -notLike ''){
                                        $Content.Add($Line)
                                    }
                                }
                            }
                            $StreamReader.Close()
                        }                   
                    }
                    if ($FoundGoodEncoding -eq $False){
                        if ($ErrorOnUnreadableFile){
                            Write-Error "Unreadable File : $($File.FullName)"
                            Return $False
                        }Else{
                            Write-Warning "Ignore Unreadable File : $($File.FullName)"
                        }
                    }
                }
                Write-Verbose "Return $($Content.Count) Lines"
                Write-output $Content
            }
            End {
                Write-Progress -Activity 'Reading File Content...' -Status "Completed Return $($Content.Count) lines..." -PercentComplete 100 -Completed
            }
        }
        Function Convert-RegContent {
            Param(
                [System.Collections.Generic.List[System.String]]
                    ${Content},
                [Switch]
                    ${IgnoreDeletion},
                [Switch]
                    ${IgnoreKeyDeletion},
                [Switch]
                    ${IgnoreValueDeletion},
                [Switch]
                    ${IgnoreTreeDeclaration},
                [Switch]
                    ${NoFiltering},
                [Switch]
                    ${ErrorOnMultiDeclaration},
                [Switch]
                    ${ErrorOnConflicts},
                [Switch]
                    ${NoProgress}

            )
            Begin {
                Write-Progress -Activity 'Importing Registry Content...' -Status 'Initialize...' -PercentComplete 0
                Write-Verbose 'Importing Registry Content...'
                if ($Content){
                    $MaxObject = $Content.Count
                    $Percent = 100 / $MaxObject
                }Else{
                    $MaxObject = 0
                    $Percent = 0
                }
                $PercentCompleted = 0
                $LineCount = 0
            

                #Registry Regexes
                $RegEx_Registry4 = [regex] '^REGEDIT4$'
                $RegEx_Registry5 = [regex] '^Windows Registry Editor Version.*$'
                $RegEx_Key = [regex]'^[\[]HKEY_\w*[\\].*[\]]$'
                $RegEx_RemoveKey = [regex]'^[\[]-HKEY_\w*[\\].*[\]]$'
                $RegEx_Value = [regex]'^.*[\=].*[^-\\]$'
                $RegEx_RemoveValue = [regex]'^.*[=][\-]$'
                $RegEx_MultiLine_First = [regex]'^.*[\=].*hex.*[\\]$'
                $RegEx_Comment = [regex]'^;'
                $RegEx_Hive = [regex]'^[\[]HKEY_\w*[\]]$'

                #Init Registry Object
                $RegistryObject = New-Object -TypeName System.Collections.Generic.List[RegInfo_Key]
                $CurrentRegKey = $Null
                $CurrentRegValue = $Null
                $ConflictErrorFound = $False
                $MultiDeclarationErrorFound = $False
                $FatalError = $False
                Function Get-RegistryKeyObject {
                    Param(
                        [String]
                            ${String},
                        [Switch]
                            $Delete
                    )
                    if ($Delete) {
                        $FullKey = $String.Replace('[-','').Replace(']','')
                    }Else{
                        $FullKey = $String.Replace('[',"").Replace(']','')
                    }
                    $KeySplit = $FullKey.Split("\")
                    $Hive = $KeySplit[0]
                    $Key = $KeySplit[1..$($KeySplit.Count - 1)]-join ("\")
                    $HashTable = @{
                        ExtractedValue = $String
                        Hive = $Hive
                        Key = $Key
                        Values = New-Object -TypeName System.Collections.Generic.List[RegInfo_Value]
                        Delete = $Delete
                    }
                    $RegKey = New-Object -TypeName RegInfo_Key -Property $HashTable
                    Write-Output $RegKey
                }
                Function Get-RegistryValueObject {
                    Param(
                        [String]
                            ${String},
                        [String[]]
                            ${StringMulti},
                        [Switch]
                            ${Delete}
                    )

                    $LineSplit=$String.Split('=')
                    $Name = $LineSplit[0]
                    if ((($Name.StartsWith('"') -eq $True) -and (($Name.EndsWith('"')) -eq $False))){
                        $LineSplit = $String -Split ('"=')
                        $Name = $LineSplit[0] + '"'
                    }

                    if ($Delete){
                        $Value = '-'
                    }Else{
                        $Value=$String.Replace("$($Name)=","")
                    }

                    If ($StringMulti) {
                        $Value = "$($Value)`r`n$($StringMulti -Join "`r`n")"
                        $String = "$($String)`r`n$($StringMulti -Join "`r`n")"
                    }
                    $HashTable = @{
                        ExtractedValue = $String
                        Name = $Name
                        Value = $Value
                        Delete = $Delete
                    }
                    $RegValue = New-Object -TypeName RegInfo_Value -Property $HashTable
                    Write-Output $RegValue
                }
            }
            Process {
                $MeasureInternRead = Measure-Command {
                    #region import Registry in a big array of registry keys
                    For ($CurrentPos = 0;$CurrentPos -lt $MaxObject;$CurrentPos ++){
                        $CurrentLine = $Content[$CurrentPos]
                        $PercentCompleted = $CurrentPos * $Percent
                        Write-Progress -Activity 'Importing Registry Content...' -Status "Reading Line $CurrentPos/$MaxObject" -CurrentOperation "$CurrentLine" -PercentComplete $PercentCompleted
                        Switch -Regex ($CurrentLine){
                            $RegEx_Registry4 {
                                #Regedit 4 Declaration ignore
                            }
                            $RegEx_Registry5 {
                                #Regedit 5 Declaration ignore
                            }
                            $RegEx_Comment {
                                #Comment is ignored
                                Write-Warning "Comment ignored : [$($CurrentLine)]"
                            }
                            $RegEx_Key {
                                #Current line is a key
                                If ($CurrentRegKey) {
                                    #A key is in the buffer add to the registry object
                                    $RegistryObject.Add($CurrentRegKey)
                                    $CurrentRegKey = $Null
                                }
                                $CurrentRegKey = Get-RegistryKeyObject -String $CurrentLine
                            }
                            $RegEx_RemoveKey {
                                #Current line is a key Remover
                                If ($CurrentRegKey) {
                                    #A key is in the buffer add to the registry object
                                    $RegistryObject.Add($CurrentRegKey)
                                    $CurrentRegKey = $Null
                                }
                                $CurrentRegKey = Get-RegistryKeyObject -String $CurrentLine -Delete
                            }
                            $RegEx_Value {
                                #Current line is a Value
                                $CurrentRegValue = Get-RegistryValueObject -String $CurrentLine
                                if ($CurrentRegKey) {
                                    #A key exist add the value to the key
                                    $CurrentRegValue.ParentHive = $CurrentRegKey.Hive
                                    $CurrentRegValue.ParentKey = $CurrentRegKey.Key
                                    $CurrentRegValue.ExtractedParent = $CurrentRegKey.ExtractedValue
                                    $CurrentRegValue.ExtractedValue = $CurrentLine
                                    $CurrentRegKey.Values.Add($CurrentRegValue)
                                }Else{
                                    Write-Warning "[$($CurrentLine)] Can't be associated to any Key]"
                                }
                            }
                            $RegEx_RemoveValue {
                                #Current line is a Value Remover
                                $CurrentRegValue = Get-RegistryValueObject -String $CurrentLine -Delete
                                if ($CurrentRegKey) {
                                    #A key exist add the value to the key
                                    $CurrentRegValue.ParentHive = $CurrentRegKey.Hive
                                    $CurrentRegValue.ParentKey = $CurrentRegKey.Key
                                    $CurrentRegValue.ExtractedParent = $CurrentRegKey.ExtractedValue
                                    $CurrentRegKey.Values.Add($CurrentRegValue)
                                }Else{
                                    Write-Warning "[$($CurrentLine)] Can't be associated to any Key]"
                                }
                                $CurrentRegValue = $Null
                            }
                            $RegEx_MultiLine_First {
                                #Current line is a MultiLine Value
                                $FirstLine = $CurrentLine
                                $NextsLine = @()
                                $CurrentPos ++
                                $CurrentLine = $CurrentLine = $Content[$CurrentPos]
                                    Do {
                                        #CurrentLine is next multiline value
                                        $NextsLine += $CurrentLine
                                        if ($CurrentPos -ne $MaxObject){
                                            $CurrentPos ++
                                            if ($CurrentPos -ne $MaxObject){
                                                $CurrentLine = $Content[$CurrentPos]
                                            }
                                        }
                                    }Until(($CurrentLine -Match $RegEx_Key) -or ($RegEx_Comment -Match $RegEx_RemoveKey) -or ($RegEx_Comment -Match $RegEx_Value) -or ($RegEx_Comment -Match $RegEx_RemoveValue) -or ($RegEx_Comment -Match $RegEx_MultiLine_First) -or ($CurrentPos -eq $MaxObject))
                                    if ($CurrentPos -ne $MaxObject){
                                        $CurrentPos = $CurrentPos - 1
                                    }
                                    $CurrentRegValue = Get-RegistryValueObject -String $FirstLine -StringMulti $NextsLine
                                    if ($CurrentRegKey) {
                                        #A key exist add the value to the key
                                        $CurrentRegValue.ParentHive = $CurrentRegKey.Hive
                                        $CurrentRegValue.ParentKey = $CurrentRegKey.Key
                                        $CurrentRegValue.ExtractedParent = $CurrentRegKey.ExtractedValue
                                        $CurrentRegKey.Values.Add($CurrentRegValue)
                                    }
                                    $CurrentRegValue = $Null
                        
                            }
                            Default {
                                If ($CurrentLine -Match $RegEx_Hive){
                                    If ($CurrentRegKey) {
                                        #A key is in the buffer add to the registry object
                                        $RegistryObject.Add($CurrentRegKey)
                                        $CurrentRegKey = $Null
                                    }
                                    $HashTable = @{
                                        ExtractedValue = $CurrentLine
                                        Hive = $($CurrentLine.Replace('[','')).Replace(']','')
                                        Key = ''
                                        Values = New-Object -TypeName System.Collections.Generic.List[RegInfo_Value]
                                        Delete = $False
                                    }
                                    $CurrentRegKey = New-Object -TypeName RegInfo_Key -Property $HashTable
                                }Else{
                                    $TestFalseMultiLine = "$($Content[$CurrentPos - 1])$($CurrentLine)"
                                    if ($TestFalseMultiLine -match $RegEx_Value){
                                        $PreviousValue = $CurrentRegKey.Values | Where {$_.ExtractedValue -eq $Content[$CurrentPos - 1]}                           
                                        if (($PreviousValue -ne $Null) -and ($CurrentRegKey -ne $Null)){
                                            $CurrentRegKey.Values.Remove($PreviousValue) | out-null
                                        }
                                        $CurrentRegValue = Get-RegistryValueObject -String $TestFalseMultiLine
                                        if ($CurrentRegKey) {
                                            #A key exist add the value to the key
                                            $CurrentRegValue.ParentHive = $CurrentRegKey.Hive
                                            $CurrentRegValue.ParentKey = $CurrentRegKey.Key
                                            $CurrentRegValue.ExtractedParent = $CurrentRegKey.ExtractedValue
                                            $CurrentRegValue.ExtractedValue = $TestFalseMultiLine
                                            $CurrentRegKey.Values.Add($CurrentRegValue)
                                        }                            
                                    }Else{
                                        Write-Host "FATAL ERROR !!! $CurrentLine is Unknown !!" -ForegroundColor Red
                                        Write-Host "FATAL ERROR !!! Context :" -ForegroundColor Red
                                        Write-Host "FATAL ERROR !!! $($Content[$CurrentPos - 1])" -ForegroundColor Red
                                        Write-Host "FATAL ERROR !!! $($Content[$CurrentPos])" -ForegroundColor Red
                                        Write-Host "FATAL ERROR !!! $($Content[$CurrentPos + 1])" -ForegroundColor Red
                                        Write-Host "FATAL ERROR !!! ----------------------------------------" -ForegroundColor Red
                                        Write-Error "FATAL ERROR"
                                        $FatalError = $True
                                    }
                                }
                            }
                        }
                    }
                    If ($CurrentRegKey) {
                        #A key is in the buffer add to the registry object
                        $RegistryObject.Add($CurrentRegKey)
                        $CurrentRegKey = $Null
                    }
                    Write-Progress -Activity 'Importing Registry Content...' -Status 'Completed' -Completed
                    #endregion import Registry in a big array of registry key
                    
                }
                $MeasureInternFilter = Measure-Command {
                    if ($NoFiltering -eq $True){
                        $ConsolidatedRegistryObject = $RegistryObject
                    }Else{
                        #region Filter object
                        #Start Filtering
                        Write-Progress -Activity 'Consolidating Registry Object...' -Status 'Initialize...' -PercentComplete 0
                        Write-Verbose 'Consolidating Registry Object...'
                        #region Remove KeyDeletion from RegistryObject
                        if ($IgnoreDeletion -or $IgnoreKeyDeletion){
                            #Remove Key with Delete -eq $True
                            $RegistryObject | Where {$_.Delete} | ForEach-Object {Write-Warning "Key deletion ignored : $($_.ExtractedValue)"}
                            $RegistryObject = $RegistryObject | Where {$_.Delete -eq $False}
                        }
                        #endregion Remove KeyDeletion from RegistryObject
                        #region init progress bar percentage get the amount of objects for progress bar

                        $PercentCompleted = 0
                        #endregion init progress bar percentage get the amount of objects for progress bar
                    
                        #region consolidate (Remove keypair deletion, Remove Double Declaration, Remove Conflicts)
                        #Create an Empty Registry Object List of RegInfo_Key
                        $ConsolidatedRegistryObject = New-Object -TypeName System.Collections.Generic.List[RegInfo_Key]
                        Write-Progress -Activity 'Consolidating Registry Objects...' -Status 'Grouping Objects' -PercentComplete $PercentCompleted
                        Write-Verbose 'Grouping Objects...'
                        #Group By Registry Keys
                        $GroupedKeys = $($RegistryObject | Group-Object -Property ExtractedValue)
                        if (@($GroupedKeys).Count -ne 0){
                            $Percent = 100 / @($GroupedKeys).Count
                        }Else{
                            $Percent = 0
                        }
                        ForEach ($GroupedKey in $GroupedKeys){
                            #region Consolidate the Key (From x Key with x values to 1 Key with x values)
                            $KeyHashTable = @{
                                ExtractedValue = $GroupedKey.Group[0].ExtractedValue
                                Hive = $GroupedKey.Group[0].Hive
                                Key = $GroupedKey.Group[0].Key
                                Values = $GroupedKey.Group.Values #Get all values for the grouped key
                                Delete = $GroupedKey.Group[0].Key
                            }
                            $ConsolidatedKey = New-Object -TypeName RegInfo_Key -Property $KeyHashTable
                            #ConsolidatedKey now contains all KeyPair for the key
                            #endregion Consolidate the Key (From x Key with x values to 1 Key with x values)
                            #region remove keypair Deletion
                            if ($NoDeletion -or $NoValueDeletion){
                                $ConsolidatedKey.Values | Where-Object {$_.Delete} | % {Write-Warning "Value deletion ignored : [$($_.ExtractedValue)]"}
                                $ConsolidatedKey.Values = $ConsolidatedKey.Values | Where-Object {$_.Delete -eq $False}
                            }
                            #endregion remove keypair Deletion
                            #region check KeyPair values for duplicate Name and conflicts
                            $ConsolidatedKeyPairList = New-Object -TypeName System.Collections.Generic.List[RegInfo_Value] #Will contains all values for this key
                            $KeyPairValues = $ConsolidatedKey.Values
                            $GroupedKeyPairValues = $KeyPairValues | Group-Object -Property Name
                            ForEach ($KeyPairList in $GroupedKeyPairValues) {
                                $KeyPairName = $KeyPairList.Name
                                $GroupedValues = $KeyPairList.Group | Group-Object -Property Value
                                $AmountOfDifferentValues = @($GroupedValues).Count
                                $AmountOfValues = @($GroupedValues).Group.Count
                                if ($AmountOfDifferentValues -eq 1){
                                    #The current key pair is declared x time but always with same value get only one
                                    $KeyPairObject = @($GroupedValues).Group[0]
                                    #Add to the consolidated Key Pair
                                    $ConsolidatedKeyPairList.Add($KeyPairObject)
                                    if ($AmountOfValues -gt 1){
                                        #There is more than 1 declaration for this Keypair
                                        $ErrorString = "$($AmountOfValues) identical Declarations for $($KeyPairObject.Name) under $($KeyPairObject.ExtractedParent)"
                                        if ($ErrorOnMultiDeclaration) {
                                            #Throw an error
                                            Write-Error -Message $ErrorString -RecommendedAction 'Review your registry or remove -ErrorOnMultiDeclaration'
                                            #Store a MultiDeclarationErrorFound
                                            $MultiDeclarationErrorFound = $True
                                        }Else{
                                            #Throw a Warning
                                            Write-Warning "$($AmountOfValues) identical Declarations for $($KeyPairObject.Name) under $($KeyPairObject.ExtractedParent)"
                                        }
                                    }
                                }Else{
                                    #Store all different values as is even they are conflictings (warning some tools like wix harvester did not accept it)
                                    ForEach ($DifferentValues in $GroupedValues){
                                        $KeyPairObject = $DifferentValues.Group[0] #Take the first object of the grouped keypair with same value
                                        $ConsolidatedKeyPairList.Add($KeyPairObject)
                                    }
                                    $Values = @($GroupedValues).Name
                                    $ErrorString = "!! $($AmountOfDifferentValues) different values ($($Values -Join ',')) in $($AmountOfValues) Declarations for $($KeyPairObject.Name) under $($KeyPairObject.ExtractedParent)"
                                    if ($ErrorOnConflicts) {
                                        #Throw an error
                                        Write-Error -Message $ErrorString -RecommendedAction 'Review your registry file(s)'
                                        #Store a ConflictErrorFound
                                        $ConflictErrorFound = $True
                                    }Else{
                                        #Throw a Warning
                                        Write-Warning $ErrorString
                                    }
                                
                                
                                }
                            }
                            #$ConsolidatedKeyPair is builded replace in the ConsolidatedKey
                            $ConsolidatedKey.Values = $ConsolidatedKeyPairList
                            $ConsolidatedRegistryObject.Add($ConsolidatedKey)
                            #endregion check KeyPair values for duplicate Name and conflicts
                            $PercentCompleted = $PercentCompleted + $Percent
                        }
                        #region Remove Tree Declaration from RegistryObject (Tree Declaration is registry key that have no KeyPair
                        if ($IgnoreTreeDeclaration){
                            $ConsolidatedRegistryObject | Where {$_.Values.Count -eq 0} | % { Write-Warning "Tree declaration ignored : $($_.ExtractedValue)"}
                            $ConsolidatedRegistryObject = $ConsolidatedRegistryObject | Where {$_.Values.Count -gt 0}
                        }
                        #endregion Remove Tree Declaration from RegistryObject (Tree Declaration is registry key that have no KeyPair
                    }
                }
                Write-Progress -Activity 'Consolidating Registry Objects...' -Status 'Completed' -Completed
            }
            End {   
                if (($ConflictErrorFound -and $ErrorOnConflicts) -or $MultiDeclarationErrorFound -or $FatalError){
                    $ConsolidatedRegistryObject = $False
                }
                Return $ConsolidatedRegistryObject,$MeasureInternRead,$MeasureInternFilter
            }
        }
        Function Write-RegContent {
            Param(
                [System.Collections.Generic.List[RegInfo_Key]]
                    ${RegInfoList},
                [String]
                    $Path,
                [ValidateSet(4,5)]
                [Int32]
                    ${OutputFormat}=5
            )
            #Creating the file content
            $RegFileContent = [System.Collections.Generic.List[String]]::New()
            #Add Registry Declaration
            if ($OutputFormat -eq 5){
                $RegFileContent.Add('Windows Registry Editor Version 5.00')
            }Else{
                $RegFileContent.Add('REGEDIT4')
            }
            ForEach($Key in $RegInfoList){
                    $RegFileContent.Add('')
                    $RegFileContent.Add($Key.ExtractedValue)
                    [System.Collections.Generic.List[RegInfo_Value]]$Values = $Key.Values
                    ForEach ($Value in $Values){
                        $RegFileContent.Add($Value.ExtractedValue)
                    }
            }
            $RegFileContent.Add('')
            $RegFileContent | out-File $Path -Force
            $RetVal = Get-Item -Path $Path
            Return $RetVal
        }
        #Get input files
        if ($InputFile){
            $FileList = Get-Item $InputFile -Filter '*.reg'
        }Elseif ($InputPath) {
            $FileList = Get-ChildItem $InputPath -Filter '*.reg'
        }Else{
            Write-Error 'InputFile or InputPath missing'
        }
        #Set output file
        if ($OutputPath -eq ''){
            #no outputpath received put scriptdirectory\Out as output path
            $ScriptDir = Split-Path $script:MyInvocation.MyCommand.Path
            if ($ScriptDir -notlike $null){
                $OutputPath = "$($ScriptDir)\Out"
            }Else{
                Write-Error 'Unable to get a valid OutputPath'
            }
        }
        if ($(Test-Path "$($OutputPath)\$($OutputFileName)") -eq $True){
            $FileToRemove = Get-Item -Path "$($OutputPath)\$($OutputFileName)"
            Write-Warning "Removing existing output file $($FileToRemove.FullName)"
            Remove-Item -Path "$($FileToRemove.FullName)" -Force | Out-Null
        }
    }
    Process {
        if (@($FileList).Count -gt 0) {
            #Create output directory
            if ($(Test-Path $OutputPath) -eq $false){
                Write-Verbose "Creating Ouput Directory under $($OutDir)"
                Try {
                    New-Item -Path $OutputPath -ItemType Directory -Force | Out-Null
                    }
                Catch {
                    Write-Verbose "Something went wrong during output directory $($OutputPath) creation"
                    Write-Error $_
                    Break
                }
            }

            #Getting the Registry File content "As is"
            $RegFileContent = Get-RegFileContent -FileList $FileList -ErrorOnUnreadableFile:$ErrorOnUnreadableFile 
            if ($RegFileContent -eq $False){
                Write-Warning 'Problem during Get-RegFileContent... review your reg files'
                if ($ErrorOnUnreadableFile){
                    Return $False
                }
            }
            #Optimize the Registry Content
            $RegInfoList,$MeasureInternRead,$MeasureInternFilter = Convert-RegContent -Content $RegFileContent -IgnoreDeletion:$NoDeletion -IgnoreKeyDeletion:$NoKeyDeletion -IgnoreValueDeletion:$NoValueDeletion -IgnoreTreeDeclaration:$NoEmptyKey -ErrorOnMultiDeclaration:$ErrorOnMultiDeclaration -ErrorOnConflicts:$ErrorOnConflicts -NoProgress:$NoProgress -NoFiltering:$NoFiltering
            Write-Verbose "Time to read the content : $($MeasureInternRead.TotalSeconds) Seconds" 
            Write-Verbose "Time to filter the content : $($MeasureInternFilter.TotalSeconds) Seconds" 
            if ($RegInfoList -eq $False){
                Write-Warning "Problem during Convert-RegContent... review your reg files"
                Return $False
            }Else{
                Write-Verbose "Convert-RegContent returned $($RegInfoList.Count) Key(s)/$($RegInfoList.Values.count) Value(s)"
                $RetVal = Write-RegContent -RegInfoList $RegInfoList -Path "$($OutputPath)\$($OutputFileName)"
                Return $RetVal   
            }
        }Else{
            Write-Error "No readable file found under [$($InputPath)]"
            Return $False 
        }
    }
    End {}
}
