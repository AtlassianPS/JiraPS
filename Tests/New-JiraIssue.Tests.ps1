. $PSScriptRoot\Shared.ps1

InModuleScope PSJira {

    [System.Diagnostics.CodeAnalysis.SuppressMessage('PSUseDeclaredVarsMoreThanAssigments', '', Scope='*', Target='SuppressImportModule')]
    $SuppressImportModule = $true
    . $PSScriptRoot\Shared.ps1

    Describe "New-JiraIssue" {
        if ($ShowDebugText)
        {
            Mock "Write-Debug" {
                Write-Host "       [DEBUG] $Message" -ForegroundColor Yellow
            }
        }

        Mock Get-JiraConfigServer {
            'https://jira.example.com'
        }

        # If we don't override this in a context or test, we don't want it to
        # actually try to query a JIRA instance
        Mock Invoke-JiraMethod {}

        Mock Get-JiraProject {
            [PSCustomObject] @{
                'ID'=$Project;
            }
        }

        Mock Get-JiraIssueType {
            [PSCustomObject] @{
                'ID'=$IssueType;
            }
        }

        Mock Get-JiraUser {
            [PSCustomObject] @{
                'Name'=$UserName;
            }
        }

        # This one needs to be able to output multiple objects
        Mock Get-JiraField {
            $Field | % {
                [PSCustomObject] @{
                    'ID'=$_;
                }
            }
        }

        $newParams = @{
            'Project'     = 'TEST';
            'IssueType'   = 1;
            'Priority'    = 1;
            'Reporter'    = 'testUsername';
            'Summary'     = 'Test summary';
            'Description' = 'Test description';
        }

        Context "Sanity checking" {
            $command = Get-Command -Name New-JiraIssue

            function defParam($name)
            {
                It "Has a -$name parameter" {
                    $command.Parameters.Item($name) | Should Not BeNullOrEmpty
                }
            }

            defParam 'Project'
            defParam 'IssueType'
            defParam 'Priority'
            defParam 'Summary'
            defParam 'Description'
            defParam 'Reporter'
            defParam 'Labels'
            defParam 'Fields'
            defParam 'Credential'
        }

        Context "Behavior testing" {
            Mock Invoke-JiraMethod {
                if ($ShowMockData)
                {
                    Write-Host "       Mocked Invoke-JiraMethod" -ForegroundColor Cyan
                    Write-Host "         [Uri]     $Uri" -ForegroundColor Cyan
                    Write-Host "         [Method]  $Method" -ForegroundColor Cyan
                    Write-Host "         [Body]    $Body" -ForegroundColor Cyan
                }
            }

            It "Creates an issue in JIRA" {
                { New-JiraIssue @newParams } | Should Not Throw
                # The String in the ParameterFilter is made from the keywords
                # we should expect to see in the JSON that should be sent,
                # including the summary provided in the test call above.
                Assert-MockCalled -CommandName Invoke-JiraMethod -ModuleName PSJira -Times 1 -Scope It -ParameterFilter { $Method -eq 'Post' -and $URI -like '*/rest/api/*/issue' }
            }
        }

        Context "Input testing" {
            It "Checks to make sure all required fields are provided" {
                # We'll create a custom field that's required, then see what happens when we don't provide it
                Mock Get-JiraIssueCreateMetadata {
                    @(
                        @{Name='Project';     ID='Project';     Required=$true},
                        @{Name='IssueType';   ID='IssueType';   Required=$true},
                        @{Name='Priority';    ID='Priority';    Required=$true},
                        @{Name='Summary';     ID='Summary';     Required=$true},
                        @{Name='Description'; ID='Description'; Required=$true},
                        @{Name='Reporter';    ID='Reporter';    Required=$true},
                        @{Name='CustomField'; ID='CustomField'; Required=$true}
                    )
                }

                { New-JiraIssue @newParams } | Should Throw
                { New-JiraIssue @newParams -Fields @{CustomField='.'} } | Should Not Throw
            }
        }
    }
}
