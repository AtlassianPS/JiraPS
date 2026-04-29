#requires -modules @{ ModuleName = "Pester"; ModuleVersion = "5.7"; MaximumVersion = "5.999" }

BeforeDiscovery {
    . "$PSScriptRoot/../../Helpers/TestTools.ps1"

    $script:moduleToTest = Initialize-TestEnvironment
}

InModuleScope JiraPS {
    Describe "Resolve-JiraGroupPayload" -Tag 'Unit' {
        Context "Canonical group payloads" {
            It "preserves the canonical group response shape" {
                $inputObject = [PSCustomObject]@{
                    groupId = 'group-id'
                    name    = 'jira-users'
                    self    = 'https://jira.example.com/rest/api/2/group?groupname=jira-users'
                    users   = [PSCustomObject]@{
                        size  = 3
                        items = @([PSCustomObject]@{ name = 'user-1' })
                    }
                }

                $result = Resolve-JiraGroupPayload -InputObject $inputObject -RequestedGroupName 'ignored-name'

                $result.groupId | Should -Be 'group-id'
                $result.name | Should -Be 'jira-users'
                $result.self | Should -Be 'https://jira.example.com/rest/api/2/group?groupname=jira-users'
                $result.users.size | Should -Be 3
                $result.users.items | Should -HaveCount 1
            }
        }

        Context "Server group member payloads" {
            It "maps groupName and total into the canonical shape" {
                $inputObject = [PSCustomObject]@{
                    id        = 'dc-group-id'
                    groupName = 'jira-software-users'
                    total     = 2
                    users     = [PSCustomObject]@{
                        items = @([PSCustomObject]@{ name = 'user-1' }, [PSCustomObject]@{ name = 'user-2' })
                    }
                }

                $result = Resolve-JiraGroupPayload -InputObject $inputObject

                $result.groupId | Should -Be 'dc-group-id'
                $result.name | Should -Be 'jira-software-users'
                $result.users.size | Should -Be 2
                $result.users.items | Should -HaveCount 2
            }

            It "falls back to the requested group name when the payload has no canonical name" {
                $inputObject = [PSCustomObject]@{
                    total = 0
                    users = [PSCustomObject]@{
                        items = @()
                    }
                }

                $result = Resolve-JiraGroupPayload -InputObject $inputObject -RequestedGroupName 'fallback-group'

                $result.name | Should -Be 'fallback-group'
                $result.users.size | Should -Be 0
                @($result.users.items) | Should -HaveCount 0
            }
        }

        Context "Pipeline support" {
            It "accepts pipeline input" {
                $inputObject = [PSCustomObject]@{
                    groupId = 'group-id'
                    name    = 'jira-users'
                }

                $result = $inputObject | Resolve-JiraGroupPayload

                $result.name | Should -Be 'jira-users'
            }
        }
    }
}
