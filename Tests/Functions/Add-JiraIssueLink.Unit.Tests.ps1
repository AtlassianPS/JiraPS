#requires -modules @{ ModuleName = "Pester"; ModuleVersion = "5.7"; MaximumVersion = "5.999" }

BeforeDiscovery {
    $script:ThisTest = "Add-JiraIssueLink"

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

            $issueKey = "TEST-01"
            $issueLink = [PSCustomObject]@{
                outwardIssue = [PSCustomObject]@{key = "TEST-10" }
                type         = [PSCustomObject]@{name = "Composition" }
            }

            Mock Get-JiraConfigServer -ModuleName JiraPS {
                Write-Output $jiraServer
            }

            Mock Get-JiraIssue -ParameterFilter { $Key -eq $issueKey } {
                $object = [PSCustomObject]@{
                    Key = $issueKey
                }
                $object.PSObject.TypeNames.Insert(0, 'JiraPS.Issue')
                return $object
            }

            Mock Resolve-JiraIssueObject -ModuleName JiraPS {
                Get-JiraIssue -Key $Issue
            }

            # Generic catch-all. This will throw an exception if we forgot to mock something.
            Mock Invoke-JiraMethod -ModuleName JiraPS {
                ShowMockInfo 'Invoke-JiraMethod' 'Method', 'Uri'
                throw "Unidentified call to Invoke-JiraMethod"
            }

            Mock Invoke-JiraMethod -ParameterFilter { $Method -eq 'POST' -and $URI -eq "$jiraServer/rest/api/2/issueLink" } {
                ShowMockInfo 'Invoke-JiraMethod' 'Method', 'Uri'
                return $true
            }
        }

        Describe "Signature" {
            BeforeAll {
                $script:command = Get-Command -Name $ThisTest
            }

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

            It "parameter '<parameter>' has a default value of '<defaultValue>'" -TestCases @(
                @{ parameter = "Credential"; defaultValue = "[System.Management.Automation.PSCredential]::Empty" }
            ) {
                $command | Should -HaveParameter $parameter -DefaultValue $defaultValue
            }

            It "parameter '<parameter>' is mandatory" -TestCases @(
                @{ parameter = "Issue" }
                @{ parameter = "IssueLink" }
            ) {
                $command | Should -HaveParameter $parameter -Mandatory
            }
        }

        Describe "Behaviour" {
            It 'Adds a new IssueLink' {
                { Add-JiraIssueLink -Issue $issueKey -IssueLink $issueLink } | Should -Not -Throw

                Assert-MockCalled -CommandName Invoke-JiraMethod -ModuleName JiraPS -Exactly -Times 1 -Scope It
            }

            It 'Validates the IssueType provided' {
                $issueLink = [PSCustomObject]@{ type = "foo" }
                { Add-JiraIssueLink -Issue $issueKey -IssueLink $issueLink } | Should -Throw
            }

            It 'Validates pipeline input object' {
                { "foo" | Add-JiraIssueLink -IssueLink $issueLink } | Should -Throw
            }
        }
    }
}
