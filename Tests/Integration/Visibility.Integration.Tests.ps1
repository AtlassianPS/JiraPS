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
    Describe 'Comment and worklog visibility' -Tag 'Integration', 'Server', 'Cloud' -Skip:$Skip {
        BeforeAll {
            . "$PSScriptRoot/../Helpers/IntegrationTestTools.ps1"
            $script:environment = Initialize-IntegrationEnvironment
            $script:session = Connect-JiraTestServer -Environment $environment
            $script:fixtures = Get-TestFixture -Environment $environment
            foreach ($required in 'TestProject') {
                if ([string]::IsNullOrWhiteSpace($fixtures[$required])) {
                    throw "Visibility integration tests require fixture '$required'."
                }
            }
            $script:apiRoot = '/rest/api/' + $(if ($fixtures.IsCloud) { '3' } else { '2' })
            $script:issue = $null
            $script:role = $null
            $script:group = $null
            $script:issue = New-TemporaryTestIssue -Fixtures $fixtures -Summary (New-TestResourceName -Type 'VisibilityIssue')
            $project = Get-JiraProject -Project $fixtures.TestProject -ErrorAction Stop
            $currentUser = Invoke-JiraMethod -URI "$apiRoot/myself" -ErrorAction Stop
            $name = 'jiraps-visibility-' + [guid]::NewGuid().ToString('N')
            $script:group = New-JiraGroup -GroupName $name -ErrorAction Stop
            $null = Add-JiraGroupMember -Group $group -UserName (ConvertTo-JiraUser -InputObject $currentUser) -ErrorAction Stop
            $script:role = Invoke-JiraMethod -URI "$apiRoot/role" -Method Post -Body (@{
                    name        = $name
                    description = 'Temporary role for JiraPS visibility integration tests'
                } | ConvertTo-Json) -ErrorAction Stop
            $user = if ($fixtures.IsCloud) { $currentUser.accountId } else { $currentUser.name }
            $null = Invoke-JiraMethod -URI "$apiRoot/project/$($project.Id)/role/$($role.id)" -Method Post -Body (@{
                    user = @($user)
                } | ConvertTo-Json) -ErrorAction Stop
        }

        AfterAll {
            try {
                if ($issue -and $issue.Key) {
                    Remove-JiraIssue -IssueId $issue.Key -Force -ErrorAction Stop
                }
            }
            finally {
                try {
                    if ($role) {
                        $null = Invoke-JiraMethod -URI "$apiRoot/role/$($role.id)" -Method Delete -ErrorAction Stop
                    }
                }
                finally {
                    try {
                        if ($group) { Remove-JiraGroup -Group $group -Force -ErrorAction Stop }
                    }
                    finally {
                        Remove-JiraSession -ErrorAction SilentlyContinue
                    }
                }
            }
        }

        It 'persists an unrestricted <resource>' -TestCases @(
            @{ resource = 'comment' }
            @{ resource = 'worklog' }
        ) {
            $parameters = @{ Issue = $issue; Comment = "Unrestricted $resource"; ErrorAction = 'Stop' }
            if ($resource -eq 'worklog') {
                $parameters.TimeSpent = [TimeSpan]::FromMinutes(1)
                $parameters.DateStarted = Get-Date
                $created = Add-JiraIssueWorklog @parameters
            }
            else { $created = Add-JiraIssueComment @parameters }
            $created.Id | Should -Not -BeNullOrEmpty
            $persisted = Invoke-JiraMethod -URI "$apiRoot/issue/$($issue.Key)/$resource/$($created.Id)" -ErrorAction Stop
            $persisted.visibility | Should -BeNullOrEmpty
        }

        It 'persists a <restriction> restriction on a <resource>' -TestCases @(
            foreach ($resource in 'comment', 'worklog') {
                @{ resource = $resource; restriction = 'role' }
                @{ resource = $resource; restriction = 'group' }
            }
        ) {
            $value = if ($restriction -eq 'role') { $role.name } else { $group.Name }
            $parameters = @{
                Issue       = $issue
                Comment     = "Restricted $resource"
                Visibility  = [AtlassianPS.JiraPS.Visibility]@{
                    Type  = $restriction
                    Value = $value
                }
                ErrorAction = 'Stop'
            }
            if ($resource -eq 'worklog') {
                $parameters.TimeSpent = [TimeSpan]::FromMinutes(1)
                $parameters.DateStarted = Get-Date
                $created = Add-JiraIssueWorklog @parameters
            }
            else { $created = Add-JiraIssueComment @parameters }
            $created.Visibility.Type | Should -Be $restriction
            $created.Visibility.Value | Should -Be $value
            $persisted = Invoke-JiraMethod -URI "$apiRoot/issue/$($issue.Key)/$resource/$($created.Id)" -ErrorAction Stop
            $persisted.visibility.type | Should -Be $restriction
            $persisted.visibility.value | Should -Be $value
        }

        It 'persists a Cloud group identifier restriction on a <resource>' -TestCases @(
            @{ resource = 'comment' }
            @{ resource = 'worklog' }
        ) {
            if (-not $fixtures.IsCloud) {
                Set-ItResult -Skipped -Because 'Data Center visibility uses group names'
                return
            }
            $group.Id | Should -Not -BeNullOrEmpty
            $parameters = @{
                Issue       = $issue
                Comment     = "Group identifier $resource"
                Visibility  = @{
                    Type       = 'group'
                    Identifier = $group.Id
                }
                ErrorAction = 'Stop'
            }
            if ($resource -eq 'worklog') {
                $parameters.TimeSpent = [TimeSpan]::FromMinutes(1)
                $parameters.DateStarted = Get-Date
                $created = Add-JiraIssueWorklog @parameters
            }
            else { $created = Add-JiraIssueComment @parameters }
            $persisted = Invoke-JiraMethod -URI "$apiRoot/issue/$($issue.Key)/$resource/$($created.Id)" -ErrorAction Stop
            $persisted.visibility.type | Should -Be 'group'
            $persisted.visibility.identifier | Should -Be $group.Id
        }
    }
}
