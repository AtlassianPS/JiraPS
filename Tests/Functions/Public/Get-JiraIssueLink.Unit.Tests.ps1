#requires -modules @{ ModuleName = "Pester"; ModuleVersion = "5.7"; MaximumVersion = "5.999" }

BeforeDiscovery {
    . "$PSScriptRoot/../../Helpers/TestTools.ps1"

    Initialize-TestEnvironment
    $script:moduleToTest = Resolve-ModuleSource

    Import-Module $script:moduleToTest -Force -ErrorAction Stop
}

InModuleScope JiraPS {
    Describe "Get-JiraIssueLink" -Tag 'Unit' {
        BeforeAll {
            . "$PSScriptRoot/../../Helpers/TestTools.ps1"
            # $VerbosePreference = 'Continue'  # Uncomment for mock debugging

            #region Definitions
            $script:jiraServer = 'http://jiraserver.example.com'
            $script:issueLinkId = 1234

            # We don't care about anything except for the id
            $script:resultsJson = @"
{
    "id": "$issueLinkId",
    "self": "",
    "type": {},
    "inwardIssue": {},
    "outwardIssue": {}
}
"@
            #endregion Definitions

            #region Mocks
            Mock Get-JiraConfigServer -ModuleName JiraPS {
                Write-MockDebugInfo 'Get-JiraConfigServer'
                Write-Output $jiraServer
            }

            # Generic catch-all. This will throw an exception if we forgot to mock something.
            Mock Invoke-JiraMethod -ModuleName JiraPS {
                Write-MockDebugInfo 'Invoke-JiraMethod' 'Method', 'Uri'
                throw "Unidentified call to Invoke-JiraMethod"
            }

            Mock Invoke-JiraMethod -ModuleName JiraPS -ParameterFilter { $Method -eq 'Get' -and $URI -eq "$jiraServer/rest/api/2/issueLink/1234" } {
                Write-MockDebugInfo 'Invoke-JiraMethod' 'Method', 'Uri'
                ConvertFrom-Json $resultsJson
            }

            Mock Get-JiraIssue -ModuleName JiraPS -ParameterFilter { $Key -eq "TEST-01" } {
                Write-MockDebugInfo 'Get-JiraIssue' 'Key'
                # We don't care about the content of any field except for the id
                $obj = [PSCustomObject]@{
                    "id"          = $issueLinkId
                    "type"        = "foo"
                    "inwardIssue" = "bar"
                }
                $obj.PSObject.TypeNames.Insert(0, 'JiraPS.IssueLink')
                return [PSCustomObject]@{
                    issueLinks = @(
                        $obj
                    )
                }
            }
            #endregion Mocks
        }

        Describe "Signature" {
            BeforeAll {
                $script:command = Get-Command -Name Get-JiraIssueLink
            }

            Context "Parameter Types" {
                It "has a parameter '<parameter>' of type '<type>'" -TestCases @(
                    @{ parameter = "Id"; type = "Int32[]" }
                    @{ parameter = "Credential"; type = "System.Management.Automation.PSCredential" }
                ) {
                    $command | Should -HaveParameter $parameter
                }
            }

            Context "Mandatory Parameters" {}

            Context "Default Values" {}
        }

        Describe "Behavior" {
            It "Returns details about specific issuelink" {
                $result = Get-JiraIssueLink -Id $issueLinkId
                $result | Should -Not -BeNullOrEmpty
                @($result) | Should -HaveCount 1
            }

            It "Provides the key of the project" {
                $result = Get-JiraIssueLink -Id $issueLinkId
                $result.Id | Should -Be $issueLinkId
            }

            It "Accepts input from pipeline" {
                $result = (Get-JiraIssue -Key TEST-01).issuelinks | Get-JiraIssueLink
                $result.Id | Should -Be $issueLinkId
            }

            It 'Fails if input from the pipeline is of the wrong type' {
                { [PSCustomObject]@{id = $issueLinkId } | Get-JiraIssueLink } | Should -Throw
            }
        }

        Describe "Input Validation" {
            Context "Type Validation - Positive Cases" {}

            Context "Type Validation - Negative Cases" {}
        }
    }
}
