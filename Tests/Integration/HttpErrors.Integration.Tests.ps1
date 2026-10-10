#requires -modules @{ ModuleName = "Pester"; ModuleVersion = "6.2.0"; MaximumVersion = "6.999" }

BeforeDiscovery {
    . "$PSScriptRoot/../Helpers/TestTools.ps1"
    . "$PSScriptRoot/../Helpers/IntegrationTestTools.ps1"

    $script:moduleToTest = Initialize-TestEnvironment
    $script:Skip = Skip-IntegrationTest
}

InModuleScope JiraPS {
    Describe "HTTP Errors" -Tag 'Integration', 'Smoke', 'Server', 'Cloud' -Skip:$Skip {
        BeforeAll {
            . "$PSScriptRoot/../Helpers/IntegrationTestTools.ps1"

            $script:environment = Initialize-IntegrationEnvironment
            $script:session = Connect-JiraTestServer -Environment $environment
            $script:missingIssueUri = "$($environment.CloudUrl)/rest/api/2/issue/0"
        }

        AfterAll {
            Remove-JiraSession -ErrorAction SilentlyContinue
        }

        It "preserves Jira's message for a missing issue" {
            $actualError = $null
            try {
                $null = Invoke-JiraMethod -Uri $missingIssueUri -ErrorAction Stop
            }
            catch {
                $actualError = $_
            }

            $actualError | Should -BeOfType [System.Management.Automation.ErrorRecord]
            $actualError.FullyQualifiedErrorId | Should -BeLike 'InvalidResponse.Status404,*'
            $actualError.CategoryInfo.Category | Should -Be 'InvalidResult'
            $actualError.Exception.Message | Should -Match 'does not exist|permission|not found'
            $actualError.Exception.Message | Should -Not -Match '^\s*(\{|\[)'
        }

        It "captures a real empty HEAD error response" {
            $splat = New-JiraWebRequestSplat -Uri $missingIssueUri -Method Head -Headers $script:DefaultHeaders
            $result = Invoke-JiraWebRequestSafely -SplatParameters $splat

            try {
                $result.Exception | Should -BeOfType [System.Management.Automation.ErrorRecord]
                $result.WebResponse.StatusCode | Should -Be ([System.Net.HttpStatusCode]::NotFound)
                if ($PSVersionTable.PSEdition -eq 'Core') {
                    $result.WebResponse | Should -BeOfType [System.Net.Http.HttpResponseMessage]
                    $result.Exception.ErrorDetails | Should -BeNullOrEmpty
                }
                else {
                    $result.WebResponse | Should -BeOfType [System.Net.HttpWebResponse]
                    $reader = [System.IO.StreamReader]::new($result.WebResponse.GetResponseStream())
                    try {
                        $reader.ReadToEnd() | Should -BeNullOrEmpty
                    }
                    finally {
                        $reader.Dispose()
                    }
                }
            }
            finally {
                if ($result.WebResponse) {
                    $result.WebResponse.Dispose()
                }
            }
        }

        It "reports the HTTP status for an empty HEAD error response" {
            $actualError = $null
            try {
                $null = Invoke-JiraMethod -Uri $missingIssueUri -Method Head -ErrorAction Stop
            }
            catch {
                $actualError = $_
            }

            $actualError | Should -BeOfType [System.Management.Automation.ErrorRecord]
            $actualError.FullyQualifiedErrorId | Should -BeLike 'InvalidResponse.Status404,*'
            $actualError.CategoryInfo.Category | Should -Be 'InvalidResult'
            $actualError.Exception.Message | Should -Be 'Server responded with NotFound'
        }

        It "emits a non-terminating HTTP error for an empty HEAD response" {
            $actualErrors = @(Invoke-JiraMethod -Uri $missingIssueUri -Method Head -ErrorAction Continue 2>&1)

            $actualErrors.Count | Should -Be 1
            $actualErrors[0] | Should -BeOfType [System.Management.Automation.ErrorRecord]
            $actualErrors[0].FullyQualifiedErrorId | Should -BeLike 'InvalidResponse.Status404,*'
            $actualErrors[0].CategoryInfo.Category | Should -Be 'InvalidResult'
            $actualErrors[0].Exception.Message | Should -Be 'Server responded with NotFound'
        }
    }
}
