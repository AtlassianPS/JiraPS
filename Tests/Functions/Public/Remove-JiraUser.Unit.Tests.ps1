#requires -modules @{ ModuleName = "Pester"; ModuleVersion = "6.2.0"; MaximumVersion = "6.999" }

BeforeDiscovery {
    . "$PSScriptRoot/../../Helpers/TestTools.ps1"

    $script:moduleToTest = Initialize-TestEnvironment
}

InModuleScope JiraPS {
    Describe "Remove-JiraUser" -Tag 'Unit' {

        BeforeAll {
            . "$PSScriptRoot/../../Helpers/TestTools.ps1"
            # $VerbosePreference = 'Continue'

            #region Definitions
            $script:jiraServer = 'http://jiraserver.example.com'
            $script:testUsername = 'powershell-test'
            $script:testEmail = "$testUsername@example.com"
            $script:testDisplayName = 'Test User'

            # Trimmed from this example JSON: expand, groups, avatarURL
            $script:testJsonGet = @"
{
    "self": "$jiraServer/rest/api/2/user?username=$testUsername",
    "key": "$testUsername",
    "name": "$testUsername",
    "emailAddress": "$testEmail",
    "displayName": "$testDisplayName",
    "active": true
}
"@
            #endregion Definitions

            #region Mocks
            Mock Test-JiraCloudServer -ModuleName JiraPS { $false }

            Mock Get-JiraUser -ModuleName JiraPS {
                Write-MockDebugInfo 'Get-JiraUser' 'UserName'
                $object = ConvertFrom-Json $testJsonGet
                $object.PSObject.TypeNames.Insert(0, 'AtlassianPS.JiraPS.User')
                return $object
            }

            Mock Invoke-JiraRequest -ModuleName JiraPS -ParameterFilter {
                $Method -eq 'DELETE' -and
                $URI -like "/rest/api/*/user?username=$testUsername"
            } {
                Write-MockDebugInfo 'Invoke-JiraRequest' 'Method', 'Uri'
                # This REST method should produce no output
            }

            # Generic catch-all. This will throw an exception if we forgot to mock something.
            Mock Invoke-JiraRequest -ModuleName JiraPS {
                Write-MockDebugInfo 'Invoke-JiraRequest' 'Method', 'Uri'
                throw "Unidentified call to Invoke-JiraRequest"
            }
            #endregion Mocks
        }

        Describe "Behavior" {
            Context "User Deletion" {
                It "Accepts a username as a String to the -User parameter" {
                    { Remove-JiraUser -User $testUsername -Confirm:$false } | Should -Not -Throw
                    Should -Invoke -CommandName Invoke-JiraRequest -Exactly -Times 1
                }

                It "Accepts a AtlassianPS.JiraPS.User object to the -User parameter" {
                    $user = Get-JiraUser -User $testUsername
                    { Remove-JiraUser -User $user -Confirm:$false } | Should -Not -Throw
                    Should -Invoke -CommandName Invoke-JiraRequest -Exactly -Times 1
                }

                It "Accepts pipeline input from Get-JiraUser" {
                    { Get-JiraUser -User $testUsername | Remove-JiraUser -Confirm:$false } | Should -Not -Throw
                    Should -Invoke -CommandName Invoke-JiraRequest -Exactly -Times 1
                }

                It "Provides no output" {
                    Remove-JiraUser -User $testUsername -Confirm:$false | Should -BeNullOrEmpty
                }
            }
        }

        Describe "Cloud Deployment" {
            BeforeAll {
                $script:testAccountId = '5b10a2844c20165700ede21a'

                Mock Test-JiraCloudServer -ModuleName JiraPS { $true }

                Mock Get-JiraUser -ModuleName JiraPS {
                    Write-MockDebugInfo 'Get-JiraUser' 'UserName'
                    $object = ConvertFrom-Json $testJsonGet
                    $object | Add-Member -MemberType NoteProperty -Name 'AccountId' -Value $testAccountId
                    $object.PSObject.TypeNames.Insert(0, 'AtlassianPS.JiraPS.User')
                    return $object
                }

                Mock Invoke-JiraRequest -ModuleName JiraPS -ParameterFilter {
                    $Method -eq 'DELETE' -and
                    $URI -like "/rest/api/*/user?accountId=*"
                } {
                    Write-MockDebugInfo 'Invoke-JiraRequest' 'Method', 'Uri'
                }
            }

            It "Uses accountId in the URI instead of username" {
                { Remove-JiraUser -User $testUsername -Confirm:$false } | Should -Not -Throw

                Should -Invoke -CommandName Invoke-JiraRequest -Exactly -Times 1 -ParameterFilter {
                    $Method -eq 'DELETE' -and
                    $URI -like "*accountId=$testAccountId*"
                }
            }
        }
    }
}
