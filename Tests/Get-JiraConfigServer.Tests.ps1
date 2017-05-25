. $PSScriptRoot\Shared.ps1


InModuleScope PSJira {

    [System.Diagnostics.CodeAnalysis.SuppressMessage('PSUseDeclaredVarsMoreThanAssigments', '', Scope='*', Target='SuppressImportModule')]
    $SuppressImportModule = $true
    . $PSScriptRoot\Shared.ps1

    $jiraServer = 'http://jiraserver.example.com'

    Describe "Get-JiraConfigServer" {
        $configFile = Join-Path -Path $TestDrive -ChildPath 'config.xml'

        It "Throws an exception if the config file does not exist" {
            { Get-JiraConfigServer -ConfigFile $configFile } | Should Throw
        }

        It "Returns the defined Server in the config.xml file" {
            Set-JiraConfigServer -Server $jiraServer -ConfigFile $configFile
            $s = Get-JiraConfigServer -ConfigFile $configFile
            $s | Should Be $jiraServer
        }
    }
}
