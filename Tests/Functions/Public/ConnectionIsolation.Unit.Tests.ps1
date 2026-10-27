#requires -modules @{ ModuleName = "Pester"; ModuleVersion = "6.2.0"; MaximumVersion = "6.999" }

BeforeDiscovery {
    . "$PSScriptRoot/../../Helpers/TestTools.ps1"

    $script:moduleToTest = Initialize-TestEnvironment
}

BeforeAll {
    . "$PSScriptRoot/../../Helpers/TestTools.ps1"

    $script:moduleToTest = Initialize-TestEnvironment
}

InModuleScope JiraPS {
    Describe 'Connection request isolation' -Tag Unit {
        BeforeEach {
            $script:previousDefault = Get-JiraConnection -Default
            $script:requests = [Collections.Generic.List[Object]]::new()
            $script:first = AtlassianPS.Configuration\New-AtlassianConnectionContext -Name isolation-first -Product Jira -BaseUri https://jira.example.com -PersonalAccessToken first-secret
            $script:second = AtlassianPS.Configuration\New-AtlassianConnectionContext -Name isolation-second -Product Jira -BaseUri https://jira.example.com -PersonalAccessToken second-secret
            foreach ($candidate in @($first, $second)) {
                $candidate.SetValidationResult('Server', 'validated-user')
                $null = AtlassianPS.Configuration\Register-AtlassianConnection -Connection $candidate
            }
            Mock Invoke-WebRequest {
                $script:requests.Add([PSCustomObject]@{
                        Uri           = $Uri
                        Session       = $WebSession
                        Authorization = $Headers.Authorization
                    })
                $content = '{"name":"result"}'
                [PSCustomObject]@{
                    StatusCode       = 200
                    Content          = $content
                    RawContentStream = [IO.MemoryStream]::new([Text.Encoding]::UTF8.GetBytes($content))
                    Headers          = @{ 'Content-Type' = 'application/json' }
                }
            }
        }

        AfterEach {
            foreach ($connection in @($first, $second)) {
                if ($connection.State -eq 'Active') { $connection | Disconnect-Jira }
            }
            if ($previousDefault -and $previousDefault.State -eq 'Active') { $null = $previousDefault | Select-JiraConnection }
        }

        It 'uses the selected identity and isolates override cookies without changing the default' {
            $null = $first | Select-JiraConnection
            $cookie = [Net.Cookie]::new('session', 'original-cookie', '/', 'jira.example.com')
            $first.GetWebSession().Cookies.Add($cookie)
            $null = Invoke-JiraMethod -Uri '/rest/api/2/field' -Connection $first -PersonalAccessToken override-secret

            $requests[0].Authorization | Should -Be 'Bearer override-secret'
            $requests[0].Session.Cookies.Count | Should -Be 0
            [Object]::ReferenceEquals($requests[0].Session, $first.GetWebSession()) | Should -BeFalse
            $first.GetWebSession().Cookies.Count | Should -Be 1
            $first.GetAuthorizationHeader() | Should -Be 'Bearer first-secret'
            (Get-JiraConnection -Default).InstanceId | Should -Be $first.InstanceId
            $null = Invoke-JiraMethod -Uri '/rest/api/2/field' -Connection $second

            $requests[1].Authorization | Should -Be 'Bearer second-secret'
        }

        It 'isolates legacy credentials on an ordinary Jira command' {
            $null = $first | Select-JiraConnection
            $cookie = [Net.Cookie]::new('session', 'original-cookie', '/', 'jira.example.com')
            $first.GetWebSession().Cookies.Add($cookie)
            $password = [Security.SecureString]::new()
            foreach ($character in 'override-secret'.ToCharArray()) {
                $password.AppendChar($character)
            }
            $credential = [PSCredential]::new('override-user', $password)

            try {
                $null = Get-JiraField -Force -Connection $first -Credential $credential

                $expected = 'Basic ' + [Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes('override-user:override-secret'))
                $requests.Count | Should -Be 1
                $requests[0].Authorization | Should -Be $expected
                $requests[0].Session.Cookies.Count | Should -Be 0
                [Object]::ReferenceEquals($requests[0].Session, $first.GetWebSession()) | Should -BeFalse
                $first.GetWebSession().Cookies.Count | Should -Be 1
                $first.GetAuthorizationHeader() | Should -Be 'Bearer first-secret'
                (Get-JiraConnection -Default).InstanceId | Should -Be $first.InstanceId
            }
            finally { $password.Dispose() }
        }

        It 'retains the resolved context through retry after another connection becomes default' {
            $null = $first | Select-JiraConnection
            $script:attempt = 0
            Mock Test-ServerResponse {
                $script:attempt++
                if ($script:attempt -eq 1) {
                    $null = $second | Select-JiraConnection
                    return $true
                }
                $false
            }
            $result = Invoke-JiraMethod -Uri '/rest/api/2/field' -PersonalAccessToken override-secret

            $result.name | Should -Be 'result'
            $requests.Count | Should -Be 2
            foreach ($request in $requests) { $request.Authorization | Should -Be 'Bearer override-secret' }
            [Object]::ReferenceEquals($requests[0].Session, $requests[1].Session) | Should -BeTrue
            (Get-JiraConnection -Default).InstanceId | Should -Be $second.InstanceId
            $first.GetAuthorizationHeader() | Should -Be 'Bearer first-secret'
        }

        It 'retains override identity across pages after another connection becomes default' {
            $null = $first | Select-JiraConnection
            Mock Invoke-WebRequest {
                $script:requests.Add([PSCustomObject]@{
                        Uri           = $Uri
                        Session       = $WebSession
                        Authorization = $Headers.Authorization
                    })
                $page = if ("$Uri" -match 'startAt=1') { 1 } else { 0 }
                if ($page -eq 0) { $null = $second | Select-JiraConnection }
                $payload = @{
                    startAt    = $page
                    maxResults = 1
                    total      = 2
                    isLast     = ($page -eq 1)
                    values     = @(@{ id = $page + 1 })
                }
                $content = $payload | ConvertTo-Json -Depth 5
                [PSCustomObject]@{
                    StatusCode       = 200
                    Content          = $content
                    RawContentStream = [IO.MemoryStream]::new([Text.Encoding]::UTF8.GetBytes($content))
                    Headers          = @{ 'Content-Type' = 'application/json' }
                }
            }
            $result = @(Invoke-JiraMethod -Uri '/rest/api/2/search?maxResults=1' -Paging -PersonalAccessToken override-secret)

            $result.Count | Should -Be 2
            $requests.Count | Should -Be 2
            foreach ($request in $requests) { $request.Authorization | Should -Be 'Bearer override-secret' }
            [Object]::ReferenceEquals($requests[0].Session, $requests[1].Session) | Should -BeTrue
            (Get-JiraConnection -Default).InstanceId | Should -Be $second.InstanceId
        }

        It 'rejects caller authentication headers before network access' {
            { Invoke-JiraMethod -Uri '/rest/api/2/field' -Connection $first -Headers @{ Authorization = 'Bearer wrong' } } | Should -Throw
            { Invoke-JiraMethod -Uri '/rest/api/2/field' -Connection $first -Headers @{ Cookie = 'wrong' } } | Should -Throw
            $requests.Count | Should -Be 0
        }
    }
}
