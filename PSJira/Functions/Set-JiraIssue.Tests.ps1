$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$sut = (Split-Path -Leaf $MyInvocation.MyCommand.Path).Replace(".Tests.", ".")
. "$here\$sut"

InModuleScope PSJira {

    $ShowMockData = $false
    $ShowDebugText = $false
    
    Describe "Set-JiraIssue" {
        if ($ShowDebugText)
        {
            Mock "Write-Debug" {
                Write-Host "       [DEBUG] $Message" -ForegroundColor Yellow
            }
        }

        Mock Get-JiraIssue{
            [PSCustomObject] @{
                'RestURL' = 'https://jira.example.com/rest/api/2/issue/12345'
            }
        }

        # If we don't override this in a context or test, we don't want it to
        # actually try to query a JIRA instance
        Mock Invoke-JiraMethod {}

        Context "Sanity checking" {
            $command = Get-Command -Name Set-JiraIssue

            function defParam($name)
            {
                It "Has a -$name parameter" {
                    $command.Parameters.Item($name) | Should Not BeNullOrEmpty
                }
            }

            defParam 'Issue'
            defParam 'Summary'
            defParam 'Description'
            defParam 'Assignee'
            defParam 'Credential'
            defParam 'PassThru'

            It "Supports the Key alias for the Issue parameter" {
                $command.Parameters.Item('Issue').Aliases | Where-Object -FilterScript {$_ -eq 'Key'} | Should Not BeNullOrEmpty
            }
        }

        Context "Behavior testing" {
            Mock Invoke-JiraMethod {
                if ($ShowMockData)
                {
                    Write-Host "       Mocked Invoke-JiraMethod" -ForegroundColor Cyan
                    Write-Host "         [Uri]     $Uri" -ForegroundColor Cyan
                    Write-Host "         [Method]  $Method" -ForegroundColor Cyan
#                    Write-Host "         [Body]    $Body" -ForegroundColor Cyan
                }
            }

            Mock Get-JiraUser {
                [PSCustomObject] @{
                    'Name' = 'username'
                }
            }

            It "Modifies the summary of an issue if the -Summary parameter is passed" {
                { Set-JiraIssue -Issue TEST-001 -Summary 'New summary' } | Should Not Throw
                # The String in the ParameterFilter is made from the keywords
                # we should expect to see in the JSON that should be sent,
                # including the summary provided in the test call above.
                Assert-MockCalled -CommandName Invoke-JiraMethod -ModuleName PSJira -Times 1 -Scope It -ParameterFilter { $Method -eq 'Put' -and $URI -like '*/rest/api/2/issue/12345' -and $Body -like '*summary*set*New summary*' }
            }

            It "Modifies the description of an issue if the -Description parameter is passed" {
                { Set-JiraIssue -Issue TEST-001 -Description 'New description' } | Should Not Throw
                Assert-MockCalled -CommandName Invoke-JiraMethod -ModuleName PSJira -Times 1 -Scope It -ParameterFilter { $Method -eq 'Put' -and $URI -like '*/rest/api/2/issue/12345' -and $Body -like '*description*set*New description*' }
            }

            It "Modifies the assignee of an issue if -Assignee is passed" {
                { Set-JiraIssue -Issue TEST-001 -Assignee username } | Should Not Throw
                Assert-MockCalled -CommandName Invoke-JiraMethod -ModuleName PSJira -Times 1 -Scope It -ParameterFilter { $Method -eq 'Put' -and $URI -like '*/rest/api/2/issue/12345/assignee' -and $Body -like '*name*username*' }
            }

            It "Unassigns an issue if 'Unassigned' is passed to the -Assignee parameter" {
                { Set-JiraIssue -Issue TEST-001 -Assignee unassigned } | Should Not Throw
                Assert-MockCalled -CommandName Invoke-JiraMethod -ModuleName PSJira -Times 1 -Scope It -ParameterFilter { $Method -eq 'Put' -and $URI -like '*/rest/api/2/issue/12345/assignee' -and $Body -like '*name*""*' }
            }

            It "Calls Invoke-JiraMethod twice if using Assignee and another field" {
                { Set-JiraIssue -Issue TEST-001 -Summary 'New summary' -Assignee username } | Should Not Throw
                Assert-MockCalled -CommandName Invoke-JiraMethod -ModuleName PSJira -Times 1 -Scope It -ParameterFilter { $Method -eq 'Put' -and $URI -like '*/rest/api/2/issue/12345' -and $Body -like '*summary*set*New summary*' }
                Assert-MockCalled -CommandName Invoke-JiraMethod -ModuleName PSJira -Times 1 -Scope It -ParameterFilter { $Method -eq 'Put' -and $URI -like '*/rest/api/2/issue/12345/assignee' -and $Body -like '*name*username*' }
            }
        }

        Context "Input testing" {
            It "Accepts an issue key for the -Issue parameter" {
                { Set-JiraIssue -Issue TEST-001 -Summary 'Test summary - using issue key' } | Should Not Throw
                Assert-MockCalled -CommandName Get-JiraIssue -ModuleName PSJira -Exactly -Times 1 -Scope It
                Assert-MockCalled -CommandName Invoke-JiraMethod -ModuleName PSJira -Exactly -Times 1 -Scope It
            }

            It "Accepts an issue object for the -Issue parameter" {
                $issue = Get-JiraIssue -Key TEST-001
                { Set-JiraIssue -Issue $issue -Summary 'Test summary - Object' } | Should Not Throw
                # Get-JiraIssue is called once explicitly in this test, and a
                # second time by Set-JiraIssue
                Assert-MockCalled -CommandName Get-JiraIssue -ModuleName PSJira -Exactly -Times 2 -Scope It
                Assert-MockCalled -CommandName Invoke-JiraMethod -ModuleName PSJira -Exactly -Times 1 -Scope It
            }

            It "Accepts the output of Get-JiraObject by pipeline for the -Issue paramete" {
                { Get-JiraIssue -Key TEST-001 | Set-JiraIssue -Summary 'Test summary - InputObject pipeline' } | Should Not Throw
                Assert-MockCalled -CommandName Get-JiraIssue -ModuleName PSJira -Exactly -Times 2 -Scope It
                Assert-MockCalled -CommandName Invoke-JiraMethod -ModuleName PSJira -Exactly -Times 1 -Scope It
            }

            It "Throws an exception if an invalid issue is provided" {
                Mock Get-JiraIssue {}
                # We're cheating a bit here and forcing Write-Error to be a
                # terminating error.
                { Set-JiraIssue -Key FAKE -Summary 'Test' -ErrorAction Stop } | Should Throw
            }

            It "Throws an exception if an invalid user is specified for the -Assignee parameter" {
                { Set-JiraIssue -Key TEST-001 -Assignee notReal } | Should Throw
            }
        }
    }
}