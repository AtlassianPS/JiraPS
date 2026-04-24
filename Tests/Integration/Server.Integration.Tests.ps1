#requires -modules @{ ModuleName = "Pester"; ModuleVersion = "5.7"; MaximumVersion = "5.999" }

<#
.SYNOPSIS
    Smoke test for the Jira Data Center (Server) integration test track.

.DESCRIPTION
    Proves the Server-track plumbing end-to-end: connectivity, Basic-auth session,
    DC-style user lookup by username, and a CRUD path against whatever project the
    bare `moveworkforward/atlas-run-standalone` image happens to provide.

    The bare image typically ships with no project, so the project-dependent CRUD
    test is allowed to skip with an explicit message. That is intentional - the
    smoke test's job is to prove the wiring works, not to gate every PR on a DC
    fixture project being present.

.NOTES
    Tagged 'Integration', 'Smoke', 'Server' - this IS the smoke test for the
    Server track and is what jira_server_ci.yml runs on every PR.
#>

[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingConvertToSecureStringWithPlainText', '', Justification = 'Integration tests against a local Docker container with known fixed credentials')]
param()

BeforeDiscovery {
    . "$PSScriptRoot/../Helpers/TestTools.ps1"
    . "$PSScriptRoot/../Helpers/IntegrationTestTools.ps1"

    $script:moduleToTest = Initialize-TestEnvironment

    $script:Skip = Skip-IntegrationTest
    if (-not $Skip) {
        $envDiscovery = Initialize-IntegrationEnvironment
        $script:SkipNotServer = $envDiscovery.IsCloud
    }
    else {
        $script:SkipNotServer = $true
    }
}

InModuleScope JiraPS {
    Describe "Server (Data Center) Smoke" -Tag 'Integration', 'Smoke', 'Server' -Skip:($Skip -or $SkipNotServer) {
        BeforeAll {
            . "$PSScriptRoot/../Helpers/IntegrationTestTools.ps1"

            $script:env = Initialize-IntegrationEnvironment
            $script:session = Connect-JiraTestServer -Environment $env
            $script:fixtures = Get-TestFixture -Environment $env

            $script:createdIssues = [System.Collections.ArrayList]::new()

            try {
                $script:hasFixtureProject = $null -ne (Get-JiraProject -Project $fixtures.TestProject -ErrorAction SilentlyContinue)
            }
            catch {
                $script:hasFixtureProject = $false
            }
        }

        AfterAll {
            if ($script:createdIssues -and $script:createdIssues.Count -gt 0) {
                foreach ($key in $script:createdIssues) {
                    try {
                        Remove-JiraIssue -IssueId $key -Force -ErrorAction SilentlyContinue
                    }
                    catch {
                        Write-Verbose "Cleanup: Failed to remove issue $key - $_"
                    }
                }
            }

            Remove-JiraSession -ErrorAction SilentlyContinue
        }

        Context "Connectivity" {
            It "reports deploymentType 'Server' from Get-JiraServerInformation" {
                $serverInfo = Get-JiraServerInformation
                $serverInfo | Should -Not -BeNullOrEmpty
                $serverInfo.DeploymentType | Should -Be 'Server'
            }

            It "exposes IsCloud=`$false on the env config" {
                $env.IsCloud | Should -BeFalse
                $env.UserIdProperty | Should -Be 'name'
            }
        }

        Context "Basic-auth session" {
            It "establishes a session via Connect-JiraTestServer" {
                $session | Should -Not -BeNullOrEmpty
                $session.PSObject.TypeNames[0] | Should -Be 'JiraPS.Session'
            }

            It "permits authenticated calls without explicit credentials" {
                $serverInfo = Get-JiraServerInformation
                $serverInfo | Should -Not -BeNullOrEmpty
            }
        }

        Context "Get-JiraUser by username (DC identity model)" {
            It "looks up the admin user by name" {
                $user = Get-JiraUser -UserName $env.Username
                $user | Should -Not -BeNullOrEmpty
                $user.Name | Should -Be $env.Username
            }
        }

        Context "Issue CRUD smoke" {
            It "creates and removes an issue in the fixture project" {
                if (-not $script:hasFixtureProject) {
                    Set-ItResult -Skipped -Because "No project '$($fixtures.TestProject)' exists in the freshly-booted Jira DC container; bootstrap a project in Wait-JiraServer.ps1 to enable CRUD smoke tests"
                    return
                }

                $summary = New-TestResourceName -Type 'ServerSmoke'
                $issue = New-JiraIssue -Project $fixtures.TestProject -IssueType 'Task' -Summary $summary
                $null = $script:createdIssues.Add($issue.Key)

                $issue | Should -Not -BeNullOrEmpty
                $issue.Key | Should -Match "^$($fixtures.TestProject)-\d+$"

                $fetched = Get-JiraIssue -Key $issue.Key
                $fetched.Summary | Should -Be $summary
            }
        }
    }
}
