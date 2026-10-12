#requires -modules @{ ModuleName = "Pester"; ModuleVersion = "6.2.0"; MaximumVersion = "6.999" }

BeforeDiscovery {
    . "$PSScriptRoot/../Helpers/TestTools.ps1"
    . "$PSScriptRoot/../Helpers/IntegrationTestTools.ps1"
    $script:moduleToTest = Initialize-TestEnvironment
    $script:Skip = Skip-IntegrationTest
    if (-not $Skip) {
        $environment = Initialize-IntegrationEnvironment
        $script:Skip = $environment.ReadOnly
    }
}

InModuleScope JiraPS {
    Describe 'Issue user identity' -Tag 'Integration', 'Server', 'Cloud' -Skip:$Skip {
        BeforeAll {
            . "$PSScriptRoot/../Helpers/IntegrationTestTools.ps1"
            $script:environment = Initialize-IntegrationEnvironment
            $script:session = Connect-JiraTestServer -Environment $environment
            $script:fixtures = Get-TestFixture -Environment $environment
            foreach ($required in 'TestProject', 'TestUser') {
                if ([string]::IsNullOrWhiteSpace($fixtures[$required])) {
                    throw "Issue identity integration tests require fixture '$required'."
                }
            }
            $script:issue = $null
            $script:project = Get-JiraProject -Project $fixtures.TestProject -ErrorAction Stop
            $identity = $fixtures.UserIdProperty
            if ($project.AssigneeType -ne [AtlassianPS.JiraPS.AssigneeType]::PROJECT_LEAD -or [string]::IsNullOrWhiteSpace($project.Lead.$identity)) {
                throw "Issue identity integration tests require TestProject '$($fixtures.TestProject)' to use Project lead as its default assignee and expose a non-empty lead $identity. Configure the dedicated fixture project's default assignee before running this suite."
            }
            $apiRoot = '/rest/api/' + $(if ($fixtures.IsCloud) { '3' } else { '2' })
            $configuration = Invoke-JiraMethod -URI "$apiRoot/configuration" -ErrorAction Stop
            if ($configuration.unassignedIssuesAllowed -ne $true) {
                throw 'Issue identity integration tests require Allow unassigned issues on the dedicated test site.'
            }
        }

        AfterAll {
            try {
                if ($issue -and $issue.Key) {
                    Remove-JiraIssue -IssueId $issue.Key -Force -ErrorAction Stop
                }
            }
            finally {
                Remove-JiraSession -ErrorAction SilentlyContinue
            }
        }

        It 'persists typed reporter and assignee through creation, unassignment, project default and reassignment' {
            $user = Get-JiraUser -InputObject $fixtures.TestUser -ErrorAction Stop
            $identity = $fixtures.UserIdProperty
            $user.$identity | Should -Not -BeNullOrEmpty
            $extras = Get-MinimumValidIssueParameter -Fixtures $fixtures -SkipFieldId @('reporter', 'assignee')
            $parameters = @{
                Project     = $fixtures.TestProject
                IssueType   = 'Task'
                Summary     = New-TestResourceName -Type 'IdentityIssue'
                Reporter    = $user
                Assignee    = $user
                ErrorAction = 'Stop'
            }
            if ($extras.Fields.Count -gt 0) { $parameters.Fields = $extras.Fields }
            $script:issue = New-JiraIssue @parameters
            $persisted = Get-JiraIssue -Key $issue.Key -ErrorAction Stop
            $persisted.Reporter.$identity | Should -Be $user.$identity
            $persisted.Assignee.$identity | Should -Be $user.$identity

            Set-JiraIssue -Issue $issue -Unassign -ErrorAction Stop
            (Get-JiraIssue -Key $issue.Key -ErrorAction Stop).Assignee | Should -BeNullOrEmpty

            Set-JiraIssue -Issue $issue -UseDefaultAssignee -ErrorAction Stop
            $persisted = Get-JiraIssue -Key $issue.Key -ErrorAction Stop
            $persisted.Assignee | Should -Not -BeNullOrEmpty
            $persisted.Assignee.$identity | Should -Be $project.Lead.$identity

            Set-JiraIssue -Issue $issue -Assignee $user -ErrorAction Stop
            $persisted = Get-JiraIssue -Key $issue.Key -ErrorAction Stop
            $persisted.Assignee.$identity | Should -Be $user.$identity
        }
    }
}
