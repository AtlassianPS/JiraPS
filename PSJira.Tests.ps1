$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$functions = Join-Path -Path $here -ChildPath 'Functions'

Describe "PSJira" {
    # We want to make sure that every .ps1 file in the Functions directory that isn't a Pester test has an associated Pester test.
    # This helps keep me honest and makes sure I'm testing my code appropriately.
    It "Includes a test for each PowerShell function in the module" {
        Get-ChildItem -Path $functions -Filter "*.ps1" -Recurse | Where-Object -FilterScript {$_.Name -notlike '*.Tests.ps1'} | % {
            $_.FullName -replace '.ps1','.Tests.ps1' | Should Exist
        }
    }
}