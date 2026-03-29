#requires -modules @{ ModuleName = "Pester"; ModuleVersion = "5.7"; MaximumVersion = "5.999" }

BeforeDiscovery {
    . "$PSScriptRoot/../../Helpers/TestTools.ps1"

    Initialize-TestEnvironment
    $script:moduleToTest = Resolve-ModuleSource

    Import-Module $moduleToTest -Force -ErrorAction Stop
}

InModuleScope JiraPS {
    Describe "Invoke-JiraIssueTransition" -Tag 'Unit' {
        BeforeAll {
            . "$PSScriptRoot/../../Helpers/TestTools.ps1"
            # $VerbosePreference = 'Continue'  # Uncomment for mock debugging

            #region Definitions
            $script:jiraServer = 'http://jiraserver.example.com'
            $script:issueID = 41701
            $script:issueKey = 'IT-3676'
            #endregion Definitions

            #region Mocks
            Mock Get-JiraConfigServer -ModuleName JiraPS {
                Write-MockDebugInfo 'Get-JiraConfigServer'
                $jiraServer
            }

            Mock Get-JiraField -ModuleName JiraPS {
                Write-MockDebugInfo 'Get-JiraField' 'Field'
                $object = [PSCustomObject] @{
                    'Name' = $Field
                    'ID'   = $Field
                }
                $object.PSObject.TypeNames.Insert(0, 'JiraPS.Field')
                $object
            }

            Mock Get-JiraIssue -ModuleName JiraPS {
                Write-MockDebugInfo 'Get-JiraIssue' 'Key'
                $t1 = [PSCustomObject] @{
                    Name = 'Start Progress'
                    ID   = 11
                }
                $t1.PSObject.TypeNames.Insert(0, 'JiraPS.Transition')
                $t2 = [PSCustomObject] @{
                    Name = 'Resolve'
                    ID   = 81
                }
                $t2.PSObject.TypeNames.Insert(0, 'JiraPS.Transition')

                $object = [PSCustomObject] @{
                    ID         = $issueID
                    Key        = $issueKey
                    RestUrl    = "$jiraServer/rest/api/2/issue/$issueID"
                    Transition = @($t1, $t2)
                }
                $object.PSObject.TypeNames.Insert(0, 'JiraPS.Issue')
                $object
            }

            Mock Resolve-JiraIssueObject -ModuleName JiraPS {
                Write-MockDebugInfo 'Resolve-JiraIssueObject' 'Issue'
                Get-JiraIssue -Key $Issue
            }

            Mock Invoke-JiraMethod -ModuleName JiraPS -ParameterFilter {
                $Method -eq 'Post' -and
                $URI -eq "$jiraServer/rest/api/2/issue/$issueID/transitions"
            } {
                Write-MockDebugInfo 'Invoke-JiraMethod' 'Method', 'Uri', 'Body'
                # This should return a 204 status code, so no data should actually be returned
            }

            Mock Invoke-JiraMethod -ModuleName JiraPS {
                Write-MockDebugInfo 'Invoke-JiraMethod' 'Method', 'Uri'
                throw "Unidentified call to Invoke-JiraMethod: $Method $URI"
            }
            #endregion Mocks
        }

        Describe "Signature" {
            BeforeAll {
                $script:command = Get-Command -Name 'Invoke-JiraIssueTransition'
            }

            Context "Parameter Types" {
                It "has a parameter '<parameter>' of type '<type>'" -TestCases @(
                    @{ parameter = "Issue"; type = "JiraPS.Issue" }
                    @{ parameter = "Transition"; type = "Object" }
                    @{ parameter = "Comment"; type = "String" }
                    @{ parameter = "Assignee"; type = "String" }
                    @{ parameter = "Fields"; type = "Hashtable" }
                    @{ parameter = "Passthru"; type = "Switch" }
                    @{ parameter = "Credential"; type = "System.Management.Automation.PSCredential" }
                ) {
                    $command | Should -HaveParameter $parameter
                }
            }

            Context "Mandatory Parameters" {
                It "parameter '<parameter>' is mandatory" -TestCases @(
                    @{ parameter = "Issue" }
                    @{ parameter = "Transition" }
                ) {
                    $command | Should -HaveParameter $parameter -Mandatory
                }
            }
        }

        Describe "Behavior" {
            Context "Transition Execution" {
                It "performs a transition when given an issue key and transition ID" {
                    { Invoke-JiraIssueTransition -Issue $issueKey -Transition 11 } | Should -Not -Throw

                    Should -Invoke Get-JiraIssue -ModuleName JiraPS -Exactly -Times 1 -Scope It
                    Should -Invoke Invoke-JiraMethod -ModuleName JiraPS -Exactly -Times 1 -Scope It
                }

                It "performs a transition when given an issue object and transition object" {
                    $issue = Get-JiraIssue -Key $issueKey
                    $transition = $issue.Transition[0]
                    { Invoke-JiraIssueTransition -Issue $issue -Transition $transition } | Should -Not -Throw

                    # Get-JiraIssue called once in test setup, once in Invoke-JiraIssueTransition
                    Should -Invoke Get-JiraIssue -ModuleName JiraPS -Exactly -Times 2 -Scope It
                    Should -Invoke Invoke-JiraMethod -ModuleName JiraPS -Exactly -Times 1 -Scope It
                }
            }

            Context "Field Updates" {
                It "updates custom fields if provided to the -Fields parameter" {
                    {
                        $parameter = @{
                            Issue      = $issueKey
                            Transition = 11
                            Fields     = @{
                                'customfield_12345' = 'foo'
                                'customfield_67890' = 'bar'
                            }
                        }
                        Invoke-JiraIssueTransition @parameter
                    } | Should -Not -Throw

                    Should -Invoke Invoke-JiraMethod -ModuleName JiraPS -Times 1 -Scope It -ParameterFilter {
                        $Method -eq 'Post' -and
                        $URI -like "*/rest/api/2/issue/$issueID/transitions" -and
                        $Body -like '*customfield_12345*set*foo*'
                    }
                    Should -Invoke Invoke-JiraMethod -ModuleName JiraPS -Times 1 -Scope It -ParameterFilter {
                        $Method -eq 'Post' -and
                        $URI -like "*/rest/api/2/issue/$issueID/transitions" -and
                        $Body -like '*customfield_67890*set*bar*'
                    }
                }

                It "updates assignee name if provided to the -Assignee parameter" {
                    Mock Get-JiraUser -ModuleName JiraPS {
                        Write-MockDebugInfo 'Get-JiraUser' 'UserName'
                        [PSCustomObject] @{
                            'Name'    = 'powershell-user'
                            'RestUrl' = "$jiraServer/rest/api/2/user?username=powershell-user"
                        }
                    }
                    { Invoke-JiraIssueTransition -Issue $issueKey -Transition 11 -Assignee 'powershell-user' } | Should -Not -Throw

                    Should -Invoke Invoke-JiraMethod -ModuleName JiraPS -Times 1 -Scope It -ParameterFilter {
                        $Method -eq 'Post' -and
                        $URI -like "*/rest/api/2/issue/$issueID/transitions" -and
                        $Body -like '*name*powershell-user*'
                    }
                }

                It "unassigns an issue if 'Unassigned' is passed to the -Assignee parameter" {
                    { Invoke-JiraIssueTransition -Issue $issueKey -Transition 11 -Assignee 'Unassigned' } | Should -Not -Throw

                    Should -Invoke Invoke-JiraMethod -ModuleName JiraPS -Times 1 -Scope It -ParameterFilter {
                        $Method -eq 'Post' -and
                        $URI -like "*/rest/api/2/issue/$issueID/transitions" -and
                        $Body -like '*name*""*'
                    }
                }

                It "adds a comment if provided to the -Comment parameter" {
                    { Invoke-JiraIssueTransition -Issue $issueKey -Transition 11 -Comment 'test comment' } | Should -Not -Throw

                    Should -Invoke Invoke-JiraMethod -ModuleName JiraPS -Times 1 -Scope It -ParameterFilter {
                        $Method -eq 'Post' -and
                        $URI -like "*/rest/api/2/issue/$issueID/transitions" -and
                        $Body -like '*body*test comment*'
                    }
                }
            }

            Context "Output Behavior" {
                It "returns the Issue object when -Passthru is provided" {
                    { $null = Invoke-JiraIssueTransition -Issue $issueKey -Transition 11 -Passthru } | Should -Not -Throw
                    $result = Invoke-JiraIssueTransition -Issue $issueKey -Transition 11 -Passthru
                    $result | Should -Not -BeNullOrEmpty

                    Should -Invoke Get-JiraIssue -ModuleName JiraPS -Exactly -Times 4 -Scope It
                }

                It "does not return a value when -Passthru is omitted" {
                    { $null = Invoke-JiraIssueTransition -Issue $issueKey -Transition 11 } | Should -Not -Throw
                    $result = Invoke-JiraIssueTransition -Issue $issueKey -Transition 11
                    $result | Should -BeNullOrEmpty

                    Should -Invoke Get-JiraIssue -ModuleName JiraPS -Exactly -Times 2 -Scope It
                }
            }
        }

        Describe "Input Validation" {
            Context "Pipeline Support" {
                It "handles pipeline input from Get-JiraIssue" {
                    { Get-JiraIssue -Key $issueKey | Invoke-JiraIssueTransition -Transition 11 } | Should -Not -Throw

                    Should -Invoke Get-JiraIssue -ModuleName JiraPS -Exactly -Times 2 -Scope It
                    Should -Invoke Invoke-JiraMethod -ModuleName JiraPS -Exactly -Times 1 -Scope It
                }
            }
        }
    }
}
