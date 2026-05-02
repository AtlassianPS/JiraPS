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

        Context "Convenience constructors" {
            # The six identifier-driven classes ship a string-arg ctor for the
            # common stub-from-an-identifier flow that scripts and pipelines
            # exercise constantly. Each one mirrors the routing logic of its
            # matching ArgumentTransformationAttribute so passing a string
            # through `[Class]::new('value')` and through `-Parameter 'value'`
            # produce identical stubs.

            It "Issue('TEST-1') stores the input in Key" {
                $issue = [AtlassianPS.JiraPS.Issue]::new('TEST-1')

                $issue | Should -BeOfType [AtlassianPS.JiraPS.Issue]
                $issue.Key | Should -Be 'TEST-1'
                $issue.ID | Should -BeNullOrEmpty
            }

            It "User('jdoe') stores the input in Name (matches UserTransformation)" {
                $user = [AtlassianPS.JiraPS.User]::new('jdoe')

                $user | Should -BeOfType [AtlassianPS.JiraPS.User]
                $user.Name | Should -Be 'jdoe'
                $user.AccountId | Should -BeNullOrEmpty
            }

            It "Project('TEST') stores the input in Key" {
                $project = [AtlassianPS.JiraPS.Project]::new('TEST')

                $project | Should -BeOfType [AtlassianPS.JiraPS.Project]
                $project.Key | Should -Be 'TEST'
                $project.ID | Should -BeNullOrEmpty
            }

            It "Group('jira-users') stores the input in Name" {
                $group = [AtlassianPS.JiraPS.Group]::new('jira-users')

                $group | Should -BeOfType [AtlassianPS.JiraPS.Group]
                $group.Name | Should -Be 'jira-users'
                $group.Size | Should -BeNullOrEmpty
            }

            It "Filter('12345') stores the input in ID" {
                $filter = [AtlassianPS.JiraPS.Filter]::new('12345')

                $filter | Should -BeOfType [AtlassianPS.JiraPS.Filter]
                $filter.ID | Should -Be '12345'
                $filter.Name | Should -BeNullOrEmpty
            }

            It "Version('10001') routes a numeric string into ID" {
                $version = [AtlassianPS.JiraPS.Version]::new('10001')

                $version | Should -BeOfType [AtlassianPS.JiraPS.Version]
                $version.ID | Should -Be '10001'
                $version.Name | Should -BeNullOrEmpty
            }

            It "Version('My Version') routes a non-numeric string into Name" {
                $version = [AtlassianPS.JiraPS.Version]::new('My Version')

                $version.Name | Should -Be 'My Version'
                $version.ID | Should -BeNullOrEmpty
            }

            It "string-arg ctors reject null, empty, and whitespace input" {
                # Symmetric with the matching ArgumentTransformationAttribute
                # error: building a stub via the ctor must not silently
                # accept nonsense that the parameter binder would reject.
                foreach ($empty in @($null, '', ' ', "`t")) {
                    { [AtlassianPS.JiraPS.Issue]::new($empty) } | Should -Throw
                    { [AtlassianPS.JiraPS.User]::new($empty) } | Should -Throw
                    { [AtlassianPS.JiraPS.Project]::new($empty) } | Should -Throw
                    { [AtlassianPS.JiraPS.Group]::new($empty) } | Should -Throw
                    { [AtlassianPS.JiraPS.Filter]::new($empty) } | Should -Throw
                    { [AtlassianPS.JiraPS.Version]::new($empty) } | Should -Throw
                }
            }

            It "the parameterless ctor is preserved on every identifier-driven class" {
                # Regression guard: declaring a parameterized ctor in C#
                # removes the implicit parameterless ctor, which the
                # [Class]@{ ... } hashtable-cast pattern depends on. Each
                # class must keep `public Foo() {}` explicitly.
                foreach ($typeName in 'AtlassianPS.JiraPS.Issue', 'AtlassianPS.JiraPS.User', 'AtlassianPS.JiraPS.Project', 'AtlassianPS.JiraPS.Group', 'AtlassianPS.JiraPS.Filter', 'AtlassianPS.JiraPS.Version') {
                    $type = $typeName -as [Type]
                    $type | Should -Not -BeNullOrEmpty -Because "$typeName must be loaded"
                    $type.GetConstructor([Type]::EmptyTypes) |
                        Should -Not -BeNullOrEmpty -Because "$typeName must keep an explicit parameterless ctor"
                }
            }

            It "the hashtable-cast pattern still works after adding the parameterized ctor" {
                # The 30+ existing [Class]@{ ... } call sites in the test
                # suite would fail loudly if we lost the parameterless ctor
                # or its property setters; this assertion locks the contract
                # in one place so it cannot regress quietly.
                ([AtlassianPS.JiraPS.Issue]@{ Key = 'TEST-1' }).Key       | Should -Be 'TEST-1'
                ([AtlassianPS.JiraPS.User]@{ Name = 'jdoe' }).Name        | Should -Be 'jdoe'
                ([AtlassianPS.JiraPS.Project]@{ Key = 'TEST' }).Key       | Should -Be 'TEST'
                ([AtlassianPS.JiraPS.Group]@{ Name = 'jira-users' }).Name | Should -Be 'jira-users'
                ([AtlassianPS.JiraPS.Filter]@{ ID = '1' }).ID             | Should -Be '1'
                ([AtlassianPS.JiraPS.Version]@{ Name = '1.0' }).Name      | Should -Be '1.0'
            }

            It "the string-arg ctor produces a stub that round-trips through the matching transformer parameter" {
                # End-to-end check: build a stub via ::new() and bind it to
                # an actual cmdlet parameter so the transformer either
                # passes it through (singleton case) or fans it out (array
                # case). This catches a transformer regression that would
                # accept the string but reject the typed stub.
                $cmd = Get-Command Add-JiraIssueComment
                $param = $cmd.Parameters['Issue']
                $param.ParameterType.FullName | Should -Be 'AtlassianPS.JiraPS.Issue'

                $stub = [AtlassianPS.JiraPS.Issue]::new('TEST-1')
                # The transformer accepts an existing Issue and returns it
                # unchanged. We do not invoke the cmdlet (no live Jira),
                # but we drive the transformer directly to prove the round-trip.
                $transformerType = [AtlassianPS.JiraPS.IssueTransformationAttribute]
                $transformer = $transformerType::new()
                $result = $transformer.Transform($null, $stub)
                $result | Should -Be $stub
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
