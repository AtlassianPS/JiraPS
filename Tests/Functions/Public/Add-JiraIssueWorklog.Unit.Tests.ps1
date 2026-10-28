#requires -modules @{ ModuleName = "Pester"; ModuleVersion = "6.2.0"; MaximumVersion = "6.999" }

BeforeDiscovery {
    . "$PSScriptRoot/../../Helpers/TestTools.ps1"

    $script:moduleToTest = Initialize-TestEnvironment
}

InModuleScope JiraPS {
    Describe "Add-JiraIssueWorklog" -Tag 'Unit' {
        BeforeAll {
            . "$PSScriptRoot/../../Helpers/TestTools.ps1"

            #region Definitions
            $jiraServer = 'http://jiraserver.example.com'
            $script:jiraUsername = 'powershell-test'
            $script:jiraUserDisplayName = 'PowerShell Test User'
            $script:jiraUserEmail = 'noreply@example.com'
            $script:issueID = 41701
            $script:issueKey = 'IT-3676'
            $script:worklogitemID = 73040

            $restResponse = @"
{
    "id": "$worklogitemID",
    "self": "$jiraServer/rest/api/2/issue/$issueID/worklog/$worklogitemID",
    "comment": "Test description",
    "created": "2015-05-01T16:24:38.000-0500",
    "updated": "2015-05-01T16:24:38.000-0500",
    "started": "2017-02-23T22:21:00.000-0500",
    "timeSpent": "1h",
    "timeSpentSeconds": "3600",
    "author": {
        "self": "$jiraServer/rest/api/2/user?username=powershell-test",
        "name": "$jiraUsername",
        "emailAddress": "$jiraUserEmail",
        "avatarUrls": {
            "48x48": "$jiraServer/secure/useravatar?avatarId=10202",
            "24x24": "$jiraServer/secure/useravatar?size=small&avatarId=10202",
            "16x16": "$jiraServer/secure/useravatar?size=xsmall&avatarId=10202",
            "32x32": "$jiraServer/secure/useravatar?size=medium&avatarId=10202"
        },
        "displayName": "$jiraUserDisplayName",
        "active": true
    },
    "updateAuthor": {
        "self": "$jiraServer/rest/api/2/user?username=powershell-test",
        "name": "powershell-test",
        "emailAddress": "$jiraUserEmail",
        "avatarUrls": {
            "48x48": "$jiraServer/secure/useravatar?avatarId=10202",
            "24x24": "$jiraServer/secure/useravatar?size=small&avatarId=10202",
            "16x16": "$jiraServer/secure/useravatar?size=xsmall&avatarId=10202",
            "32x32": "$jiraServer/secure/useravatar?size=medium&avatarId=10202"
        },
        "displayName": "$jiraUserDisplayName",
        "active": true
    }
}
"@
            #endregion Definitions

            #region Mocks
            Mock Get-JiraIssue -ModuleName JiraPS {
                Write-MockDebugInfo 'Get-JiraIssue' 'Key'
                $result = [AtlassianPS.JiraPS.Issue]@{
                    ID      = $issueID
                    Key     = $issueKey
                    RestUrl = "$jiraServer/rest/api/2/issue/$issueID"
                }
                Write-Output $result
            }

            Mock Resolve-JiraIssueObject -ModuleName JiraPS {
                Write-MockDebugInfo 'Resolve-JiraIssueObject' 'InputObject'
                Get-JiraIssue -Key $InputObject.Key
            }

            Mock Invoke-JiraRequest -ModuleName JiraPS -ParameterFilter { $Method -eq 'POST' -and $URI -eq "$jiraServer/rest/api/2/issue/$issueID/worklog" } {
                Write-MockDebugInfo 'Invoke-JiraRequest' 'Method', 'Uri', 'Body'
                ConvertFrom-Json $restResponse
            }

            # Cloud equivalent: when Test-JiraCloudServer returns $true the
            # cmdlet hits the v3 endpoint (so the API accepts ADF). The
            # mocked response is the same — only the URI changes.
            Mock Invoke-JiraRequest -ModuleName JiraPS -ParameterFilter { $Method -eq 'POST' -and $URI -eq "$jiraServer/rest/api/3/issue/$issueID/worklog" } {
                Write-MockDebugInfo 'Invoke-JiraRequest' 'Method', 'Uri', 'Body'
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

        Describe "Behavior" {

            It "Adds a worklog item to an issue in JIRA" {
                $commentResult = Add-JiraIssueWorklog -Comment 'This is a test worklog entry from Pester.' -Issue $issueKey -TimeSpent 3600 -DateStarted "2018-01-01"
                $commentResult | Should -Not -BeNullOrEmpty

                # Get-JiraIssue should be used to identify the issue parameter
                Should -Invoke -CommandName Get-JiraIssue -ModuleName JiraPS -Exactly -Times 1

                # Invoke-JiraRequest should be used to add the comment
                Should -Invoke -CommandName Invoke-JiraRequest -ModuleName JiraPS -Exactly -Times 1
            }

            It "formats DateStarted independently of the input" {
                Add-JiraIssueWorklog -Comment 'This is a test worklog entry from Pester.' -Issue $issueKey -TimeSpent "00:10:00" -DateStarted "2018-01-01"
                Add-JiraIssueWorklog -Comment 'This is a test worklog entry from Pester.' -Issue $issueKey -TimeSpent "00:10:00" -DateStarted (Get-Date)
                Add-JiraIssueWorklog -Comment 'This is a test worklog entry from Pester.' -Issue $issueKey -TimeSpent "00:10:00" -DateStarted (Get-Date -Date "01.01.2000")

                Should -Invoke -CommandName Invoke-JiraRequest -ModuleName JiraPS -ParameterFilter {
                    $Body -match '"started":\s*"\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}.\d{3}[\+\-]\d{4}"'
                } -Exactly -Times 3
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
                    Add-JiraIssueWorklog -Issue $issueKey -Comment 'Visibility test' -TimeSpent '00:10:00' -DateStarted '2018-01-01' @parameters | Out-Null
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
                    Add-JiraIssueWorklog -Issue $issueKey -Comment 'Visibility test' -TimeSpent '00:10:00' -DateStarted '2018-01-01' -Visibility $value | Out-Null
                    Should -Invoke Invoke-JiraRequest -ModuleName JiraPS -Exactly -Times 1 -ParameterFilter {
                        $payload = $Body | ConvertFrom-Json
                        $payload.visibility.type -eq $expectedType -and
                        $payload.visibility.value -eq $expectedValue -and
                        $payload.visibility.PSObject.Properties.Name -notcontains 'identifier'
                    }
                }

                It "sends a Cloud group identifier without inventing a name" {
                    Mock Test-JiraCloudServer -ModuleName JiraPS { $true }
                    Add-JiraIssueWorklog -Issue $issueKey -Comment 'Visibility test' -TimeSpent '00:10:00' -DateStarted '2018-01-01' -Visibility @{
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
                    { Add-JiraIssueWorklog -Issue $issueKey -Comment 'Visibility test' -TimeSpent '00:10:00' -DateStarted '2018-01-01' -Visibility $value -ErrorAction Stop } |
                        Should -Throw -ExceptionType ([System.Management.Automation.ParameterBindingException])
                    Should -Invoke Resolve-JiraIssueObject -ModuleName JiraPS -Exactly -Times 0
                    Should -Invoke Invoke-JiraRequest -ModuleName JiraPS -Exactly -Times 0
                }
            }

            Context "Cloud vs Data Center comment shape" {
                It "sends a plain-string comment on Server / Data Center" {
                    Mock Test-JiraCloudServer -ModuleName JiraPS { return $false }

                    Add-JiraIssueWorklog -Comment 'Spent on *fix*' -Issue $issueKey -TimeSpent "00:10:00" -DateStarted "2018-01-01" | Out-Null

                    Should -Invoke 'Invoke-JiraRequest' -ModuleName JiraPS -ParameterFilter {
                        $payload = $Body | ConvertFrom-Json
                        $payload.comment -is [string] -and $payload.comment -eq 'Spent on *fix*'
                    }
                }

                It "wraps the comment in an Atlassian Document Format document on Cloud" {
                    Mock Test-JiraCloudServer -ModuleName JiraPS { return $true }

                    Add-JiraIssueWorklog -Comment 'Spent on the fix' -Issue $issueKey -TimeSpent "00:10:00" -DateStarted "2018-01-01" | Out-Null

                    Should -Invoke 'Invoke-JiraRequest' -ModuleName JiraPS -ParameterFilter {
                        $payload = $Body | ConvertFrom-Json
                        $payload.comment.type -eq 'doc' -and
                        $payload.comment.version -eq 1 -and
                        $payload.comment.content[0].type -eq 'paragraph' -and
                        $payload.comment.content[0].content[0].text -eq 'Spent on the fix'
                    }
                }

                It "targets the v3 worklog endpoint on Cloud" {
                    Mock Test-JiraCloudServer -ModuleName JiraPS { return $true }

                    Add-JiraIssueWorklog -Comment 'Spent on the fix' -Issue $issueKey -TimeSpent "00:10:00" -DateStarted "2018-01-01" | Out-Null

                    Should -Invoke 'Invoke-JiraRequest' -ModuleName JiraPS -ParameterFilter {
                        $Method -eq 'POST' -and $URI -eq "$jiraServer/rest/api/3/issue/$issueID/worklog"
                    }
                }

                It "targets the v2 worklog endpoint on Server / DC" {
                    Mock Test-JiraCloudServer -ModuleName JiraPS { return $false }

                    Add-JiraIssueWorklog -Comment 'Spent on the fix' -Issue $issueKey -TimeSpent "00:10:00" -DateStarted "2018-01-01" | Out-Null

                    Should -Invoke 'Invoke-JiraRequest' -ModuleName JiraPS -ParameterFilter {
                        $Method -eq 'POST' -and $URI -eq "$jiraServer/rest/api/2/issue/$issueID/worklog"
                    }
                }
            }
        }

        Describe "Input Validation" {
            Context "Type Validation - Positive Cases" {
                It "Accepts pipeline input from Get-JiraIssue" {
                    $commentResult = Get-JiraIssue -Key $IssueKey | Add-JiraIssueWorklog -Comment 'This is a test worklog item from Pester, using the pipeline!' -TimeSpent "3600" -DateStarted "2018-01-01"
                    $commentResult | Should -Not -BeNullOrEmpty

                    # Get-JiraIssue should be called once here to fetch the initial test issue
                    Should -Invoke -CommandName Get-JiraIssue -ModuleName JiraPS -Exactly -Times 2
                    Should -Invoke -CommandName Invoke-JiraRequest -ModuleName JiraPS -Exactly -Times 1
                }
            }

        }
    }
}
