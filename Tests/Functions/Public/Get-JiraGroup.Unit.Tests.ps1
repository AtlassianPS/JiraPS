#requires -modules @{ ModuleName = "Pester"; ModuleVersion = "5.7"; MaximumVersion = "5.999" }

BeforeDiscovery {
    . "$PSScriptRoot/../../Helpers/TestTools.ps1"

    $script:moduleToTest = Initialize-TestEnvironment
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
            $script:testGroupId = '276f955c-63d7-42c8-9520-92d01dca0625'

            $script:restResult = @"
{
    "name": "$testGroupName",
    "groupId": "$testGroupId",
    "self": "$jiraServer/rest/api/2/group/member?groupname=$testGroupName",
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

            $script:bulkRestResult = @"
{
    "isLast": true,
    "maxResults": 50,
    "startAt": 0,
    "total": 1,
    "values": [
        {
            "groupId": "$testGroupId",
            "name": "$testGroupName"
        }
    ]
}
"@

            #endregion Definitions

            #region Mocks

            Mock Test-JiraCloudServer -ModuleName JiraPS {
                Write-MockDebugInfo 'Test-JiraCloudServer'
                $false
            }

            Mock Get-JiraConfigServer -ModuleName JiraPS {
                Write-MockDebugInfo 'Get-JiraConfigServer'
                $jiraServer
            }

            Mock ConvertTo-JiraGroup -ModuleName JiraPS {
                Write-MockDebugInfo 'ConvertTo-JiraGroup'
                if ($null -eq $InputObject -or @($InputObject).Count -eq 0) {
                    return
                }

                $object = [PSCustomObject]@{
                    Name = $InputObject.name
                    Id   = $InputObject.groupId
                    Size = if ($InputObject.users) { $InputObject.users.size } else { $null }
                }
                $object.PSObject.TypeNames.Insert(0, 'JiraPS.Group')
                $object
            }

            Mock Invoke-JiraMethod -ModuleName JiraPS -ParameterFilter {
                $Method -eq 'Get' -and
                $URI -eq '/rest/api/2/group/member' -and
                $GetParameter['groupname'] -eq $testGroupName -and
                $GetParameter['maxResults'] -eq 1
            } {
                Write-MockDebugInfo 'Invoke-JiraMethod' 'Method', 'Uri', 'GetParameter'
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
                    $getResult.Id | Should -Be $testGroupId

                    Should -Invoke Invoke-JiraMethod -ModuleName JiraPS -Exactly -Times 1 -ParameterFilter {
                        $Method -eq 'Get' -and
                        $URI -eq '/rest/api/2/group/member' -and
                        $GetParameter['groupname'] -eq $testGroupName -and
                        $GetParameter['maxResults'] -eq 1
                    }
                }

                It "uses ConvertTo-JiraGroup to format output" {
                    Get-JiraGroup -GroupName $testGroupName

                    Should -Invoke ConvertTo-JiraGroup -ModuleName JiraPS -Exactly -Times 1
                }
            }

            Context "API Interaction" {
                It "calls Invoke-JiraMethod with correct parameters" {
                    { Get-JiraGroup -GroupName $testGroupName } | Should -Not -Throw

                    Should -Invoke Invoke-JiraMethod -ModuleName JiraPS -Exactly -Times 1 -ParameterFilter {
                        $Method -eq 'Get' -and
                        $URI -eq '/rest/api/2/group/member' -and
                        $GetParameter['groupname'] -eq $testGroupName -and
                        $GetParameter['maxResults'] -eq 1
                    }
                }
            }
        }

        Describe "Input Validation" {
            Context "Multiple Groups" {
                It "can retrieve multiple groups" {
                    Mock Invoke-JiraMethod -ModuleName JiraPS -ParameterFilter {
                        $Method -eq 'Get' -and
                        $URI -eq '/rest/api/2/group/member' -and
                        $GetParameter['groupname'] -and
                        $GetParameter['maxResults'] -eq 1
                    } {
                        Write-MockDebugInfo 'Invoke-JiraMethod' 'Method', 'Uri', 'GetParameter'
                        ConvertFrom-Json -InputObject $restResult
                    }

                    $result = Get-JiraGroup -GroupName $testGroupName, 'Another Group'
                    $result | Should -HaveCount 2

                    Should -Invoke Invoke-JiraMethod -ModuleName JiraPS -Exactly -Times 2 -ParameterFilter {
                        $Method -eq 'Get' -and
                        $URI -eq '/rest/api/2/group/member' -and
                        $GetParameter['groupname'] -and
                        $GetParameter['maxResults'] -eq 1
                    }
                }
            }

            Context "URL Encoding" {
                It "passes the group name as a query parameter" {
                    Get-JiraGroup -GroupName $testGroupName

                    Should -Invoke Invoke-JiraMethod -ModuleName JiraPS -Exactly -Times 1 -ParameterFilter {
                        $URI -eq '/rest/api/2/group/member' -and
                        $GetParameter['groupname'] -eq $testGroupName -and
                        $GetParameter['maxResults'] -eq 1
                    }
                }
            }

            Context "Server Response Normalization" {
                It "accepts a Data Center payload that only exposes groupName" {
                    Mock Invoke-JiraMethod -ModuleName JiraPS -ParameterFilter {
                        $Method -eq 'Get' -and
                        $URI -eq '/rest/api/2/group/member' -and
                        $GetParameter['groupname'] -eq 'dc-group' -and
                        $GetParameter['maxResults'] -eq 1
                    } {
                        [PSCustomObject]@{
                            groupName = 'dc-group'
                            total     = 2
                            users     = [PSCustomObject]@{
                                items = @()
                            }
                        }
                    }

                    $group = Get-JiraGroup -GroupName 'dc-group'

                    $group | Should -Not -BeNullOrEmpty
                    $group.Name | Should -Be 'dc-group'
                    $group.Size | Should -Be 2
                }
            }

            Context "Modern Group API" {
                BeforeAll {
                    Mock Test-JiraCloudServer -ModuleName JiraPS { $true }

                    Mock Invoke-JiraMethod -ModuleName JiraPS -ParameterFilter {
                        $Method -eq 'Get' -and
                        $URI -eq '/rest/api/2/group/bulk' -and
                        $GetParameter['groupName'] -eq $testGroupName -and
                        $Paging
                    } {
                        Write-MockDebugInfo 'Invoke-JiraMethod' 'Method', 'Uri', 'GetParameter'
                        (ConvertFrom-Json -InputObject $bulkRestResult).values[0]
                    }
                }

                It "uses the bulk endpoint for Cloud" {
                    $getResult = Get-JiraGroup -GroupName $testGroupName

                    $getResult | Should -Not -BeNullOrEmpty
                    $getResult.Name | Should -Be $testGroupName
                    $getResult.Id | Should -Be $testGroupId

                    Should -Invoke Invoke-JiraMethod -ModuleName JiraPS -Exactly -Times 1 -ParameterFilter {
                        $Method -eq 'Get' -and
                        $URI -eq '/rest/api/2/group/bulk' -and
                        $GetParameter['groupName'] -eq $testGroupName -and
                        $Paging
                    }
                }

                It "writes an error when the bulk endpoint returns no exact match" {
                    Mock Invoke-JiraMethod -ModuleName JiraPS -ParameterFilter {
                        $Method -eq 'Get' -and
                        $URI -eq '/rest/api/2/group/bulk' -and
                        $GetParameter['groupName'] -eq 'missing-group' -and
                        $Paging
                    } {
                        Write-MockDebugInfo 'Invoke-JiraMethod' 'Method', 'Uri', 'GetParameter'
                        @()
                    }

                    { Get-JiraGroup -GroupName 'missing-group' -ErrorAction Stop } | Should -Throw -ExpectedMessage "*did not return exactly one canonical group*"
                }
            }

            Context "Endpoint Fallback" {
                It "writes an error when the Server group member endpoint returns no payload" {
                    Mock Invoke-JiraMethod -ModuleName JiraPS -ParameterFilter {
                        $Method -eq 'Get' -and
                        $URI -eq '/rest/api/2/group/member' -and
                        $GetParameter['groupname'] -eq $testGroupName -and
                        $GetParameter['maxResults'] -eq 1
                    } {
                        $null
                    }

                    { Get-JiraGroup -GroupName $testGroupName -ErrorAction Stop } | Should -Throw -ExpectedMessage "*did not return a canonical group payload*"

                    Should -Invoke Invoke-JiraMethod -ModuleName JiraPS -Exactly -Times 1 -ParameterFilter {
                        $Method -eq 'Get' -and
                        $URI -eq '/rest/api/2/group/member' -and
                        $GetParameter['groupname'] -eq $testGroupName -and
                        $GetParameter['maxResults'] -eq 1
                    }
                }

                It "returns other groups while writing a non-terminating error for a missing group" {
                    Mock Invoke-JiraMethod -ModuleName JiraPS -ParameterFilter {
                        $Method -eq 'Get' -and
                        $URI -eq '/rest/api/2/group/member' -and
                        $GetParameter['groupname'] -eq 'missing-group' -and
                        $GetParameter['maxResults'] -eq 1
                    } {
                        $null
                    }

                    $errors = @()
                    $result = Get-JiraGroup -GroupName $testGroupName, 'missing-group' -ErrorVariable +errors

                    $result | Should -HaveCount 1
                    $result.Name | Should -Be $testGroupName
                    $errors | Should -HaveCount 1
                    $errors[0].FullyQualifiedErrorId | Should -Be 'GroupNotFound,Get-JiraGroup'
                }

                It "throws when the Cloud bulk endpoint returns 404" {
                    Mock Test-JiraCloudServer -ModuleName JiraPS { $true }

                    Mock Invoke-JiraMethod -ModuleName JiraPS -ParameterFilter {
                        $Method -eq 'Get' -and
                        $URI -eq '/rest/api/2/group/bulk' -and
                        $GetParameter['groupName'] -eq $testGroupName -and
                        $Paging
                    } {
                        ThrowError -Cmdlet $PSCmdlet -Exception ([System.Exception]'Invalid Server Response') -ErrorId 'InvalidResponse.Status404' -Category InvalidResult
                    }

                    { Get-JiraGroup -GroupName $testGroupName -ErrorAction Stop } | Should -Throw -ExpectedMessage '*Invalid Server Response*'

                    Should -Invoke Invoke-JiraMethod -ModuleName JiraPS -Exactly -Times 1 -ParameterFilter {
                        $Method -eq 'Get' -and
                        $URI -eq '/rest/api/2/group/bulk' -and
                        $GetParameter['groupName'] -eq $testGroupName -and
                        $Paging
                    }
                }
            }
        }
    }
}
