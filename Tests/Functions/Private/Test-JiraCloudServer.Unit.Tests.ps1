#requires -modules @{ ModuleName = "Pester"; ModuleVersion = "6.2.0"; MaximumVersion = "6.999" }

BeforeDiscovery {
    . "$PSScriptRoot/../../Helpers/TestTools.ps1"

    $script:moduleToTest = Initialize-TestEnvironment
}

InModuleScope JiraPS {
    Describe 'Test-JiraCloudServer' -Tag Unit {
        BeforeAll {
            . "$PSScriptRoot/../../Helpers/TestTools.ps1"

            $script:moduleToTest = Initialize-TestEnvironment
        }

        BeforeEach {
            $script:requestContext = AtlassianPS.Configuration\New-AtlassianConnectionContext -Name cloud-test -Product Jira -BaseUri https://jira.example.com -Anonymous
            Mock Invoke-JiraRequest { throw 'Deployment detection must use the resolved context.' }
        }

        AfterEach {
            $requestContext.Dispose()
        }

        It 'returns false when the deployment type is unavailable' {
            $result = Test-JiraCloudServer -RequestContext $requestContext

            $result | Should -BeOfType ([Boolean])
            $result | Should -BeFalse
            Should -Invoke Invoke-JiraRequest -Times 0 -Exactly
        }

        It 'identifies <DeploymentType> from the resolved context' -ForEach @(
            @{ DeploymentType = 'Cloud'; Expected = $true }
            @{ DeploymentType = 'Server'; Expected = $false }
            @{ DeploymentType = 'Data Center'; Expected = $false }
        ) {
            $requestContext.SetValidationResult($DeploymentType, $null)

            $result = Test-JiraCloudServer -RequestContext $requestContext

            $result | Should -BeOfType ([Boolean])
            $result | Should -Be $Expected
            Should -Invoke Invoke-JiraRequest -Times 0 -Exactly
        }
    }
}
