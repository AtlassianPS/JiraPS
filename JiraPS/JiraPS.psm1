﻿$moduleRoot = Split-Path -Path $MyInvocation.MyCommand.Path -Parent
$functions = Join-Path -Path $moduleRoot -ChildPath 'Public'
$internal = Join-Path -Path $moduleRoot -ChildPath 'Internal'

try {
    Add-Type -Path (Join-Path $PSScriptRoot JiraPS.Types.cs) -ReferencedAssemblies Microsoft.CSharp
}
catch {
    if (!(("JiraPS.AssigneeType" -as [Type]))) {
        $errorMessage = @{
            Category         = "OperationStopped"
            CategoryActivity = "Loading custom classes"
            ErrorId          = 1001
            Message          = "Failed to load module JiraPS. [Could not import JiraPS classes]"
        }
        Write-Error @errorMessage
    }
}

# Import all .ps1 files that aren't Pester tests, and export the names of each one as a module function
$items = Resolve-Path "$functions\*.ps1" | Where-Object -FilterScript { -not ($_.ProviderPath.Contains(".Tests.")) }
foreach ($i in $items) {
    . $i.ProviderPath
}

# Same logic here, but don't export these. These functions should be private.
$items = Resolve-Path "$internal\*.ps1" | Where-Object -FilterScript { -not ($_.ProviderPath.Contains(".Tests.")) }
foreach ($i in $items) {
    . $i.ProviderPath
}

# Apparently, PowerShell only automatically loads format files from modules within PSModulePath.
# This line forces the current PowerShell session to load the module format file, even if the module is saved in an unusual location.
# If this module lives somewhere in your PSModulePath, this line is unnecessary (but it doesn't do any harm either).
$formatFile = Join-Path -Path $moduleRoot -ChildPath 'JiraPS.format.ps1xml'
Write-Verbose "Updating format data with file '$formatFile'"
Update-FormatData -AppendPath $formatFile -ErrorAction Continue
