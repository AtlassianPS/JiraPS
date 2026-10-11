#requires -modules @{ ModuleName = "Pester"; ModuleVersion = "6.2.0"; MaximumVersion = "6.999" }

BeforeDiscovery {
    . "$PSScriptRoot/../../Helpers/TestTools.ps1"

    $script:moduleToTest = Initialize-TestEnvironment
}

InModuleScope JiraPS {
    Describe "ConvertTo-JiraEnum" -Tag 'Unit' {
        It 'maps Jira wire value <value> to <expected>' -TestCases @(
            @{
                value    = 'atlassian-user-role-actor'
                expected = [AtlassianPS.JiraPS.ActorType]::AtlassianUserRoleActor
            }
            @{
                value    = 'atlassian-group-role-actor'
                expected = [AtlassianPS.JiraPS.ActorType]::AtlassianGroupRoleActor
            }
            @{
                value    = 'projectRole'
                expected = [AtlassianPS.JiraPS.FilterShareType]::ROLE
            }
            @{
                value    = 'ATLASSIAN-USER-ROLE-ACTOR'
                expected = [AtlassianPS.JiraPS.ActorType]::AtlassianUserRoleActor
            }
            @{
                value    = 'ATLASSIAN-GROUP-ROLE-ACTOR'
                expected = [AtlassianPS.JiraPS.ActorType]::AtlassianGroupRoleActor
            }
            @{
                value    = 'PROJECTROLE'
                expected = [AtlassianPS.JiraPS.FilterShareType]::ROLE
            }
        ) {
            param($value, $expected)
            $actual = ConvertTo-JiraEnum -Type $expected.GetType() -Value $value
            $actual | Should -BeOfType $expected.GetType()
            $actual | Should -Be $expected
        }

        It 'defines the known <name> values and maps every member' -TestCases @(
            @{
                name    = 'DeploymentType'
                members = @('Cloud', 'Server', 'DataCenter')
            }
            @{
                name    = 'AccountType'
                members = @('atlassian', 'app', 'customer')
            }
            @{
                name    = 'AssigneeType'
                members = @('PROJECT_DEFAULT', 'COMPONENT_LEAD', 'PROJECT_LEAD', 'UNASSIGNED')
            }
            @{
                name    = 'FilterShareType'
                members = @('GLOBAL', 'LOGGEDIN', 'PROJECT', 'GROUP', 'ROLE', 'AUTHENTICATED', 'USER')
            }
            @{
                name    = 'ActorType'
                members = @('AtlassianUserRoleActor', 'AtlassianGroupRoleActor')
            }
        ) {
            param($name, $members)
            $enum = "AtlassianPS.JiraPS.$name" -as [type]
            [Enum]::GetNames($enum) | Should -Be $members
            foreach ($member in $members) {
                (ConvertTo-JiraEnum -Type $enum -Value $member).ToString() | Should -Be $member
            }
            ConvertTo-JiraEnum -Type $enum -Value $null | Should -BeNullOrEmpty
            ConvertTo-JiraEnum -Type $enum -Value 'future' | Should -BeNullOrEmpty
            ConvertTo-JiraEnum -Type $enum -Value '0' | Should -BeNullOrEmpty
        }
    }
}
