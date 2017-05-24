. $PSScriptRoot\Shared.ps1

InModuleScope PSJira {

    [System.Diagnostics.CodeAnalysis.SuppressMessage('PSUseDeclaredVarsMoreThanAssigments', '', Scope='*', Target='SuppressImportModule')]
    $SuppressImportModule = $true
    . $PSScriptRoot\Shared.ps1

    $jiraServer = 'http://jiraserver.example.com'

    Describe "Set-JiraConfigServer" {

        $configFile = Join-Path -Path $TestDrive -ChildPath 'config.xml'
        Set-JiraConfigServer -Server $jiraServer -ConfigFile $configFile

        It "Ensures that a config.xml file exists" {
            $configFile | Should Exist
        }

        $xml = New-Object -TypeName Xml
        $xml.Load($configFile)
        $xmlServer = $xml.Config.Server

        It "Ensures that the XML file has a Config.Server element" {
            $xmlServer | Should Not BeNullOrEmpty
        }

        It "Sets the config file's Server value " {
            $xmlServer | Should Be $jiraServer
        }

        It "Trims whitespace from the provided Server parameter" {
            Set-JiraConfigServer -Server "$jiraServer " -ConfigFile $configFile
            $xml = New-Object -TypeName Xml
            $xml.Load($configFile)
            $xml.Config.Server | Should Be $jiraServer
        }

        It "Trims trailing slasher from the provided Server parameter" {
            Set-JiraConfigServer -Server "$jiraServer/" -ConfigFile $configFile
            $xml = New-Object -TypeName Xml
            $xml.Load($configFile)
            $xml.Config.Server | Should Be $jiraServer
        }
    }
}


