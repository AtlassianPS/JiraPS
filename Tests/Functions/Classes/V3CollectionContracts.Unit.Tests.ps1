#requires -modules @{ ModuleName = "Pester"; ModuleVersion = "6.2.0"; MaximumVersion = "6.999" }

BeforeDiscovery {
    . "$PSScriptRoot/../../Helpers/TestTools.ps1"
    $script:moduleToTest = Initialize-TestEnvironment
}

InModuleScope JiraPS {
    Describe 'v3 collection and selector regressions' -Tag Unit {
        It 'keeps present empty project collections typed' {
            $project = ConvertTo-JiraProject -InputObject (ConvertFrom-Json '{"issueTypes":[],"components":[],"versions":[]}')
            $project.IssueTypes.GetType() | Should -Be ([AtlassianPS.JiraPS.IssueType[]])
            $project.Components.GetType() | Should -Be ([AtlassianPS.JiraPS.Component[]])
            $project.Versions.GetType() | Should -Be ([AtlassianPS.JiraPS.Version[]])
            $project.IssueTypes.Count | Should -Be 0
            $project.Components.Count | Should -Be 0
            $project.Versions.Count | Should -Be 0
        }

        It 'keeps present empty comment properties typed' {
            $comment = ConvertTo-JiraComment -InputObject (ConvertFrom-Json '{"properties":[]}')
            $comment.Properties.GetType() | Should -Be ([AtlassianPS.JiraPS.EntityProperty[]])
            $comment.Properties.Count | Should -Be 0
        }

        It 'keeps present empty filter permissions typed' {
            $filter = ConvertTo-JiraFilter -InputObject (ConvertFrom-Json '{"sharePermissions":[]}')
            $filter.SharePermission.GetType() | Should -Be ([AtlassianPS.JiraPS.FilterPermission[]])
            $filter.SharePermission.Count | Should -Be 0
        }

        It 'keeps present empty group members typed' {
            $group = ConvertTo-JiraGroup -InputObject (ConvertFrom-Json '{"users":{"size":0,"items":[]}}')
            $group.Member.GetType() | Should -Be ([AtlassianPS.JiraPS.User[]])
            $group.Member.Count | Should -Be 0
        }

        It 'distinguishes absent operations from present empty allowed values' {
            $meta = ConvertTo-JiraCreateMetaField -InputObject (ConvertFrom-Json '{"allowedValues":[]}')
            $meta.Operations | Should -BeNullOrEmpty
            $meta.AllowedValues.GetType() | Should -Be ([object[]])
            $meta.AllowedValues.Count | Should -Be 0
        }

        It 'selects returned objects by ID when display names are duplicated' {
            Mock Invoke-JiraMethod {
                if ($Uri -like '*/field') {
                    ConvertFrom-Json '[{"id":"customfield_1","name":"Duplicate"},{"id":"customfield_2","name":"Duplicate"}]'
                }
                elseif ($Uri -like '*/issuetype') { ConvertFrom-Json '[{"id":"1","name":"Bug"},{"id":"2","name":"Bug"}]' }
            }
            $fields = @(Get-JiraField -Field ([AtlassianPS.JiraPS.Field]@{ Id = 'customfield_1'; Name = 'Duplicate' }))
            $fields.Count | Should -Be 1
            $fields[0].Id | Should -Be 'customfield_1'
            $types = @(Get-JiraIssueType -IssueType ([AtlassianPS.JiraPS.IssueType]@{ Id = 1; Name = 'Bug' }))
            $types.Count | Should -Be 1
            $types[0].Id | Should -Be 1
            @(Get-JiraField -Field 'Dupli*').Count | Should -Be 2
            @(Get-JiraIssueType -IssueType 'B*').Count | Should -Be 2
        }
    }
}
