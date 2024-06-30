$PSD1 = Import-PowershellDataFile -Path "$($PSScriptRoot)\SPS-MergeRegistry.psd1" -Verbose:$False
$ModuleName = $PSD1.RootModule -replace '\.psm1$'
$ModuleVersion = $PSD1.ModuleVersion
$UserPSModuleRootPath = $Env:PSModulePath.Split(';') | Where-Object {$_ -like "$Env:USERPROFILE\*"} | Select-Object -First 1
$DestinationPath = "$($UserPSModuleRootPath)\$($ModuleName)\$($ModuleVersion)"
# Remove the module (if loaded).
if (Get-Module -Name $ModuleName -ErrorAction Ignore) {
    Try {
        Remove-Module -Name $ModuleName
    } Catch {
        Write-Warning "Unable to remove module: $($_.Exception.Message)"
    }
    Write-Warning "The script cannot continue..."
    BREAK
}

# Delete the destination if exist.
if (Test-Path -Path $DestinationPath) {
    Remove-Item -Path $DestinationPath -Recurse -Force | out-null
}

# Copy the module to the destination.
Copy-Item -Path $PSScriptRoot -Destination $DestinationPath -Recurse -Force

# Import the module using its name and version.
Import-Module -Name $ModuleName -Version $ModuleVersion -Force

# end of the import