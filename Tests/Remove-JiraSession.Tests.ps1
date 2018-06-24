Describe "Remove-JiraSession" {
    BeforeAll {
        Remove-Module JiraPS -ErrorAction SilentlyContinue
        Import-Module "$PSScriptRoot/../JiraPS" -Force -ErrorAction Stop
    }

    . "$PSScriptRoot/Shared.ps1"

    #region Mocks
    Mock Get-JiraSession -ModuleName JiraPS {
        (Get-Module JiraPS).PrivateData.Session
    }
    #endregion Mocks

    Context "Sanity checking" {
        $command = Get-Command -Name Remove-JiraSession

        defParam $command 'Session'
    }

    Context "Behavior testing" {
        It "Closes a removes the JiraPS.Session data from module PrivateData" {
            (Get-Module JiraPS).PrivateData = @{ Session = $true }
            (Get-Module JiraPS).PrivateData.Session | Should -Not -BeNullOrEmpty

            Remove-JiraSession

            (Get-Module JiraPS).PrivateData.Session | Should -BeNullOrEmpty
        }
    }
}
