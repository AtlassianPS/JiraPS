#requires -modules @{ ModuleName = "Pester"; ModuleVersion = "6.2.0"; MaximumVersion = "6.999" }

BeforeDiscovery {
    . "$PSScriptRoot/../../Helpers/TestTools.ps1"

    $script:moduleToTest = Initialize-TestEnvironment
}

InModuleScope JiraPS {
    Describe 'Connect-Jira' -Tag Unit {
        BeforeAll {
            . "$PSScriptRoot/../../Helpers/TestTools.ps1"

            $script:moduleToTest = Initialize-TestEnvironment
        }

        BeforeEach {
            $script:previousDefault = Get-JiraConnection -Default
            Mock Invoke-JiraMethod {
                if ($Uri -eq '/rest/api/2/serverInfo') {
                    return [PSCustomObject]@{
                        version        = '11.0'
                        deploymentType = 'Server'
                    }
                }
                if ($Uri -eq '/rest/api/2/myself') { return [PSCustomObject]@{ name = 'validated-user' } }
                throw 'Unexpected validation request.'
            }
        }

        AfterEach {
            Get-JiraConnection | Where-Object Name -Like 'contract-*' | Disconnect-Jira
            if ($script:previousDefault -and $script:previousDefault.State -eq 'Active') {
                $script:previousDefault | Select-JiraConnection | Out-Null
            }
        }

        It 'validates the product and identity before registering and preserves the default' {
            $first = Connect-Jira -Name contract-first -Uri https://jira.example.com -PersonalAccessToken first
            $second = Connect-Jira -Name contract-second -Uri https://jira.example.com -PersonalAccessToken second -Default

            $first | Should -BeOfType ([AtlassianPS.Connection])
            $first.Username | Should -Be 'validated-user'
            (Get-JiraConnection -Default).InstanceId | Should -Be $second.InstanceId
            $first.GetAuthorizationHeader() | Should -Be 'Bearer first'
            $second.GetAuthorizationHeader() | Should -Be 'Bearer second'
        }

        It 'uses only the profile endpoint and explicitly supplied authentication' {
            Add-AtlassianServerConfiguration -Name contract-saved -Type Jira -Uri https://jira.example.com/jira
            $profile = Get-AtlassianServerConfiguration -Name contract-saved
            $certificate = [System.Security.Cryptography.X509Certificates.X509Certificate]::new()

            try {
                $profile.Headers = @{ Authorization = 'stored-header' }
                $profile.Certificate = $certificate
                $profile.Session = [Microsoft.PowerShell.Commands.WebRequestSession]::new()
                $profile.Session.Headers['Authorization'] = 'stored-session'

                $connection = Connect-Jira -Name contract-profile -Profile contract-saved -PersonalAccessToken supplied-token

                $connection.BaseUri.AbsoluteUri | Should -Be 'https://jira.example.com/jira'
                $connection.GetAuthorizationHeader() | Should -Be 'Bearer supplied-token'
                $connection.Username | Should -Be 'validated-user'
            }
            finally {
                Remove-AtlassianServerConfiguration -Name contract-saved -Confirm:$false
                $certificate.Dispose()
            }
        }

        It 'does not register or change defaults after anonymous metadata with failed identity validation' {
            Mock Invoke-JiraMethod {
                [PSCustomObject]@{
                    version        = '11.0'
                    deploymentType = 'Server'
                }
            }
            $before = (Get-JiraConnection -Default).InstanceId

            { Connect-Jira -Name contract-invalid -Uri https://jira.example.com -PersonalAccessToken sentinel -Default } | Should -Throw '*identity*'
            Get-JiraConnection -Name contract-invalid | Should -BeNullOrEmpty
            (Get-JiraConnection -Default).InstanceId | Should -Be $before
        }

        It 'preserves metadata transport failures without registering a connection' {
            Mock Invoke-JiraMethod { Write-Error 'Metadata transport failed.' }
            $before = (Get-JiraConnection -Default).InstanceId

            { Connect-Jira -Name contract-transport -Uri https://jira.example.com -Anonymous } | Should -Throw '*Metadata transport failed*'

            Get-JiraConnection -Name contract-transport | Should -BeNullOrEmpty
            (Get-JiraConnection -Default).InstanceId | Should -Be $before
        }

        It 'rejects invalid authentication before HTTP' {
            { Connect-Jira -Name contract-invalid -Uri https://jira.example.com -PersonalAccessToken '' } | Should -Throw
            { Connect-Jira -Name contract-invalid -Uri https://jira.example.com -ApiToken token } | Should -Throw
            { Connect-Jira -Name contract-invalid -Uri https://jira.example.com -Anonymous -PersonalAccessToken token } | Should -Throw
            Should -Invoke Invoke-JiraMethod -Times 0 -Exactly
        }

        It 'rejects wrong-product metadata before registration' {
            Mock Invoke-JiraMethod { [PSCustomObject]@{ product = 'Confluence' } }

            { Connect-Jira -Name contract-invalid -Uri https://jira.example.com -Anonymous } | Should -Throw '*Jira server information*'
        }
    }

    Describe 'Connect-Jira request paths' -Tag Unit {
        BeforeAll {
            . "$PSScriptRoot/../../Helpers/TestTools.ps1"

            function script:New-ReviewWebResponse {
                param([String]$Json)

                [PSCustomObject]@{
                    StatusCode       = [System.Net.HttpStatusCode]::OK
                    Content          = $Json
                    RawContentStream = [IO.MemoryStream]::new([Text.Encoding]::UTF8.GetBytes($Json))
                    Headers          = @{}
                }
            }
        }

        BeforeEach {
            $script:previousDefault = Get-JiraConnection -Default
        }

        AfterEach {
            Get-JiraConnection | Where-Object Name -Like 'review-*' | Disconnect-Jira
            if ($previousDefault -and $previousDefault.State -eq 'Active') {
                $previousDefault | Select-JiraConnection | Out-Null
            }
        }

        It 'preserves a transport failure from the HTTP boundary without registering a connection' {
            Mock Invoke-WebRequest { throw [System.Net.WebException]::new('Connection refused sentinel') }

            { Connect-Jira -Name review-transport -Uri https://jira.example.com -Anonymous } |
                Should -Throw -ExpectedMessage '*Connection refused sentinel*'

            Get-JiraConnection -Name review-transport | Should -BeNullOrEmpty
            (Get-JiraConnection -Default).InstanceId | Should -Be $previousDefault.InstanceId
            Should -Invoke Invoke-WebRequest -Exactly 1
        }

        It 'uses returned site resource links through the explicitly selected Cloud gateway' {
            Mock Invoke-WebRequest {
                switch ($Uri.AbsolutePath) {
                    '/ex/jira/11111111-1111-1111-1111-111111111111/rest/api/2/serverInfo' {
                        New-ReviewWebResponse '{"version":"11.0","deploymentType":"Cloud","baseUrl":"https://site.atlassian.net"}'
                    }
                    '/ex/jira/11111111-1111-1111-1111-111111111111/rest/api/2/myself' {
                        New-ReviewWebResponse '{"accountId":"review-account"}'
                    }
                    '/ex/jira/11111111-1111-1111-1111-111111111111/rest/api/2/issue/TEST-1' {
                        New-ReviewWebResponse '{"id":"1","key":"TEST-1","self":"https://site.atlassian.net/rest/api/2/issue/1","fields":{"summary":"Test"}}'
                    }
                    '/ex/jira/11111111-1111-1111-1111-111111111111/rest/api/2/issue/1/comment' {
                        New-ReviewWebResponse '{"startAt":0,"maxResults":50,"total":1,"comments":[{"id":"2","body":"Review comment"}]}'
                    }
                    default { throw "Unexpected request: $($Uri.AbsolutePath)" }
                }
            }

            $connection = Connect-Jira -Name review-gateway -Uri https://api.atlassian.com/ex/jira/11111111-1111-1111-1111-111111111111 -EmailAddress identity@example.com -ApiToken test-token
            $comments = @(Get-JiraIssueComment -Issue TEST-1 -Connection $connection)

            $connection.SiteUri.AbsoluteUri | Should -Be 'https://site.atlassian.net/'
            $comments.Count | Should -Be 1
            $comments[0].Body | Should -Be 'Review comment'
            Should -Invoke Invoke-WebRequest -Exactly 4 -ParameterFilter {
                $Uri.Host -eq 'api.atlassian.com' -and
                $Uri.AbsolutePath.StartsWith('/ex/jira/11111111-1111-1111-1111-111111111111/')
            }
            Should -Invoke Invoke-WebRequest -Exactly 0 -ParameterFilter { $Uri.Host -ne 'api.atlassian.com' }
        }

        It 'rejects an invalid site origin in explicit gateway metadata: <BaseUrl>' -ForEach @(
            @{ BaseUrl = 'http://site.atlassian.net' }
            @{ BaseUrl = 'https://foreign.example.com' }
            @{ BaseUrl = 'https://site.atlassian.net/path' }
            @{ BaseUrl = 'https://site.atlassian.net?token=value' }
        ) {
            Mock Invoke-WebRequest {
                New-ReviewWebResponse (@{
                        version        = '11.0'
                        deploymentType = 'Cloud'
                        baseUrl        = $BaseUrl
                    } | ConvertTo-Json -Compress)
            }

            { Connect-Jira -Name review-invalid -Uri https://api.atlassian.com/ex/jira/11111111-1111-1111-1111-111111111111 -Anonymous } |
                Should -Throw -ExpectedMessage '*baseUrl*'

            Get-JiraConnection -Name review-invalid | Should -BeNullOrEmpty
            (Get-JiraConnection -Default).InstanceId | Should -Be $previousDefault.InstanceId
            Should -Invoke Invoke-WebRequest -Exactly 1
        }
    }
}
