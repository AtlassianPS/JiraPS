#requires -modules @{ ModuleName = "Pester"; ModuleVersion = "5.7"; MaximumVersion = "5.999" }

BeforeDiscovery {
    . "$PSScriptRoot/../../Helpers/TestTools.ps1"

    Initialize-TestEnvironment
    $script:moduleToTest = Resolve-ModuleSource

    Import-Module $moduleToTest -Force -ErrorAction Stop
}

InModuleScope JiraPS {
    Describe "Get-JiraGroup" -Tag 'Unit' {
        BeforeAll {
            . "$PSScriptRoot/../../Helpers/TestTools.ps1"
            # $VerbosePreference = 'Continue'  # Uncomment for mock debugging

            #region Definitions
            $script:jiraServer = 'http://jiraserver.example.com'
            $script:testGroupName = 'Test Group'
            $script:testGroupNameEscaped = [System.Web.HttpUtility]::UrlEncode($testGroupName)
            $script:testGroupSize = 1

            $script:restResult = @"
{
    "name": "$testGroupName",
    "self": "$jiraServer/rest/api/2/group?groupname=$testGroupName",
    "users": {
        "size": "$testGroupSize",
        "items": [],
        "max-results": 50,
        "start-index": 0,
        "end-index": 0
    },
    "expand": "users"
}
"@
            #endregion Definitions

            #region Mocks
            Mock Get-JiraConfigServer -ModuleName JiraPS {
                Write-MockDebugInfo 'Get-JiraConfigServer'
                $jiraServer
            }

            Mock ConvertTo-JiraGroup -ModuleName JiraPS {
                Write-MockDebugInfo 'ConvertTo-JiraGroup'
                $object = [PSCustomObject]@{
                    Name = $InputObject.name
                    Size = $InputObject.users.size
                }
                $object.PSObject.TypeNames.Insert(0, 'JiraPS.Group')
                $object
            }

            Mock Invoke-JiraMethod -ModuleName JiraPS -ParameterFilter {
                $Method -eq 'Get' -and
                $URI -eq "$jiraServer/rest/api/2/group?groupname=$testGroupNameEscaped"
            } {
                Write-MockDebugInfo 'Invoke-JiraMethod' 'Method', 'Uri'
                ConvertFrom-Json -InputObject $restResult
            }

            Mock Invoke-JiraMethod -ModuleName JiraPS {
                Write-MockDebugInfo 'Invoke-JiraMethod' 'Method', 'Uri'
                throw "Unidentified call to Invoke-JiraMethod: $Method $URI"
            }
            #endregion Mocks
        }

        Describe "Signature" {
            BeforeAll {
                $script:command = Get-Command -Name 'Get-JiraGroup'
            }

            Context "Parameter Types" {
                It "has a parameter '<parameter>' of type '<type>'" -TestCases @(
                    @{ parameter = "GroupName"; type = "String[]" }
                    @{ parameter = "Credential"; type = "System.Management.Automation.PSCredential" }
                ) {
                    $command | Should -HaveParameter $parameter
                }
            }

            Context "Mandatory Parameters" {
                It "parameter '<parameter>' is mandatory" -TestCases @(
                    @{ parameter = "GroupName" }
                ) {
                    $command | Should -HaveParameter $parameter -Mandatory
                }
            }
        }

        Describe "Behavior" {
            Context "Group Retrieval" {
                It "gets information about a provided Jira group" {
                    $getResult = Get-JiraGroup -GroupName $testGroupName
                    $getResult | Should -Not -BeNullOrEmpty
                    $getResult.Name | Should -Be $testGroupName

                    Should -Invoke Invoke-JiraMethod -ModuleName JiraPS -Exactly -Times 1 -Scope It -ParameterFilter {
                        $Method -eq 'Get' -and
                        $URI -like "*/rest/api/2/group?groupname=$testGroupNameEscaped"
                    }
                }

                It "uses ConvertTo-JiraGroup to format output" {
                    Get-JiraGroup -GroupName $testGroupName

                    Should -Invoke ConvertTo-JiraGroup -ModuleName JiraPS -Exactly -Times 1 -Scope It
                }
            }

            Context "API Interaction" {
                It "calls Invoke-JiraMethod with correct parameters" {
                    { Get-JiraGroup -GroupName $testGroupName } | Should -Not -Throw

                    Should -Invoke Invoke-JiraMethod -ModuleName JiraPS -Exactly -Times 1 -Scope It -ParameterFilter {
                        $Method -eq 'Get' -and
                        $URI -eq "$jiraServer/rest/api/2/group?groupname=$testGroupNameEscaped"
                    }
                }
            }
        }

        Describe "Input Validation" {
            Context "Multiple Groups" {
                It "can retrieve multiple groups" {
                    Mock Invoke-JiraMethod -ModuleName JiraPS -ParameterFilter {
                        $Method -eq 'Get' -and
                        $URI -like "*/rest/api/2/group?groupname=*"
                    } {
                        Write-MockDebugInfo 'Invoke-JiraMethod' 'Method', 'Uri'
                        ConvertFrom-Json -InputObject $restResult
                    }

                    $result = Get-JiraGroup -GroupName $testGroupName, 'Another Group'
                    $result | Should -HaveCount 2

                    Should -Invoke Invoke-JiraMethod -ModuleName JiraPS -Exactly -Times 2 -Scope It
                }
            }

            Context "URL Encoding" {
                It "properly encodes group names with special characters" {
                    Get-JiraGroup -GroupName $testGroupName

                    Should -Invoke Invoke-JiraMethod -ModuleName JiraPS -Exactly -Times 1 -Scope It -ParameterFilter {
                        $URI -like "*groupname=$testGroupNameEscaped*"
                    }
                }
            }
        }
    }
}
