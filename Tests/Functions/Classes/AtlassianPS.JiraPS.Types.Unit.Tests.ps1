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

        Context "Strong cross-reference slot typing" {
            # These assertions lock in the slot type for every cross-reference
            # so a future loosening (e.g. Project.Lead going back to System.Object)
            # is caught immediately. Strong slots are what give us IntelliSense
            # and parse-time errors when the wrong thing is assigned.

            It "Project.Lead is AtlassianPS.JiraPS.User" {
                [AtlassianPS.JiraPS.Project].GetProperty('Lead').PropertyType.FullName | Should -Be 'AtlassianPS.JiraPS.User'
            }

            It "Comment.Author and Comment.UpdateAuthor are AtlassianPS.JiraPS.User" {
                [AtlassianPS.JiraPS.Comment].GetProperty('Author').PropertyType.FullName | Should -Be 'AtlassianPS.JiraPS.User'
                [AtlassianPS.JiraPS.Comment].GetProperty('UpdateAuthor').PropertyType.FullName | Should -Be 'AtlassianPS.JiraPS.User'
            }

            It "Issue.Project is AtlassianPS.JiraPS.Project" {
                [AtlassianPS.JiraPS.Issue].GetProperty('Project').PropertyType.FullName | Should -Be 'AtlassianPS.JiraPS.Project'
            }

            It "Filter.Owner is AtlassianPS.JiraPS.User" {
                [AtlassianPS.JiraPS.Filter].GetProperty('Owner').PropertyType.FullName | Should -Be 'AtlassianPS.JiraPS.User'
            }

            It "Issue.Assignee stays System.Object (legacy 'Unassigned' string sentinel)" {
                [AtlassianPS.JiraPS.Issue].GetProperty('Assignee').PropertyType.FullName | Should -Be 'System.Object'
            }

            It "Issue.Creator and Issue.Reporter are AtlassianPS.JiraPS.User" {
                [AtlassianPS.JiraPS.Issue].GetProperty('Creator').PropertyType.FullName | Should -Be 'AtlassianPS.JiraPS.User'
                [AtlassianPS.JiraPS.Issue].GetProperty('Reporter').PropertyType.FullName | Should -Be 'AtlassianPS.JiraPS.User'
            }

            It "Issue.Comment is AtlassianPS.JiraPS.Comment[]" {
                [AtlassianPS.JiraPS.Issue].GetProperty('Comment').PropertyType.FullName | Should -Be 'AtlassianPS.JiraPS.Comment[]'
            }

            It "Issue.Description and Comment.Body are System.String" {
                [AtlassianPS.JiraPS.Issue].GetProperty('Description').PropertyType.FullName | Should -Be 'System.String'
                [AtlassianPS.JiraPS.Comment].GetProperty('Body').PropertyType.FullName | Should -Be 'System.String'
            }

            It "User.Groups is System.String[]" {
                [AtlassianPS.JiraPS.User].GetProperty('Groups').PropertyType.FullName | Should -Be 'System.String[]'
            }

            It "ServerInfo.ScmInfo is System.String and ServerInfo.BuildNumber is Nullable<Int64>" {
                [AtlassianPS.JiraPS.ServerInfo].GetProperty('ScmInfo').PropertyType | Should -Be ([string])
                [AtlassianPS.JiraPS.ServerInfo].GetProperty('BuildNumber').PropertyType | Should -Be ([System.Nullable[long]])
            }

            It "Filter.Favourite is System.Boolean" {
                [AtlassianPS.JiraPS.Filter].GetProperty('Favourite').PropertyType | Should -Be ([bool])
            }

            It "Version.Archived, Version.Released and Version.Overdue are System.Boolean" {
                [AtlassianPS.JiraPS.Version].GetProperty('Archived').PropertyType | Should -Be ([bool])
                [AtlassianPS.JiraPS.Version].GetProperty('Released').PropertyType | Should -Be ([bool])
                [AtlassianPS.JiraPS.Version].GetProperty('Overdue').PropertyType | Should -Be ([bool])
            }

            It "Version.Project is Nullable<Int64>" {
                [AtlassianPS.JiraPS.Version].GetProperty('Project').PropertyType | Should -Be ([System.Nullable[long]])
            }

            It "Version.StartDate and Version.ReleaseDate are Nullable<DateTime>" {
                [AtlassianPS.JiraPS.Version].GetProperty('StartDate').PropertyType | Should -Be ([System.Nullable[datetime]])
                [AtlassianPS.JiraPS.Version].GetProperty('ReleaseDate').PropertyType | Should -Be ([System.Nullable[datetime]])
            }
        }

        Context "ConvertTo-Hashtable" {
            It "round-trips a PSCustomObject into a Hashtable" {
                $hash = [PSCustomObject]@{ A = 1; B = 'two' } | ConvertTo-Hashtable

                $hash | Should -BeOfType [hashtable]
                $hash.A | Should -Be 1
                $hash.B | Should -Be 'two'
            }

            It "lets a [Class](ConvertTo-Hashtable) cast succeed where [Class]\$psobject would fail on PS5.1" {
                # The motivating bug for ConvertTo-Hashtable: casting a
                # PSCustomObject to a custom .NET class throws
                # PSInvalidCastException on Windows PowerShell 5.1, but casting
                # from a Hashtable is fine. This test would fail on PS5.1
                # without the round-trip.
                $payload = [PSCustomObject]@{ Name = 'jdoe'; DisplayName = 'John Doe'; Active = $true }
                { [AtlassianPS.JiraPS.User](ConvertTo-Hashtable -InputObject $payload) } | Should -Not -Throw
            }
        }
    }
}
