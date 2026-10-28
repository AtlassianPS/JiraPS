#requires -modules @{ ModuleName = "Pester"; ModuleVersion = "6.2.0"; MaximumVersion = "6.999" }

BeforeDiscovery {
    . "$PSScriptRoot/../../Helpers/TestTools.ps1"

    $script:moduleToTest = Initialize-TestEnvironment
}

InModuleScope JiraPS {
    Describe "Add-JiraIssueComment" -Tag 'Unit' {
        BeforeAll {
            . "$PSScriptRoot/../../Helpers/TestTools.ps1"

            #region Definitions
            $jiraServer = 'http://jiraserver.example.com'
            $script:issueID = 41701
            $script:issueKey = 'IT-3676'

            $restResponse = @"
{
    "self": "$jiraServer/rest/api/2/issue/$issueID/comment/90730",
    "id": "90730",
    "body": "Test comment",
    "created": "2015-05-01T16:24:38.000-0500",
    "updated": "2015-05-01T16:24:38.000-0500"
}
"@
            #endregion Definitions

            #region Mocks
            Mock Get-JiraConfigServer -ModuleName JiraPS {
                Write-MockDebugInfo 'Get-JiraConfigServer'
                Write-Output $jiraServer
            }

            Mock ConvertTo-JiraComment -ModuleName JiraPS {
                Write-MockDebugInfo 'ConvertTo-JiraComment' 'InputObject'
                return $InputObject
            }

            Mock Get-JiraIssueOperation -ModuleName JiraPS {
                Write-MockDebugInfo 'Get-JiraIssue' 'Key'
                $object = [AtlassianPS.JiraPS.Issue]@{
                    ID      = $issueID
                    Key     = $issueKey
                    RestUrl = "$jiraServer/rest/api/2/issue/$issueID"
                }
                return $object
            }

            Mock Resolve-JiraIssueObject -ModuleName JiraPS {
                Write-MockDebugInfo 'Resolve-JiraIssueObject' 'InputObject'
                Get-JiraIssue -Key $InputObject.Key
            }

            Mock Invoke-JiraRequest -ModuleName JiraPS -ParameterFilter { $Method -eq 'POST' -and $URI -eq "$jiraServer/rest/api/2/issue/$issueID/comment" } {
                Write-MockDebugInfo 'Invoke-JiraRequest' 'Method', 'Uri'
                ConvertFrom-Json $restResponse
            }

            # Cloud equivalent: when Test-JiraCloudServer returns $true the
            # cmdlet hits the v3 endpoint (so the API accepts ADF). The
            # mocked response is the same — only the URI changes.
            Mock Invoke-JiraRequest -ModuleName JiraPS -ParameterFilter { $Method -eq 'POST' -and $URI -eq "$jiraServer/rest/api/3/issue/$issueID/comment" } {
                Write-MockDebugInfo 'Invoke-JiraRequest' 'Method', 'Uri'
                ConvertFrom-Json $restResponse
            }

            # Generic catch-all. This will throw an exception if we forgot to mock something.
            Mock Invoke-JiraRequest -ModuleName JiraPS {
                Write-MockDebugInfo 'Invoke-JiraRequest' 'Method', 'Uri'
                throw "Unidentified call to Invoke-JiraRequest"
            }

            Mock Test-JiraCloudServer -ModuleName JiraPS { return $false }
            #endregion Mocks
        }

        Describe "Signature" {
            BeforeAll {
                $script:command = Get-Command -Name "Add-JiraIssueComment"
            }

            Context "Parameter Types" {
                It "has a parameter '<parameter>' of type '<type>'" -TestCases @(
                    @{ parameter = 'Comment'; type = 'String' }
                    @{ parameter = 'Issue'; type = 'AtlassianPS.JiraPS.Issue' }
                    @{ parameter = 'Visibility'; type = 'AtlassianPS.JiraPS.Visibility' }
                    @{ parameter = 'Credential'; type = 'System.Management.Automation.PSCredential' }
                ) {
                    $command | Should -HaveParameter $parameter -Type $type
                }
            }

            Context "Default Values" {
                It "parameter '<parameter>' has a default value of '<defaultValue>'" -TestCases @(
                    @{ parameter = "Visibility"; defaultValue = $null }
                    @{ parameter = "Credential"; defaultValue = $null }
                ) {
                    $command | Should -HaveParameter $parameter -DefaultValue $defaultValue
                }
            }

            Context "Mandatory Parameters" {
                It "parameter '<parameter>' is mandatory" -TestCases @(
                    @{ parameter = "Comment" }
                    @{ parameter = "Issue" }
                ) {
                    $command | Should -HaveParameter $parameter -Mandatory
                }
            }
        }

        Describe "Behavior" {
            It "Adds a comment to an issue in JIRA" {
                $commentResult = Add-JiraIssueComment -Comment 'This is a test comment from Pester.' -Issue $issueKey
                $commentResult | Should -Not -BeNullOrEmpty

                Should -Invoke 'Get-JiraIssueOperation' -ModuleName JiraPS -Exactly -Times 1
                Should -Invoke 'Resolve-JiraIssueObject' -ModuleName JiraPS -Exactly -Times 1
                Should -Invoke 'Invoke-JiraRequest' -ModuleName JiraPS -Exactly -Times 1
            }

            It "returns a Jira.Comment object" {
                Add-JiraIssueComment -Comment 'This is a test comment from Pester.' -Issue $issueKey | Out-Null

                Should -Invoke 'ConvertTo-JiraComment'
            }

            Context "Visibility payloads" {
                It "omits visibility for <description> on Cloud=<cloud>" -TestCases @(
                    foreach ($cloud in $false, $true) {
                        @{
                            cloud       = $cloud
                            description = 'default access'
                            parameters  = @{}
                        }
                        @{
                            cloud       = $cloud
                            description = 'All Users'
                            parameters  = @{
                                Visibility = 'All Users'
                            }
                        }
                        @{
                            cloud       = $cloud
                            description = 'VisibleRole alias'
                            parameters  = @{
                                VisibleRole = 'aLl UsErS'
                            }
                        }
                        @{
                            cloud       = $cloud
                            description = 'role object All Users'
                            parameters  = @{
                                Visibility = @{
                                    Type  = 'role'
                                    Value = 'All Users'
                                }
                            }
                        }
                        @{
                            cloud       = $cloud
                            description = 'typed role All Users'
                            parameters  = @{
                                Visibility = [AtlassianPS.JiraPS.Visibility]@{
                                    Type  = 'role'
                                    Value = 'All Users'
                                }
                            }
                        }
                    }
                ) {
                    Mock Test-JiraCloudServer -ModuleName JiraPS { $cloud }
                    Add-JiraIssueComment -Issue $issueKey -Comment 'Visibility test' @parameters | Out-Null
                    Should -Invoke Invoke-JiraRequest -ModuleName JiraPS -Exactly -Times 1 -ParameterFilter {
                        $payload = $Body | ConvertFrom-Json
                        $payload.PSObject.Properties.Name -notcontains 'visibility'
                    }
                }

                It "sends <description> on Cloud=<cloud>" -TestCases @(
                    foreach ($cloud in $false, $true) {
                        @{
                            cloud         = $cloud
                            description   = 'custom role name'
                            value         = 'Release Managers'
                            expectedType  = 'role'
                            expectedValue = 'Release Managers'
                        }
                        @{
                            cloud         = $cloud
                            description   = 'group object'
                            value         = @{
                                Type  = 'group'
                                Value = 'jira-users'
                            }
                            expectedType  = 'group'
                            expectedValue = 'jira-users'
                        }
                        @{
                            cloud         = $cloud
                            description   = 'typed role'
                            value         = [AtlassianPS.JiraPS.Visibility]@{
                                Type  = 'role'
                                Value = 'Developers'
                            }
                            expectedType  = 'role'
                            expectedValue = 'Developers'
                        }
                        @{
                            cloud         = $cloud
                            description   = 'group actually named All Users'
                            value         = @{
                                Type  = 'group'
                                Value = 'All Users'
                            }
                            expectedType  = 'group'
                            expectedValue = 'All Users'
                        }
                    }
                ) {
                    Mock Test-JiraCloudServer -ModuleName JiraPS { $cloud }
                    Add-JiraIssueComment -Issue $issueKey -Comment 'Visibility test' -Visibility $value | Out-Null
                    Should -Invoke Invoke-JiraRequest -ModuleName JiraPS -Exactly -Times 1 -ParameterFilter {
                        $payload = $Body | ConvertFrom-Json
                        $payload.visibility.type -eq $expectedType -and
                        $payload.visibility.value -eq $expectedValue -and
                        $payload.visibility.PSObject.Properties.Name -notcontains 'identifier'
                    }
                }

                It "sends a Cloud group identifier without inventing a name" {
                    Mock Test-JiraCloudServer -ModuleName JiraPS { $true }
                    Add-JiraIssueComment -Issue $issueKey -Comment 'Visibility test' -Visibility @{
                        Type       = 'group'
                        Identifier = 'group-123'
                    } | Out-Null
                    Should -Invoke Invoke-JiraRequest -ModuleName JiraPS -Exactly -Times 1 -ParameterFilter {
                        $payload = $Body | ConvertFrom-Json
                        $payload.visibility.type -eq 'group' -and $payload.visibility.identifier -eq 'group-123' -and
                        $payload.visibility.PSObject.Properties.Name -notcontains 'value'
                    }
                }

                It "rejects malformed visibility <description> before making API calls" -TestCases @(
                    @{
                        description = 'unsupported type'
                        value       = @{
                            Type  = 'user'
                            Value = 'someone'
                        }
                    }
                    @{
                        description = 'missing role name'
                        value       = @{
                            Type = 'role'
                        }
                    }
                    @{
                        description = 'blank group name'
                        value       = @{
                            Type  = 'group'
                            Value = ' '
                        }
                    }
                    @{ description = 'empty string'; value = '' }
                    @{ description = 'numeric value'; value = 123 }
                ) {
                    { Add-JiraIssueComment -Issue $issueKey -Comment 'Visibility test' -Visibility $value -ErrorAction Stop } |
                        Should -Throw -ExceptionType ([System.Management.Automation.ParameterBindingException])
                    Should -Invoke Resolve-JiraIssueObject -ModuleName JiraPS -Exactly -Times 0
                    Should -Invoke Invoke-JiraRequest -ModuleName JiraPS -Exactly -Times 0
                }
            }

            Context "Cloud vs Data Center body shape" {
                It "sends a plain-string body on Server / Data Center" {
                    Mock Test-JiraCloudServer -ModuleName JiraPS { return $false }

                    Add-JiraIssueComment -Comment 'Hello *world*' -Issue $issueKey | Out-Null

                    Should -Invoke 'Invoke-JiraRequest' -ModuleName JiraPS -ParameterFilter {
                        $payload = $Body | ConvertFrom-Json
                        $payload.body -is [string] -and $payload.body -eq 'Hello *world*'
                    }
                }

                It "wraps the body in an Atlassian Document Format document on Cloud" {
                    Mock Test-JiraCloudServer -ModuleName JiraPS { return $true }

                    Add-JiraIssueComment -Comment 'Hello world' -Issue $issueKey | Out-Null

                    Should -Invoke 'Invoke-JiraRequest' -ModuleName JiraPS -ParameterFilter {
                        $payload = $Body | ConvertFrom-Json
                        $payload.body.type -eq 'doc' -and
                        $payload.body.version -eq 1 -and
                        $payload.body.content[0].type -eq 'paragraph' -and
                        $payload.body.content[0].content[0].text -eq 'Hello world'
                    }
                }

                It "preserves the visibility block alongside an ADF body on Cloud" {
                    Mock Test-JiraCloudServer -ModuleName JiraPS { return $true }

                    Add-JiraIssueComment -Comment 'Restricted note' -VisibleRole 'Developers' -Issue $issueKey | Out-Null

                    Should -Invoke 'Invoke-JiraRequest' -ModuleName JiraPS -ParameterFilter {
                        $payload = $Body | ConvertFrom-Json
                        $payload.body.type -eq 'doc' -and
                        $payload.visibility.type -eq 'role' -and
                        $payload.visibility.value -eq 'Developers'
                    }
                }

                It "targets the v3 comment endpoint on Cloud" {
                    Mock Test-JiraCloudServer -ModuleName JiraPS { return $true }

                    Add-JiraIssueComment -Comment 'Hello world' -Issue $issueKey | Out-Null

                    Should -Invoke 'Invoke-JiraRequest' -ModuleName JiraPS -ParameterFilter {
                        $Method -eq 'POST' -and $URI -eq "$jiraServer/rest/api/3/issue/$issueID/comment"
                    }
                }

                It "targets the v2 comment endpoint on Server / DC" {
                    Mock Test-JiraCloudServer -ModuleName JiraPS { return $false }

                    Add-JiraIssueComment -Comment 'Hello world' -Issue $issueKey | Out-Null

                    Should -Invoke 'Invoke-JiraRequest' -ModuleName JiraPS -ParameterFilter {
                        $Method -eq 'POST' -and $URI -eq "$jiraServer/rest/api/2/issue/$issueID/comment"
                    }
                }
            }
        }

        Describe "Input Validation" {
            Context "Type Validation - Positive Cases" {
                It "Accepts pipeline input from Get-JiraIssue" {
                    $commentResult = Get-JiraIssue -Key $IssueKey | Add-JiraIssueComment -Comment 'This is a test comment from Pester, using the pipeline!'

                    $commentResult | Should -Not -BeNullOrEmpty
                }
            }

            Context "Type Validation - Negative Cases" {}
        }
    }
}
