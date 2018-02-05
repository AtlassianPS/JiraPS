Describe "Remove-JiraGroup" {

    Import-Module "$PSScriptRoot/../JiraPS" -Force -ErrorAction Stop

    InModuleScope JiraPS {

        . "$PSScriptRoot/Shared.ps1"

        $jiraServer = 'http://jiraserver.example.com'

        $testGroupName = 'testGroup'

        $testJson = @"
{
    "name": "$testGroupName",
    "self": "$jiraServer/rest/api/2/group?groupname=$testGroupName",
    "users": {
        "size": 0,
        "items": [],
        "max-results": 50,
        "start-index": 0,
        "end-index": 0
    },
    "expand": "users"
}
"@

        Mock Get-JiraConfigServer -ModuleName JiraPS {
            Write-Output $jiraServer
        }

        Mock Get-JiraGroup -ModuleName JiraPS {
            $object = ConvertFrom-Json2 $testJson
            $object.PSObject.TypeNames.Insert(0, 'JiraPS.Group')
            return $object
        }

        Mock Invoke-JiraMethod -ModuleName JiraPS -ParameterFilter {$Method -eq 'DELETE' -and $URI -like "$jiraServer/rest/api/*/group?groupname=$testGroupName"} {
            ShowMockInfo 'Invoke-JiraMethod' 'Method', 'Uri'
            # This REST method should produce no output
        }

        # Generic catch-all. This will throw an exception if we forgot to mock something.
        Mock Invoke-JiraMethod -ModuleName JiraPS {
            ShowMockInfo 'Invoke-JiraMethod' 'Method', 'Uri'
            throw "Unidentified call to Invoke-JiraMethod"
        }

        #############
        # Tests
        #############

        It "Accepts a group name as a String to the -Group parameter" {
            { Remove-JiraGroup -Group $testGroupName -Force } | Should Not Throw
            Assert-MockCalled -CommandName Invoke-JiraMethod -Exactly -Times 1 -Scope It
        }

        It "Accepts a JiraPS.Group object to the -Group parameter" {
            $group = Get-JiraGroup -GroupName $testGroupName
            { Remove-JiraGroup -Group $group -Force } | Should Not Throw
            Assert-MockCalled -CommandName Invoke-JiraMethod -Exactly -Times 1 -Scope It
        }

        It "Accepts pipeline input from Get-JiraGroup" {
            { Get-JiraGroup -GroupName $testGroupName | Remove-JiraGroup -Force } | Should Not Throw
            Assert-MockCalled -CommandName Invoke-JiraMethod -Exactly -Times 1 -Scope It
        }

        It "Removes a group from JIRA" {
            { Remove-JiraGroup -Group $testGroupName -Force } | Should Not Throw
            Assert-MockCalled -CommandName Invoke-JiraMethod -Exactly -Times 1 -Scope It
        }

        It "Provides no output" {
            Remove-JiraGroup -Group $testGroupName -Force | Should BeNullOrEmpty
        }
    }
}
