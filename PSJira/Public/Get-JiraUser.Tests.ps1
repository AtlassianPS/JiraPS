$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$sut = (Split-Path -Leaf $MyInvocation.MyCommand.Path).Replace(".Tests.", ".")
. "$here\$sut"

InModuleScope PSJira {

    $ShowMockData = $false
    $ShowDebugText = $false

    Describe "Get-JiraUser" {
        if ($ShowDebugText)
        {
            Mock "Write-Debug" {
                Write-Host "       [DEBUG] $Message" -ForegroundColor Yellow
            }
            Mock "Write-Verbose" {
                Write-Host "       [VERBOSE] $Message" -ForegroundColor Cyan
            }
        }

        Mock Get-JiraConfigServer {
            'https://jira.example.com'
        }

        # If we don't override this in a context or test, we don't want it to
        # actually try to query a JIRA instance
        Mock Invoke-JiraMethod {
            if ($ShowMockData)
            {
                Write-Host "Mocked Invoke-JiraMethod"
                Write-Host "  URI: [$URI]"
                Write-Host "  Method: [$Method]"
            }
        }

        Mock ConvertTo-JiraUser { $true }

        Context "Sanity checking" {
            $command = Get-Command -Name Get-JiraUser

            function defParam($name)
            {
                It "Has a -$name parameter" {
                    $command.Parameters.Item($name) | Should Not BeNullOrEmpty
                }
            }

            defParam 'UserName'
            defParam 'InputObject'
            defParam 'AlwaysSearch'
            defParam 'IncludeInactive'
            defParam 'Credential'
        }

        Context "Behavior testing - exact username exists" {
            Mock Invoke-JiraMethod { $true }

            $output = Get-JiraUser -UserName 'tom'
            It "Returns a user if the exact username exists" {
                Assert-MockCalled -CommandName Invoke-JiraMethod -Scope Context -Exactly -Times 1 -ParameterFilter {$Method -eq 'Get' -and $URI -like '*rest/api/latest/user?username=tom&expand=groups'}
            }

            It "Does not search for a user if the exact username was found" {
                Assert-MockCalled -CommandName Invoke-JiraMethod -Scope Context -Exactly -Times 0 -ParameterFilter {$Method -eq 'Get' -and $URI -like '*rest/api/latest/user/search?*' }
            }
        }

        Context "Behavior testing - exact username does not exist" {
            Mock Invoke-JiraMethod -ParameterFilter {$URI -like '*search?username=tom*'} {
                if ($ShowMockData)
                {
                    Write-Host "Mocked Invoke-JiraMethod"
                    Write-Host "  URI: [$URI]"
                    Write-Host "  Method: [$Method]"
                }

                # Next call to Invoke-JiraMethod relies on this returning real data
                [PSCustomObject] @{
                    self = "https://jira.example.com/rest/api/latest/user?username=tom"
                }
            }

            $output = Get-JiraUser -UserName 'tom'
            It "Searches for a user if the exact name does not exist" {
                # "Get" should be called once for the initial search and once to get full details on the user
                Assert-MockCalled -CommandName Invoke-JiraMethod -Scope Context -Exactly -Times 2 -ParameterFilter {$Method -eq 'Get' -and $URI -like '*rest/api/latest/user?username=tom&expand=groups'}

                # "Search" should only be called once
                Assert-MockCalled -CommandName Invoke-JiraMethod -Scope Context -Exactly -Times 1 -ParameterFilter {$Method -eq 'Get' -and $URI -like '*rest/api/latest/user/search?*' }
            }
        }
    }
}
