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

        It 'uses the selected identity and cookies while rejecting authentication overrides' {
            $null = $first | Select-JiraConnection
            $cookie = [Net.Cookie]::new('session', 'original-cookie', '/', 'jira.example.com')
            $first.GetWebSession().Cookies.Add($cookie)
            { Invoke-JiraMethod -Uri '/rest/api/2/field' -Connection $first -PersonalAccessToken override-secret } | Should -Throw
            $requests.Count | Should -Be 0
            $null = Invoke-JiraMethod -Uri '/rest/api/2/field' -Connection $first

            $requests[0].Authorization | Should -Be 'Bearer first-secret'
            $requests[0].Session.Cookies.Count | Should -Be 1
            [Object]::ReferenceEquals($requests[0].Session, $first.GetWebSession()) | Should -BeTrue
            $first.GetWebSession().Cookies.Count | Should -Be 1
            $first.GetAuthorizationHeader() | Should -Be 'Bearer first-secret'
            (Get-JiraConnection -Default).InstanceId | Should -Be $first.InstanceId
            $null = Invoke-JiraMethod -Uri '/rest/api/2/field' -Connection $second

            $requests[1].Authorization | Should -Be 'Bearer second-secret'
        }

        It 'rejects legacy credentials on an ordinary Jira command before transport' {
            $null = $first | Select-JiraConnection
            $cookie = [Net.Cookie]::new('session', 'original-cookie', '/', 'jira.example.com')
            $first.GetWebSession().Cookies.Add($cookie)
            $password = [Security.SecureString]::new()
            foreach ($character in 'override-secret'.ToCharArray()) {
                $password.AppendChar($character)
            }
            $credential = [PSCredential]::new('override-user', $password)

            try {
                { Get-JiraField -Refresh -Connection $first -Credential $credential } | Should -Throw -ErrorId 'NamedParameterNotFound,*'
                $requests.Count | Should -Be 0
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
            $result = Invoke-JiraMethod -Uri '/rest/api/2/field' -Connection $first

            $result.name | Should -Be 'result'
            $requests.Count | Should -Be 2
            foreach ($request in $requests) { $request.Authorization | Should -Be 'Bearer first-secret' }
            [Object]::ReferenceEquals($requests[0].Session, $requests[1].Session) | Should -BeTrue
            (Get-JiraConnection -Default).InstanceId | Should -Be $second.InstanceId
            $first.GetAuthorizationHeader() | Should -Be 'Bearer first-secret'
        }

        It 'uses the explicit connection for a filter lookup and every search page' {
            $null = $second | Select-JiraConnection
            Mock Invoke-WebRequest {
                $script:requests.Add([PSCustomObject]@{
                        Uri           = $Uri
                        Session       = $WebSession
                        Authorization = $Headers.Authorization
                    })
                if ($Uri.AbsolutePath -eq '/rest/api/2/filter/12844') {
                    $payload = @{
                        id        = 12844
                        searchUrl = 'https://jira.example.com/rest/api/2/search?jql=project%3DTEST'
                    }
                }
                else {
                    $page = if ("$Uri" -match 'startAt=1') { 1 } else { 0 }
                    $payload = @{
                        startAt    = $page
                        maxResults = 1
                        total      = 2
                        issues     = @(@{ id = $page + 1; key = "TEST-$($page + 1)"; fields = @{ summary = "Issue $page" } })
                    }
                }
                $content = $payload | ConvertTo-Json -Depth 5
                [PSCustomObject]@{
                    StatusCode       = 200
                    Content          = $content
                    RawContentStream = [IO.MemoryStream]::new([Text.Encoding]::UTF8.GetBytes($content))
                    Headers          = @{ 'Content-Type' = 'application/json' }
                }
            }
            $result = @(Get-JiraIssue -Filter 12844 -PageSize 1 -Connection $first)

            $result.Key | Should -Be @('TEST-1', 'TEST-2')
            $requests.Count | Should -Be 3
            $requests[0].Uri.AbsolutePath | Should -Be '/rest/api/2/filter/12844'
            $requests[1].Uri.AbsolutePath | Should -Be '/rest/api/2/search'
            $requests[2].Uri.Query | Should -Match 'startAt=1'
            foreach ($request in $requests) { $request.Authorization | Should -Be 'Bearer first-secret' }
            foreach ($request in $requests) { [Object]::ReferenceEquals($request.Session, $first.GetWebSession()) | Should -BeTrue }
            (Get-JiraConnection -Default).InstanceId | Should -Be $second.InstanceId
        }

        It 'rejects caller authentication headers before network access' {
            { Invoke-JiraMethod -Uri '/rest/api/2/field' -Connection $first -Headers @{ Authorization = 'Bearer wrong' } } | Should -Throw
            { Invoke-JiraMethod -Uri '/rest/api/2/field' -Connection $first -Headers @{ Cookie = 'wrong' } } | Should -Throw
            $requests.Count | Should -Be 0
        }

        It 'caches and refreshes <CommandName> <Lookup> independently per connection' -ForEach @(
            @{ CommandName = 'Get-JiraField'; Lookup = 'catalogue'; Selector = @{} }
            @{ CommandName = 'Get-JiraIssueType'; Lookup = 'catalogue'; Selector = @{} }
            @{ CommandName = 'Get-JiraIssueLinkType'; Lookup = 'catalogue'; Selector = @{} }
            @{ CommandName = 'Get-JiraIssueLinkType'; Lookup = 'ID'; Selector = @{ LinkType = 1 } }
            @{ CommandName = 'Get-JiraStatus'; Lookup = 'catalogue'; Selector = @{} }
            @{ CommandName = 'Get-JiraStatus'; Lookup = 'ID'; Selector = @{ Status = 1 } }
            @{ CommandName = 'Get-JiraStatus'; Lookup = 'name'; Selector = @{ Status = 'Open' } }
            @{ CommandName = 'Get-JiraPriority'; Lookup = 'catalogue'; Selector = @{} }
            @{ CommandName = 'Get-JiraPriority'; Lookup = 'ID'; Selector = @{ Id = 1 } }
        ) {
            $script:JiraCache = @{}
            $script:catalogueName = 'original'
            Mock Invoke-WebRequest {
                $script:requests.Add($Uri)
                $record = @{ id = '1'; name = $script:catalogueName; inward = 'is blocked by'; outward = 'blocks' }
                $payload = if ($Uri.AbsolutePath -eq '/rest/api/2/issueLinkType') { @{ issueLinkTypes = @($record) } }
                elseif ($Uri.AbsolutePath -match '/(field|issuetype|status|priority)$') { , @($record) }
                else { $record }
                $content = ConvertTo-Json -InputObject $payload -Depth 5
                [PSCustomObject]@{
                    StatusCode       = 200
                    Content          = $content
                    RawContentStream = [IO.MemoryStream]::new([Text.Encoding]::UTF8.GetBytes($content))
                    Headers          = @{ 'Content-Type' = 'application/json' }
                }
            }

            (& $CommandName @Selector -Connection $first).Name | Should -Be 'original'
            $script:catalogueName = 'fresh'
            (& $CommandName @Selector -Connection $first).Name | Should -Be 'original'
            $requests.Count | Should -Be 1

            (& $CommandName @Selector -Connection $second).Name | Should -Be 'fresh'
            (& $CommandName @Selector -Connection $first).Name | Should -Be 'original'
            $requests.Count | Should -Be 2

            (& $CommandName @Selector -Refresh -Connection $first).Name | Should -Be 'fresh'
            (& $CommandName @Selector -Connection $first).Name | Should -Be 'fresh'
            $requests.Count | Should -Be 3

            foreach ($entry in $script:JiraCache.Values) {
                ($entry.Expiry - (Get-Date)).TotalMinutes | Should -BeGreaterThan 59
                ($entry.Expiry - (Get-Date)).TotalMinutes | Should -BeLessOrEqual 60
            }
        }

        It 'reuses an empty <CommandName> catalogue for subsequent pipeline selectors' -ForEach @(
            @{ CommandName = 'Get-JiraField' }
            @{ CommandName = 'Get-JiraIssueType' }
        ) {
            Mock Invoke-WebRequest {
                $script:requests.Add($Uri)
                [PSCustomObject]@{
                    StatusCode       = 200
                    Content          = '[]'
                    RawContentStream = [IO.MemoryStream]::new([Text.Encoding]::UTF8.GetBytes('[]'))
                    Headers          = @{ 'Content-Type' = 'application/json' }
                }
            }

            @('1', '2' | & $CommandName -Refresh -Connection $first).Count | Should -Be 0
            $requests.Count | Should -Be 1
        }
    }
}
