#requires -modules @{ ModuleName = "Pester"; ModuleVersion = "6.2.0"; MaximumVersion = "6.999" }

BeforeDiscovery {
    . "$PSScriptRoot/../../Helpers/TestTools.ps1"

    $script:moduleToTest = Initialize-TestEnvironment
}

InModuleScope JiraPS {
    Describe 'ConvertTo-Jira* null input contracts' -Tag 'Unit' {
        BeforeDiscovery {
            $script:nullInputConverterCases = @(
                Get-Command -Name 'ConvertTo-Jira*' -CommandType Function |
                    Where-Object -FilterScript {
                        $_.ModuleName -eq 'JiraPS' -and
                        $_.Parameters.ContainsKey('InputObject') -and
                        $_.Name -ne 'ConvertTo-JiraTable'
                    } |
                    Sort-Object -Property Name |
                    ForEach-Object -Process { @{ converter = $_.Name } }
            )
            $script:arrayInputConverterCases = @(
                foreach ($case in $script:nullInputConverterCases) {
                    $command = Get-Command -Name $case.converter
                    if ($command.Parameters['InputObject'].ParameterType.IsArray) { $case }
                }
            )
        }

        It 'accounts for every ConvertTo-Jira function' {
            $converters = @(
                Get-Command -Name 'ConvertTo-Jira*' -CommandType Function |
                    Where-Object -FilterScript { $_.ModuleName -eq 'JiraPS' }
            )
            $converters.Count | Should -BeGreaterThan 0
            $specialConverters = @(
                'ConvertTo-JiraEnum'
                'ConvertTo-JiraFieldAssignment'
                'ConvertTo-JiraRestApiV3Url'
                'ConvertTo-JiraTable'
            )
            $uncovered = @(
                $converters | Where-Object -FilterScript {
                    -not $_.Parameters.ContainsKey('InputObject') -and $_.Name -notin $specialConverters
                }
            )
            $uncovered.Count | Should -Be 0 -Because "every converter needs a null contract: $($uncovered.Name -join ', ')"
        }

        Context 'Optional object input' {
            It '<converter> returns null for explicit null input' -TestCases $script:nullInputConverterCases {
                param($converter)
                $result = & $converter -InputObject $null
                ($null -eq $result) | Should -BeTrue
            }

            It '<converter> returns null when input is omitted' -TestCases $script:nullInputConverterCases {
                param($converter)
                $result = & $converter
                ($null -eq $result) | Should -BeTrue
            }

            It '<converter> returns null for piped null input' -TestCases $script:nullInputConverterCases {
                param($converter)
                $result = $null | & $converter
                ($null -eq $result) | Should -BeTrue
            }
        }

        Context 'Array input' {
            It '<converter> emits no objects for an empty array' -TestCases $script:arrayInputConverterCases {
                param($converter)
                $result = @(& $converter -InputObject @())
                $result.Count | Should -Be 0
            }

            It '<converter> emits no objects for null array entries' -TestCases $script:arrayInputConverterCases {
                param($converter)
                $result = @(& $converter -InputObject @($null, $null))
                $result.Count | Should -Be 0
            }

            It '<converter> emits no objects for piped null array entries' -TestCases $script:arrayInputConverterCases {
                param($converter)
                $result = @(@($null, $null) | & $converter)
                $result.Count | Should -Be 0
            }

            It '<converter> skips null entries without dropping adjacent objects' -TestCases $script:arrayInputConverterCases {
                param($converter)
                $item = if ($converter -eq 'ConvertTo-JiraEditMetaField') {
                    [PSCustomObject]@{ fields = [PSCustomObject]@{ summary = [PSCustomObject]@{} } }
                }
                else { [PSCustomObject]@{} }

                $result = @(& $converter -InputObject @($null, $item, $null, $item, $null))
                $result.Count | Should -Be 2
            }
        }

        Context 'Other converter signatures' {
            It 'ConvertTo-JiraEnum returns null for a missing enum value' {
                $result = ConvertTo-JiraEnum -Type ([AtlassianPS.JiraPS.AccountType]) -Value $null
                ($null -eq $result) | Should -BeTrue
            }

            It 'ConvertTo-JiraTable rejects null input' {
                { ConvertTo-JiraTable -InputObject $null } | Should -Throw -ExpectedMessage '*InputObject*null*'
            }

            It 'ConvertTo-JiraFieldAssignment rejects null fields' {
                { ConvertTo-JiraFieldAssignment -Fields $null -IsCloud $false } | Should -Throw -ExpectedMessage '*Fields*null*'
            }

            It 'ConvertTo-JiraRestApiV3Url preserves null as an empty string on <deployment>' -TestCases @(
                @{ deployment = 'Cloud'; isCloud = $true }
                @{ deployment = 'Data Center'; isCloud = $false }
            ) {
                param($isCloud)
                $result = ConvertTo-JiraRestApiV3Url -Url $null -IsCloud $isCloud
                $result | Should -BeOfType [string]
                $result.Length | Should -Be 0
            }
        }

        Context 'Projects on issue type scopes' {
            It 'handles <shape> scope project input' -TestCases @(
                @{ shape = 'omitted' }
                @{ shape = 'explicit null' }
                @{ shape = 'empty' }
                @{ shape = 'populated' }
                @{ shape = 'already typed' }
            ) {
                param($shape)
                $project = switch ($shape) {
                    'empty' { [PSCustomObject]@{} }
                    'populated' { [PSCustomObject]@{ id = '123'; key = 'TEST' } }
                    'already typed' { [AtlassianPS.JiraPS.Project]@{ Id = '123'; Key = 'TEST' } }
                }
                $scope = [PSCustomObject]@{ type = 'PROJECT' }
                if ($shape -ne 'omitted') { $scope | Add-Member -NotePropertyName project -NotePropertyValue $project }

                $result = ConvertTo-JiraIssueType -InputObject ([PSCustomObject]@{ id = '1'; scope = $scope })
                $result.Scope | Should -BeOfType [AtlassianPS.JiraPS.IssueTypeScope]
                $result.Scope.Type | Should -Be 'PROJECT'
                if ($shape -in 'omitted', 'explicit null') { ($null -eq $result.Scope.Project) | Should -BeTrue }
                else {
                    $result.Scope.Project | Should -BeOfType [AtlassianPS.JiraPS.Project]
                    if ($shape -eq 'empty') { $result.Scope.Project.Id | Should -BeExactly ([string]::Empty) }
                    else {
                        $result.Scope.Project.Id | Should -BeExactly '123'
                        $result.Scope.Project.Key | Should -Be 'TEST'
                    }
                }
            }
        }

        Context 'Optional nested objects and maps' {
            It '<converter> keeps <property> null when <shape>' -TestCases @(
                foreach ($case in @(
                        @{ converter = 'ConvertTo-JiraAttachment'; property = 'Author'; sourceProperty = 'author' }
                        @{ converter = 'ConvertTo-JiraComment'; property = 'Visibility'; sourceProperty = 'visibility' }
                        @{ converter = 'ConvertTo-JiraWorklogitem'; property = 'Visibility'; sourceProperty = 'visibility' }
                        @{ converter = 'ConvertTo-JiraUser'; property = 'AvatarUrl'; sourceProperty = 'avatarUrls' }
                        @{ converter = 'ConvertTo-JiraProject'; property = 'Roles'; sourceProperty = 'roles' }
                        @{ converter = 'ConvertTo-JiraTransition'; property = 'ResultStatus'; sourceProperty = 'to' }
                        @{ converter = 'ConvertTo-JiraIssueHistoryEntry'; property = 'Author'; sourceProperty = 'author' }
                        @{ converter = 'ConvertTo-JiraProject'; property = 'Lead'; sourceProperty = 'lead' }
                        @{ converter = 'ConvertTo-JiraFilterSubscription'; property = 'User'; sourceProperty = 'user' }
                        @{ converter = 'ConvertTo-JiraFilterSubscription'; property = 'Group'; sourceProperty = 'group' }
                        @{ converter = 'ConvertTo-JiraRoleActor'; property = 'ActorUser'; sourceProperty = 'actorUser' }
                        @{ converter = 'ConvertTo-JiraRoleActor'; property = 'ActorGroup'; sourceProperty = 'actorGroup' }
                    )) {
                    foreach ($shape in 'omitted', 'explicit null') {
                        $testCase = $case.Clone()
                        $testCase.shape = $shape
                        $testCase
                    }
                }
            ) {
                param($converter, $property, $sourceProperty, $shape)
                $inputObject = [PSCustomObject]@{}
                if ($shape -eq 'explicit null') { $inputObject | Add-Member -NotePropertyName $sourceProperty -NotePropertyValue $null }

                $result = @(& $converter -InputObject $inputObject)
                $result.Count | Should -Be 1
                ($null -eq $result[0].$property) | Should -BeTrue
            }
        }

        Context 'Schemas on containing objects' {
            It '<converter> keeps an <shape> schema null' -TestCases @(
                foreach ($converter in 'ConvertTo-JiraCreateMetaField', 'ConvertTo-JiraEditMetaField', 'ConvertTo-JiraField') {
                    @{ converter = $converter; shape = 'omitted' }
                    @{ converter = $converter; shape = 'explicit null' }
                }
            ) {
                param($converter, $shape)
                $field = [PSCustomObject]@{ fieldId = 'summary'; id = 'summary'; name = 'Summary' }
                if ($shape -eq 'explicit null') { $field | Add-Member -NotePropertyName schema -NotePropertyValue $null }
                $response = if ($converter -eq 'ConvertTo-JiraEditMetaField') {
                    [PSCustomObject]@{ fields = [PSCustomObject]@{ summary = $field } }
                }
                else { $field }

                $result = @(& $converter -InputObject $response)
                $result.Count | Should -Be 1
                ($null -eq $result[0].Schema) | Should -BeTrue
            }

            It '<converter> retains a typed schema for <shape> input' -TestCases @(
                foreach ($converter in 'ConvertTo-JiraCreateMetaField', 'ConvertTo-JiraEditMetaField', 'ConvertTo-JiraField') {
                    @{ converter = $converter; shape = 'empty' }
                    @{ converter = $converter; shape = 'populated' }
                    @{ converter = $converter; shape = 'already typed' }
                }
            ) {
                param($converter, $shape)
                $schema = switch ($shape) {
                    'empty' { [PSCustomObject]@{} }
                    'populated' { [PSCustomObject]@{ type = 'string'; system = 'summary' } }
                    'already typed' { [AtlassianPS.JiraPS.FieldSchema]@{ Type = 'string'; System = 'summary' } }
                }
                $field = [PSCustomObject]@{
                    fieldId = 'summary'
                    id      = 'summary'
                    name    = 'Summary'
                    schema  = $schema
                }
                $response = if ($converter -eq 'ConvertTo-JiraEditMetaField') {
                    [PSCustomObject]@{ fields = [PSCustomObject]@{ summary = $field } }
                }
                else { $field }

                $result = @(& $converter -InputObject $response)
                $result.Count | Should -Be 1
                $result[0].Schema.GetType() | Should -Be ([AtlassianPS.JiraPS.FieldSchema])
                if ($shape -eq 'empty') { $result[0].Schema.Type | Should -BeExactly ([string]::Empty) }
                else {
                    $result[0].Schema.Type | Should -Be 'string'
                    $result[0].Schema.System | Should -Be 'summary'
                }
            }
        }
    }
}
