$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$sut = (Split-Path -Leaf $MyInvocation.MyCommand.Path).Replace(".Tests.", ".")
. "$here\$sut"

InModuleScope PSJira {

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