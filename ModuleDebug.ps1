<#
    .SYNOPSIS
        This script file help reloading a module and test it's internal functions.
    .DESCRIPTION
        This script file help reloading a module and test it's internal functions.
    .INPUTS
        None.
    .OUTPUTS
        None.
    .LINK
        https://github.com/SwissPowershell/PowershellHelpers/tree/main/DebugModule.ps1
#>
# Import the module based on the current directory
# Get the module name, version and definition file
$ModuleVersion = Split-Path -Path $PSScriptRoot -leaf;$ModuleName = Split-Path -Path $(Split-Path -Path $PSScriptRoot) -leaf;$ModuleDefinitionFile = Get-ChildItem -Path $PSScriptRoot -Filter '*.psd1'
# Remove the module (if loaded)
if (Get-Module -Name $ModuleName -ErrorAction Ignore) {Try {Remove-Module -Name $ModuleName} Catch {Write-Warning "Unable to remove module: $($_.Exception.Message)"};Write-Warning "The script cannot continue...";BREAK}
# Add the module using the definition file
Try {Import-Module $ModuleDefinitionFile.FullName -ErrorAction Stop}Catch {Write-Warning "Unable to load the module: $($_.Exception.Message)";Write-Warning "The script cannot continue...";BREAK}
# Control that the module added is in the same version as the detected version
$Module = Get-Module -Name $ModuleName -ErrorAction Ignore
if (($Module | Select-Object -ExpandProperty Version) -ne $ModuleVersion) {Write-Warning "The module version loaded does not match the folder version: please review !";Write-Warning "The script cannot continue...";BREAK}
# List all the exposed function from the module
Write-Host "Module [" -ForegroundColor Yellow -NoNewline; Write-Host $ModuleName -NoNewline -ForegroundColor Magenta; Write-Host "] Version [" -ForegroundColor Yellow -NoNewline;Write-Host $ModuleVersion -NoNewline -ForegroundColor Magenta;Write-Host "] : " -NoNewline; Write-Host "Loaded !" -ForegroundColor Green
if ($Module.ExportedCommands.count -gt 0) {Write-Host "Available Commands:" -ForegroundColor Yellow;$Module.ExportedCommands | Select-Object -ExpandProperty 'Keys' -ErrorAction Ignore| ForEach-Object {Write-Host "`t - $($_)" -ForegroundColor Magenta};Write-Host ''}Else{Write-Host "`t !! There is no exported command in this module !!" -ForegroundColor Red}
Write-Host "------------------ Starting script ------------------" -ForegroundColor Yellow
$DebugStart = Get-Date
############################
# Test your functions here #
############################
# Warning this file is aimed to be used inside an installed module folder and will fail if started outside of it

# call the debug scripts
."$($PSScriptRoot)\Debug-Get-SPSRegistryContent.ps1"
."$($PSScriptRoot)\Debug-Merge-SPSRegistryContent.ps1"

##################################
# End of the tests show mettrics #
##################################
Write-Host "------------------- Ending script -------------------" -ForegroundColor Yellow
$TimeSpentInDebugScript = New-TimeSpan -Start $DebugStart -Verbose:$False -ErrorAction SilentlyContinue;$TimeUnits = [ORDERED] @{TotalDays = "$($TimeSpentInDebugScript.TotalDays) D.";TotalHours = "$($TimeSpentInDebugScript.TotalHours) h.";TotalMinutes = "$($TimeSpentInDebugScript.TotalMinutes) min.";TotalSeconds = "$($TimeSpentInDebugScript.TotalSeconds) s.";TotalMilliseconds = "$($TimeSpentInDebugScript.TotalMilliseconds) ms."}
ForEach ($Unit in $TimeUnits.GetEnumerator()) {if ($TimeSpentInDebugScript.($Unit.Key) -gt 1) {$TimeSpentString = $Unit.Value;break}};if (-not $TimeSpentString) {$TimeSpentString = "$($TimeSpentInDebugScript.Ticks) Ticks"}
Write-Host "Ending : " -ForegroundColor Yellow -NoNewLine; Write-Host $($MyInvocation.MyCommand) -ForegroundColor Magenta -NoNewLine;Write-Host " - TimeSpent : " -ForegroundColor Yellow -NoNewLine; Write-Host $TimeSpentString -ForegroundColor Magenta

# end of the Debug
