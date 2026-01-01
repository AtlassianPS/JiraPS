#requires -modules @{ ModuleName = "Pester"; ModuleVersion = "5.7"; MaximumVersion = "5.999" }

BeforeDiscovery {
    . "$PSScriptRoot/../../Helpers/TestTools.ps1"

    Initialize-TestEnvironment
    $script:moduleToTest = Resolve-ModuleSource

    Import-Module $script:moduleToTest -Force -ErrorAction Stop
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

                Should -Invoke 'Get-JiraIssue' -ModuleName JiraPS -Exactly -Times 1 -Scope It
                Should -Invoke 'Resolve-JiraIssueObject' -ModuleName JiraPS -Exactly -Times 1 -Scope It
                Should -Invoke 'Invoke-JiraMethod' -ModuleName JiraPS -Exactly -Times 1 -Scope It
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
    }
}
