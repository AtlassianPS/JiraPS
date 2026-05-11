#requires -modules @{ ModuleName = "Pester"; ModuleVersion = "5.7"; MaximumVersion = "5.999" }

BeforeDiscovery {
    . "$PSScriptRoot/../../Helpers/TestTools.ps1"

    $script:moduleToTest = Initialize-TestEnvironment
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
                $object = [AtlassianPS.JiraPS.Issue]@{
                    Key = $issueKey
                }
                return $object
            }

            Mock Resolve-JiraIssueObject -ModuleName JiraPS {
                Write-MockDebugInfo 'Resolve-JiraIssueObject' 'InputObject'
                if ($InputObject.Key -eq "foo") {
                    throw "Invalid Issue"
                }
                Get-JiraIssue -Key $InputObject.Key
            }

            Mock Invoke-JiraMethod -ModuleName JiraPS -ParameterFilter {
                $Method -eq 'POST' -and
                $URI -eq "/rest/api/2/issueLink"
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
                    @{ parameter = "Issue"; type = "AtlassianPS.JiraPS.Issue" }
                    @{ parameter = "IssueLink"; type = "AtlassianPS.JiraPS.IssueLinkCreateRequest[]" }
                    @{ parameter = "Comment"; type = "String" }
                    @{ parameter = "Credential"; type = "System.Management.Automation.PSCredential" }
                ) {
                    $command | Should -HaveParameter $parameter -Type $type
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

                Should -Invoke -CommandName Invoke-JiraMethod -ModuleName JiraPS -Exactly -Times 1
            }

            It "maps loose object payloads to key-based request JSON" {
                $linkPayload = [PSCustomObject]@{
                    outwardIssue = [PSCustomObject]@{ key = "TEST-10" }
                    type         = [PSCustomObject]@{ name = "Composition" }
                }

                Add-JiraIssueLink -Issue $issueKey -IssueLink $linkPayload

                Should -Invoke -CommandName Invoke-JiraMethod -ModuleName JiraPS -Exactly -Times 1 -ParameterFilter {
                    $parsed = $Body | ConvertFrom-Json
                    $parsed.type.name -eq "Composition" -and
                    $parsed.outwardIssue.key -eq "TEST-10" -and
                    -not $parsed.type.id -and
                    -not $parsed.outwardIssue.id
                }
            }

            It "maps id-based refs to id-based request JSON" {
                $linkPayload = [PSCustomObject]@{
                    outwardIssue = [PSCustomObject]@{ id = "10001" }
                    type         = [PSCustomObject]@{ id = "10000" }
                }

                Add-JiraIssueLink -Issue $issueKey -IssueLink $linkPayload

                Should -Invoke -CommandName Invoke-JiraMethod -ModuleName JiraPS -Exactly -Times 1 -ParameterFilter {
                    $parsed = $Body | ConvertFrom-Json
                    $parsed.type.id -eq "10000" -and
                    $parsed.outwardIssue.id -eq "10001" -and
                    -not $parsed.type.name -and
                    -not $parsed.outwardIssue.key
                }
            }
        }

        Describe "Input Validation" {
            Context "Type Validation - Positive Cases" { }

            Context "Type Validation - Negative Cases" {
                It 'pipeline input must be AtlassianPS.JiraPS.Issue or String' {
                    { (Get-Date) | Add-JiraIssueLink -IssueLink $issueLink -ErrorAction Stop } | Should -Throw -ExpectedMessage "*to AtlassianPS.JiraPS.Issue*"
                }

                It "requires a specific object type for -IssueLink" {
                    $string = "invalid-object"
                    $incompleteObject = [PSCustomObject]@{ type = "foo" }

                    { Add-JiraIssueLink -Issue $issueKey -IssueLink $string -ErrorAction Stop } | Should -Throw -ExpectedMessage "*Cannot convert a string to AtlassianPS.JiraPS.IssueLinkCreateRequest*"
                    { Add-JiraIssueLink -Issue $issueKey -IssueLink $incompleteObject } | Should -Throw -ErrorId 'ParameterProperties.Incomplete,Add-JiraIssueLink'
                }

                It "rejects malformed type objects in -IssueLink payload" {
                    $invalidTypeObject = [PSCustomObject]@{
                        outwardIssue = [PSCustomObject]@{ key = "TEST-10" }
                        type         = [PSCustomObject]@{ foo = "bar" }
                    }

                    { Add-JiraIssueLink -Issue $issueKey -IssueLink $invalidTypeObject -ErrorAction Stop } |
                        Should -Throw -ExpectedMessage "*IssueLinkCreateRequest property 'type' must include either a non-empty 'name' or 'id'.*"
                }

                It "rejects malformed inward/outward issue objects in -IssueLink payload" {
                    $invalidIssueObject = [PSCustomObject]@{
                        outwardIssue = [PSCustomObject]@{ foo = "bar" }
                        type         = [PSCustomObject]@{ name = "Composition" }
                    }

                    { Add-JiraIssueLink -Issue $issueKey -IssueLink $invalidIssueObject -ErrorAction Stop } |
                        Should -Throw -ExpectedMessage "*IssueLinkCreateRequest property 'outwardIssue' must include either a non-empty 'key' or 'id'.*"
                }
            }
        }
    }
}
