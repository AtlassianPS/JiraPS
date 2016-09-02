$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$sut = (Split-Path -Leaf $MyInvocation.MyCommand.Path).Replace(".Tests.", ".")
. "$here\$sut"

InModuleScope PSJira {

    $ShowMockData = $false
    $ShowDebugText = $false

    Describe 'Get-JiraIssueLinkType' {
        Mock Get-JiraConfigServer { 'https://jira.example.com' }

        if ($ShowDebugText)
        {
            Mock 'Write-Debug' {
                Write-Host "[DEBUG] $Message" -ForegroundColor Yellow
            }
        }

        function ShowMockInfo($functionName, [String[]] $params) {
            if ($ShowMockData)
            {
                Write-Host "       Mocked $functionName" -ForegroundColor Cyan
                foreach ($p in $params) {
                    Write-Host "         [$p]  $(Get-Variable -Name $p -ValueOnly)" -ForegroundColor Cyan
                }
            }
        }

        Context "Sanity checking" {
            $command = Get-Command -Name Get-JiraIssueLinkType

            function defParam($name)
            {
                It "Has a -$name parameter" {
                    $command.Parameters.Item($name) | Should Not BeNullOrEmpty
                }
            }

            defParam 'LinkType'
            defParam 'Credential'
        }

        $filterAll = {$Method -eq 'Get' -and $Uri -ceq 'https://jira.example.com/rest/api/latest/issueLinkType'}
        $filterOne = {$Method -eq 'Get' -and $Uri -ceq 'https://jira.example.com/rest/api/latest/issueLinkType/10000'}

        Mock Invoke-JiraMethod -ParameterFilter $filterAll {
            ShowMockInfo 'Invoke-JiraMethod' 'Method','Uri'
            [PSCustomObject] @{
                issueLinkTypes = @(
                    # We don't care what data actually comes back here
                    'foo'
                )
            }
        }

        Mock Invoke-JiraMethod -ParameterFilter $filterOne {
            ShowMockInfo 'Invoke-JiraMethod' 'Method','Uri'
            [PSCustomObject] @{
                issueLinkTypes = @(
                    'bar'
                )
            }
        }

        Mock Invoke-JiraMethod {
            ShowMockInfo 'Invoke-JiraMethod' 'Method','Uri'
            throw "Unhandled call to Invoke-JiraMethod"
        }

        Context "Behavior testing - returning all link types" {

            Mock ConvertTo-JiraIssueLinkType {
                ShowMockInfo 'ConvertTo-JiraIssueLinkType'

                # We also don't care what comes out of here - this function has its own tests
                [PSCustomObject] @{
                    PSTypeName = 'PSJira.IssueLinkType'
                    foo = 'bar'
                }
            }

            $output = Get-JiraIssueLinkType

            It 'Uses Invoke-JiraMethod to communicate with JIRA' {
                Assert-MockCalled -CommandName Invoke-JiraMethod -ParameterFilter $filterAll -Exactly -Times 1 -Scope Context
            }

            It 'Returns all link types if no value is passed to the -LinkType parameter' {
                $output | Should Not BeNullOrEmpty
            }

            It 'Uses the helper method ConvertTo-JiraIssueLinkType to process output' {
                Assert-MockCalled -CommandName ConvertTo-JiraIssueLinkType -ParameterFilter {$InputObject -contains 'foo'} -Exactly -Times 1 -Scope Context
            }

            It 'Outputs PSJira.IssueLinkType objects' {
                $output | Should Not BeNullOrEmpty
                ($output | Get-Member).TypeName | Should Be 'PSJira.IssueLinkType'
                $output.foo | Should Be 'bar'
            }
        }

        Context "Behavior testing - returning one link type" {
            Mock ConvertTo-JiraIssueLinkType {
                ShowMockInfo 'ConvertTo-JiraIssueLinkType'

                # We also don't care what comes out of here - this function has its own tests
                [PSCustomObject] @{
                    PSTypeName = 'PSJira.IssueLinkType'
                    Name = 'myLink'
                    ID   = 5
                }
            }

            It 'Returns a single link type if an ID number is passed to the -LinkType parameter' {
                $output = Get-JiraIssueLinkType -LinkType 10000
                Assert-MockCalled -CommandName Invoke-JiraMethod -ParameterFilter $filterOne -Exactly -Times 1 -Scope It
                $output | Should Not BeNullOrEmpty
                @($output).Count | Should Be 1
            }

            It 'Returns the correct link type it a type name is passed to the -LinkType parameter' {
                $output = Get-JiraIssueLinkType -LinkType 'myLink'
                Assert-MockCalled -CommandName Invoke-JiraMethod -ParameterFilter $filterAll -Exactly -Times 1 -Scope It
                $output | Should Not BeNullOrEmpty
                @($output).Count | Should Be 1
                $output.ID | Should Be 5
            }
        }
    }
}
