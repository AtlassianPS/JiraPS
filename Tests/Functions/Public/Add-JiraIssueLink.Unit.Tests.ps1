#requires -modules @{ ModuleName = "Pester"; ModuleVersion = "5.7"; MaximumVersion = "5.999" }

BeforeDiscovery {
    . "$PSScriptRoot/../../Helpers/TestTools.ps1"

    Initialize-TestEnvironment
    $script:moduleToTest = Resolve-ModuleSource

    Import-Module $script:moduleToTest -Force -ErrorAction Stop
}

InModuleScope JiraPS {
    Describe "Add-JiraIssueLink" -Tag 'Unit' {
        BeforeAll {
            . "$PSScriptRoot/../../Helpers/TestTools.ps1" -Force

            #region Definitions
            $jiraServer = 'http://jiraserver.example.com'

            $script:issueKey = "TEST-01"
            $script:issueLink = [PSCustomObject]@{
                outwardIssue = [PSCustomObject]@{key = "TEST-10" }
                type         = [PSCustomObject]@{name = "Composition" }
            }
            #endregion Definitions

            #region Mocks
            Mock Get-JiraConfigServer -ModuleName JiraPS {
                Write-MockDebugInfo 'Get-JiraConfigServer'
                Write-Output $jiraServer
            }

            Mock Get-JiraIssue -ModuleName JiraPS -ParameterFilter { $Key -eq $issueKey } {
                Write-MockDebugInfo 'Get-JiraIssue' 'Key'
                $object = [PSCustomObject]@{
                    Key = $issueKey
                }
                $object.PSObject.TypeNames.Insert(0, 'JiraPS.Issue')
                return $object
            }

            Mock Resolve-JiraIssueObject -ModuleName JiraPS {
                Write-MockDebugInfo 'Resolve-JiraIssueObject' 'Issue'
                if ($Issue -eq "foo") {
                    throw "Invalid Issue"
                }
                Get-JiraIssue -Key $Issue
            }

            Mock Invoke-JiraMethod -ModuleName JiraPS -ParameterFilter {
                $Method -eq 'POST' -and
                $URI -eq "$jiraServer/rest/api/2/issueLink"
            } {
                Write-MockDebugInfo 'Invoke-JiraMethod' 'Method', 'Uri', 'Body'
                return $true
            }

            # Generic catch-all. This will throw an exception if we forgot to mock something.
            Mock Invoke-JiraMethod -ModuleName JiraPS {
                Write-MockDebugInfo 'Invoke-JiraMethod' 'Method', 'Uri', 'Body'
                throw "Unidentified call to Invoke-JiraMethod"
            }
            #endregion Mocks
        }

        Describe "Signature" {
            BeforeAll {
                $script:command = Get-Command -Name "Add-JiraIssueLink"
            }

            Context "Parameter Types" {
                It "has a parameter '<parameter>' of type '<type>'" -TestCases @(
                    @{ parameter = "Issue"; type = "Object[]" }
                    @{ parameter = "IssueLink"; type = "Object[]" }
                    @{ parameter = "Comment"; type = "String" }
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
                    @{ parameter = "Credential"; defaultValue = "[System.Management.Automation.PSCredential]::Empty" }
                ) {
                    $command | Should -HaveParameter $parameter -DefaultValue $defaultValue
                }
            }

            Context "Mandatory Parameters" {
                It "parameter '<parameter>' is mandatory" -TestCases @(
                    @{ parameter = "Issue" }
                    @{ parameter = "IssueLink" }
                ) {
                    $command | Should -HaveParameter $parameter -Mandatory
                }
            }
        }

        Describe "Behavior" {
            It 'Adds a new IssueLink' {
                { Add-JiraIssueLink -Issue $issueKey -IssueLink $issueLink } | Should -Not -Throw

                Should -Invoke -CommandName Invoke-JiraMethod -ModuleName JiraPS -Exactly -Times 1 -Scope It
            }
        }

        Describe "Input Validation" {
            Context "Type Validation - Positive Cases" { }

            Context "Type Validation - Negative Cases" {
                It 'pipeline input must be JiraPS.Issue or String' {
                    { (Get-Date) | Add-JiraIssueLink -IssueLink $issueLink -ErrorAction SilentlyContinue } | Should -Throw -ErrorId 'ParameterType.NotJiraIssue,Add-JiraIssueLink'
                }

                It "requires a specific object type for -IssueLink" {
                    $string = "invalid-object"
                    $incompleteObject = [PSCustomObject]@{ type = "foo" }

                    { Add-JiraIssueLink -Issue $issueKey -IssueLink $string } | Should -Throw -ErrorId 'ParameterProperties.Incomplete,Add-JiraIssueLink'
                    { Add-JiraIssueLink -Issue $issueKey -IssueLink $incompleteObject } | Should -Throw -ErrorId 'ParameterProperties.Incomplete,Add-JiraIssueLink'
                }
            }
        }
    }
}
