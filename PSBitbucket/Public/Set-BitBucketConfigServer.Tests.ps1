$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$sut = (Split-Path -Leaf $MyInvocation.MyCommand.Path).Replace(".Tests.", ".")
. "$here\$sut"

InModuleScope PSBitBucket {

    $BitBucketServer = 'http://BitBucketserver.example.com'

    Describe "Set-BitBucketConfigServer" {

        $configFile = Join-Path -Path $TestDrive -ChildPath 'config.xml'
        Set-BitBucketConfigServer -Server $BitBucketServer -ConfigFile $configFile

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
            $xmlServer | Should Be $BitBucketServer
        }

        It "Trims whitespace from the provided Server parameter" {
            Set-BitBucketConfigServer -Server "$BitBucketServer " -ConfigFile $configFile
            $xml = New-Object -TypeName Xml
            $xml.Load($configFile)
            $xml.Config.Server | Should Be $BitBucketServer
        }

        It "Trims trailing slasher from the provided Server parameter" {
            Set-BitBucketConfigServer -Server "$BitBucketServer/" -ConfigFile $configFile
            $xml = New-Object -TypeName Xml
            $xml.Load($configFile)
            $xml.Config.Server | Should Be $BitBucketServer
        }
    }
}


