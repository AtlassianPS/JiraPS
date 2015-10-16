$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$sut = (Split-Path -Leaf $MyInvocation.MyCommand.Path).Replace(".Tests.", ".")
. "$here\$sut"

InModuleScope PSJira {

    $ShowMockData = $false
    $ShowDebugText = $false

    Describe 'Get-JiraFilter' {
        if ($ShowDebugText)
        {
            Mock 'Write-Debug' {
                Write-Host "       [DEBUG] $Message" -ForegroundColor Yellow
            }
        }

        Mock Get-JiraConfigServer {
            'https://jira.example.com'
        }

        # If we don't override this in a context or test, we don't want it to
        # actually try to query a JIRA instance
        Mock Invoke-JiraMethod -ModuleName PSJira {
            if ($ShowMockData)
            {
                Write-Host "       Mocked Invoke-WebRequest" -ForegroundColor Cyan
                Write-Host "         [Uri]     $Uri" -ForegroundColor Cyan
                Write-Host "         [Method]  $Method" -ForegroundColor Cyan
            }
        }

        Context "Sanity checking" {
            $command = Get-Command -Name Get-JiraFilter

            function defParam($name)
            {
                It "Has a -$name parameter" {
                    $command.Parameters.Item($name) | Should Not BeNullOrEmpty
                }
            }

            defParam 'Id'
            defParam 'Credential'
        }

        Context "Behavior testing" {
            It "Queries JIRA for a filter with a given ID" {
                { Get-JiraFilter -Id 12345 } | Should Not Throw
                Assert-MockCalled -CommandName Invoke-JiraMethod -ModuleName PSJira -Exactly -Times 1 -Scope It -ParameterFilter {$Method -eq 'Get' -and $URI -like '*/rest/api/*/filter/12345'}
            }

            It "Uses ConvertTo-JiraFilter to output a Filter object if JIRA returns data" {
                Mock Invoke-JiraMethod -ModuleName PSJira { $true }
                Mock ConvertTo-JiraFilter -ModuleName PSJira {}
                { Get-JiraFilter -Id 12345 } | Should Not Throw
                Assert-MockCalled -CommandName ConvertTo-JiraFilter -ModuleName PSJira
            }
        }

        Context "Input testing" {
            It "Accepts a filter ID for the -Filter parameter" {
                { Get-JiraFilter -Id 12345 } | Should Not Throw
                Assert-MockCalled -CommandName Invoke-JiraMethod -ModuleName PSJira -Exactly -Times 1 -Scope It
            }

            It "Accepts multiple filter IDs to the -Filter parameter" {
                { Get-JiraFilter -Id '12345','67890' } | Should Not Throw
                Assert-MockCalled -CommandName Invoke-JiraMethod -ModuleName PSJira -Exactly -Times 1 -Scope It -ParameterFilter {$Method -eq 'Get' -and $URI -like '*/rest/api/*/filter/12345'}
                Assert-MockCalled -CommandName Invoke-JiraMethod -ModuleName PSJira -Exactly -Times 1 -Scope It -ParameterFilter {$Method -eq 'Get' -and $URI -like '*/rest/api/*/filter/67890'}
            }
        }
    }
}