Describe "New-JiraSession" {
    BeforeAll {
        Remove-Module JiraPS -ErrorAction SilentlyContinue
        Import-Module "$PSScriptRoot/../JiraPS" -Force -ErrorAction Stop
    }
    AfterEach {
        try {
            (Get-Module JiraPS).PrivateData.Remove("Session")
        }
        catch { $null = 0 }
    }

    InModuleScope JiraPS {

        . "$PSScriptRoot/Shared.ps1"

        #region Definitions
        $jiraServer = 'http://jiraserver.example.com'

        $testCredential = [System.Management.Automation.PSCredential]::Empty
        #endregion Definitions

        #region Mocks
        Mock Get-JiraConfigServer -ModuleName JiraPS {
            Write-Output $jiraServer
        }

        Mock ConvertTo-JiraSession -ModuleName JiraPS { }

        Mock Invoke-JiraMethod -ModuleName JiraPS -ParameterFilter {$Method -eq 'Get' -and $Uri -like "*/rest/api/*/mypermissions"} {
            ShowMockInfo 'Invoke-JiraMethod' 'Method', 'Uri'
            New-Object -TypeName Microsoft.PowerShell.Commands.WebRequestSession
        }

        Mock Invoke-JiraMethod -ModuleName JiraPS {
            ShowMockInfo 'Invoke-JiraMethod' 'Method', 'Uri'
            throw "Unidentified call to Invoke-JiraMethod"
        }
        #endregion Mocks

        Context "Sanity checking" {
            $command = Get-Command -Name New-JiraSession

            defParam $command 'Credential'
            defParam $command 'Headers'
        }

        Context "Behavior testing" {
            It "uses Basic Authentication to generate a session" {
                { New-JiraSession -Credential $testCredential } | Should -Not -Throw

                $assertMockCalledSplat = @{
                    CommandName     = 'Invoke-JiraMethod'
                    ModuleName      = 'JiraPS'
                    ParameterFilter = {
                        $Credential -eq $testCredential
                    }
                    Exactly         = $true
                    Times           = 1
                    Scope           = 'It'
                }
                Assert-MockCalled @assertMockCalledSplat
            }

            It "can influence the Headers used in the request" {
                { New-JiraSession -Credential $testCredential -Headers @{ "X-Header" = $true } } | Should -Not -Throw

                $assertMockCalledSplat = @{
                    CommandName     = 'Invoke-JiraMethod'
                    ModuleName      = 'JiraPS'
                    ParameterFilter = {
                        $Headers.ContainsKey("X-Header")
                    }
                    Exactly         = $true
                    Times           = 1
                    Scope           = 'It'
                }
                Assert-MockCalled @assertMockCalledSplat
            }

            It "stores the session variable in the module's PrivateData" {
                (Get-Module JiraPS).PrivateData.Session | Should -BeNullOrEmpty

                New-JiraSession -Credential $testCredential

                (Get-Module JiraPS).PrivateData.Session | Should -Not -BeNullOrEmpty
            }
        }

        Context "Input testing" { }
    }
}
