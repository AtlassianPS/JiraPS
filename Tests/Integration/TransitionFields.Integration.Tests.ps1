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
    Describe 'Transition screen fields' -Tag 'Integration', 'Server', 'Cloud' -Skip:$Skip {
        BeforeAll {
            . "$PSScriptRoot/../Helpers/IntegrationTestTools.ps1"
            $script:environment = Initialize-IntegrationEnvironment
            $script:session = Connect-JiraTestServer -Environment $environment
            $script:fixtures = Get-TestFixture -Environment $environment
            $script:createdIssues = [System.Collections.Generic.List[string]]::new()
            foreach ($required in 'TestProject', 'TestUser') {
                if ([string]::IsNullOrWhiteSpace($fixtures[$required])) {
                    throw "Transition field integration tests require fixture '$required'."
                }
            }
            $script:apiRoot = '/rest/api/' + $(if ($fixtures.IsCloud) { '3' } else { '2' })
            $configuration = Invoke-JiraMethod -URI "$apiRoot/configuration" -ErrorAction Stop
            if (-not $configuration.timeTrackingEnabled -or -not $configuration.unassignedIssuesAllowed) {
                throw 'Transition field integration tests require time tracking and unassigned issues on the dedicated test site.'
            }
            $script:user = Get-JiraUser -InputObject $fixtures.TestUser -ErrorAction Stop
            $script:identity = $fixtures.UserIdProperty
            $user.$identity | Should -Not -BeNullOrEmpty
        }

        BeforeEach {
            $script:issue = New-TemporaryTestIssue -Fixtures $fixtures -Summary (New-TestResourceName -Type 'TransitionFields')
            $createdIssues.Add($issue.Key)
            $metadata = Invoke-JiraMethod -URI "$apiRoot/issue/$($issue.Key)/transitions" -GetParameter @{ expand = 'transitions.fields' } -ErrorAction Stop
            $compatible = @(foreach ($candidate in $metadata.transitions) {
                    if (-not $candidate.hasScreen) { continue }
                    $fieldIds = @($candidate.fields.PSObject.Properties.Name)
                    if (@(@('summary', 'description', 'assignee', 'worklog') | Where-Object { $_ -notin $fieldIds }).Count) { continue }
                    if ('set' -notin $candidate.fields.summary.operations -or
                        'set' -notin $candidate.fields.description.operations -or
                        'set' -notin $candidate.fields.assignee.operations -or
                        'add' -notin $candidate.fields.worklog.operations) { continue }
                    if ($candidate.fields.assignee.required -or $candidate.fields.worklog.required -or $candidate.fields.comment.required) { continue }
                    if ($candidate.fields.resolution.required -and
                        ('set' -notin $candidate.fields.resolution.operations -or
                        @($candidate.fields.resolution.allowedValues | Where-Object id).Count -eq 0)) { continue }
                    $unexpectedRequired = @($candidate.fields.PSObject.Properties | Where-Object {
                            $_.Value.required -and -not $_.Value.hasDefaultValue -and
                            $_.Name -notin @('summary', 'description', 'assignee', 'worklog', 'comment', 'resolution')
                        })
                    if ($unexpectedRequired.Count -eq 0) { $candidate }
                })
            if ($compatible.Count -eq 0) {
                throw "No available transition in project '$($fixtures.TestProject)' exposes Summary, Description, Assignee and Log Work without extra required fields. Configure the dedicated fixture workflow as documented in Tests/Integration/README.md."
            }
            $script:transition = $compatible[0]
            $script:transitionFields = @{}
            if ($transition.fields.resolution.required) {
                $resolution = $transition.fields.resolution.allowedValues | Where-Object id | Select-Object -First 1
                $transitionFields.resolution = @{ id = $resolution.id }
            }
        }

        AfterAll {
            try {
                foreach ($key in $createdIssues) { Remove-JiraIssue -IssueId $key -Force -ErrorAction Stop }
            }
            finally {
                Remove-JiraSession -ErrorAction SilentlyContinue
            }
        }

        It 'persists fields, assignment, a comment and a worklog on a screened transition' {
            Set-JiraIssue -Issue $issue.Key -Unassign -ErrorAction Stop
            (Get-JiraIssue -Key $issue.Key -ErrorAction Stop).Assignee | Should -BeNullOrEmpty
            @(Get-JiraIssueComment -Issue $issue.Key -ErrorAction Stop).Count | Should -Be 0
            @(Get-JiraIssueWorklog -Issue $issue.Key -ErrorAction Stop).Count | Should -Be 0
            $summary = New-TestResourceName -Type 'TransitionUpdated'
            $description = "Transition description $([guid]::NewGuid())"
            $comment = "Transition comment $([guid]::NewGuid())"

            $fields = $transitionFields.Clone()
            $fields.Summary = $summary
            $fields.Description = $description
            Invoke-JiraIssueTransition -Issue $issue.Key -Transition $transition.id -Assignee $user -Fields $fields -Comment $comment -TimeSpent ([TimeSpan]::FromMinutes(1)) -ErrorAction Stop

            $deadline = (Get-Date).AddSeconds(10)
            do {
                $persisted = Get-JiraIssue -Key $issue.Key -ErrorAction Stop
                $comments = @(Get-JiraIssueComment -Issue $issue.Key -ErrorAction Stop)
                $worklogs = @(Get-JiraIssueWorklog -Issue $issue.Key -ErrorAction Stop)
                if ($persisted.Summary -eq $summary -and $persisted.Description -eq $description -and
                    $persisted.Assignee.$identity -eq $user.$identity -and $persisted.Status.Id -eq $transition.to.id -and
                    $comments.Count -eq 1 -and $worklogs.Count -eq 1) { break }
                Start-Sleep -Milliseconds 500
            } while ((Get-Date) -lt $deadline)

            $persisted.Summary | Should -Be $summary
            $persisted.Description | Should -Be $description
            $persisted.Assignee.$identity | Should -Be $user.$identity
            $persisted.Status.Id | Should -Be $transition.to.id
            $comments.Count | Should -Be 1
            $comments[0].Body | Should -Be $comment
            $worklogs.Count | Should -Be 1
            $worklogs[0].TimeSpentSeconds | Should -Be 60

            $raw = Invoke-JiraMethod -URI "$apiRoot/issue/$($issue.Key)" -GetParameter @{ fields = 'description' } -ErrorAction Stop
            if ($fixtures.IsCloud) { $raw.fields.description.type | Should -Be 'doc' }
            else { $raw.fields.description | Should -Be $description }
        }

        It 'persists unassignment on a screened transition' {
            Set-JiraIssue -Issue $issue.Key -Assignee $user -ErrorAction Stop
            (Get-JiraIssue -Key $issue.Key -ErrorAction Stop).Assignee.$identity | Should -Be $user.$identity

            Invoke-JiraIssueTransition -Issue $issue.Key -Transition $transition.id -Unassign -Fields $transitionFields -ErrorAction Stop

            $deadline = (Get-Date).AddSeconds(10)
            do {
                $persisted = Get-JiraIssue -Key $issue.Key -ErrorAction Stop
                if (-not $persisted.Assignee -and $persisted.Status.Id -eq $transition.to.id) { break }
                Start-Sleep -Milliseconds 500
            } while ((Get-Date) -lt $deadline)

            $persisted.Assignee | Should -BeNullOrEmpty
            $persisted.Status.Id | Should -Be $transition.to.id
        }
    }
}
