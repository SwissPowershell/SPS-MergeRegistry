Import-Module "$($PSScriptRoot)\SPS-MergeRegistry.psd1" -Force
# Set the most constrained mode
Set-StrictMode -Version Latest
# Set the error preference
$ErrorActionPreference = 'Stop'
# Set the verbose preference in order to get some insights
$VerbosePreference = 'Continue'

# change the verbose color so it's not the same color than the warnings
if (Get-Variable -Name PSStyle -ErrorAction SilentlyContinue) {
    $PSStyle.Formatting.Verbose = $PSStyle.Foreground.Cyan
}else{
    $Host.PrivateData.VerboseForegroundColor = [System.ConsoleColor]::Cyan
}

# shorten the test file root directory
$TestRoot = "$($PSScriptRoot)\TestFiles"

# Test each of the test files for getting content
# ReadMe.md is not a registry file there should be a warning about it
Write-Host "Reading a non registry file (this should generate a warning and return a null object)" -ForegroundColor Magenta
$NonReg = Get-SPSRegistryContent -File "$($TestRoot)\ReadMe.md"
Write-Host "`t The result is null: $($Null -eq $NonReg)" -ForegroundColor Green

# Classic.reg is a classic registry file there should be no issue reading it
Write-Host "Reading a classic registry file (this should not generate any warning or errors)" -ForegroundColor Magenta
$ClassicReg = Get-SPSRegistryContent -File "$($TestRoot)\Classic.reg"
Write-Host "`t The result is null: $($Null -eq $ClassicReg)" -ForegroundColor Green

Write-Host "Reading a classic registry file using strict mode" -ForegroundColor Magenta
$ClassicReg_Strict = Get-SPSRegistryContent -File "$($TestRoot)\Classic.reg" -Strict
Write-Host "`t The result is null: $($Null -eq $ClassicReg_Strict)" -ForegroundColor Green

# Classic.txt is a classic registry file but not using .reg extention there should be no issue reading it
Write-Host "Reading a classic registry file as .txt (this should not generate any warning or errors)" -ForegroundColor Magenta
$ClassicTxt = Get-SPSRegistryContent -File "$($TestRoot)\Classic.txt"
Write-Host "`t The result is null: $($Null -eq $ClassicTxt)" -ForegroundColor Green

# ClassicV4.reg is a classic registry file in REGEDIT4 mode there should be no issue reading it
Write-Host "Reading a classic V4 registry file as (this should not generate any warning or errors)" -ForegroundColor Magenta
$ClassicV4 = Get-SPSRegistryContent -File "$($TestRoot)\ClassicV4.reg"
Write-Host "`t The result is null: $($Null -eq $ClassicV4)" -ForegroundColor Green

# CommentedClassic.reg is a classic registry file with comments there should be no issue reading it
Write-Host "Reading a classic registry file with comments (this should not generate any warning or errors)" -ForegroundColor Magenta
$CommentedClassic = Get-SPSRegistryContent -File "$($TestRoot)\CommentedClassic.reg"
Write-Host "`t The result is null: $($Null -eq $CommentedClassic)" -ForegroundColor Green

# Conflict_KeyDeletion.reg is a registry file with key deletion conflict there should be no issue reading it
Write-Host "Reading a registry file with key deletion (this should not generate any warning or errors)" -ForegroundColor Magenta
$Conflict_KeyDeletion = Get-SPSRegistryContent -File "$($TestRoot)\Conflict_KeyDeletion.reg"
Write-Host "`t The result is null: $($Null -eq $Conflict_KeyDeletion)" -ForegroundColor Green

# Conflict_ValueDeletion.reg is a registry file with value deletion conflict there should be no issue reading it
Write-Host "Reading a registry file with value deletion (this should not generate any warning or errors)" -ForegroundColor Magenta
$Conflict_ValueDeletion = Get-SPSRegistryContent -File "$($TestRoot)\Conflict_ValueDeletion.reg"
Write-Host "`t The result is null: $($Null -eq $Conflict_ValueDeletion)" -ForegroundColor Green

# Conflict_Value.reg is a registry file with value conflict there should be no issue reading it
Write-Host "Reading a registry file with value conflict (this should not generate any warning or errors)" -ForegroundColor Magenta
$Conflict_Value = Get-SPSRegistryContent -File "$($TestRoot)\Conflict_ValueConflict.reg"
Write-Host "`t The result is null: $($Null -eq $Conflict_Value)" -ForegroundColor Green

# PourlyFormated.reg is a registry file with pourly formated content there should be no issue reading it
Write-Host "Reading a registry file with pourly formated content (this should not generate any warning or errors)" -ForegroundColor Magenta
$PourlyFormated = Get-SPSRegistryContent -File "$($TestRoot)\PourlyFormated.reg"
Write-Host "`t The result is null: $($Null -eq $PourlyFormated)" -ForegroundColor Green

# Error_Malformated is a registry file with malformated content there should be an error reading it while using strict mode
Write-Host "Reading a registry file with malformated content (this should not generate an error)" -ForegroundColor Magenta
$Error_Malformated = Get-SPSRegistryContent -File "$($TestRoot)\Error_Malformated.reg"
Write-Host "`t The result is null: $($Null -eq $Error_Malformated)" -ForegroundColor Green

Write-Host "Reading a registry file with malformated content using strict mode (this should generate an error)" -ForegroundColor Magenta
Try {
    $Error_Malformated_Strict = Get-SPSRegistryContent -File "$($TestRoot)\Error_Malformated.reg" -Strict
}Catch {
    Write-Warning "DEBUGGING: Error catched but converted to non terminating error"
    $BeforeErrorAction = $ErrorActionPreference
    $ErrorActionPreference = 'Continue'
    Write-Error $_
    $ErrorActionPreference = $BeforeErrorAction
    $Error_Malformated_Strict = $null
}
Write-Host "`t The result is null: $($Null -eq $Error_Malformated_Strict)" -ForegroundColor Green

# the the function using the pipeline from 'get-childitem'
Write-Host "Reading a set of registry files using the pipeline from 'Get-ChildItem' (this should not generate an error as strict mode is not used)" -ForegroundColor Magenta
$AllRegistries = Get-ChildItem -Path $TestRoot -File | Get-SPSRegistryContent
Write-Host "`t The result is null: $($Null -eq $AllRegistries)" -ForegroundColor Green

Write-Host "Reading a set of registry files using the pipeline from 'Get-ChildItem' (this should generate an error as strict mode is used)" -ForegroundColor Magenta
Try {
    $AllRegistries_Strict = Get-ChildItem -Path $TestRoot -File | Get-SPSRegistryContent -Strict
}Catch {
    Write-Warning "DEBUGGING: Error catched but converted to non terminating error. The pipeline should be stopped"
    $BeforeErrorAction = $ErrorActionPreference
    $ErrorActionPreference = 'Continue'
    Write-Error $_
    $ErrorActionPreference = $BeforeErrorAction
    $AllRegistries_Strict = $null
}
Write-Host "`t The result is null: $($Null -eq $AllRegistries_Strict)" -ForegroundColor Green