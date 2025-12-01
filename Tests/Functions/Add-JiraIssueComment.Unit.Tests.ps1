#requires -modules @{ ModuleName = "Pester"; ModuleVersion = "5.7"; MaximumVersion = "5.999" }

BeforeDiscovery {
    $script:ThisTest = "Add-JiraIssueComment"

    . "$PSScriptRoot/../Helpers/Resolve-ModuleSource.ps1"
    $script:moduleToTest = Resolve-ModuleSource

    $dependentModules = Get-Module | Where-Object { $_.RequiredModules.Name -eq 'JiraPS' }
    $dependentModules, "JiraPS" | Remove-Module -Force -ErrorAction SilentlyContinue
    Import-Module $moduleToTest -Force -ErrorAction Stop
}

InModuleScope JiraPS {
    Describe "$ThisTest" -Tag 'Unit' {
        BeforeAll {
            . "$PSScriptRoot/../Helpers/Shared.ps1"

            $jiraServer = 'http://jiraserver.example.com'
            $issueID = 41701
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

            Mock Get-JiraConfigServer {
                Write-Output $jiraServer
            }

            Mock Get-JiraIssue {
                $object = [PSCustomObject] @{
                    ID      = $issueID
                    Key     = $issueKey
                    RestUrl = "$jiraServer/rest/api/2/issue/$issueID"
                }
                $object.PSObject.TypeNames.Insert(0, 'JiraPS.Issue')
                return $object
            }

            Mock Resolve-JiraIssueObject -ModuleName JiraPS {
                Get-JiraIssue -Key $Issue
            }

            Mock Invoke-JiraMethod -ParameterFilter { $Method -eq 'POST' -and $URI -eq "$jiraServer/rest/api/2/issue/$issueID/comment" } {
                ShowMockInfo 'Invoke-JiraMethod' 'Method', 'Uri'
                ConvertFrom-Json $restResponse
            }

            # Generic catch-all. This will throw an exception if we forgot to mock something.
            Mock Invoke-JiraMethod {
                ShowMockInfo 'Invoke-JiraMethod' 'Method', 'Uri'
                throw "Unidentified call to Invoke-JiraMethod"
            }
        }

        Describe "Signature" {
            BeforeAll {
                $script:command = Get-Command -Name $ThisTest
            }

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

            It "parameter '<parameter>' has a default value of '<defaultValue>'" -TestCases @(
                @{ parameter = "VisibleRole"; defaultValue = "All Users" }
                @{ parameter = "Credential"; defaultValue = "[System.Management.Automation.PSCredential]::Empty" }
            ) {
                $command | Should -HaveParameter $parameter -DefaultValue $defaultValue
            }

            It "parameter '<parameter>' is mandatory" -TestCases @(
                @{ parameter = "Comment" }
                @{ parameter = "Issue" }
            ) {
                $command | Should -HaveParameter $parameter -Mandatory
            }
        }

        Describe "Behaviour" {
            It "Adds a comment to an issue in JIRA" {
                $commentResult = Add-JiraIssueComment -Comment 'This is a test comment from Pester.' -Issue $issueKey
                $commentResult | Should -Not -BeNullOrEmpty

                Assert-MockCalled 'Get-JiraIssue' -ModuleName JiraPS -Exactly -Times 1 -Scope It
                Assert-MockCalled 'Resolve-JiraIssueObject' -ModuleName JiraPS -Exactly -Times 1 -Scope It
                Assert-MockCalled 'Invoke-JiraMethod' -ModuleName JiraPS -Exactly -Times 1 -Scope It
            }

            It "Accepts pipeline input from Get-JiraIssue" {
                $commentResult = Get-JiraIssue -Key $IssueKey | Add-JiraIssueComment -Comment 'This is a test comment from Pester, using the pipeline!'
                $commentResult | Should -Not -BeNullOrEmpty

                Assert-MockCalled 'Get-JiraIssue' -ModuleName JiraPS -Exactly -Times 2 -Scope It
                Assert-MockCalled 'Resolve-JiraIssueObject' -ModuleName JiraPS -Exactly -Times 1 -Scope It
                Assert-MockCalled 'Invoke-JiraMethod' -ModuleName JiraPS -Exactly -Times 1 -Scope It
            }
        }

        Describe "Output checking" {
            BeforeAll {
                Mock ConvertTo-JiraComment {}
            }

            It "Uses ConvertTo-JiraComment to beautify output" {
                Add-JiraIssueComment -Comment 'This is a test comment from Pester.' -Issue $issueKey | Out-Null

                Assert-MockCalled 'ConvertTo-JiraComment'
            }
        }
    }
}
