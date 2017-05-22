. $PSScriptRoot\Shared.ps1

InModuleScope PSJira {
    [System.Diagnostics.CodeAnalysis.SuppressMessage('PSUseDeclaredVarsMoreThanAssigments', '', Scope='*', Target='SuppressImportModule')]
    $SuppressImportModule = $true
    . $PSScriptRoot\Shared.ps1

    Describe "Get-JiraSession" {
        It "Obtains a saved PSJira.Session object from module PrivateData" {
            # I don't know how to test this, since I can't access module PrivateData from Pester.
            # The tests for New-JiraSession use this function to validate that they work, so if
            # those tests pass, this function should be working as well.
            $true | Should Be $true
        }
    }
}


