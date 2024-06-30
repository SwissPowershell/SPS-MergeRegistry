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

# List all test files
$AllRegs = Get-ChildItem -Path $TestRoot -File
$NonConflictingRegs = $AllRegs | Where-Object name -notmatch 'Conflict'
$KeyDeletionReg = $AllRegs | Where-Object name -match 'KeyDeletion'
$ValueDeletionReg = $AllRegs | Where-Object name -match 'ValueDeletion'
$ValueConflictReg = $AllRegs | Where-Object name -match 'ValueConflict'

# Build the [registry] object accordingly
$AllRegistriesObj = $AllRegs | Get-SPSRegistryContent -Verbose:$False -WarningAction SilentlyContinue
$AllNonConflictingRegsObj = $NonConflictingRegs | Get-SPSRegistryContent -Verbose:$False -WarningAction SilentlyContinue
$KeyDeletionConflictRegObj = $NonConflictingRegs,$KeyDeletionReg | Get-SPSRegistryContent -Verbose:$False -WarningAction SilentlyContinue
$ValueDeletionConflictRegObj = $NonConflictingRegs,$ValueDeletionReg | Get-SPSRegistryContent -Verbose:$False -WarningAction SilentlyContinue
$ValueConflictRegObj = $NonConflictingRegs,$ValueConflictReg | Get-SPSRegistryContent -Verbose:$False -WarningAction SilentlyContinue

# Merge all the valid registry files together (this should not generate an error)
Write-Host "==> Merging all the valid registry files together (this should not generate an error)" -ForegroundColor Magenta
$AllNonConflictMerged = Merge-SPSRegistryContent -InputObject $AllNonConflictingRegsObj -Passthru -Verbose:$False
Write-Host "`t ==> The result is null: $($Null -eq $AllNonConflictMerged)" -ForegroundColor Green

# Merge all the valid registry files together (this should generate warnings about multiple declarations)
Write-Host "==> Merging all the valid registry files together (this should generate warnings about multiple declarations)" -ForegroundColor Magenta
$AllNonConflictMerged_Multi = Merge-SPSRegistryContent -InputObject $AllNonConflictingRegsObj -Passthru -MultiDeclarationWarning -Verbose:$False
Write-Host "`t ==> The result is null: $($Null -eq $AllNonConflictMerged_Multi)" -ForegroundColor Green

# Merge all the registry files together using ignore conflict (this should warnings about conflicts)
Write-Host "==> Merging all the registry files together (this should generate warnings about conflicts)" -ForegroundColor Magenta
$AllRegsMerged_ConflictIgnored = Merge-SPSRegistryContent -InputObject $AllRegistriesObj -Passthru -Verbose:$False -IgnoreConflicts
Write-Host "`t ==> The result is null: $($Null -eq $AllRegsMerged_ConflictIgnored)" -ForegroundColor Green

# Merge all the registry files together (this should generate an error about conflicts)
Write-Host "==> Merging all the registry files together (this should generate an error about conflicts)" -ForegroundColor Magenta
Try {
    $AllRegsMerged = Merge-SPSRegistryContent -InputObject $AllRegistriesObj -Passthru -Verbose:$False
}Catch {
    Write-Warning "DEBUGGING: Error catched but converted to non terminating error. The pipeline should be stopped"
    $BeforeErrorAction = $ErrorActionPreference
    $ErrorActionPreference = 'Continue'
    Write-Error $_
    $ErrorActionPreference = $BeforeErrorAction
    $AllRegsMerged = $null
}
Write-Host "`t ==> The result is null: $($Null -eq $AllRegsMerged)" -ForegroundColor Green

# Merge valid registry with a KeyDeletion reg (this should generate an error about conflicts)
Write-Host "==> Merging all the registry files with a KeyDeletion (this should generate an error about conflicts)" -ForegroundColor Magenta
Try {
    $KeyDeletionConflictMerged = Merge-SPSRegistryContent -InputObject $KeyDeletionConflictRegObj -Passthru -Verbose:$False
}Catch {
    Write-Warning "DEBUGGING: Error catched but converted to non terminating error. The pipeline should be stopped"
    $BeforeErrorAction = $ErrorActionPreference
    $ErrorActionPreference = 'Continue'
    Write-Error $_
    $ErrorActionPreference = $BeforeErrorAction
    $KeyDeletionConflictMerged = $null
}
Write-Host "`t ==> The result is null: $($Null -eq $KeyDeletionConflictMerged)" -ForegroundColor Green

# Merge valid registry with a ValueDeletion reg (this should generate an error about conflicts)
Write-Host "==> Merging all the registry files with a ValueDeletion (this should generate an error about conflicts)" -ForegroundColor Magenta
Try {
    $ValueDeletionConflictMerged = Merge-SPSRegistryContent -InputObject $ValueDeletionConflictRegObj -Passthru -Verbose:$False
}Catch {
    Write-Warning "DEBUGGING: Error catched but converted to non terminating error. The pipeline should be stopped"
    $BeforeErrorAction = $ErrorActionPreference
    $ErrorActionPreference = 'Continue'
    Write-Error $_
    $ErrorActionPreference = $BeforeErrorAction
    $ValueDeletionConflictMerged = $null
}
Write-Host "`t ==> The result is null: $($Null -eq $ValueDeletionConflictMerged)" -ForegroundColor Green

# Merge valid registry with a ValueConflict reg (this should generate an error about conflicts)
Write-Host "==> Merging all the registry files with a ValueConflict (this should generate an error about conflicts)" -ForegroundColor Magenta
Try {
    $ValueConflictMerged = Merge-SPSRegistryContent -InputObject $ValueConflictRegObj -Passthru -Verbose:$False
}Catch {
    Write-Warning "DEBUGGING: Error catched but converted to non terminating error. The pipeline should be stopped"
    $BeforeErrorAction = $ErrorActionPreference
    $ErrorActionPreference = 'Continue'
    Write-Error $_
    $ErrorActionPreference = $BeforeErrorAction
    $ValueConflictMerged = $null
}
Write-Host "`t ==> The result is null: $($Null -eq $ValueConflictMerged)" -ForegroundColor Green

# Merging all the registry files with files with a KeyDeletion using ignoreDeletion (this should not generate an error).
Write-Host "==> Merging all the registry files with a KeyDeletion using ignoreDeletion (this should not generate an error)" -ForegroundColor Magenta
$KeyDeletionConflictMerged_DelIgnored = Merge-SPSRegistryContent -InputObject $KeyDeletionConflictRegObj -Passthru -NoDeletion -Verbose:$False
Write-Host "`t ==> The result is null: $($Null -eq $KeyDeletionConflictMerged_DelIgnored)" -ForegroundColor Green

# Merging all the registry files with files with a valueDeletion using ignoreDeletion (this should not generate an error).
Write-Host "==> Merging all the registry files with a valueDeletion using ignoreDeletion (this should not generate an error)" -ForegroundColor Magenta
$ValueDeletionConflictMerged_DelIgnored = Merge-SPSRegistryContent -InputObject $ValueDeletionConflictRegObj -Passthru -NoDeletion -Verbose:$False
Write-Host "`t ==> The result is null: $($Null -eq $ValueDeletionConflictMerged_DelIgnored)" -ForegroundColor Green

# Create the merged file (not using passthru)
Merge-SPSRegistryContent -InputObject $AllNonConflictingRegsObj -Verbose:$False

# end of the test