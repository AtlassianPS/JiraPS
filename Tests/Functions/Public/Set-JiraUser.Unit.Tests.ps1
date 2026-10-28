#requires -modules @{ ModuleName = "Pester"; ModuleVersion = "6.2.0"; MaximumVersion = "6.999" }

BeforeDiscovery {
    . "$PSScriptRoot/../../Helpers/TestTools.ps1"

    $script:moduleToTest = Initialize-TestEnvironment
}

InModuleScope JiraPS {
    Describe "Set-JiraUser" -Tag 'Unit' {
        BeforeAll {
            . "$PSScriptRoot/../../Helpers/TestTools.ps1"
            # $VerbosePreference = 'Continue'  # Uncomment for mock debugging

            #region Definitions
            $script:jiraServer = 'http://jiraserver.example.com'
            $script:testUsername = 'powershell-test'
            $script:testDisplayName = 'PowerShell Test User'
            $script:testEmail = "$testUsername@example.com"
            $script:testDisplayNameChanged = "$testDisplayName Modified"
            $script:testEmailChanged = "$testUsername@example2.com"

            $script:restResultGet = @"
{
    "self": "$jiraServer/rest/api/2/user?username=$testUsername",
    "key": "$testUsername",
    "name": "$testUsername",
    "displayName": "$testDisplayName",
    "emailAddress": "$testEmail",
    "active": true
}
"@
            #endregion Definitions

            #region Mocks
            Mock Test-JiraCloudServer -ModuleName JiraPS { $false }

            Mock Get-JiraUser -ModuleName JiraPS {
                Write-MockDebugInfo 'Get-JiraUser' 'UserName'
                ConvertTo-JiraUser -InputObject (ConvertFrom-Json $restResultGet)
            }

            Mock Invoke-JiraRequest -ModuleName JiraPS -ParameterFilter { $Method -eq 'Put' -and $URI -eq "/rest/api/2/user?username=$testUsername" } {
                Write-MockDebugInfo 'Invoke-JiraRequest' 'Method', 'Uri'
                ConvertFrom-Json $restResultGet
            }

            Mock Invoke-JiraRequest -ModuleName JiraPS {
                Write-MockDebugInfo 'Invoke-JiraRequest' 'Method', 'Uri'
                throw "Unidentified call to Invoke-JiraRequest"
            }
            #endregion Mocks
        }

        Describe "Behavior" {

            It "Accepts a AtlassianPS.JiraPS.User object to the -User parameter" {
                $user = Get-JiraUser -User $testUsername
                { Set-JiraUser -User $user -DisplayName $testDisplayNameChanged } | Should -Not -Throw
                Should -Invoke Invoke-JiraRequest -ModuleName JiraPS -Exactly -Times 1
            }

            It "Accepts pipeline input from Get-JiraUser" {
                { Get-JiraUser -User $testUsername | Set-JiraUser -DisplayName $testDisplayNameChanged } | Should -Not -Throw
                Should -Invoke Invoke-JiraRequest -ModuleName JiraPS -Exactly -Times 1
            }

            It "Modifies a user's DisplayName if the -DisplayName parameter is passed" {
                Set-JiraUser -User $testUsername -DisplayName $testDisplayNameChanged

                Should -Invoke Invoke-JiraRequest -ModuleName JiraPS -Exactly -Times 1 -ParameterFilter {
                    $Method -eq 'Put' -and $URI -eq "/rest/api/2/user?username=$testUsername" -and
                    ($Body | ConvertFrom-Json).displayName -eq $testDisplayNameChanged
                }
            }

            It "Modifies a user's EmailAddress if the -EmailAddress parameter is passed" {
                Set-JiraUser -User $testUsername -EmailAddress $testEmailChanged

                Should -Invoke Invoke-JiraRequest -ModuleName JiraPS -Exactly -Times 1 -ParameterFilter {
                    $Method -eq 'Put' -and $URI -eq "/rest/api/2/user?username=$testUsername" -and
                    ($Body | ConvertFrom-Json).emailAddress -eq $testEmailChanged
                }
            }

            It "Provides no output if the -PassThru parameter is not passed" {
                $output = Set-JiraUser -User $testUsername -DisplayName $testDisplayNameChanged
                $output | Should -BeNullOrEmpty
            }

            It "Outputs a AtlassianPS.JiraPS.User object if the -PassThru parameter is passed" {
                $output = Set-JiraUser -User $testUsername -DisplayName $testDisplayNameChanged -PassThru
                $output | Should -BeOfType ([AtlassianPS.JiraPS.User])
                $output.Name | Should -Be $testUsername
            }
        }

        Describe "Cloud Deployment" {
            It "fails before mutation with account administration guidance" {
                Mock Test-JiraCloudServer { $true }
                { Set-JiraUser -User 'opaque-account' -DisplayName 'Changed name' } |
                    Should -Throw '*Atlassian account administration*'
                Should -Invoke Invoke-JiraRequest -Exactly 0
            }
        }
    }
}
