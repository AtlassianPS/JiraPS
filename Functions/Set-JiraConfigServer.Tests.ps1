$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$sut = (Split-Path -Leaf $MyInvocation.MyCommand.Path).Replace(".Tests.", ".")
. "$here\$sut"

InModuleScope PSJira {
    
    $jiraServer = 'http://jiraserver.example.com'

    Describe "Set-JiraConfigServer" {

        $configFile = Join-Path -Path $TestDrive -ChildPath 'config.xml'

        It "Ensures that a config.xml file exists" {
            Set-JiraConfigServer -Server $jiraServer -ConfigFile $configFile
            $configFile | Should Exist
        }

        It "Ensures that the XML file has a Config.Server element" {
            $xml = New-Object -TypeName Xml
            $xml.Load($configFile)
            $xml.Config.Server | Should Not BeNullOrEmpty
        }

        It "Sets the config file's Server value " {    
            $xml = New-Object -TypeName Xml
            $xml.Load($configFile)
            $xml.Config.Server | Should Be $jiraServer
        }
    }
}