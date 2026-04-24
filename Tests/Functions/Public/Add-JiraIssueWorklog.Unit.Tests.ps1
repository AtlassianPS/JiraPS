#requires -modules @{ ModuleName = "Pester"; ModuleVersion = "5.7"; MaximumVersion = "5.999" }

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
            Mock Get-JiraConfigServer -ModuleName JiraPS {
                Write-MockDebugInfo 'Get-JiraConfigServer'
                Write-Output $jiraServer
            }

            Mock Get-JiraIssue -ModuleName JiraPS {
                Write-MockDebugInfo 'Get-JiraIssue' 'Key'
                $result = [PSCustomObject] @{
                    ID      = $issueID
                    Key     = $issueKey
                    RestUrl = "$jiraServer/rest/api/2/issue/$issueID"
                }
                $result.PSObject.TypeNames.Insert(0, 'JiraPS.Issue')
                Write-Output $result
            }

            Mock Resolve-JiraIssueObject -ModuleName JiraPS {
                Write-MockDebugInfo 'Resolve-JiraIssueObject' 'Issue'
                Get-JiraIssue -Key $Issue
            }

            Mock Invoke-JiraMethod -ModuleName JiraPS -ParameterFilter { $Method -eq 'POST' -and $URI -eq "$jiraServer/rest/api/2/issue/$issueID/worklog" } {
                Write-MockDebugInfo 'Invoke-JiraMethod' 'Method', 'Uri', 'Body'
                ConvertFrom-Json $restResponse
            }

            # Generic catch-all. This will throw an exception if we forgot to mock something.
            Mock Invoke-JiraMethod -ModuleName JiraPS {
                Write-MockDebugInfo 'Invoke-JiraMethod' 'Method', 'Uri'
                throw "Unidentified call to Invoke-JiraMethod"
            }
            #endregion Mocks
        }

        Describe "Signature" {
            BeforeAll {
                $script:command = Get-Command -Name "Add-JiraIssueWorklog"
            }

            Context "Parameter Types" {
                It "has a parameter '<parameter>' of type '<type>'" -TestCases @(
                    @{ parameter = "Comment"; type = "String" }
                    @{ parameter = "Issue"; type = "Object" }
                    @{ parameter = "TimeSpent"; type = "TimeSpan" }
                    @{ parameter = "DateStarted"; type = "DateTime" }
                    @{ parameter = "VisibleRole"; type = "String" }
                    @{ parameter = "Credential"; type = "System.Management.Automation.PSCredential" }
                ) {
                    $command | Should -HaveParameter $parameter

                    #ToDo:CustomClass
                    # can't use -Type as long we are using `PSObject.TypeNames.Insert(0, 'JiraPS.Filter')`
                    (Get-Member -InputObject $command.Parameters.Item($parameter)).Attributes | Should -Contain $typeName
                }
            }

            Context "Default Values" {
                It "parameter '<parameter>' has a default value of '<defaultValue>'" -TestCases @(
                    @{ parameter = "VisibleRole"; defaultValue = "All Users" }
                    @{ parameter = "Credential"; defaultValue = "[System.Management.Automation.PSCredential]::Empty" }
                ) {
                    $command | Should -HaveParameter $parameter -DefaultValue $defaultValue
                }
            }

            Context "Mandatory Parameters" {
                It "parameter '<parameter>' is mandatory" -TestCases @(
                    @{ parameter = "Comment" }
                    @{ parameter = "Issue" }
                    @{ parameter = "TimeSpent" }
                    @{ parameter = "DateStarted" }
                ) {
                    $command | Should -HaveParameter $parameter -Mandatory
                }
            }
        }

        Describe "Behavior" {

            It "Adds a worklog item to an issue in JIRA" {
                $commentResult = Add-JiraIssueWorklog -Comment 'This is a test worklog entry from Pester.' -Issue $issueKey -TimeSpent 3600 -DateStarted "2018-01-01"
                $commentResult | Should -Not -BeNullOrEmpty

                # Get-JiraIssue should be used to identify the issue parameter
                Should -Invoke -CommandName Get-JiraIssue -ModuleName JiraPS -Exactly -Times 1

                # Invoke-JiraMethod should be used to add the comment
                Should -Invoke -CommandName Invoke-JiraMethod -ModuleName JiraPS -Exactly -Times 1
            }

            It "formats DateStarted independently of the input" {
                Add-JiraIssueWorklog -Comment 'This is a test worklog entry from Pester.' -Issue $issueKey -TimeSpent "00:10:00" -DateStarted "2018-01-01"
                Add-JiraIssueWorklog -Comment 'This is a test worklog entry from Pester.' -Issue $issueKey -TimeSpent "00:10:00" -DateStarted (Get-Date)
                Add-JiraIssueWorklog -Comment 'This is a test worklog entry from Pester.' -Issue $issueKey -TimeSpent "00:10:00" -DateStarted (Get-Date -Date "01.01.2000")

                Should -Invoke -CommandName Invoke-JiraMethod -ModuleName JiraPS -ParameterFilter {
                    $Body -match '"started":\s*"\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}.\d{3}[\+\-]\d{4}"'
                } -Exactly -Times 3
            }
        }

        Describe "Input Validation" {
            Context "Type Validation - Positive Cases" {
                It "Accepts pipeline input from Get-JiraIssue" {
                    $commentResult = Get-JiraIssue -Key $IssueKey | Add-JiraIssueWorklog -Comment 'This is a test worklog item from Pester, using the pipeline!' -TimeSpent "3600" -DateStarted "2018-01-01"
                    $commentResult | Should -Not -BeNullOrEmpty

                    # Get-JiraIssue should be called once here to fetch the initial test issue
                    Should -Invoke -CommandName Get-JiraIssue -ModuleName JiraPS -Exactly -Times 2
                    Should -Invoke -CommandName Invoke-JiraMethod -ModuleName JiraPS -Exactly -Times 1
                }
            }

            Context "Type Validation - Negative Cases" {}
        }

        Describe "Cloud-deployment warning for wiki-markup tables" {
            # Wiki-markup tables (`||header||`) render as literal text on Jira Cloud
            # REST v3 endpoints. Add-JiraIssueWorklog detects this content shape and
            # warns when the active session is connected to Cloud, so users get
            # actionable feedback at the actual point of harm (the API call) rather
            # than at the upstream ConvertTo-JiraTable step.
            BeforeAll {
                $script:wikiTable = "||A||B||$([Environment]::NewLine)|1|2|"
                $script:plainComment = 'Plain text worklog with no wiki markup.'
            }

            Context "Cloud session" {
                BeforeAll {
                    Mock Test-JiraCloudServer -ModuleName JiraPS { $true }
                }

                It "Warns when -Comment contains wiki-markup table syntax" {
                    Add-JiraIssueWorklog -Comment $wikiTable -Issue $issueKey -TimeSpent "3600" -DateStarted "2018-01-01" -WarningVariable warn -WarningAction SilentlyContinue | Out-Null

                    $warn | Should -Not -BeNullOrEmpty
                    ($warn -join ' ') | Should -Match 'Jira Cloud'
                    ($warn -join ' ') | Should -Match 'wiki-markup'
                    ($warn -join ' ') | Should -Match 'ADF|Atlassian Document Format'
                }

                It "Does not warn when -Comment is plain text" {
                    Add-JiraIssueWorklog -Comment $plainComment -Issue $issueKey -TimeSpent "3600" -DateStarted "2018-01-01" -WarningVariable warn -WarningAction SilentlyContinue | Out-Null

                    $warn | Should -BeNullOrEmpty
                }

                It "Does not warn for ambiguous '||' patterns (e.g. boolean operators)" {
                    Add-JiraIssueWorklog -Comment 'A comparison: a || b || c, see code.' -Issue $issueKey -TimeSpent "3600" -DateStarted "2018-01-01" -WarningVariable warn -WarningAction SilentlyContinue | Out-Null

                    $warn | Should -BeNullOrEmpty
                }

                It "Honors -WarningAction SilentlyContinue (warning stream is silent)" {
                    # PowerShell's -WarningVariable still captures warnings even when
                    # -WarningAction is SilentlyContinue, so verify the user-visible
                    # contract directly: the warning STREAM (3) is empty.
                    $output = Add-JiraIssueWorklog -Comment $wikiTable -Issue $issueKey -TimeSpent "3600" -DateStarted "2018-01-01" -WarningAction SilentlyContinue 3>&1

                    @($output | Where-Object { $_ -is [System.Management.Automation.WarningRecord] }).Count |
                        Should -Be 0
                }

                It "Posts the worklog regardless of the warning" {
                    $result = Add-JiraIssueWorklog -Comment $wikiTable -Issue $issueKey -TimeSpent "3600" -DateStarted "2018-01-01" -WarningAction SilentlyContinue

                    $result | Should -Not -BeNullOrEmpty
                    Should -Invoke 'Invoke-JiraMethod' -ModuleName JiraPS -ParameterFilter {
                        $Method -eq 'POST' -and $URI -eq "$jiraServer/rest/api/2/issue/$issueID/worklog"
                    } -Times 1
                }
            }

            Context "Data Center / Server session" {
                BeforeAll {
                    Mock Test-JiraCloudServer -ModuleName JiraPS { $false }
                }

                It "Does not warn even with wiki-markup table syntax" {
                    Add-JiraIssueWorklog -Comment $wikiTable -Issue $issueKey -TimeSpent "3600" -DateStarted "2018-01-01" -WarningVariable warn -WarningAction SilentlyContinue | Out-Null

                    $warn | Should -BeNullOrEmpty
                }
            }

            Context "No session / unknown deployment" {
                BeforeAll {
                    # Simulate the offline case: Test-JiraCloudServer fails because
                    # Get-JiraConfigServer has no value. The cmdlet must not throw
                    # in its content-detection path even when the lookup is impossible.
                    Mock Test-JiraCloudServer -ModuleName JiraPS { throw 'No JiraConfigServer set' }
                }

                It "Does not throw and does not emit a Cloud warning" {
                    { Add-JiraIssueWorklog -Comment $wikiTable -Issue $issueKey -TimeSpent "3600" -DateStarted "2018-01-01" -WarningVariable warn -WarningAction SilentlyContinue | Out-Null } |
                        Should -Not -Throw

                    Add-JiraIssueWorklog -Comment $wikiTable -Issue $issueKey -TimeSpent "3600" -DateStarted "2018-01-01" -WarningVariable warn -WarningAction SilentlyContinue | Out-Null
                    $warn | Should -BeNullOrEmpty
                }
            }
        }
    }
}
