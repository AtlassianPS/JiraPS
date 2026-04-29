#requires -modules @{ ModuleName = "Pester"; ModuleVersion = "5.7"; MaximumVersion = "5.999" }

BeforeDiscovery {
    . "$PSScriptRoot/../../Helpers/TestTools.ps1"

    $script:moduleToTest = Initialize-TestEnvironment
}

InModuleScope JiraPS {
    Describe "Add-JiraGroupMember" -Tag 'Unit' {
        BeforeAll {
            . "$PSScriptRoot/../../Helpers/TestTools.ps1"

            #region Definitions
            $script:jiraServer = 'http://jiraserver.example.com'

            # In most test cases, user 1 is a member of the group and user 2 is not
            $script:testGroupName = 'testGroup'
            $script:testUsername1 = 'testUsername1'
            $script:testUsername2 = 'testUsername2'
            #endregion Definitions

            #region Mocks
            Mock Test-JiraCloudServer -ModuleName JiraPS { $false }

            Mock Get-JiraConfigServer -ModuleName JiraPS {
                Write-MockDebugInfo 'Get-JiraConfigServer'
                Write-Output $jiraServer
            }

            Mock Get-JiraGroup -ModuleName JiraPS {
                Write-MockDebugInfo 'Get-JiraGroup'
                $object = [PSCustomObject] @{
                    'Name' = $testGroupName
                    'Size' = 2
                }
                $object.PSObject.TypeNames.Insert(0, 'JiraPS.Group')
                return $object
            }

            Mock Get-JiraUser -ModuleName JiraPS {
                Write-MockDebugInfo 'Get-JiraUser' 'UserName'
                foreach ($user in $UserName) {
                    $object = [PSCustomObject] @{
                        'Name' = "$user"
                    }
                    $object.PSObject.TypeNames.Insert(0, 'AtlassianPS.JiraPS.User')
                    Write-Output $object
                }
            }

            Mock Get-JiraGroupMember -ModuleName JiraPS {
                Write-MockDebugInfo 'Get-JiraGroupMember'
                @(
                    [PSCustomObject] @{
                        'Name' = $testUsername1
                    }
                )
            }

            Mock ConvertTo-JiraGroup -ModuleName JiraPS {
                Write-MockDebugInfo 'ConvertTo-JiraGroup' 'InputObject'
                $InputObject
            }

            Mock Invoke-JiraMethod -ModuleName JiraPS {
                Write-MockDebugInfo 'Invoke-JiraMethod' 'Method', 'Uri', 'Body'
                return $true
            }
            #endregion Mocks
        }

        Describe "Signature" {
            BeforeAll {
                $script:command = Get-Command -Name "Add-JiraGroupMember"
            }

            Context "Parameter Types" {
                It "has a parameter '<parameter>' of type '<type>'" -TestCases @(
                    @{ parameter = "Group"; type = "AtlassianPS.JiraPS.Group[]" }
                    @{ parameter = "UserName"; type = "AtlassianPS.JiraPS.User[]" }
                    @{ parameter = "Credential"; type = "System.Management.Automation.PSCredential" }
                    @{ parameter = "Passthru"; type = "Switch" }
                ) {
                    $command | Should -HaveParameter $parameter

                    #ToDo:CustomClass
                    # can't use -Type as long we are using `PSObject.TypeNames.Insert(0, 'AtlassianPS.JiraPS.Filter')`
                    (Get-Member -InputObject $command.Parameters.Item($parameter)).Attributes | Should -Contain $typeName
                }
            }

            Context "Default Values" {
                It "parameter '<parameter>' has a default value of '<defaultValue>'" -TestCases @(
                    @{ parameter = "Credential"; defaultValue = "[System.Management.Automation.PSCredential]::Empty" }
                ) {
                    $command | Should -HaveParameter $parameter -DefaultValue $defaultValue
                }
            }

            Context "Mandatory Parameters" {
                It "parameter '<parameter>' is mandatory" -TestCases @(
                    @{ parameter = "Group" }
                    @{ parameter = "UserName" }
                ) {
                    $command | Should -HaveParameter $parameter -Mandatory
                }
            }

            It "Accepts a group name as a String to the -Group parameter" {
                { Add-JiraGroupMember -Group $testGroupName -User $testUsername2 } | Should -Not -Throw
                { Add-JiraGroupMember -Group $testGroupName -User $testUsername2 -PassThru } | Should -Not -Throw

                Should -Invoke -CommandName Get-JiraGroupMember -Exactly -Times 2
                Should -Invoke -CommandName Get-JiraUser -Exactly -Times 2
                Should -Invoke -CommandName Invoke-JiraMethod -ParameterFilter {
                    $URI -match $testGroupName
                } -Exactly -Times 2
                Should -Invoke -CommandName ConvertTo-JiraGroup -Exactly -Times 1
            }

            It "Accepts a JiraPS.Group object to the -Group parameter" {
                $group = Get-JiraGroup -GroupName $testGroupName
                { Add-JiraGroupMember -Group $group -User $testUsername2 } | Should -Not -Throw

                Should -Invoke -CommandName Invoke-JiraMethod -ParameterFilter {
                    $URI -match $testGroupName
                } -Exactly -Times 1
            }

            It "Accepts pipeline input from Get-JiraGroup" {
                { Get-JiraGroup -GroupName $testGroupName | Add-JiraGroupMember -User $testUsername2 } | Should -Not -Throw

                Should -Invoke -CommandName Invoke-JiraMethod -ParameterFilter {
                    $URI -match $testGroupName
                } -Exactly -Times 1
            }
        }

        Describe "Behavior" {

            It "Tests to see if a provided user is currently a member of the provided JIRA group before attempting to add them" {
                { Add-JiraGroupMember -Group $testGroupName -User $testUsername1 -ErrorAction Stop } | Should -Throw -ExpectedMessage "*already a member*"

                Should -Invoke -CommandName Get-JiraGroupMember -Exactly -Times 1
            }

            It "Adds a user to a JIRA group if the user is not a member" {
                { Add-JiraGroupMember -Group $testGroupName -User $testUsername2 } | Should -Not -Throw

                Should -Invoke -CommandName Invoke-JiraMethod -ParameterFilter {
                    $Method -eq 'POST' -and $URI -match $testGroupName -and $Body -match $testUsername2
                } -Exactly -Times 1
            }

            It "Adds multiple users to a JIRA group if they are passed to the -User parameter" {
                # Override our previous mock so we have no group members
                Mock Get-JiraGroupMember -ModuleName JiraPS { @() }

                # Should use the REST method twice, since at present, you can only add one group member per API call
                { Add-JiraGroupMember -Group $testGroupName -User $testUsername1, $testUsername2 } | Should -Not -Throw

                Should -Invoke -CommandName Invoke-JiraMethod -ParameterFilter {
                    $Method -eq 'Post' -and $URI -match $testGroupName
                } -Exactly -Times 2
            }
        }

        Describe "Error checking" {
            It "Gracefully handles cases where a provided user is already in the provided group" {
                { Add-JiraGroupMember -Group $testGroupName -User $testUsername1, $testUsername2 -ErrorAction SilentlyContinue } | Should -Not -Throw

                Should -Invoke -CommandName Invoke-JiraMethod -ParameterFilter {
                    $Method -eq 'Post' -and $URI -match $testGroupName
                } -Exactly -Times 1
            }
        }

        Describe "Input Validation" {
            Context "Type Validation - Positive Cases" {}

            Context "Type Validation - Negative Cases" {}
        }

        Describe "Cloud Deployment" {
            BeforeAll {
                Mock Test-JiraCloudServer -ModuleName JiraPS { $true }

                Mock Get-JiraGroupMember -ModuleName JiraPS {
                    Write-MockDebugInfo 'Get-JiraGroupMember'
                    @()
                }

                Mock Get-JiraUser -ModuleName JiraPS {
                    Write-MockDebugInfo 'Get-JiraUser' 'UserName'
                    foreach ($user in $UserName) {
                        $object = [PSCustomObject] @{
                            'Name'      = "$user"
                            'AccountId' = "abc123def456"
                        }
                        $object.PSObject.TypeNames.Insert(0, 'AtlassianPS.JiraPS.User')
                        Write-Output $object
                    }
                }
            }

            It "uses accountId in POST body when adding a user on Cloud" {
                { Add-JiraGroupMember -Group $testGroupName -User $testUsername2 } | Should -Not -Throw

                Should -Invoke Invoke-JiraMethod -ModuleName JiraPS -Exactly 1 -ParameterFilter {
                    $Method -eq 'Post' -and $Body -match 'accountId'
                }
            }
        }
    }
}
