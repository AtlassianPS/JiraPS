#requires -modules @{ ModuleName = "Pester"; ModuleVersion = "5.7"; MaximumVersion = "5.999" }

BeforeDiscovery {
    . "$PSScriptRoot/../../Helpers/TestTools.ps1"

    Initialize-TestEnvironment
    $script:moduleToTest = Resolve-ModuleSource

    Import-Module $script:moduleToTest -Force -ErrorAction Stop
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
                Should -Invoke -CommandName Get-JiraIssue -ModuleName JiraPS -Exactly -Times 1 -Scope It

                # Invoke-JiraMethod should be used to add the comment
                Should -Invoke -CommandName Invoke-JiraMethod -ModuleName JiraPS -Exactly -Times 1 -Scope It
            }

            It "formats DateStarted independetly of the input" {
                Add-JiraIssueWorklog -Comment 'This is a test worklog entry from Pester.' -Issue $issueKey -TimeSpent "00:10:00" -DateStarted "2018-01-01"
                Add-JiraIssueWorklog -Comment 'This is a test worklog entry from Pester.' -Issue $issueKey -TimeSpent "00:10:00" -DateStarted (Get-Date)
                Add-JiraIssueWorklog -Comment 'This is a test worklog entry from Pester.' -Issue $issueKey -TimeSpent "00:10:00" -DateStarted (Get-Date -Date "01.01.2000")

                Should -Invoke -CommandName Invoke-JiraMethod -ModuleName JiraPS -ParameterFilter {
                    $Body -match '"started":\s*"\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}.\d{3}[\+\-]\d{4}"'
                } -Exactly -Times 3 -Scope It
            }
        }

        Describe "Input Validation" {
            Context "Type Validation - Positive Cases" {
                It "Accepts pipeline input from Get-JiraIssue" {
                    $commentResult = Get-JiraIssue -Key $IssueKey | Add-JiraIssueWorklog -Comment 'This is a test worklog item from Pester, using the pipeline!' -TimeSpent "3600" -DateStarted "2018-01-01"
                    $commentResult | Should -Not -BeNullOrEmpty

                    # Get-JiraIssue should be called once here to fetch the initial test issue
                    Should -Invoke -CommandName Get-JiraIssue -ModuleName JiraPS -Exactly -Times 2 -Scope It
                    Should -Invoke -CommandName Invoke-JiraMethod -ModuleName JiraPS -Exactly -Times 1 -Scope It
                }
            }

            Context "Type Validation - Negative Cases" {}
        }
    }
}
