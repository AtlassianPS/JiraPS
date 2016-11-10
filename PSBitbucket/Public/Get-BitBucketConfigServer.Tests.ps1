$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$sut = (Split-Path -Leaf $MyInvocation.MyCommand.Path).Replace(".Tests.", ".")
. "$here\$sut"

InModuleScope PSBitBucket {

    $BitBucketServer = 'http://BitBucketserver.example.com'

    Describe "Get-BitBucketConfigServer" {
        $configFile = Join-Path -Path $TestDrive -ChildPath 'config.xml'

        It "Throws an exception if the config file does not exist" {
            { Get-BitBucketConfigServer -ConfigFile $configFile } | Should Throw
        }

        It "Returns the defined Server in the config.xml file" {
            Set-BitBucketConfigServer -Server $BitBucketServer -ConfigFile $configFile
            $s = Get-BitBucketConfigServer -ConfigFile $configFile
            $s | Should Be $BitBucketServer
        }
    }
}
