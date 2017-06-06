#Requires -Modules psake,BuildHelpers

# This is a shortcut script that just invokes the "main" build logic.

# Builds the module by invoking psake on the build.psake.ps1 script.
Invoke-PSake $PSScriptRoot\build.psake.ps1 -taskList Build
