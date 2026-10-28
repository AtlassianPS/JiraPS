#requires -modules @{ ModuleName = "Pester"; ModuleVersion = "6.2.0"; MaximumVersion = "6.999" }

BeforeDiscovery {
    . "$PSScriptRoot/../../Helpers/TestTools.ps1"
    $script:moduleToTest = Initialize-TestEnvironment
}

InModuleScope JiraPS {
    Describe 'Invoke-JiraMethod caller contract and shared transport' -Tag Unit {
        BeforeAll {
            . "$PSScriptRoot/../../Helpers/TestTools.ps1"
        }
        BeforeEach {
            $script:requests = [Collections.Generic.List[Object]]::new()
            $script:json = '{"id":42,"name":"result"}'
            $script:status = [Net.HttpStatusCode]::OK
            $script:sequence = [Collections.Generic.Queue[String]]::new()
            $script:JiraCache = @{}
            Mock Set-TlsLevel {}
            Mock Resolve-DefaultParameterValue { @{} }
            Mock Test-ServerResponse { $false }
            Mock Invoke-WebRequest {
                $content = if ($script:sequence.Count) { $script:sequence.Dequeue() }
                elseif ($Uri.AbsolutePath -match '/serverInfo$') { '{"deploymentType":"Server","product":"Jira"}' }
                elseif ($Uri.AbsolutePath -match '/myself$') { '{"name":"standalone-user"}' }
                else { $script:json }
                $bytes = [Text.Encoding]::UTF8.GetBytes($content)
                if ($OutFile) { [IO.File]::WriteAllBytes($OutFile, $bytes) }
                $response = [PSCustomObject]@{
                    StatusCode       = $script:status
                    Content          = $content
                    RawContentStream = [IO.MemoryStream]::new($bytes)
                    Headers          = @{ 'Content-Type' = 'application/json'; 'X-Trace' = 'trace-123' }
                }
                $script:requests.Add([PSCustomObject]@{
                        Uri         = $Uri
                        Method      = $Method
                        Body        = $Body
                        Headers     = $Headers
                        ContentType = $ContentType
                        Session     = $WebSession
                        TimeoutSec  = $TimeoutSec
                        OutFile     = $OutFile
                        PassThru    = $PassThru
                        Response    = $response
                    })
                $response
            }
        }

        It 'makes only Uri positional and excludes internal and removed parameters' {
            $command = Get-Command Invoke-JiraMethod
            foreach ($set in $command.ParameterSets) {
                @($set.Parameters | Where-Object Position -GE 0).Name | Should -Be @('Uri')
            }
            foreach ($name in @('StoreSession', 'RawBody', 'InFile', 'OutputType', 'CacheKey', 'CacheExpiry', 'BypassCache', 'Cmdlet', '_RetryCount', 'RequestContext', 'Discovery', 'GetParameter')) {
                $command.Parameters.ContainsKey($name) | Should -BeFalse
            }
            $command.Parameters.Connection.Aliases | Should -Not -Contain 'Session'
            (Get-Command Invoke-JiraRequest).Module.ExportedFunctions.ContainsKey('Invoke-JiraRequest') | Should -BeFalse
        }

        It 'uses a default GET without adding query parameters' {
            $result = Invoke-JiraMethod '/rest/api/2/field'
            $result.id | Should -Be 42
            $requests[0].Method | Should -Be 'Get'
            $requests[0].Uri.AbsoluteUri | Should -Be 'https://jira.example.com/rest/api/2/field'
        }

        It 'preserves repeated query values and encodes supplied arrays as repeated keys' {
            $null = Invoke-JiraMethod '/rest/api/2/field?field=one&field=two' -QueryParameter @{ expand = @('a&b', 'Müller'); q = 'a?b=c' }
            $query = ConvertTo-ParameterHash -Uri $requests[0].Uri
            $parsed = [Web.HttpUtility]::ParseQueryString($requests[0].Uri.Query)
            $parsed.GetValues('field') | Should -Be @('one', 'two')
            $parsed.GetValues('expand') | Should -Be @('a&b', 'Müller')
            $query.q | Should -Be 'a?b=c'
            $query.ContainsKey('maxResults') | Should -BeFalse
        }

        It 'overrides URI query values without changing the input hashtable' {
            $query = @{ fields = 'summary,status' }
            $null = Invoke-JiraMethod '/rest/api/2/issue/PROJ-1?fields=description' -QueryParameter $query
            (ConvertTo-ParameterHash -Uri $requests[0].Uri).fields | Should -Be 'summary,status'
            $query.Count | Should -Be 1
        }

        It 'preserves bare flags, empty values and encoded delimiters in resource queries' {
            $null = Invoke-JiraMethod '/rest/plugin/endpoint?flag&empty=&q=a%3Db'
            $query = ConvertTo-ParameterHash -Uri $requests[0].Uri
            $query.ContainsKey('flag') | Should -BeTrue
            $query.empty | Should -BeNullOrEmpty
            $query.q | Should -Be 'a=b'
        }

        It 'preserves mixed bare and valued query keys: <Query>' -ForEach @(
            @{ Query = 'q=hello&flag'; Expected = @('') }
            @{ Query = 'flag=one&flag'; Expected = @('one', '') }
            @{ Query = 'flag&flag=one'; Expected = @('', 'one') }
            @{ Query = 'flag=one&flag&flag=two'; Expected = @('one', '', 'two') }
            @{ Query = 'flag&flag'; Expected = @('', '') }
        ) {
            $null = Invoke-JiraMethod "/rest/plugin/endpoint?$Query"
            $parsed = [Web.HttpUtility]::ParseQueryString($requests[0].Uri.Query)
            $parsed.GetValues('flag') | Should -Be $Expected
        }

        It 'serializes a nested JSON body and preserves Unicode without changing the input' {
            $body = @{ fields = @{ summary = 'مرحبا Müller 😁'; customfield_100 = @{ value = 'nested' } } }
            $null = Invoke-JiraMethod '/rest/api/2/issue' -Method Post -Body $body -Confirm:$false
            $actual = [Text.Encoding]::UTF8.GetString($requests[0].Body) | ConvertFrom-Json
            $actual.fields.summary | Should -Be $body.fields.summary
            $actual.fields.customfield_100.value | Should -Be 'nested'
            $requests[0].ContentType | Should -Be 'application/json; charset=utf-8'
            $requests[0].Uri.Query | Should -BeNullOrEmpty
        }

        It 'preserves JSON arrays, explicit null, false and empty strings' {
            foreach ($body in @(@{ input = @(@{ name = 'a' }, @{ name = 'b' }); expected = '[{"name":"a"},{"name":"b"}]' },
                    @{ input = $null; expected = 'null' }, @{ input = $false; expected = 'false' }, @{ input = ''; expected = '' })) {
                $null = Invoke-JiraMethod '/rest/api/2/issue' -Method Post -Body $body.input -Confirm:$false
                [Text.Encoding]::UTF8.GetString($requests[-1].Body) | Should -Be $body.expected
            }
        }

        It 'preserves serialized JSON strings and raw bytes' {
            $json = '{ "name": "Müller" }'
            $null = Invoke-JiraMethod '/rest/api/2/group' -Method Post -Body $json -Confirm:$false
            [Text.Encoding]::UTF8.GetString($requests[0].Body) | Should -BeExactly $json
            $bytes = [Byte[]]@(0, 128, 255)
            $null = Invoke-JiraMethod '/rest/api/2/avatar' -Method Post -Body $bytes -ContentType application/octet-stream -Confirm:$false
            $requests[1].Body | Should -Be $bytes
        }

        It 'supports explicit text content and rejects structured non-JSON bodies' {
            $null = Invoke-JiraMethod '/rest/plugin/endpoint' -Method Post -Body 'Müller' -ContentType 'text/plain; charset=utf-8' -Confirm:$false
            $requests[0].ContentType | Should -Be 'text/plain; charset=utf-8'
            [Text.Encoding]::UTF8.GetString($requests[0].Body) | Should -Be 'Müller'
            foreach ($body in @(@{ name = 'x' }, $null)) {
                { Invoke-JiraMethod '/rest/plugin/endpoint' -Method Post -Body $body -ContentType text/plain -Confirm:$false } |
                    Should -Throw '*require a JSON ContentType*'
            }
            $requests.Count | Should -Be 1
        }

        It 'honors ordinary headers without mutating them and rejects conflicting ContentType' {
            $headers = @{ 'X-Trace' = 'caller'; 'Content-Type' = 'text/plain' }
            $null = Invoke-JiraMethod '/rest/plugin/endpoint' -Method Post -Body 'text' -Headers $headers -Confirm:$false
            $requests[0].Headers['X-Trace'] | Should -Be 'caller'
            $requests[0].ContentType | Should -Be 'text/plain'
            $headers['Content-Type'] | Should -Be 'text/plain'
            { Invoke-JiraMethod '/rest/plugin/endpoint' -Headers $headers -ContentType application/json } | Should -Throw '*not both*'
        }

        It 'merges module, global web-request and caller headers in precedence order' {
            Mock Resolve-DefaultParameterValue {
                @{ 'Invoke-WebRequest:Headers' = @{ Accept = 'text/plain'; 'X-Trace' = 'global'; 'X-Global' = 'retained' } }
            }
            $null = Invoke-JiraMethod '/rest/api/2/field' -Headers @{ Accept = 'application/json'; 'X-Trace' = 'caller' }
            $requests[0].Headers.Accept | Should -Be 'application/json'
            $requests[0].Headers['X-Trace'] | Should -Be 'caller'
            $requests[0].Headers['X-Global'] | Should -Be 'retained'
            $requests[0].Headers['Accept-Charset'] | Should -Be 'utf-8'
        }

        It 'rejects global authentication defaults and headers before HTTP' {
            Mock Resolve-DefaultParameterValue { @{ 'Invoke-WebRequest:Credential' = [PSCredential]::Empty } }
            { Invoke-JiraMethod '/rest/api/2/field' } | Should -Throw '*conflicting low-level authentication*'
            Mock Resolve-DefaultParameterValue { @{ 'Invoke-WebRequest:Headers' = @{ Cookie = 'secret' } } }
            { Invoke-JiraMethod '/rest/api/2/field' } | Should -Throw '*Authentication headers*'
            $requests.Count | Should -Be 0
        }

        It 'selects a named connection without changing the default' {
            $default = Get-JiraConnection -Default
            $null = Invoke-JiraMethod '/rest/api/2/field' -ConnectionName $default.Name
            (Get-JiraConnection -Default).InstanceId | Should -Be $default.InstanceId
            [Object]::ReferenceEquals($requests[0].Session, $default.GetWebSession()) | Should -BeTrue
        }

        It 'rejects authentication overrides and conflicting connection selectors' {
            $connection = Get-JiraConnection -Default
            { Invoke-JiraMethod '/rest/api/2/field' -Connection $connection -PersonalAccessToken 'secret' } | Should -Throw
            { Invoke-JiraMethod '/rest/api/2/field' -Connection $connection -ConnectionName $connection.Name } | Should -Throw
            { Invoke-JiraMethod '/rest/api/2/field' -BaseUri https://jira.example.com -Anonymous -PersonalAccessToken 'secret' } | Should -Throw
            $requests.Count | Should -Be 0
        }

        It 'validates standalone authentication and preserves the default connection' {
            $default = Get-JiraConnection -Default
            $result = Invoke-JiraMethod '/rest/api/2/field' -BaseUri https://standalone.example.com -PersonalAccessToken 'standalone-secret'
            $result.id | Should -Be 42
            $requests.Count | Should -Be 3
            $requests[0].Uri.AbsolutePath | Should -Be '/rest/api/2/serverInfo'
            $requests[1].Uri.AbsolutePath | Should -Be '/rest/api/2/myself'
            $requests[2].Headers.Authorization | Should -Be 'Bearer standalone-secret'
            (Get-JiraConnection -Default).InstanceId | Should -Be $default.InstanceId
            @(Get-JiraConnection | Where-Object BaseUri -EQ 'https://standalone.example.com/').Count | Should -Be 0
        }

        It 'disposes a standalone context when the transport fails' {
            $script:standalone = $null
            Mock New-JiraCandidate {
                $script:standalone = AtlassianPS.Configuration\New-AtlassianConnectionContext -Name Standalone -Product Jira -BaseUri $Uri -Anonymous
                $script:standalone.SetValidationResult('Server', $null)
                $script:standalone
            }
            Mock Invoke-JiraRequest { throw 'Transport sentinel' }
            { Invoke-JiraMethod '/rest/api/2/field' -BaseUri https://standalone.example.com -Anonymous } | Should -Throw '*Transport sentinel*'
            $standalone.State | Should -Be 'Disconnected'
        }

        It 'prevents requests and standalone discovery under WhatIf' {
            $null = Invoke-JiraMethod '/rest/api/2/group' -Method Post -Body @{ name = 'x' } -BaseUri https://example.atlassian.net -EmailAddress test@example.com -ApiToken 'secret' -WhatIf
            $null = Invoke-JiraMethod '/rest/api/2/field' -OutFile "$TestDrive/result.json" -WhatIf
            $requests.Count | Should -Be 0
            Test-Path "$TestDrive/result.json" | Should -BeFalse
        }

        It 'returns the native response for header and content inspection' {
            $response = Invoke-JiraMethod '/rest/api/2/field' -RawResponse
            [Object]::ReferenceEquals($response, $requests[0].Response) | Should -BeTrue
            $response.Headers['X-Trace'] | Should -Be 'trace-123'
            $response.Content | Should -Be $json
        }

        It 'requires an explicit raw response mode for non-JSON content' {
            $script:json = 'non-JSON response'
            { Invoke-JiraMethod '/rest/plugin/endpoint' } | Should -Throw '*Use -RawResponse*'
            (Invoke-JiraMethod '/rest/plugin/endpoint' -RawResponse).Content | Should -Be $json
        }

        It 'preserves Jira HTTP errors and the caller ErrorAction preference' {
            Mock Invoke-JiraWebRequestSafely {
                $body = '{"errorMessages":["Jira validation sentinel"]}'
                $response = [PSCustomObject]@{ Stream = [IO.MemoryStream]::new([Text.Encoding]::UTF8.GetBytes($body)) } |
                    Add-Member -MemberType ScriptMethod -Name GetResponseStream -Value { $this.Stream } -PassThru
                @{
                    WebResponse = @{ StatusCode = 400 }
                    Exception   = [PSCustomObject]@{
                        ErrorDetails = [PSCustomObject]@{ Message = $body }
                        Exception    = [PSCustomObject]@{ Response = $response }
                    }
                }
            }
            { Invoke-JiraMethod '/rest/api/2/field' -ErrorAction Stop } | Should -Throw '*Jira validation sentinel*'
            $errors = @()
            @(Invoke-JiraMethod '/rest/api/2/field' -RawResponse -ErrorAction SilentlyContinue -ErrorVariable errors).Count | Should -Be 0
            $errors.Count | Should -Be 1
            $errors[0].FullyQualifiedErrorId | Should -Match 'InvalidResponse.Status400'
        }

        It 'saves the response unchanged and returns FileInfo, including for POST responses' {
            $script:json = 'plain text Müller'
            $path = "$TestDrive/download.txt"
            $result = Invoke-JiraMethod '/rest/plugin/download' -Method Post -Body '{}' -OutFile $path -Confirm:$false
            $result | Should -BeOfType ([IO.FileInfo])
            [IO.File]::ReadAllText($result.FullName) | Should -BeExactly $json
            $requests[0].PassThru | Should -BeTrue
        }

        It 'returns no objects for a successful response without content' {
            $script:status = [Net.HttpStatusCode]::NoContent
            $script:json = ''
            @(Invoke-JiraMethod '/rest/api/2/issue/PROJ-1' -Method Delete -Confirm:$false).Count | Should -Be 0
        }

        It 'rejects directory output paths before making requests' {
            { Invoke-JiraMethod '/rest/api/2/field' -OutFile $TestDrive -Confirm:$false } | Should -Throw '*must name a file*'
            $requests.Count | Should -Be 0
        }

        It 'rejects conflicting response modes and paging options without Paging' {
            foreach ($parameters in @(@{ Paging = $true; RawResponse = $true }, @{ Paging = $true; OutFile = "$TestDrive/x" },
                    @{ RawResponse = $true; OutFile = "$TestDrive/x" }, @{ First = 1 }, @{ Skip = 1 }, @{ IncludeTotalCount = $true }, @{ PageSize = 5 })) {
                { Invoke-JiraMethod '/rest/api/2/search' @parameters } | Should -Throw
            }
            { Invoke-JiraMethod '/rest/api/2/search' -Paging -PageSize 10 -QueryParameter @{ maxResults = 5 } } | Should -Throw '*not both*'
            { Invoke-JiraMethod '/rest/api/3/search/jql' -Method Post -Body '{}' -Paging -Confirm:$false } | Should -Throw '*GET requests*'
            $requests.Count | Should -Be 0
        }

        It 'pages offset results with bounded First, Skip and server page caps' {
            $sequence.Enqueue('{"startAt":2,"maxResults":2,"total":10,"issues":[{"id":3},{"id":4}]}')
            $sequence.Enqueue('{"startAt":4,"maxResults":1,"total":10,"issues":[{"id":5}]}')
            $result = @(Invoke-JiraMethod '/rest/api/2/search' -Paging -PageSize 5 -Skip 2 -First 3 -IncludeTotalCount)
            $result[0] | Should -Be 10
            $result[0].Accuracy | Should -Be 1
            $result[1..3].id | Should -Be @(3, 4, 5)
            (ConvertTo-ParameterHash -Uri $requests[0].Uri).startAt | Should -Be '2'
            (ConvertTo-ParameterHash -Uri $requests[1].Uri).maxResults | Should -Be '1'
        }

        It 'skips token-paged items locally without sending offset parameters' {
            $sequence.Enqueue('{"issues":[{"id":1},{"id":2},{"id":3}],"nextPageToken":"page & 2","isLast":false}')
            $sequence.Enqueue('{"issues":[{"id":4},{"id":5}],"isLast":true}')
            $result = @(Invoke-JiraMethod '/rest/api/3/search/jql' -Paging -PageSize 3 -Skip 2 -First 2)
            $result.id | Should -Be @(3, 4)
            $requests.Count | Should -Be 2
            foreach ($request in $requests) { (ConvertTo-ParameterHash -Uri $request.Uri).ContainsKey('startAt') | Should -BeFalse }
            (ConvertTo-ParameterHash -Uri $requests[1].Uri).nextPageToken | Should -Be 'page & 2'
        }

        It 'fails clearly for unsupported or ambiguous paging responses' {
            { Invoke-JiraMethod '/rest/api/2/field' -Paging } | Should -Throw '*paging response*'
            $script:json = '{"issues":[],"values":[],"total":0}'
            { Invoke-JiraMethod '/rest/api/2/field' -Paging } | Should -Throw '*ambiguous*'
        }

        It 'applies token Skip to a single final page that omits nextPageToken' {
            $script:json = '{"issues":[{"id":1},{"id":2},{"id":3}],"isLast":true}'
            $result = @(Invoke-JiraMethod '/rest/api/3/search/jql' -Paging -Skip 2 -First 1)
            $result.id | Should -Be 3
            $requests.Count | Should -Be 1
            (ConvertTo-ParameterHash -Uri $requests[0].Uri).ContainsKey('startAt') | Should -BeFalse
        }

        It 'follows a token even when the initial page contains no visible items' {
            $sequence.Enqueue('{"issues":[],"nextPageToken":"page-2","isLast":false}')
            $sequence.Enqueue('{"issues":[{"id":1,"count":0}],"isLast":true}')
            $result = @(Invoke-JiraMethod '/rest/api/3/search/jql' -Paging)
            $result.Count | Should -Be 1
            $result.id | Should -Be 1
            $requests.Count | Should -Be 2
        }

        It 'stops a non-consecutive pagination-token cycle' {
            $sequence.Enqueue('{"issues":[{"id":1}],"nextPageToken":"a"}')
            $sequence.Enqueue('{"issues":[{"id":2}],"nextPageToken":"b"}')
            $sequence.Enqueue('{"issues":[{"id":3}],"nextPageToken":"a"}')
            { Invoke-JiraMethod '/rest/api/3/search/jql' -Paging -Skip 100 } | Should -Throw '*repeated a pagination token*'
            $requests.Count | Should -Be 3
        }

        It 'stops when the response repeats the initial caller token' {
            $script:json = '{"issues":[{"id":1}],"nextPageToken":"initial"}'
            { Invoke-JiraMethod '/rest/api/3/search/jql' -Paging -QueryParameter @{ nextPageToken = 'initial' } } | Should -Throw '*repeated a pagination token*'
            $requests.Count | Should -Be 1
        }

        It 'does not request a page when First is zero' {
            @(Invoke-JiraMethod '/rest/api/2/search' -Paging -First 0).Count | Should -Be 0
            $requests.Count | Should -Be 0
        }

        It 'keeps cached and fresh paging output identical, including typed conversion and totals' {
            $script:json = '{"values":[{"id":"1","name":"v1"},{"id":"2","name":"v2"}],"total":2,"maxResults":25,"startAt":0}'
            foreach ($attempt in 1..2) {
                $result = @(Invoke-JiraRequest -Uri '/rest/api/2/version' -Paging -OutputType JiraVersion -CacheKey Versions -IncludeTotalCount)
                $result.Count | Should -Be 3
                $result[0] | Should -Be 2
                $result[1] | Should -BeOfType ([AtlassianPS.JiraPS.Version])
                $result[1..2].Name | Should -Be @('v1', 'v2')
            }
            $requests.Count | Should -Be 1
        }

        It 'refreshes cached responses and scopes entries to the full URI' {
            $null = Invoke-JiraRequest -Uri '/rest/api/2/field?fields=a' -CacheKey Fields
            $script:json = '{"id":99}'
            (Invoke-JiraRequest -Uri '/rest/api/2/field?fields=a' -CacheKey Fields -BypassCache).id | Should -Be 99
            (Invoke-JiraRequest -Uri '/rest/api/2/field?fields=a' -CacheKey Fields).id | Should -Be 99
            $null = Invoke-JiraRequest -Uri '/rest/api/2/field?fields=b' -CacheKey Fields
            $requests.Count | Should -Be 3
        }

        It 'validates resource URIs before serving cached responses' {
            $null = Invoke-JiraRequest -Uri '/rest/api/2/field' -CacheKey Fields
            { Invoke-JiraRequest -Uri 'invalid-relative-path' -CacheKey Fields } | Should -Throw '*must start with one slash*'
            $requests.Count | Should -Be 1
        }

        It 'isolates caches for separate identities on the same endpoint' {
            $previousDefault = Get-JiraConnection -Default
            $first = AtlassianPS.Configuration\New-AtlassianConnectionContext -Name cache-first -Product Jira -BaseUri https://jira.example.com -PersonalAccessToken first-secret
            $second = AtlassianPS.Configuration\New-AtlassianConnectionContext -Name cache-second -Product Jira -BaseUri https://jira.example.com -PersonalAccessToken second-secret
            foreach ($candidate in @($first, $second)) {
                $candidate.SetValidationResult('Server', 'validated-user')
                $null = AtlassianPS.Configuration\Register-AtlassianConnection -Connection $candidate
            }
            try {
                $first | Select-JiraConnection | Out-Null
                (Invoke-JiraRequest -Uri '/rest/api/2/field' -CacheKey Fields).id | Should -Be 42
                $script:json = '{"id":99}'
                $second | Select-JiraConnection | Out-Null
                (Invoke-JiraRequest -Uri '/rest/api/2/field' -CacheKey Fields).id | Should -Be 99
                $first | Select-JiraConnection | Out-Null
                (Invoke-JiraRequest -Uri '/rest/api/2/field' -CacheKey Fields).id | Should -Be 42
                $requests.Count | Should -Be 2
            }
            finally {
                $first | Disconnect-Jira
                $second | Disconnect-Jira
                if ($previousDefault -and $previousDefault.State -eq 'Active') {
                    $previousDefault | Select-JiraConnection | Out-Null
                }
            }
        }

        It 'does not cache standalone responses' {
            $context = AtlassianPS.Configuration\New-AtlassianConnectionContext -Name Standalone -Product Jira -BaseUri https://jira.example.com -Anonymous
            $context.SetValidationResult('Server', $null)
            $context.MakeStandalone([Guid]::Empty)
            try {
                $null = Invoke-JiraRequest -Uri '/rest/api/2/field' -RequestContext $context -CacheKey Fields
                $script:json = '{"id":99}'
                (Invoke-JiraRequest -Uri '/rest/api/2/field' -RequestContext $context -CacheKey Fields).id | Should -Be 99
                $requests.Count | Should -Be 2
                $script:JiraCache.Count | Should -Be 0
            }
            finally { $context.Dispose() }
        }

        It 'logs configured headers for success and terminal errors without making logger failures fatal' {
            $previous = $script:JiraResponseHeaderLogConfiguration
            $script:JiraResponseHeaderLogConfiguration = [PSCustomObject]@{ Mode = 'Wildcard' }
            Mock Write-JiraResponseHeaderLog {}
            Mock Resolve-ErrorWebResponse {}
            try {
                $null = Invoke-JiraMethod '/rest/api/2/field'
                $script:status = [Net.HttpStatusCode]::BadRequest
                $null = Invoke-JiraMethod '/rest/api/2/field'
                Should -Invoke Write-JiraResponseHeaderLog -Times 2 -Exactly
                Mock Write-JiraResponseHeaderLog { throw 'Logger sentinel' }
                $script:status = [Net.HttpStatusCode]::OK
                (Invoke-JiraMethod '/rest/api/2/field').id | Should -Be 42
            }
            finally { $script:JiraResponseHeaderLogConfiguration = $previous }
        }

        It 'restricts candidates to validation endpoints' {
            $candidate = AtlassianPS.Configuration\New-AtlassianConnectionContext -Name candidate -Product Jira -BaseUri https://jira.example.com -Anonymous
            try {
                { Invoke-JiraRequest -Uri '/rest/api/2/issue' -RequestContext $candidate } | Should -Throw '*restricted*'
                { Invoke-JiraRequest -Uri '/rest/api/2/myself' -Method Post -RequestContext $candidate } | Should -Throw '*restricted*'
                $requests.Count | Should -Be 0
            }
            finally { $candidate.Dispose() }
        }

        It 'honors timeout overrides and rejects authentication headers before the request' {
            $null = Invoke-JiraMethod '/rest/api/2/field' -TimeoutSec 30
            $requests[0].TimeoutSec | Should -Be 30
            $null = Invoke-JiraMethod '/rest/api/2/field' -TimeoutSec 0
            $requests[1].TimeoutSec | Should -Be 0
            foreach ($header in @('Authorization', 'Cookie', 'Proxy-Authorization')) {
                { Invoke-JiraMethod '/rest/api/2/field' -Headers @{ $header = 'secret' } } | Should -Throw '*Authentication headers*'
            }
            $requests.Count | Should -Be 2
        }

        It 'retries safe GET requests but never arbitrary POST mutations' {
            $script:attempt = 0
            Mock Test-ServerResponse {
                $script:attempt++
                $MaxRetries -gt 0 -and $script:attempt -eq 1
            }
            $null = Invoke-JiraMethod '/rest/api/2/field'
            $requests.Count | Should -Be 2
            Should -Invoke Test-ServerResponse -Times 2 -Exactly -ParameterFilter { $MaxRetries -eq 3 }
            $script:attempt = 0
            $null = Invoke-JiraMethod '/rest/api/2/group' -Method Post -Body '{}' -Confirm:$false
            $requests.Count | Should -Be 3
            Should -Invoke Test-ServerResponse -Times 1 -Exactly -ParameterFilter { $MaxRetries -eq 0 }
        }

        It 'rejects redirects and releases TLS state on failure' {
            $script:status = [Net.HttpStatusCode]::Found
            { Invoke-JiraMethod '/rest/api/2/field' } | Should -Throw '*redirected*'
            Should -Invoke Set-TlsLevel -Times 1 -Exactly -ParameterFilter { $Revert }
        }
    }
}
