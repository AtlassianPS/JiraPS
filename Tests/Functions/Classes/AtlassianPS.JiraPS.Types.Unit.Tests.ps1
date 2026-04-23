#requires -modules @{ ModuleName = "Pester"; ModuleVersion = "5.7"; MaximumVersion = "5.999" }

BeforeDiscovery {
    . "$PSScriptRoot/../../Helpers/TestTools.ps1"

    Initialize-TestEnvironment
    $script:moduleToTest = Resolve-ModuleSource

    Import-Module $script:moduleToTest -Force -ErrorAction Stop
}

InModuleScope JiraPS {
    Describe "AtlassianPS.JiraPS strong-typed POCO classes" -Tag 'Unit' {
        BeforeAll {
            . "$PSScriptRoot/../../Helpers/TestTools.ps1"

            $script:expectedTypes = @(
                'AtlassianPS.JiraPS.User'
                'AtlassianPS.JiraPS.Project'
                'AtlassianPS.JiraPS.Comment'
                'AtlassianPS.JiraPS.Issue'
                'AtlassianPS.JiraPS.Version'
                'AtlassianPS.JiraPS.Filter'
                'AtlassianPS.JiraPS.Session'
                'AtlassianPS.JiraPS.ServerInfo'
            )
        }

        Context "Type loading" {
            It "loads all eight in-scope types into the current AppDomain" {
                foreach ($typeName in $script:expectedTypes) {
                    ($typeName -as [Type]) | Should -Not -BeNullOrEmpty -Because "$typeName must be available after module import"
                }
            }
        }

        Context "Hashtable construction" {
            It "constructs an Issue from a hashtable literal" {
                $issue = [AtlassianPS.JiraPS.Issue]@{ Key = 'TEST-1'; Summary = 'hashtable init' }

                $issue.Key | Should -Be 'TEST-1'
                $issue.Summary | Should -Be 'hashtable init'
            }

            It "constructs a User from a hashtable literal" {
                $user = [AtlassianPS.JiraPS.User]@{ Name = 'jdoe'; DisplayName = 'John Doe'; Active = $true }

                $user.Name | Should -Be 'jdoe'
                $user.DisplayName | Should -Be 'John Doe'
                $user.Active | Should -BeTrue
            }
        }

        Context "ToString() overrides" {
            It "Issue formats as '[<Key>] <Summary>'" {
                $issue = [AtlassianPS.JiraPS.Issue]@{ Key = 'TEST-1'; Summary = 'my summary' }
                $issue.ToString() | Should -Be '[TEST-1] my summary'
            }

            It "User prefers Name, then DisplayName, then AccountId" {
                ([AtlassianPS.JiraPS.User]@{ Name = 'jdoe'; DisplayName = 'John' }).ToString() | Should -Be 'jdoe'
                ([AtlassianPS.JiraPS.User]@{ DisplayName = 'John' }).ToString() | Should -Be 'John'
                ([AtlassianPS.JiraPS.User]@{ AccountId = 'abc-123' }).ToString() | Should -Be 'abc-123'
                ([AtlassianPS.JiraPS.User]::new()).ToString() | Should -Be ''
            }

            It "Project returns Name" {
                ([AtlassianPS.JiraPS.Project]@{ Name = 'My Project' }).ToString() | Should -Be 'My Project'
            }

            It "Version returns Name" {
                ([AtlassianPS.JiraPS.Version]@{ Name = '1.0.0' }).ToString() | Should -Be '1.0.0'
            }

            It "Filter returns Name" {
                ([AtlassianPS.JiraPS.Filter]@{ Name = 'My Filter' }).ToString() | Should -Be 'My Filter'
            }

            It "Comment returns the body's string representation" {
                ([AtlassianPS.JiraPS.Comment]@{ Body = 'hello' }).ToString() | Should -Be 'hello'
                ([AtlassianPS.JiraPS.Comment]::new()).ToString() | Should -Be ''
            }

            It "ServerInfo formats as '[<DeploymentType>] <Version>'" {
                ([AtlassianPS.JiraPS.ServerInfo]@{ DeploymentType = 'Cloud'; Version = '1001.0.0' }).ToString() | Should -Be '[Cloud] 1001.0.0'
            }

            It "Session formats as 'JiraSession[JSessionID=<id>]'" {
                ([AtlassianPS.JiraPS.Session]@{ JSessionID = 'abc' }).ToString() | Should -Be 'JiraSession[JSessionID=abc]'
            }
        }

        Context "Cross-reference property typing (Windows PowerShell 5.1 hashtable-cast guard)" {
            # On Windows PowerShell 5.1, [Type]@{ Property = $value } throws
            # PSInvalidCastException when $value is a PSObject-wrapped instance
            # (which Add-LegacyTypeAlias produces) and the destination property
            # is typed as a sibling .NET class. PowerShell 7 silently unwraps,
            # so this regression class would slip through PS7-only CI.
            #
            # These assertions lock the cross-reference slots open so any future
            # tightening of e.g. Project.Lead to `User` triggers a test failure
            # on every platform, not just on PS5.1.

            It "keeps Project.Lead, Project.IssueTypes, and Project.Components as object" {
                [AtlassianPS.JiraPS.Project].GetProperty('Lead').PropertyType.FullName | Should -Be 'System.Object'
                [AtlassianPS.JiraPS.Project].GetProperty('IssueTypes').PropertyType.FullName | Should -Be 'System.Object'
                [AtlassianPS.JiraPS.Project].GetProperty('Components').PropertyType.FullName | Should -Be 'System.Object'
            }

            It "keeps Comment.Author and Comment.UpdateAuthor as object" {
                [AtlassianPS.JiraPS.Comment].GetProperty('Author').PropertyType.FullName | Should -Be 'System.Object'
                [AtlassianPS.JiraPS.Comment].GetProperty('UpdateAuthor').PropertyType.FullName | Should -Be 'System.Object'
            }

            It "keeps Issue.Project, Issue.Assignee, Issue.Creator, Issue.Reporter as object" {
                [AtlassianPS.JiraPS.Issue].GetProperty('Project').PropertyType.FullName | Should -Be 'System.Object'
                [AtlassianPS.JiraPS.Issue].GetProperty('Assignee').PropertyType.FullName | Should -Be 'System.Object'
                [AtlassianPS.JiraPS.Issue].GetProperty('Creator').PropertyType.FullName | Should -Be 'System.Object'
                [AtlassianPS.JiraPS.Issue].GetProperty('Reporter').PropertyType.FullName | Should -Be 'System.Object'
            }

            It "keeps Filter.Owner as object" {
                [AtlassianPS.JiraPS.Filter].GetProperty('Owner').PropertyType.FullName | Should -Be 'System.Object'
            }
        }

        Context "Add-LegacyTypeAlias" {
            It "inserts the legacy PSTypeName at index 0" {
                $strong = [AtlassianPS.JiraPS.Issue]@{ Key = 'TEST-1' }
                Add-LegacyTypeAlias -InputObject $strong -LegacyName 'JiraPS.Issue' | Out-Null

                $strong.PSObject.TypeNames[0] | Should -Be 'JiraPS.Issue'
                $strong.PSObject.TypeNames | Should -Contain 'AtlassianPS.JiraPS.Issue'
            }

            It "is idempotent across repeated invocations" {
                $strong = [AtlassianPS.JiraPS.User]@{ Name = 'jdoe' }
                1..3 | ForEach-Object { Add-LegacyTypeAlias -InputObject $strong -LegacyName 'JiraPS.User' | Out-Null }

                ($strong.PSObject.TypeNames | Where-Object { $_ -eq 'JiraPS.User' }).Count | Should -Be 1
            }

            It "passes the object through the pipeline" {
                $strong = [AtlassianPS.JiraPS.Project]@{ Name = 'Repro' }
                $piped = $strong | Add-LegacyTypeAlias -LegacyName 'JiraPS.Project'

                $piped | Should -Be $strong
                $piped.PSObject.TypeNames[0] | Should -Be 'JiraPS.Project'
            }

            It "no-ops on `$null without throwing" {
                { Add-LegacyTypeAlias -InputObject $null -LegacyName 'JiraPS.Issue' } | Should -Not -Throw
            }
        }
    }
}
