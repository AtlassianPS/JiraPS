#requires -modules @{ ModuleName = "Pester"; ModuleVersion = "6.2.0"; MaximumVersion = "6.999" }

BeforeDiscovery {
    . "$PSScriptRoot/../../Helpers/TestTools.ps1"
    Initialize-TestEnvironment
}

InModuleScope JiraPS {
    Describe 'ConvertTo-JiraEnum' -Tag Unit {
        It 'defines the known <name> values and maps every member' -TestCases @(
            @{ name = 'DeploymentType'; members = @('Cloud', 'Server', 'DataCenter') }
            @{ name = 'AccountType'; members = @('atlassian', 'app', 'customer') }
            @{ name = 'AssigneeType'; members = @('PROJECT_DEFAULT', 'COMPONENT_LEAD', 'PROJECT_LEAD', 'UNASSIGNED') }
            @{ name = 'FilterShareType'; members = @('GLOBAL', 'LOGGEDIN', 'PROJECT', 'GROUP', 'ROLE', 'AUTHENTICATED', 'USER') }
            @{ name = 'ActorType'; members = @('AtlassianUserRoleActor', 'AtlassianGroupRoleActor') }
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
