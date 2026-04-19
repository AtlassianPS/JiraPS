#requires -modules @{ ModuleName = "Pester"; ModuleVersion = "5.7"; MaximumVersion = "5.999" }

<#
.SYNOPSIS
    Integration tests for Issue Link cmdlets.

.DESCRIPTION
    Tests issue linking functionality against a live Jira Cloud instance.
    Covers:
    - Get-JiraIssueLinkType
    - Add-JiraIssueLink
    - Get-JiraIssueLink
    - Remove-JiraIssueLink

.NOTES
    Issue links connect two issues with a relationship type (e.g., "blocks", "relates to").
    Common link types in Jira Cloud:
    - Blocks / is blocked by
    - Clones / is cloned by
    - Duplicate / is duplicated by
    - Relates to / relates to
#>

BeforeDiscovery {
    . "$PSScriptRoot/../Helpers/TestTools.ps1"
    . "$PSScriptRoot/../Helpers/IntegrationTestTools.ps1"

    Initialize-TestEnvironment
    $script:moduleToTest = Resolve-ModuleSource

    Import-Module $script:moduleToTest -Force -ErrorAction Stop

    $script:Skip = Skip-IntegrationTest
    if (-not $Skip) {
        $testEnv = Initialize-IntegrationEnvironment
        $script:SkipWrite = $testEnv.ReadOnly
    }
}

InModuleScope JiraPS {
    Describe "Issue Links" -Tag 'Integration' -Skip:$Skip {
        BeforeAll {
            . "$PSScriptRoot/../Helpers/IntegrationTestTools.ps1"

            $script:env = Initialize-IntegrationEnvironment
            $script:session = Connect-JiraTestServer -Environment $env
            $script:fixtures = Get-TestFixture -Environment $env

            $script:createdIssues = [System.Collections.ArrayList]::new()

            Remove-StaleTestResource -Fixtures $fixtures
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

        Describe "Get-JiraIssueLinkType" {
            Context "Retrieving Link Types" {
                It "retrieves all issue link types" {
                    $linkTypes = Get-JiraIssueLinkType

                    $linkTypes | Should -Not -BeNullOrEmpty
                    $linkTypes.Count | Should -BeGreaterThan 0
                }

                It "link types have correct type name" {
                    $linkTypes = Get-JiraIssueLinkType

                    $linkTypes[0].PSObject.TypeNames[0] | Should -Be 'JiraPS.IssueLinkType'
                }

                It "link types have Id, Name, Inward, and Outward properties" {
                    $linkTypes = Get-JiraIssueLinkType

                    $linkTypes[0].Id | Should -Not -BeNullOrEmpty
                    $linkTypes[0].Name | Should -Not -BeNullOrEmpty
                    $linkTypes[0].InwardDescription | Should -Not -BeNullOrEmpty
                    $linkTypes[0].OutwardDescription | Should -Not -BeNullOrEmpty
                }

                It "retrieves a specific link type by ID" {
                    $allTypes = Get-JiraIssueLinkType
                    $firstType = $allTypes[0]

                    $specificType = Get-JiraIssueLinkType -LinkType $firstType.Id

                    $specificType | Should -Not -BeNullOrEmpty
                    $specificType.Id | Should -Be $firstType.Id
                }

                It "retrieves a specific link type by name" {
                    $allTypes = Get-JiraIssueLinkType
                    $firstName = $allTypes[0].Name

                    $specificType = Get-JiraIssueLinkType -LinkType $firstName

                    $specificType | Should -Not -BeNullOrEmpty
                    $specificType.Name | Should -Be $firstName
                }
            }
        }

        Describe "Add-JiraIssueLink" -Skip:$SkipWrite {
            BeforeAll {
                if ([string]::IsNullOrEmpty($fixtures.TestProject)) {
                    $script:sourceIssue = $null
                    $script:targetIssue = $null
                }
                else {
                    $summary1 = New-TestResourceName -Type "LinkSource"
                    $script:sourceIssue = New-JiraIssue -Project $fixtures.TestProject -IssueType 'Task' -Summary $summary1
                    if ($sourceIssue) {
                        $null = $script:createdIssues.Add($sourceIssue.Key)
                    }

                    $summary2 = New-TestResourceName -Type "LinkTarget"
                    $script:targetIssue = New-JiraIssue -Project $fixtures.TestProject -IssueType 'Task' -Summary $summary2
                    if ($targetIssue) {
                        $null = $script:createdIssues.Add($targetIssue.Key)
                    }
                }
            }

            Context "Creating Issue Links" {
                It "creates an issue link between two issues" {
                    if (-not $sourceIssue -or -not $targetIssue) {
                        Set-ItResult -Skipped -Because "JIRA_TEST_PROJECT not configured"
                        return
                    }

                    $linkTypes = Get-JiraIssueLinkType
                    $relatesType = $linkTypes | Where-Object { $_.Name -like '*Relates*' -or $_.Name -like '*relates*' } | Select-Object -First 1
                    if (-not $relatesType) {
                        $relatesType = $linkTypes[0]
                    }

                    $issueLink = [PSCustomObject]@{
                        type         = @{ name = $relatesType.Name }
                        outwardIssue = @{ key = $targetIssue.Key }
                    }

                    { Add-JiraIssueLink -Issue $sourceIssue.Key -IssueLink $issueLink } |
                        Should -Not -Throw
                }

                It "creates an issue link with inward direction" {
                    if (-not $sourceIssue -or -not $targetIssue) {
                        Set-ItResult -Skipped -Because "JIRA_TEST_PROJECT not configured"
                        return
                    }

                    $linkTypes = Get-JiraIssueLinkType
                    $blocksType = $linkTypes | Where-Object { $_.Name -like '*Block*' } | Select-Object -First 1
                    if (-not $blocksType) {
                        $blocksType = $linkTypes[0]
                    }

                    $issueLink = [PSCustomObject]@{
                        type        = @{ name = $blocksType.Name }
                        inwardIssue = @{ key = $targetIssue.Key }
                    }

                    { Add-JiraIssueLink -Issue $sourceIssue.Key -IssueLink $issueLink } |
                        Should -Not -Throw
                }

                It "created links appear on the issue" {
                    if (-not $sourceIssue) {
                        Set-ItResult -Skipped -Because "JIRA_TEST_PROJECT not configured"
                        return
                    }

                    $issue = Get-JiraIssue -Key $sourceIssue.Key
                    $issue.issueLinks | Should -Not -BeNullOrEmpty
                }

                It "accepts issue via pipeline" {
                    if (-not $sourceIssue -or -not $targetIssue) {
                        Set-ItResult -Skipped -Because "JIRA_TEST_PROJECT not configured"
                        return
                    }

                    $summary = New-TestResourceName -Type "LinkPipeline"
                    $pipelineIssue = New-JiraIssue -Project $fixtures.TestProject -IssueType 'Task' -Summary $summary
                    $null = $script:createdIssues.Add($pipelineIssue.Key)

                    $linkTypes = Get-JiraIssueLinkType
                    $issueLink = [PSCustomObject]@{
                        type         = @{ name = $linkTypes[0].Name }
                        outwardIssue = @{ key = $targetIssue.Key }
                    }

                    { $pipelineIssue | Add-JiraIssueLink -IssueLink $issueLink } |
                        Should -Not -Throw
                }
            }
        }

        Describe "Get-JiraIssueLink" -Skip:$SkipWrite {
            BeforeAll {
                if ([string]::IsNullOrEmpty($fixtures.TestProject)) {
                    $script:linkTestIssue = $null
                }
                else {
                    $summary1 = New-TestResourceName -Type "GetLinkSource"
                    $script:linkTestIssue = New-JiraIssue -Project $fixtures.TestProject -IssueType 'Task' -Summary $summary1
                    if ($linkTestIssue) {
                        $null = $script:createdIssues.Add($linkTestIssue.Key)
                    }

                    $summary2 = New-TestResourceName -Type "GetLinkTarget"
                    $script:linkTestTarget = New-JiraIssue -Project $fixtures.TestProject -IssueType 'Task' -Summary $summary2
                    if ($linkTestTarget) {
                        $null = $script:createdIssues.Add($linkTestTarget.Key)
                    }

                    if ($linkTestIssue -and $linkTestTarget) {
                        $linkTypes = Get-JiraIssueLinkType
                        $issueLink = [PSCustomObject]@{
                            type         = @{ name = $linkTypes[0].Name }
                            outwardIssue = @{ key = $linkTestTarget.Key }
                        }
                        Add-JiraIssueLink -Issue $linkTestIssue.Key -IssueLink $issueLink
                    }
                }
            }

            Context "Retrieving Issue Links" {
                It "retrieves an issue link by ID" {
                    if (-not $linkTestIssue) {
                        Set-ItResult -Skipped -Because "JIRA_TEST_PROJECT not configured"
                        return
                    }

                    $issue = Get-JiraIssue -Key $linkTestIssue.Key
                    if (-not $issue.issueLinks -or $issue.issueLinks.Count -eq 0) {
                        Set-ItResult -Skipped -Because "No issue links found on test issue"
                        return
                    }

                    $linkId = $issue.issueLinks[0].Id
                    $link = Get-JiraIssueLink -Id $linkId

                    $link | Should -Not -BeNullOrEmpty
                    $link.Id | Should -Be $linkId
                }

                It "link has correct type name" {
                    if (-not $linkTestIssue) {
                        Set-ItResult -Skipped -Because "JIRA_TEST_PROJECT not configured"
                        return
                    }

                    $issue = Get-JiraIssue -Key $linkTestIssue.Key
                    if (-not $issue.issueLinks -or $issue.issueLinks.Count -eq 0) {
                        Set-ItResult -Skipped -Because "No issue links found on test issue"
                        return
                    }

                    $linkId = $issue.issueLinks[0].Id
                    $link = Get-JiraIssueLink -Id $linkId

                    $link.PSObject.TypeNames[0] | Should -Be 'JiraPS.IssueLink'
                }

                It "link includes type information" {
                    if (-not $linkTestIssue) {
                        Set-ItResult -Skipped -Because "JIRA_TEST_PROJECT not configured"
                        return
                    }

                    $issue = Get-JiraIssue -Key $linkTestIssue.Key
                    if (-not $issue.issueLinks -or $issue.issueLinks.Count -eq 0) {
                        Set-ItResult -Skipped -Because "No issue links found on test issue"
                        return
                    }

                    $linkId = $issue.issueLinks[0].Id
                    $link = Get-JiraIssueLink -Id $linkId

                    $link.Type | Should -Not -BeNullOrEmpty
                }
            }
        }

        Describe "Remove-JiraIssueLink" -Skip:$SkipWrite {
            Context "Removing Issue Links" {
                It "removes an issue link" {
                    if ([string]::IsNullOrEmpty($fixtures.TestProject)) {
                        Set-ItResult -Skipped -Because "JIRA_TEST_PROJECT not configured"
                        return
                    }

                    $summary1 = New-TestResourceName -Type "RemoveLinkSource"
                    $removeSource = New-JiraIssue -Project $fixtures.TestProject -IssueType 'Task' -Summary $summary1
                    $null = $script:createdIssues.Add($removeSource.Key)

                    $summary2 = New-TestResourceName -Type "RemoveLinkTarget"
                    $removeTarget = New-JiraIssue -Project $fixtures.TestProject -IssueType 'Task' -Summary $summary2
                    $null = $script:createdIssues.Add($removeTarget.Key)

                    $linkTypes = Get-JiraIssueLinkType
                    $issueLink = [PSCustomObject]@{
                        type         = @{ name = $linkTypes[0].Name }
                        outwardIssue = @{ key = $removeTarget.Key }
                    }
                    Add-JiraIssueLink -Issue $removeSource.Key -IssueLink $issueLink

                    $issue = Get-JiraIssue -Key $removeSource.Key
                    $linkToRemove = $issue.issueLinks[0]

                    { Remove-JiraIssueLink -IssueLink $linkToRemove -Confirm:$false } |
                        Should -Not -Throw

                    $afterRemoval = Get-JiraIssue -Key $removeSource.Key
                    $afterRemoval.issueLinks | Should -BeNullOrEmpty
                }

                It "removes issue link via pipeline from issue object" {
                    if ([string]::IsNullOrEmpty($fixtures.TestProject)) {
                        Set-ItResult -Skipped -Because "JIRA_TEST_PROJECT not configured"
                        return
                    }

                    $summary1 = New-TestResourceName -Type "RemovePipeSource"
                    $pipeSource = New-JiraIssue -Project $fixtures.TestProject -IssueType 'Task' -Summary $summary1
                    $null = $script:createdIssues.Add($pipeSource.Key)

                    $summary2 = New-TestResourceName -Type "RemovePipeTarget"
                    $pipeTarget = New-JiraIssue -Project $fixtures.TestProject -IssueType 'Task' -Summary $summary2
                    $null = $script:createdIssues.Add($pipeTarget.Key)

                    $linkTypes = Get-JiraIssueLinkType
                    $issueLink = [PSCustomObject]@{
                        type         = @{ name = $linkTypes[0].Name }
                        outwardIssue = @{ key = $pipeTarget.Key }
                    }
                    Add-JiraIssueLink -Issue $pipeSource.Key -IssueLink $issueLink

                    $issue = Get-JiraIssue -Key $pipeSource.Key

                    { $issue | Remove-JiraIssueLink -Confirm:$false } |
                        Should -Not -Throw

                    $afterRemoval = Get-JiraIssue -Key $pipeSource.Key
                    $afterRemoval.issueLinks | Should -BeNullOrEmpty
                }
            }
        }

        Context "Error Handling" {
            It "Get-JiraIssueLinkType fails for invalid link type ID" {
                { Get-JiraIssueLinkType -LinkType 99999 -ErrorAction Stop } |
                    Should -Throw
            }

            It "Get-JiraIssueLink fails for invalid link ID" {
                { Get-JiraIssueLink -Id 99999999 -ErrorAction Stop } |
                    Should -Throw
            }
        }
    }
}
