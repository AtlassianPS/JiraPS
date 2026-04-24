#requires -modules @{ ModuleName = "Pester"; ModuleVersion = "5.7"; MaximumVersion = "5.999" }

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

            Mock Get-JiraIssue -ModuleName JiraPS {
                Write-MockDebugInfo 'Get-JiraIssue' 'Key'
                $object = [PSCustomObject] @{
                    ID      = $issueID
                    Key     = $issueKey
                    RestUrl = "$jiraServer/rest/api/2/issue/$issueID"
                }
                $object.PSObject.TypeNames.Insert(0, 'JiraPS.Issue')
                return $object
            }

            Mock Resolve-JiraIssueObject -ModuleName JiraPS {
                Write-MockDebugInfo 'Resolve-JiraIssueObject' 'Issue'
                Get-JiraIssue -Key $Issue
            }

            Mock Invoke-JiraMethod -ModuleName JiraPS -ParameterFilter { $Method -eq 'POST' -and $URI -eq "$jiraServer/rest/api/2/issue/$issueID/comment" } {
                Write-MockDebugInfo 'Invoke-JiraMethod' 'Method', 'Uri'
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
                $script:command = Get-Command -Name "Add-JiraIssueComment"
            }

            Context "Parameter Types" {
                It "has a parameter '<parameter>' of type '<type>'" -TestCases @(
                    @{ parameter = "Comment"; type = "String" }
                    @{ parameter = "Issue"; type = "Object" }
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
                ) {
                    $command | Should -HaveParameter $parameter -Mandatory
                }
            }
        }

        Describe "Behavior" {
            It "Adds a comment to an issue in JIRA" {
                $commentResult = Add-JiraIssueComment -Comment 'This is a test comment from Pester.' -Issue $issueKey
                $commentResult | Should -Not -BeNullOrEmpty

                Should -Invoke 'Get-JiraIssue' -ModuleName JiraPS -Exactly -Times 1
                Should -Invoke 'Resolve-JiraIssueObject' -ModuleName JiraPS -Exactly -Times 1
                Should -Invoke 'Invoke-JiraMethod' -ModuleName JiraPS -Exactly -Times 1
            }

            It "returns a Jira.Comment object" {
                Add-JiraIssueComment -Comment 'This is a test comment from Pester.' -Issue $issueKey | Out-Null

                Should -Invoke 'ConvertTo-JiraComment'
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

        Describe "Cloud-deployment warning for wiki-markup tables" {
            # Wiki-markup tables (`||header||`) render as literal text on Jira Cloud
            # REST v3 endpoints. Add-JiraIssueComment detects this content shape and
            # warns when the active session is connected to Cloud, so users get
            # actionable feedback at the actual point of harm (the API call) rather
            # than at the upstream ConvertTo-JiraTable step.
            BeforeAll {
                $script:wikiTable = "||A||B||$([Environment]::NewLine)|1|2|"
                $script:plainComment = 'Plain text comment with no wiki markup.'
            }

            Context "Cloud session" {
                BeforeAll {
                    Mock Test-JiraCloudServer -ModuleName JiraPS { $true }
                }

                It "Warns when -Comment contains wiki-markup table syntax" {
                    Add-JiraIssueComment -Comment $wikiTable -Issue $issueKey -WarningVariable warn -WarningAction SilentlyContinue | Out-Null

                    $warn | Should -Not -BeNullOrEmpty
                    ($warn -join ' ') | Should -Match 'Jira Cloud'
                    ($warn -join ' ') | Should -Match 'wiki-markup'
                    ($warn -join ' ') | Should -Match 'ADF|Atlassian Document Format'
                }

                It "Does not warn when -Comment is plain text" {
                    Add-JiraIssueComment -Comment $plainComment -Issue $issueKey -WarningVariable warn -WarningAction SilentlyContinue | Out-Null

                    $warn | Should -BeNullOrEmpty
                }

                It "Does not warn for ambiguous '||' patterns (e.g. boolean operators)" {
                    Add-JiraIssueComment -Comment 'A comparison: a || b || c, see code.' -Issue $issueKey -WarningVariable warn -WarningAction SilentlyContinue | Out-Null

                    $warn | Should -BeNullOrEmpty
                }

                It "Honors -WarningAction SilentlyContinue (warning stream is silent)" {
                    # PowerShell's -WarningVariable still captures warnings even when
                    # -WarningAction is SilentlyContinue, so verify the user-visible
                    # contract directly: the warning STREAM (3) is empty.
                    $output = Add-JiraIssueComment -Comment $wikiTable -Issue $issueKey -WarningAction SilentlyContinue 3>&1

                    @($output | Where-Object { $_ -is [System.Management.Automation.WarningRecord] }).Count |
                        Should -Be 0
                }

                It "Emits the warning only once per invocation, regardless of pipeline length" {
                    @('IT-1', 'IT-2', 'IT-3') | Add-JiraIssueComment -Comment $wikiTable -WarningVariable warn -WarningAction SilentlyContinue | Out-Null

                    @($warn).Count | Should -Be 1
                }

                It "Posts the comment regardless of the warning" {
                    $result = Add-JiraIssueComment -Comment $wikiTable -Issue $issueKey -WarningAction SilentlyContinue

                    $result | Should -Not -BeNullOrEmpty
                    Should -Invoke 'Invoke-JiraMethod' -ModuleName JiraPS -ParameterFilter {
                        $Method -eq 'POST' -and $URI -eq "$jiraServer/rest/api/2/issue/$issueID/comment"
                    } -Times 1
                }
            }

            Context "Data Center / Server session" {
                BeforeAll {
                    Mock Test-JiraCloudServer -ModuleName JiraPS { $false }
                }

                It "Does not warn even with wiki-markup table syntax" {
                    Add-JiraIssueComment -Comment $wikiTable -Issue $issueKey -WarningVariable warn -WarningAction SilentlyContinue | Out-Null

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
                    { Add-JiraIssueComment -Comment $wikiTable -Issue $issueKey -WarningVariable warn -WarningAction SilentlyContinue | Out-Null } |
                        Should -Not -Throw

                    Add-JiraIssueComment -Comment $wikiTable -Issue $issueKey -WarningVariable warn -WarningAction SilentlyContinue | Out-Null
                    $warn | Should -BeNullOrEmpty
                }
            }
        }
    }
}
