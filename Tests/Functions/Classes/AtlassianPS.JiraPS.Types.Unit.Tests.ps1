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

            function Get-JiraTestObject {
                param(
                    [Parameter(Mandatory)]
                    [string]$TypeName,

                    [hashtable]$Property = @{}
                )

                $type = $TypeName -as [Type]
                $object = [Activator]::CreateInstance($type)
                foreach ($name in $Property.Keys) {
                    $object.$name = $Property[$name]
                }
                $object
            }

            function Get-JiraTestObjectFromString {
                param(
                    [Parameter(Mandatory)]
                    [string]$TypeName,

                    [AllowNull()]
                    [string]$Value
                )

                [Activator]::CreateInstance(($TypeName -as [Type]), [object[]]@($Value))
            }
        }

        Context "Type loading" {
            It "loads <typeName> into the current AppDomain" -TestCases @(
                @{ typeName = 'AtlassianPS.JiraPS.Attachment' }
                @{ typeName = 'AtlassianPS.JiraPS.Comment' }
                @{ typeName = 'AtlassianPS.JiraPS.Component' }
                @{ typeName = 'AtlassianPS.JiraPS.CreateMetaField' }
                @{ typeName = 'AtlassianPS.JiraPS.EditMetaField' }
                @{ typeName = 'AtlassianPS.JiraPS.Field' }
                @{ typeName = 'AtlassianPS.JiraPS.Filter' }
                @{ typeName = 'AtlassianPS.JiraPS.FilterPermission' }
                @{ typeName = 'AtlassianPS.JiraPS.Issue' }
                @{ typeName = 'AtlassianPS.JiraPS.IssueLink' }
                @{ typeName = 'AtlassianPS.JiraPS.IssueLinkType' }
                @{ typeName = 'AtlassianPS.JiraPS.IssueType' }
                @{ typeName = 'AtlassianPS.JiraPS.Link' }
                @{ typeName = 'AtlassianPS.JiraPS.Priority' }
                @{ typeName = 'AtlassianPS.JiraPS.Project' }
                @{ typeName = 'AtlassianPS.JiraPS.ProjectRole' }
                @{ typeName = 'AtlassianPS.JiraPS.Resolution' }
                @{ typeName = 'AtlassianPS.JiraPS.ServerInfo' }
                @{ typeName = 'AtlassianPS.JiraPS.Session' }
                @{ typeName = 'AtlassianPS.JiraPS.Status' }
                @{ typeName = 'AtlassianPS.JiraPS.StatusCategory' }
                @{ typeName = 'AtlassianPS.JiraPS.Transition' }
                @{ typeName = 'AtlassianPS.JiraPS.User' }
                @{ typeName = 'AtlassianPS.JiraPS.Version' }
                @{ typeName = 'AtlassianPS.JiraPS.Worklogitem' }
            ) {
                param($typeName)

                ($typeName -as [Type]) | Should -Not -BeNullOrEmpty -Because "$typeName must be available after module import"
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
            It "<typeName> formats <scenario>" -TestCases @(
                @{ typeName = 'AtlassianPS.JiraPS.Issue'; property = @{ Key = 'TEST-1'; Summary = 'my summary' }; scenario = 'key and summary'; expected = '[TEST-1] my summary' }
                @{ typeName = 'AtlassianPS.JiraPS.User'; property = @{ Name = 'jdoe'; DisplayName = 'John' }; scenario = 'name first'; expected = 'jdoe' }
                @{ typeName = 'AtlassianPS.JiraPS.User'; property = @{ DisplayName = 'John' }; scenario = 'display name fallback'; expected = 'John' }
                @{ typeName = 'AtlassianPS.JiraPS.User'; property = @{ AccountId = 'abc-123' }; scenario = 'account ID fallback'; expected = 'abc-123' }
                @{ typeName = 'AtlassianPS.JiraPS.User'; property = @{}; scenario = 'empty'; expected = '' }
                @{ typeName = 'AtlassianPS.JiraPS.Project'; property = @{ Name = 'My Project' }; scenario = 'name'; expected = 'My Project' }
                @{ typeName = 'AtlassianPS.JiraPS.Version'; property = @{ Name = '1.0.0' }; scenario = 'name'; expected = '1.0.0' }
                @{ typeName = 'AtlassianPS.JiraPS.Filter'; property = @{ Name = 'My Filter' }; scenario = 'name'; expected = 'My Filter' }
                @{ typeName = 'AtlassianPS.JiraPS.Comment'; property = @{ Body = 'hello' }; scenario = 'body'; expected = 'hello' }
                @{ typeName = 'AtlassianPS.JiraPS.Comment'; property = @{}; scenario = 'empty'; expected = '' }
                @{ typeName = 'AtlassianPS.JiraPS.ServerInfo'; property = @{ DeploymentType = 'Cloud'; Version = '1001.0.0' }; scenario = 'deployment and version'; expected = '[Cloud] 1001.0.0' }
                @{ typeName = 'AtlassianPS.JiraPS.ServerInfo'; property = @{ Version = '1001.0.0' }; scenario = 'version fallback'; expected = '1001.0.0' }
                @{ typeName = 'AtlassianPS.JiraPS.ServerInfo'; property = @{ DeploymentType = 'Cloud' }; scenario = 'deployment fallback'; expected = 'Cloud' }
                @{ typeName = 'AtlassianPS.JiraPS.ServerInfo'; property = @{}; scenario = 'empty'; expected = '' }
                @{ typeName = 'AtlassianPS.JiraPS.Session'; property = @{ JSessionID = 'abc' }; scenario = 'session ID'; expected = 'JiraSession[JSessionID=abc]' }
                @{ typeName = 'AtlassianPS.JiraPS.Session'; property = @{}; scenario = 'empty'; expected = 'JiraSession' }
            ) {
                param($typeName, $property, $expected)

                (Get-JiraTestObject -TypeName $typeName -Property $property).ToString() | Should -Be $expected
            }
        }

        Context "Strong cross-reference slot typing" {
            # These assertions lock in the slot type for every cross-reference
            # so a future loosening (e.g. Project.Lead going back to System.Object)
            # is caught immediately. Strong slots are what give us IntelliSense
            # and parse-time errors when the wrong thing is assigned.

            It "<typeName>.<property> is <expectedType>" -TestCases @(
                @{ typeName = 'AtlassianPS.JiraPS.Project'; property = 'Lead'; expectedType = [AtlassianPS.JiraPS.User] }
                @{ typeName = 'AtlassianPS.JiraPS.Comment'; property = 'Author'; expectedType = [AtlassianPS.JiraPS.User] }
                @{ typeName = 'AtlassianPS.JiraPS.Comment'; property = 'UpdateAuthor'; expectedType = [AtlassianPS.JiraPS.User] }
                @{ typeName = 'AtlassianPS.JiraPS.Issue'; property = 'Project'; expectedType = [AtlassianPS.JiraPS.Project] }
                @{ typeName = 'AtlassianPS.JiraPS.Filter'; property = 'Owner'; expectedType = [AtlassianPS.JiraPS.User] }
                @{ typeName = 'AtlassianPS.JiraPS.Issue'; property = 'Assignee'; expectedType = [object] }
                @{ typeName = 'AtlassianPS.JiraPS.Issue'; property = 'Creator'; expectedType = [AtlassianPS.JiraPS.User] }
                @{ typeName = 'AtlassianPS.JiraPS.Issue'; property = 'Reporter'; expectedType = [AtlassianPS.JiraPS.User] }
                @{ typeName = 'AtlassianPS.JiraPS.Issue'; property = 'Comment'; expectedType = [AtlassianPS.JiraPS.Comment[]] }
                @{ typeName = 'AtlassianPS.JiraPS.Issue'; property = 'Status'; expectedType = [AtlassianPS.JiraPS.Status] }
                @{ typeName = 'AtlassianPS.JiraPS.Issue'; property = 'IssueLinks'; expectedType = [AtlassianPS.JiraPS.IssueLink[]] }
                @{ typeName = 'AtlassianPS.JiraPS.Issue'; property = 'Attachment'; expectedType = [AtlassianPS.JiraPS.Attachment[]] }
                @{ typeName = 'AtlassianPS.JiraPS.Issue'; property = 'Transition'; expectedType = [AtlassianPS.JiraPS.Transition[]] }
                @{ typeName = 'AtlassianPS.JiraPS.Project'; property = 'IssueTypes'; expectedType = [AtlassianPS.JiraPS.IssueType[]] }
                @{ typeName = 'AtlassianPS.JiraPS.Project'; property = 'Components'; expectedType = [AtlassianPS.JiraPS.Component[]] }
                @{ typeName = 'AtlassianPS.JiraPS.Filter'; property = 'FilterPermissions'; expectedType = [AtlassianPS.JiraPS.FilterPermission[]] }
                @{ typeName = 'AtlassianPS.JiraPS.Issue'; property = 'RestUrl'; expectedType = [uri] }
                @{ typeName = 'AtlassianPS.JiraPS.Issue'; property = 'HttpUrl'; expectedType = [uri] }
                @{ typeName = 'AtlassianPS.JiraPS.User'; property = 'RestUrl'; expectedType = [uri] }
                @{ typeName = 'AtlassianPS.JiraPS.Filter'; property = 'SearchUrl'; expectedType = [uri] }
                @{ typeName = 'AtlassianPS.JiraPS.Issue'; property = 'Description'; expectedType = [string] }
                @{ typeName = 'AtlassianPS.JiraPS.Comment'; property = 'Body'; expectedType = [string] }
                @{ typeName = 'AtlassianPS.JiraPS.User'; property = 'Groups'; expectedType = [string[]] }
                @{ typeName = 'AtlassianPS.JiraPS.ServerInfo'; property = 'ScmInfo'; expectedType = [string] }
                @{ typeName = 'AtlassianPS.JiraPS.ServerInfo'; property = 'BuildNumber'; expectedType = [System.Nullable[long]] }
                @{ typeName = 'AtlassianPS.JiraPS.Filter'; property = 'Favourite'; expectedType = [bool] }
                @{ typeName = 'AtlassianPS.JiraPS.Version'; property = 'Archived'; expectedType = [bool] }
                @{ typeName = 'AtlassianPS.JiraPS.Version'; property = 'Released'; expectedType = [bool] }
                @{ typeName = 'AtlassianPS.JiraPS.Version'; property = 'Overdue'; expectedType = [bool] }
                @{ typeName = 'AtlassianPS.JiraPS.Version'; property = 'Project'; expectedType = [System.Nullable[long]] }
                @{ typeName = 'AtlassianPS.JiraPS.Version'; property = 'StartDate'; expectedType = [System.Nullable[datetime]] }
                @{ typeName = 'AtlassianPS.JiraPS.Version'; property = 'ReleaseDate'; expectedType = [System.Nullable[datetime]] }
                @{ typeName = 'AtlassianPS.JiraPS.Issue'; property = 'Created'; expectedType = [System.Nullable[System.DateTimeOffset]] }
                @{ typeName = 'AtlassianPS.JiraPS.Comment'; property = 'Updated'; expectedType = [System.Nullable[System.DateTimeOffset]] }
                @{ typeName = 'AtlassianPS.JiraPS.ServerInfo'; property = 'ServerTime'; expectedType = [System.Nullable[System.DateTimeOffset]] }
            ) {
                param($typeName, $property, $expectedType)

                ($typeName -as [Type]).GetProperty($property).PropertyType | Should -Be $expectedType
            }
        }

        Context "Convenience constructors" {
            # The six identifier-driven classes ship a string-arg ctor for the
            # common stub-from-an-identifier flow that scripts and pipelines
            # exercise constantly. Each one mirrors the routing logic of its
            # matching ArgumentTransformationAttribute so passing a string
            # through `[Class]::new('value')` and through `-Parameter 'value'`
            # produce identical stubs.

            It "<typeName>('<inputValue>') stores input in <expectedProperty>" -TestCases @(
                @{ typeName = 'AtlassianPS.JiraPS.Issue'; inputValue = 'TEST-1'; expectedProperty = 'Key'; expectedValue = 'TEST-1'; emptyProperty = 'ID' }
                @{ typeName = 'AtlassianPS.JiraPS.User'; inputValue = 'jdoe'; expectedProperty = 'Name'; expectedValue = 'jdoe'; emptyProperty = 'AccountId' }
                @{ typeName = 'AtlassianPS.JiraPS.Project'; inputValue = 'TEST'; expectedProperty = 'Key'; expectedValue = 'TEST'; emptyProperty = 'ID' }
                @{ typeName = 'AtlassianPS.JiraPS.Group'; inputValue = 'jira-users'; expectedProperty = 'Name'; expectedValue = 'jira-users'; emptyProperty = 'Size' }
                @{ typeName = 'AtlassianPS.JiraPS.Filter'; inputValue = '12345'; expectedProperty = 'ID'; expectedValue = '12345'; emptyProperty = 'Name' }
                @{ typeName = 'AtlassianPS.JiraPS.Version'; inputValue = '10001'; expectedProperty = 'ID'; expectedValue = '10001'; emptyProperty = 'Name' }
                @{ typeName = 'AtlassianPS.JiraPS.Version'; inputValue = 'My Version'; expectedProperty = 'Name'; expectedValue = 'My Version'; emptyProperty = 'ID' }
            ) {
                param($typeName, $inputValue, $expectedProperty, $expectedValue, $emptyProperty)

                $value = Get-JiraTestObjectFromString -TypeName $typeName -Value $inputValue

                $value | Should -BeOfType ($typeName -as [Type])
                $value.$expectedProperty | Should -Be $expectedValue
                $value.$emptyProperty | Should -BeNullOrEmpty
            }

            It "<typeName> string-arg ctor rejects '<label>' input" -TestCases @(
                # Symmetric with the matching ArgumentTransformationAttribute
                # error: building a stub via the ctor must not silently
                # accept nonsense that the parameter binder would reject.
                foreach ($typeName in 'AtlassianPS.JiraPS.Issue', 'AtlassianPS.JiraPS.User', 'AtlassianPS.JiraPS.Project', 'AtlassianPS.JiraPS.Group', 'AtlassianPS.JiraPS.Filter', 'AtlassianPS.JiraPS.Version') {
                    foreach ($case in @(
                            @{ label = 'null'; value = $null }
                            @{ label = 'empty'; value = '' }
                            @{ label = 'space'; value = ' ' }
                            @{ label = 'tab'; value = "`t" }
                        )) {
                        @{ typeName = $typeName; label = $case.label; value = $case.value }
                    }
                }
            ) {
                param($typeName, $value)

                { Get-JiraTestObjectFromString -TypeName $typeName -Value $value } | Should -Throw
            }

            It "the parameterless ctor is preserved on <typeName>" -TestCases @(
                # Regression guard: declaring a parameterized ctor in C#
                # removes the implicit parameterless ctor, which the
                # [Class]@{ ... } hashtable-cast pattern depends on. Each
                # class must keep `public Foo() {}` explicitly.
                @{ typeName = 'AtlassianPS.JiraPS.Issue' }
                @{ typeName = 'AtlassianPS.JiraPS.User' }
                @{ typeName = 'AtlassianPS.JiraPS.Project' }
                @{ typeName = 'AtlassianPS.JiraPS.Group' }
                @{ typeName = 'AtlassianPS.JiraPS.Filter' }
                @{ typeName = 'AtlassianPS.JiraPS.Version' }
                @{ typeName = 'AtlassianPS.JiraPS.Comment' }
                @{ typeName = 'AtlassianPS.JiraPS.Session' }
                @{ typeName = 'AtlassianPS.JiraPS.ServerInfo' }
            ) {
                param($typeName)

                $type = $typeName -as [Type]
                $type | Should -Not -BeNullOrEmpty -Because "$typeName must be loaded"
                $type.GetConstructor([Type]::EmptyTypes) |
                    Should -Not -BeNullOrEmpty -Because "$typeName must keep an explicit parameterless ctor"
            }

            It "the hashtable-cast pattern still works for <typeName>.<property>" -TestCases @(
                # The 30+ existing [Class]@{ ... } call sites in the test
                # suite would fail loudly if we lost the parameterless ctor
                # or its property setters; this assertion locks the contract
                # in one place so it cannot regress quietly.
                @{ typeName = 'AtlassianPS.JiraPS.Issue'; property = 'Key'; value = 'TEST-1'; create = { [AtlassianPS.JiraPS.Issue]@{ Key = 'TEST-1' } } }
                @{ typeName = 'AtlassianPS.JiraPS.User'; property = 'Name'; value = 'jdoe'; create = { [AtlassianPS.JiraPS.User]@{ Name = 'jdoe' } } }
                @{ typeName = 'AtlassianPS.JiraPS.Project'; property = 'Key'; value = 'TEST'; create = { [AtlassianPS.JiraPS.Project]@{ Key = 'TEST' } } }
                @{ typeName = 'AtlassianPS.JiraPS.Group'; property = 'Name'; value = 'jira-users'; create = { [AtlassianPS.JiraPS.Group]@{ Name = 'jira-users' } } }
                @{ typeName = 'AtlassianPS.JiraPS.Filter'; property = 'ID'; value = '1'; create = { [AtlassianPS.JiraPS.Filter]@{ ID = '1' } } }
                @{ typeName = 'AtlassianPS.JiraPS.Version'; property = 'Name'; value = '1.0'; create = { [AtlassianPS.JiraPS.Version]@{ Name = '1.0' } } }
            ) {
                param($property, $value, $create)

                (& $create).$property | Should -Be $value
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

        Context "Identifier-based equality and comparison" {
            BeforeAll {
                function Assert-IdentifierBehavior {
                    param(
                        [Parameter(Mandatory)]
                        [object]$Primary,

                        [Parameter(Mandatory)]
                        [object]$Equivalent,

                        [Parameter(Mandatory)]
                        [object]$Different
                    )

                    ($Primary -eq $Equivalent) | Should -BeTrue
                    ($Primary -eq $Different) | Should -BeFalse
                    (@($Primary) -contains $Equivalent) | Should -BeTrue

                    (@($Different, $Primary) | Sort-Object)[0] | Should -Be $Primary
                    (@($Primary, $Equivalent, $Different) | Sort-Object -Unique).Count | Should -Be 2

                    $groups = @($Primary, $Equivalent, $Different) | Group-Object -AsHashTable
                    $groups.Count | Should -Be 2
                    $groups[$Primary].Count | Should -Be 2

                    $lookup = @{}
                    $lookup[$Primary] = 'first'
                    $lookup[$Equivalent] = 'second'
                    $lookup[$Different] = 'third'

                    $lookup.Count | Should -Be 2
                    $lookup[$Primary] | Should -Be 'second'
                }
            }

            It "<scenario>" -TestCases @(
                @{
                    scenario   = 'Issue compares by Key'
                    primary    = { [AtlassianPS.JiraPS.Issue]@{ Key = 'TEST-1'; Summary = 'first' } }
                    equivalent = { [AtlassianPS.JiraPS.Issue]@{ Key = 'test-1'; Summary = 'second' } }
                    different  = { [AtlassianPS.JiraPS.Issue]@{ Key = 'TEST-2'; Summary = 'third' } }
                }
                @{
                    scenario   = 'Project compares by Key'
                    primary    = { [AtlassianPS.JiraPS.Project]@{ Key = 'ALPHA'; Name = 'Alpha' } }
                    equivalent = { [AtlassianPS.JiraPS.Project]@{ Key = 'alpha'; Name = 'Alpha (clone)' } }
                    different  = { [AtlassianPS.JiraPS.Project]@{ Key = 'BETA'; Name = 'Beta' } }
                }
                @{
                    scenario   = 'Group compares by Name'
                    primary    = { [AtlassianPS.JiraPS.Group]@{ Name = 'jira-admins' } }
                    equivalent = { [AtlassianPS.JiraPS.Group]@{ Name = 'JIRA-ADMINS' } }
                    different  = { [AtlassianPS.JiraPS.Group]@{ Name = 'jira-users' } }
                }
                @{
                    scenario   = 'Filter compares by ID'
                    primary    = { [AtlassianPS.JiraPS.Filter]@{ ID = '10001'; Name = '10001' } }
                    equivalent = { [AtlassianPS.JiraPS.Filter]@{ ID = '10001'; Name = 'same-id-different-name' } }
                    different  = { [AtlassianPS.JiraPS.Filter]@{ ID = '20001'; Name = '20001' } }
                }
                @{
                    scenario   = 'Version compares by ID first, then Name'
                    primary    = { [AtlassianPS.JiraPS.Version]@{ ID = '10001'; Name = '1.0.0' } }
                    equivalent = { [AtlassianPS.JiraPS.Version]@{ ID = '10001'; Name = '1.0.0-alt' } }
                    different  = { [AtlassianPS.JiraPS.Version]@{ ID = '20001'; Name = '2.0.0' } }
                }
                @{
                    scenario   = 'User compares by AccountId first, then Name'
                    primary    = { [AtlassianPS.JiraPS.User]@{ AccountId = 'abc-123'; Name = 'legacy-user-a' } }
                    equivalent = { [AtlassianPS.JiraPS.User]@{ AccountId = 'ABC-123'; Name = 'legacy-user-b' } }
                    different  = { [AtlassianPS.JiraPS.User]@{ AccountId = 'def-456'; Name = 'legacy-user-a' } }
                }
                @{
                    scenario   = 'User falls back to Name when AccountId is absent'
                    primary    = { [AtlassianPS.JiraPS.User]@{ Name = 'asmith' } }
                    equivalent = { [AtlassianPS.JiraPS.User]@{ Name = 'ASMITH'; DisplayName = 'Alice Smith' } }
                    different  = { [AtlassianPS.JiraPS.User]@{ Name = 'jdoe' } }
                }
            ) {
                param($primary, $equivalent, $different)

                Assert-IdentifierBehavior -Primary (& $primary) -Equivalent (& $equivalent) -Different (& $different)
            }

            It "<type> identifier-less objects do not deduplicate under Sort-Object -Unique" -TestCases @(
                @{ type = 'Issue'; create = { [AtlassianPS.JiraPS.Issue]::new() } }
                @{ type = 'Project'; create = { [AtlassianPS.JiraPS.Project]::new() } }
                @{ type = 'Group'; create = { [AtlassianPS.JiraPS.Group]::new() } }
                @{ type = 'Filter'; create = { [AtlassianPS.JiraPS.Filter]::new() } }
                @{ type = 'Version'; create = { [AtlassianPS.JiraPS.Version]::new() } }
                @{ type = 'User'; create = { [AtlassianPS.JiraPS.User]::new() } }
            ) {
                param($type, $create)

                $first = & $create
                $second = & $create

                ($first -eq $second) | Should -BeFalse -Because "$type equality is identity-based only when an identifier exists"
                ($first.CompareTo($second)) | Should -Not -Be 0 -Because "$type comparison must not collapse distinct identifier-less objects"
                (@($first, $second) | Sort-Object -Unique).Count | Should -Be 2 -Because "$type identifier-less instances must stay distinct"
            }

            It "<type> identifier-less objects still equal themselves" -TestCases @(
                @{ type = 'Issue'; create = { [AtlassianPS.JiraPS.Issue]::new() } }
                @{ type = 'Project'; create = { [AtlassianPS.JiraPS.Project]::new() } }
                @{ type = 'Group'; create = { [AtlassianPS.JiraPS.Group]::new() } }
                @{ type = 'Filter'; create = { [AtlassianPS.JiraPS.Filter]::new() } }
                @{ type = 'Version'; create = { [AtlassianPS.JiraPS.Version]::new() } }
                @{ type = 'User'; create = { [AtlassianPS.JiraPS.User]::new() } }
            ) {
                param($type, $create)

                $value = & $create

                ($value.Equals($value)) | Should -BeTrue -Because "$type must satisfy reflexive equality even before an identifier is populated"
                ($value.CompareTo($value)) | Should -Be 0 -Because "$type compare-to-self must remain stable"
            }
        }

        Context "Transformer fallthrough across competing parameter sets" {
            BeforeAll {
                function Invoke-IssuePreferredBinding {
                    [CmdletBinding(DefaultParameterSetName = 'Issue')]
                    param(
                        [Parameter(Mandatory, ValueFromPipeline, ParameterSetName = 'Issue')]
                        [AtlassianPS.JiraPS.IssueTransformation()]
                        [AtlassianPS.JiraPS.Issue]$Issue,

                        [Parameter(Mandatory, ValueFromPipeline, ParameterSetName = 'Project')]
                        [AtlassianPS.JiraPS.ProjectTransformation()]
                        [AtlassianPS.JiraPS.Project]$Project
                    )
                    process { $PSCmdlet.ParameterSetName }
                }

                function Invoke-UserPreferredBinding {
                    [CmdletBinding(DefaultParameterSetName = 'User')]
                    param(
                        [Parameter(Mandatory, ValueFromPipeline, ParameterSetName = 'User')]
                        [AtlassianPS.JiraPS.UserTransformation()]
                        [AtlassianPS.JiraPS.User]$User,

                        [Parameter(Mandatory, ValueFromPipeline, ParameterSetName = 'Group')]
                        [AtlassianPS.JiraPS.GroupTransformation()]
                        [AtlassianPS.JiraPS.Group]$Group
                    )
                    process { $PSCmdlet.ParameterSetName }
                }

                function Invoke-GroupPreferredBinding {
                    [CmdletBinding(DefaultParameterSetName = 'Group')]
                    param(
                        [Parameter(Mandatory, ValueFromPipeline, ParameterSetName = 'Group')]
                        [AtlassianPS.JiraPS.GroupTransformation()]
                        [AtlassianPS.JiraPS.Group]$Group,

                        [Parameter(Mandatory, ValueFromPipeline, ParameterSetName = 'User')]
                        [AtlassianPS.JiraPS.UserTransformation()]
                        [AtlassianPS.JiraPS.User]$User
                    )
                    process { $PSCmdlet.ParameterSetName }
                }

                function Invoke-VersionPreferredBinding {
                    [CmdletBinding(DefaultParameterSetName = 'Version')]
                    param(
                        [Parameter(Mandatory, ValueFromPipeline, ParameterSetName = 'Version')]
                        [AtlassianPS.JiraPS.VersionTransformation()]
                        [AtlassianPS.JiraPS.Version]$Version,

                        [Parameter(Mandatory, ValueFromPipeline, ParameterSetName = 'Project')]
                        [AtlassianPS.JiraPS.ProjectTransformation()]
                        [AtlassianPS.JiraPS.Project]$Project
                    )
                    process { $PSCmdlet.ParameterSetName }
                }

                function Invoke-FilterPreferredBinding {
                    [CmdletBinding(DefaultParameterSetName = 'Filter')]
                    param(
                        [Parameter(Mandatory, ValueFromPipeline, ParameterSetName = 'Filter')]
                        [AtlassianPS.JiraPS.FilterTransformation()]
                        [AtlassianPS.JiraPS.Filter]$Filter,

                        [Parameter(Mandatory, ValueFromPipeline, ParameterSetName = 'Project')]
                        [AtlassianPS.JiraPS.ProjectTransformation()]
                        [AtlassianPS.JiraPS.Project]$Project
                    )
                    process { $PSCmdlet.ParameterSetName }
                }

                function Invoke-ProjectPreferredBinding {
                    [CmdletBinding(DefaultParameterSetName = 'Project')]
                    param(
                        [Parameter(Mandatory, ValueFromPipeline, ParameterSetName = 'Project')]
                        [AtlassianPS.JiraPS.ProjectTransformation()]
                        [AtlassianPS.JiraPS.Project]$Project,

                        [Parameter(Mandatory, ValueFromPipeline, ParameterSetName = 'Version')]
                        [AtlassianPS.JiraPS.VersionTransformation()]
                        [AtlassianPS.JiraPS.Version]$Version
                    )
                    process { $PSCmdlet.ParameterSetName }
                }
            }

            It "<transformer> falls through to <expectedParameterSet> when competing input is piped" -TestCases @(
                @{
                    transformer          = 'IssueTransformation'
                    createInput          = { [AtlassianPS.JiraPS.Project]::new('TEST') }
                    invokeBinding        = { param($value) $value | Invoke-IssuePreferredBinding }
                    expectedParameterSet = 'Project'
                }
                @{
                    transformer          = 'UserTransformation'
                    createInput          = { [AtlassianPS.JiraPS.Group]::new('jira-users') }
                    invokeBinding        = { param($value) $value | Invoke-UserPreferredBinding }
                    expectedParameterSet = 'Group'
                }
                @{
                    transformer          = 'GroupTransformation'
                    createInput          = { [AtlassianPS.JiraPS.User]::new('jdoe') }
                    invokeBinding        = { param($value) $value | Invoke-GroupPreferredBinding }
                    expectedParameterSet = 'User'
                }
                @{
                    transformer          = 'VersionTransformation'
                    createInput          = { [AtlassianPS.JiraPS.Project]::new('TEST') }
                    invokeBinding        = { param($value) $value | Invoke-VersionPreferredBinding }
                    expectedParameterSet = 'Project'
                }
                @{
                    transformer          = 'FilterTransformation'
                    createInput          = { [AtlassianPS.JiraPS.Project]::new('TEST') }
                    invokeBinding        = { param($value) $value | Invoke-FilterPreferredBinding }
                    expectedParameterSet = 'Project'
                }
                @{
                    transformer          = 'ProjectTransformation'
                    createInput          = { [AtlassianPS.JiraPS.Version]::new('10001') }
                    invokeBinding        = { param($value) $value | Invoke-ProjectPreferredBinding }
                    expectedParameterSet = 'Version'
                }
            ) {
                param($createInput, $invokeBinding, $expectedParameterSet)

                & $invokeBinding (& $createInput) | Should -Be $expectedParameterSet
            }

            It "<transformerType> reports type-specific errors on unrelated values" -TestCases @(
                @{ transformerType = [AtlassianPS.JiraPS.VersionTransformationAttribute]; expectedMessage = '*AtlassianPS.JiraPS.Version*' }
                @{ transformerType = [AtlassianPS.JiraPS.FilterTransformationAttribute]; expectedMessage = '*AtlassianPS.JiraPS.Filter*' }
                @{ transformerType = [AtlassianPS.JiraPS.ProjectTransformationAttribute]; expectedMessage = '*AtlassianPS.JiraPS.Project*' }
            ) {
                param($transformerType, $expectedMessage)

                $transformer = $transformerType::new()
                { $transformer.Transform($null, [datetime]::UtcNow) } | Should -Throw $expectedMessage
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
