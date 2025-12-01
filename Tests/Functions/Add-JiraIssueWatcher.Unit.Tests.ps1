#requires -modules @{ ModuleName = "Pester"; ModuleVersion = "5.7"; MaximumVersion = "5.999" }

BeforeDiscovery {
    $script:ThisTest = "Add-JiraIssueWatcher"

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
            $issueKey = 'IT-3676'

            Mock Get-JiraConfigServer -ModuleName JiraPS {
                Write-Output $jiraServer
            }

            Mock Get-JiraIssue -ModuleName JiraPS {
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

            Mock Invoke-JiraMethod -ModuleName JiraPS -ParameterFilter { $Method -eq 'POST' -and $URI -eq "$jiraServer/rest/api/2/issue/$issueID/watchers" } {
                ShowMockInfo 'Invoke-JiraMethod' -Params 'Uri', 'Method'
            }

            # Generic catch-all. This will throw an exception if we forgot to mock something.
            Mock Invoke-JiraMethod -ModuleName JiraPS {
                ShowMockInfo 'Invoke-JiraMethod' -Params 'Uri', 'Method'
                throw "Unidentified call to Invoke-JiraMethod"
            }
        }

        Describe "Signature" {
            BeforeAll {
                $script:command = Get-Command -Name $ThisTest
            }

            It "has a parameter '<parameter>' of type '<type>'" -TestCases @(
                @{ parameter = "Watcher"; type = "String[]" }
                @{ parameter = "Issue"; type = "Object" }
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
                @{ parameter = "Watcher" }
                @{ parameter = "Issue" }
            ) {
                $command | Should -HaveParameter $parameter -Mandatory
            }
        }

        Describe "Behavior testing" {
            It "Adds a Watcher to an issue in JIRA" {
                $WatcherResult = Add-JiraIssueWatcher -Watcher 'fred' -Issue $issueKey
                $WatcherResult | Should -BeNullOrEmpty

                # Get-JiraIssue should be used to identify the issue parameter
                Assert-MockCalled -CommandName Get-JiraIssue -ModuleName JiraPS -Exactly -Times 1 -Scope It

                # Invoke-JiraMethod should be used to add the Watcher
                Assert-MockCalled -CommandName Invoke-JiraMethod -ModuleName JiraPS -Exactly -Times 1 -Scope It
            }

            It "Accepts pipeline input from Get-JiraIssue" {
                $WatcherResult = Get-JiraIssue -Key $issueKey | Add-JiraIssueWatcher -Watcher 'fred'
                $WatcherResult | Should -BeNullOrEmpty

                # Get-JiraIssue should be called once here, and once inside Add-JiraIssueWatcher (to identify the InputObject parameter)
                Assert-MockCalled -CommandName Get-JiraIssue -ModuleName JiraPS -Exactly -Times 2 -Scope It
                Assert-MockCalled -CommandName Invoke-JiraMethod -ModuleName JiraPS -Exactly -Times 1 -Scope It
            }
        }
    }
}
