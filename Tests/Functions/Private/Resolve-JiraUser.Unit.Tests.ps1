#requires -modules @{ ModuleName = "Pester"; ModuleVersion = "6.2.0"; MaximumVersion = "6.999" }

BeforeDiscovery {
    . "$PSScriptRoot/../../Helpers/TestTools.ps1"

    $script:moduleToTest = Initialize-TestEnvironment
}

BeforeAll {
    . "$PSScriptRoot/../../Helpers/TestTools.ps1"

    $script:moduleToTest = Initialize-TestEnvironment
}

InModuleScope JiraPS {

    Describe 'Resolve-JiraUser' -Tag Unit {
        It 'uses validated <Deployment> identity with the effective override context' -ForEach @(
            @{ Deployment = 'Cloud'; Identity = @{ AccountId = 'account-1' } }
            @{ Deployment = 'Server'; Identity = @{ Name = 'user-1' } }
        ) {
            $source = New-AtlassianConnectionContext -Name nested-user -Product Jira -BaseUri https://jira.example.com -PersonalAccessToken source-secret
            $source.SetValidationResult($Deployment, 'source-user')
            $null = Register-AtlassianConnection -Connection $source
            $script:context = Resolve-AtlassianRequestContext -Product Jira -Connection $source -PersonalAccessToken override-secret
            Mock Get-JiraUserOperation { [AtlassianPS.JiraPS.User]@{ Name = $UserName; AccountId = $AccountId } }
            try {
                $result = Resolve-JiraUser -InputObject ([AtlassianPS.JiraPS.User]$Identity) -RequestContext $context

                if ($Deployment -eq 'Cloud') { $result.AccountId | Should -Be 'account-1' }
                else { $result.Name | Should -Be 'user-1' }
                Should -Invoke Get-JiraUserOperation -Exactly 1 -ParameterFilter {
                    [Object]::ReferenceEquals($RequestContext, $script:context) -and
                    $RequestContext.GetAuthorizationHeader() -eq 'Bearer override-secret'
                }
                $source.GetAuthorizationHeader() | Should -Be 'Bearer source-secret'
            }
            finally {
                $context.Dispose()
                Disconnect-AtlassianConnection -Connection $source
            }
        }
    }
}
