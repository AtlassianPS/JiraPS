#requires -modules @{ ModuleName = "Pester"; ModuleVersion = "5.7"; MaximumVersion = "5.999" }

[Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSAvoidUsingConvertToSecureStringWithPlainText", "")]
param()

BeforeDiscovery {
    . "$PSScriptRoot/../../Helpers/TestTools.ps1"

    $script:moduleToTest = Initialize-TestEnvironment
}

InModuleScope JiraPS {
    Describe "Invoke-JiraMethod" -Tag 'Unit' {
        BeforeAll {
            . "$PSScriptRoot/../../Helpers/TestTools.ps1"
            # $VerbosePreference = 'Continue'  # Uncomment for mock debugging

            #region Definitions
            $script:utf8String = "Lorem مرحبا Здравствуйте 😁"
            $script:testUsername = 'testUsername'
            $script:testPassword = ConvertTo-SecureString -AsPlainText -Force 'password123'
            $script:testCred = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $testUsername, $testPassword
            $script:pagedResponse1 = @"
{
    "startAt" : 0,
    "maxResults" : 5,
    "total": 7,
    "issues": [
        { "id": 1 },
        { "id": 2 },
        { "id": 3 },
        { "id": 4 },
        { "id": 5 }
    ]
}
"@
            $script:pagedResponse2 = @"
{
    "startAt" : 5,
    "maxResults" : 5,
    "total": 7,
    "issues": [
        { "id": 6 },
        { "id": 7 }
    ]
}
"@
            $script:pagedResponse3 = "{}"
            $script:supportedTypes = @("JiraComment", "JiraIssue", "JiraUser", "JiraVersion")
            #endregion

            #region Mocks
            Mock Resolve-DefaultParameterValue -ModuleName 'JiraPS' {
                Write-MockDebugInfo 'Resolve-DefaultParameterValue'
                @{ }
            }
            Mock Join-Hashtable -ModuleName 'JiraPS' {
                Write-MockDebugInfo 'Join-Hashtable'
                @{ }
            }
            Mock Set-TlsLevel -ModuleName 'JiraPS' {
                Write-MockDebugInfo 'Set-TlsLevel'
            }
            Mock Resolve-ErrorWebResponse -ModuleName 'JiraPS' {
                Write-MockDebugInfo 'Resolve-ErrorWebResponse'
            }
            Mock Expand-Result -ModuleName 'JiraPS' {
                Write-MockDebugInfo 'Expand-Result'
            }
            Mock Convert-Result -ModuleName 'JiraPS' {
                Write-MockDebugInfo 'Convert-Result'
            }
            Mock Get-JiraSession -ModuleName 'JiraPS' {
                Write-MockDebugInfo 'Get-JiraSession'
                [PSCustomObject]@{
                    WebSession = New-Object -TypeName Microsoft.PowerShell.Commands.WebRequestSession
                }
            }
            Mock Get-JiraConfigServer -ModuleName 'JiraPS' {
                'https://jira.example.com'
            }
            Mock Test-ServerResponse -ModuleName 'JiraPS' {
                Write-MockDebugInfo 'Test-ServerResponse'
            }
            Mock ConvertTo-JiraSession -ModuleName 'JiraPS' {
                Write-MockDebugInfo 'ConvertTo-JiraSession'
            }
            foreach ($type in $supportedTypes) {
                Mock -CommandName "ConvertTo-$type" -ModuleName 'JiraPS' {
                    Write-MockDebugInfo "ConvertTo-$type"
                }
            }
            # Synthetic response factory. The previous implementation shelled out
            # to the real postman-echo.com on every test (~300 ms each, ~9 s total
            # for this file alone). We now build an offline response that mimics
            # the subset of Invoke-WebRequest's output that Invoke-JiraMethod
            # actually reads: StatusCode, Content, RawContentStream, Headers -
            # and shaped to echo the caller's headers/body like postman-echo did,
            # so downstream "$response.headers.'x-fake' | Should -Be ..." assertions
            # keep working without referencing the wire format.
            function script:New-FakeEchoResponse {
                param(
                    [Parameter(Mandatory)][uri] $Uri,
                    [string] $Method,
                    $Body,
                    [hashtable] $Headers,
                    [hashtable] $ResponseHeaders = @{}
                )

                $statusCode = if ($Uri.AbsolutePath -match '/status/(\d+)') {
                    [System.Net.HttpStatusCode][int]$Matches[1]
                }
                else {
                    [System.Net.HttpStatusCode]::OK
                }

                $data = if ($null -eq $Body) { $null }
                elseif ($Body -is [byte[]]) { [System.Text.Encoding]::UTF8.GetString($Body) }
                else { [string]$Body }

                $echoHeaders = @{}
                if ($Headers) {
                    foreach ($k in $Headers.Keys) {
                        $echoHeaders[[string]$k.ToString().ToLower()] = $Headers[$k]
                    }
                }
                $payload = [ordered]@{
                    args    = @{}
                    headers = $echoHeaders
                    data    = $data
                    url     = $Uri.AbsoluteUri
                }
                $json = $payload | ConvertTo-Json -Depth 10 -Compress
                $bytes = [System.Text.Encoding]::UTF8.GetBytes($json)

                [PSCustomObject]@{
                    StatusCode       = $statusCode
                    Content          = $json
                    RawContentStream = [System.IO.MemoryStream]::new($bytes)
                    Headers          = $ResponseHeaders
                }
            }

            Mock Invoke-WebRequest -ModuleName 'JiraPS' {
                Write-MockDebugInfo 'Invoke-WebRequest' 'Uri', 'Method', 'Body', 'Headers', 'ContentType', 'SessionVariable', 'WebSession'

                if ($SessionVariable) {
                    Set-Variable -Name $SessionVariable -Value (New-Object -TypeName Microsoft.PowerShell.Commands.WebRequestSession) -Scope 3 # Pester adds 2 levels of nesting
                }

                New-FakeEchoResponse -Uri $Uri -Method $Method -Body $Body -Headers $Headers
            }
            #endregion
        }

        Describe "Signature" {
            BeforeAll {
                $script:command = Get-Command -Name Invoke-JiraMethod
            }

            Context "Parameter Types" {
                It "has a parameter '<parameter>'" -TestCases @(
                    @{ parameter = 'URI' }
                    @{ parameter = 'Method' }
                    @{ parameter = 'Body' }
                    @{ parameter = 'RawBody' }
                    @{ parameter = 'Headers' }
                    @{ parameter = 'GetParameter' }
                    @{ parameter = 'Paging' }
                    @{ parameter = 'InFile' }
                    @{ parameter = 'OutFile' }
                    @{ parameter = 'StoreSession' }
                    @{ parameter = 'OutputType' }
                    @{ parameter = 'Credential' }
                    @{ parameter = 'CmdLet' }
                    @{ parameter = 'TimeoutSec' }
                ) {
                    param($parameter)
                    $command | Should -HaveParameter $parameter
                }

                It "Restricts the METHODs to WebRequestMethod" {
                    $methodType = $command.Parameters.Method.ParameterType
                    $methodType.FullName | Should -Be "Microsoft.PowerShell.Commands.WebRequestMethod"
                }
            }

            Context "Mandatory Parameters" {}

            Context "Default Values" {}
        }

        Describe "Behavior" {
            It "uses Invoke-WebMethod under the hood" {
                Invoke-JiraMethod -URI "https://postman-echo.com/get?test=123" -ErrorAction Stop

                $assertMockCalledSplat = @{
                    CommandName = 'Invoke-WebRequest'
                    ModuleName  = 'JiraPS'
                    Exactly     = $true
                    Times       = 1
                    Scope       = 'It'
                }
                Should -Invoke @assertMockCalledSplat
            }

            It "parses a JSON response" {
                $response = Invoke-JiraMethod -URI "https://postman-echo.com/get?test=123" -ErrorAction Stop

                $response | Should -BeOfType [PSCustomObject]
            }

            It "resolves errors" {
                Invoke-JiraMethod -URI "https://postman-echo.com/status/400" -ErrorAction Stop

                Should -Invoke -CommandName Resolve-ErrorWebResponse -ModuleName 'JiraPS' -Exactly -Times 1
            }

            It "supports TLS1.2 connections" {
                Invoke-JiraMethod -URI "https://postman-echo.com/get?test=123" -ErrorAction Stop

                Should -Invoke -CommandName Set-TlsLevel -ModuleName 'JiraPS' -Exactly -Times 2
                Should -Invoke -CommandName Set-TlsLevel -ModuleName 'JiraPS' -ParameterFilter { $Tls12 -eq $true } -Exactly -Times 1
                Should -Invoke -CommandName Set-TlsLevel -ModuleName 'JiraPS' -ParameterFilter { $Revert -eq $true } -Exactly -Times 1
            }

            It "uses global default values for parameters" {
                Invoke-JiraMethod -URI "https://postman-echo.com/get?test=123" -ErrorAction Stop

                Should -Invoke -CommandName Resolve-DefaultParameterValue -ModuleName 'JiraPS' -Exactly -Times 1
            }

            It "does not log response headers before logging is configured" {
                Mock Invoke-WebRequest -ModuleName 'JiraPS' {
                    New-FakeEchoResponse -Uri $Uri -Method $Method -Body $Body -Headers $Headers -ResponseHeaders @{
                        'X-AREQUESTID' = 'request-123'
                    }
                }
                Mock Write-DebugMessage -ModuleName 'JiraPS' {}

                $script:JiraResponseHeaderLogConfiguration = $null
                Invoke-JiraMethod -URI "https://postman-echo.com/get?test=123" -ErrorAction Stop

                Should -Invoke -CommandName Write-DebugMessage -ModuleName 'JiraPS' -ParameterFilter {
                    $Message -like '*Jira response headers*'
                } -Exactly -Times 0
            }

            It "logs configured response headers from successful responses" {
                Mock Invoke-WebRequest -ModuleName 'JiraPS' {
                    New-FakeEchoResponse -Uri $Uri -Method $Method -Body $Body -Headers $Headers -ResponseHeaders @{
                        'X-AREQUESTID' = 'request-123'
                        'X-Auth-Token' = 'secret'
                        'Set-Cookie'   = 'cookie=value'
                    }
                }
                Mock Write-DebugMessage -ModuleName 'JiraPS' {}

                Set-JiraResponseHeaderLogConfiguration -Include 'X-A*' -Exclude 'X-Auth*'
                Invoke-JiraMethod -URI "https://postman-echo.com/get?test=123" -ErrorAction Stop

                Should -Invoke -CommandName Write-DebugMessage -ModuleName 'JiraPS' -ParameterFilter {
                    $Message -like '*Jira response headers*'
                } -Exactly -Times 1
                Should -Invoke -CommandName Write-DebugMessage -ModuleName 'JiraPS' -ParameterFilter {
                    $Message -like '*X-AREQUESTID*request-123*' -and
                    $Message -notlike '*secret*' -and
                    $Message -notlike '*cookie=value*'
                } -Exactly -Times 1
            }

            It "logs configured response headers from terminal error responses" {
                Mock Invoke-WebRequest -ModuleName 'JiraPS' {
                    New-FakeEchoResponse -Uri ([Uri]'https://postman-echo.com/status/400') -Method $Method -Body $Body -Headers $Headers -ResponseHeaders @{
                        'X-AREQUESTID' = 'failed-request-123'
                    }
                }
                Mock Write-DebugMessage -ModuleName 'JiraPS' {}

                Set-JiraResponseHeaderLogConfiguration -Pattern '^X-A(?!uth)'
                Invoke-JiraMethod -URI "https://postman-echo.com/status/400" -ErrorAction Stop

                Should -Invoke -CommandName Write-DebugMessage -ModuleName 'JiraPS' -ParameterFilter {
                    $Message -like '*X-AREQUESTID*failed-request-123*'
                } -Exactly -Times 1
            }

            It "always suppresses cookie and authorization response headers even when configured" {
                Mock Invoke-WebRequest -ModuleName 'JiraPS' {
                    New-FakeEchoResponse -Uri $Uri -Method $Method -Body $Body -Headers $Headers -ResponseHeaders @{
                        'Set-Cookie'          = 'sid=cookie-secret'
                        'Set-Cookie2'         = 'session=cookie2-secret'
                        'Authorization'       = 'Bearer auth-secret'
                        'Proxy-Authorization' = 'Basic proxy-secret'
                        'X-ANODEID'           = 'node-1'
                    }
                }
                Mock Write-DebugMessage -ModuleName 'JiraPS' {}

                Set-JiraResponseHeaderLogConfiguration -Include '*'
                Invoke-JiraMethod -URI "https://postman-echo.com/get?test=123" -ErrorAction Stop

                Should -Invoke -CommandName Write-DebugMessage -ModuleName 'JiraPS' -ParameterFilter {
                    $Message -like '*X-ANODEID*node-1*' -and
                    $Message -notlike '*cookie-secret*' -and
                    $Message -notlike '*cookie2-secret*' -and
                    $Message -notlike '*auth-secret*' -and
                    $Message -notlike '*proxy-secret*'
                } -Exactly -Times 1
            }

            It "does not derail the main flow when response-header logging fails" {
                Mock Invoke-WebRequest -ModuleName 'JiraPS' {
                    New-FakeEchoResponse -Uri $Uri -Method $Method -Body $Body -Headers $Headers -ResponseHeaders @{
                        'X-ANODEID' = 'node-1'
                    }
                }
                Mock Write-JiraResponseHeaderLog -ModuleName 'JiraPS' { throw 'boom' }

                Set-JiraResponseHeaderLogConfiguration -Include '*'

                { Invoke-JiraMethod -URI "https://postman-echo.com/get?test=123" -ErrorAction Stop } | Should -Not -Throw
            }
        }

        Context "Input testing" {
            It "parses a string to URi" {
                [Uri]$Uri = "https://postman-echo.com/get?test=123"
                $Uri | Should -BeOfType [Uri]

                { Invoke-JiraMethod -URI "https://postman-echo.com/get?test=123" -ErrorAction Stop } | Should -Not -Throw
                { Invoke-JiraMethod -URI $Uri -ErrorAction Stop } | Should -Not -Throw

                { Invoke-JiraMethod -URI "hello" -ErrorAction Stop } | Should -Throw -ExpectedMessage "*must start with '/'*"
            }

            It "resolves relative URIs against configured Jira server" {
                $null = Invoke-JiraMethod -URI "/rest/api/2/field" -ErrorAction Stop

                Should -Invoke -CommandName Invoke-WebRequest -ModuleName 'JiraPS' -ParameterFilter {
                    $Uri -like "https://jira.example.com/rest/api/2/field?*"
                } -Exactly -Times 1
            }

            It "throws when relative URI is used without configured Jira server" {
                Mock Get-JiraConfigServer -ModuleName 'JiraPS' { $null }

                { Invoke-JiraMethod -URI "/rest/api/2/field" -ErrorAction Stop } | Should -Throw -ExpectedMessage "*no Jira server is configured*"
            }

            It "validates URI before returning cached data" {
                $script:JiraCache = @{
                    "TestCache:https://jira.example.com" = @{
                        Data   = [PSCustomObject]@{ id = "cached-data" }
                        Expiry = (Get-Date).AddMinutes(5)
                    }
                }

                { Invoke-JiraMethod -URI "hello" -CacheKey 'TestCache' -ErrorAction Stop } | Should -Throw -ExpectedMessage "*must start with '/'*"
            }

            It "accepts [<_>] as HTTP method" -ForEach @('GET', 'POST', 'PUT', 'DELETE') {
                Invoke-JiraMethod -Method $_ -URI "https://postman-echo.com/$_" -ErrorAction Stop

                $assertMockCalledSplat = @{
                    CommandName     = 'Invoke-WebRequest'
                    ModuleName      = 'JiraPS'
                    ParameterFilter = {
                        $Method -eq $_
                    }
                    Exactly         = $true
                    Times           = 1
                    Scope           = 'It'
                }
                Should -Invoke @assertMockCalledSplat
            }

            It "encodes the Body with UTF-8 to support special chars" {
                $invokeJiraMethodSplat = @{
                    Method = 'Post'
                    URI    = "https://postman-echo.com/post"
                    Body   = $utf8String
                }
                Invoke-JiraMethod @invokeJiraMethodSplat

                $assertMockCalledSplat = @{
                    CommandName     = 'Invoke-WebRequest'
                    ModuleName      = 'JiraPS'
                    ParameterFilter = {
                        $Body -is [Byte[]] -and
                        (($Body -join " ") -eq "76 111 114 101 109 32 195 153 226 128 166 195 152 194 177 195 152 194 173 195 152 194 168 195 152 194 167 32 195 144 226 128 148 195 144 194 180 195 145 226 130 172 195 144 194 176 195 144 194 178 195 145 194 129 195 145 226 128 154 195 144 194 178 195 145 198 146 195 144 194 185 195 145 226 128 154 195 144 194 181 32 195 176 197 184 203 156 194 129" -or
                        ($Body -join " ") -eq "76 111 114 101 109 32 217 133 216 177 216 173 216 168 216 167 32 208 151 208 180 209 128 208 176 208 178 209 129 209 130 208 178 209 131 208 185 209 130 208 181 32 240 159 152 129")
                    }
                    Exactly         = $true
                    Times           = 1
                    Scope           = 'It'
                }
                Should -Invoke @assertMockCalledSplat
            }

            It "allows for skipping the UTF-8 encoding of the Body" {
                $invokeJiraMethodSplat = @{
                    Method  = 'Post'
                    URI     = "https://postman-echo.com/post"
                    Body    = $utf8String
                    RawBody = $true
                }
                Invoke-JiraMethod @invokeJiraMethodSplat

                $assertMockCalledSplat = @{
                    CommandName     = 'Invoke-WebRequest'
                    ModuleName      = 'JiraPS'
                    ParameterFilter = {
                        $Body -is [String] -and
                        $Body -eq $utf8String
                    }
                    Exactly         = $true
                    Times           = 1
                    Scope           = 'It'
                }
                Should -Invoke @assertMockCalledSplat
            }

            It "overwrites module default headers with global PSDefaultParameterValues" {
                # Mock Resolve-DefaultParameterValue so it returns a known Invoke-WebRequest header
                # without mutating the live $global:PSDefaultParameterValues (which conflicts with
                # Pester's mock infrastructure when the dict contains an 'Invoke-WebRequest:Headers' entry).
                Mock Resolve-DefaultParameterValue -ModuleName 'JiraPS' {
                    @{ 'Invoke-WebRequest:Headers' = @{ 'X-From-Default' = 'default-value' } }
                }
                Mock Join-Hashtable -ModuleName 'JiraPS' {
                    $table = @{}
                    foreach ($item in $Hashtable) {
                        if ($null -ne $item) {
                            foreach ($key in $item.Keys) { $table[$key] = $item[$key] }
                        }
                    }
                    $table
                }

                $null = Invoke-JiraMethod -Method 'Get' -URI 'https://postman-echo.com/headers' -ErrorAction SilentlyContinue

                Should -Invoke -CommandName 'Invoke-WebRequest' -ModuleName 'JiraPS' -Exactly -Times 1 -ParameterFilter {
                    $Headers.ContainsKey('X-From-Default') -and $Headers['X-From-Default'] -eq 'default-value'
                }
            }

            It "overwrites global PSDefaultParameterValues with -Header" {
                Mock Join-Hashtable -ModuleName 'JiraPS' {
                    $table = @{}
                    foreach ($item in $Hashtable) {
                        if ($null -ne $item) {
                            foreach ($key in $item.Keys) { $table[$key] = $item[$key] }
                        }
                    }
                    $table
                }

                $global:PSDefaultParameterValues['Invoke-WebRequest:Headers'] = @{ 'X-Precedence' = 'from-global' }
                try {
                    $null = Invoke-JiraMethod -Method 'Get' -URI 'https://postman-echo.com/headers' -Header @{ 'X-Precedence' = 'from-param' } -ErrorAction SilentlyContinue

                    Should -Invoke -CommandName 'Invoke-WebRequest' -ModuleName 'JiraPS' -Exactly -Times 1 -ParameterFilter {
                        $Headers['X-Precedence'] -eq 'from-param'
                    }
                }
                finally {
                    $global:PSDefaultParameterValues.Remove('Invoke-WebRequest:Headers')
                }
            }

            It "overwrites module default headers with -Header" {
                Mock Join-Hashtable -ModuleName 'JiraPS' {
                    $table = @{}
                    foreach ($item in $Hashtable) {
                        if ($null -ne $item) {
                            foreach ($key in $item.Keys) { $table[$key] = $item[$key] }
                        }
                    }
                    $table
                }

                $null = Invoke-JiraMethod -Method 'Get' -URI 'https://postman-echo.com/headers' -Header @{ 'X-Override' = 'caller-value' } -ErrorAction SilentlyContinue

                Should -Invoke -CommandName 'Invoke-WebRequest' -ModuleName 'JiraPS' -Exactly -Times 1 -ParameterFilter {
                    $Headers.ContainsKey('X-Override') -and $Headers['X-Override'] -eq 'caller-value'
                }
            }

            It "overwrites get parameters in the URI with -GetParameter values" {}

            It "passes the -InFile to Invoke-WebRequest" {
                $invokeJiraMethodSplat = @{
                    Method = 'Post'
                    URI    = "https://postman-echo.com/post"
                    InFile = "./file-does-not-exist.txt"
                }
                Invoke-JiraMethod @invokeJiraMethodSplat

                $assertMockCalledSplat = @{
                    CommandName     = 'Invoke-WebRequest'
                    ModuleName      = 'JiraPS'
                    ParameterFilter = {
                        $inFile -eq "./file-does-not-exist.txt"
                    }
                    Exactly         = $true
                    Times           = 1
                    Scope           = 'It'
                }
                Should -Invoke @assertMockCalledSplat
            }

            It "passes the -OutFile to Invoke-WebRequest" {
                $invokeJiraMethodSplat = @{
                    Method  = 'Post'
                    URI     = "https://postman-echo.com/post"
                    OutFile = "./file-does-not-exist.txt"
                }
                Invoke-JiraMethod @invokeJiraMethodSplat

                $assertMockCalledSplat = @{
                    CommandName     = 'Invoke-WebRequest'
                    ModuleName      = 'JiraPS'
                    ParameterFilter = {
                        $OutFile -eq "./file-does-not-exist.txt"
                    }
                    Exactly         = $true
                    Times           = 1
                    Scope           = 'It'
                }
                Should -Invoke @assertMockCalledSplat
            }

            It "forwards the default 100s -TimeoutSec to Invoke-WebRequest" {
                Invoke-JiraMethod -URI "https://postman-echo.com/get" -ErrorAction Stop

                Should -Invoke -CommandName Invoke-WebRequest -ModuleName 'JiraPS' -ParameterFilter {
                    $TimeoutSec -eq 100
                } -Exactly -Times 1 -Scope It
            }

            It "forwards an explicit -TimeoutSec to Invoke-WebRequest" {
                Invoke-JiraMethod -URI "https://postman-echo.com/get" -TimeoutSec 30 -ErrorAction Stop

                Should -Invoke -CommandName Invoke-WebRequest -ModuleName 'JiraPS' -ParameterFilter {
                    $TimeoutSec -eq 30
                } -Exactly -Times 1 -Scope It
            }

            It "omits TimeoutSec from the Invoke-WebRequest splat when -TimeoutSec is 0" {
                Invoke-JiraMethod -URI "https://postman-echo.com/get" -TimeoutSec 0 -ErrorAction Stop

                Should -Invoke -CommandName Invoke-WebRequest -ModuleName 'JiraPS' -ParameterFilter {
                    -not $PSBoundParameters.ContainsKey('TimeoutSec')
                } -Exactly -Times 1 -Scope It
            }

            It "rejects a negative -TimeoutSec via ValidateRange" {
                { Invoke-JiraMethod -URI "https://postman-echo.com/get" -TimeoutSec -1 -ErrorAction Stop } |
                    Should -Throw -ErrorId 'ParameterArgumentValidationError,Invoke-JiraMethod'
            }

            It "uses ConvertTo-JiraSession to store the Session" {
                $invokeJiraMethodSplat = @{
                    Method       = 'Get'
                    URI          = "https://postman-echo.com/get"
                    StoreSession = $true
                    ErrorAction  = "Stop"
                }
                Invoke-JiraMethod @invokeJiraMethodSplat

                $assertMockCalledSplat = @{
                    CommandName     = "Invoke-WebRequest"
                    ModuleName      = 'JiraPS'
                    ParameterFilter = { $SessionVariable -eq "newSessionVar" }
                    Exactly         = $true
                    Times           = 1
                    Scope           = 'It'
                }
                Should -Invoke @assertMockCalledSplat
                Should -Invoke -CommandName ConvertTo-JiraSession -ModuleName 'JiraPS' -Exactly -Times 1
            }

            foreach ($type in $supportedTypes) {
                It "uses ConvertTo-$type to transform the results" {
                    Invoke-JiraMethod -Method get -URI "https://postman-echo.com/get" -OutputType $type -Paging -ErrorAction Stop

                    $assertMockCalledSplat = @{
                        CommandName     = "Convert-Result"
                        ModuleName      = 'JiraPS'
                        ParameterFilter = { $OutputType -eq $type }
                        Exactly         = $true
                        Times           = 1
                        Scope           = 'It'
                    }
                    Should -Invoke @assertMockCalledSplat
                }

                It "only uses -OutputType with -Paging [$type]" {
                    Invoke-JiraMethod -Method get -URI "https://postman-echo.com/get" -OutputType $type -ErrorAction Stop

                    $assertMockCalledSplat = @{
                        CommandName     = "Convert-Result"
                        ModuleName      = 'JiraPS'
                        ParameterFilter = { $OutputType -eq $type }
                        Exactly         = $true
                        Times           = 0
                        Scope           = 'It'
                    }
                    Should -Invoke @assertMockCalledSplat
                }
            }

            It "uses session if no -Credential are passed" {
                $invokeJiraMethodSplat = @{
                    URI         = "https://postman-echo.com/get"
                    Method      = 'get'
                    ErrorAction = "Stop"
                }
                Invoke-JiraMethod @invokeJiraMethodSplat

                $assertMockCalledSplat = @{
                    CommandName     = 'Invoke-WebRequest'
                    ModuleName      = 'JiraPS'
                    ParameterFilter = {
                        $WebSession -is [Microsoft.PowerShell.Commands.WebRequestSession] -and
                        $Credential -eq $null
                    }
                    Exactly         = $true
                    Times           = 1
                    Scope           = 'It'
                }
                Should -Invoke @assertMockCalledSplat
                Should -Invoke -CommandName Get-JiraSession -ModuleName 'JiraPS' -Exactly -Times 1
            }

            It "uses -Credential even if session is present" {
                Mock Get-JiraSession -ModuleName 'JiraPS' {
                    [PSCustomObject]@{
                        WebSession = New-Object -TypeName Microsoft.PowerShell.Commands.WebRequestSession
                    }
                }

                $invokeJiraMethodSplat = @{
                    URI         = "https://postman-echo.com/get"
                    Method      = 'get'
                    Credential  = $testCred
                    ErrorAction = "Stop"
                }
                Invoke-JiraMethod @invokeJiraMethodSplat

                $assertMockCalledSplat = @{
                    CommandName     = 'Invoke-WebRequest'
                    ModuleName      = 'JiraPS'
                    ParameterFilter = {
                        $SessionVariable -eq $null -and
                        $Credential -ne $null
                    }
                    Exactly         = $true
                    Times           = 1
                    Scope           = 'It'
                }
                Should -Invoke @assertMockCalledSplat
                Should -Invoke -CommandName Get-JiraSession -ModuleName 'JiraPS' -Exactly -Times 0
            }

            It "uses -Headers for the call" {
                Mock Join-Hashtable -ModuleName 'JiraPS' {
                    $table = @{ }
                    foreach ($item in $Hashtable) {
                        foreach ($key in $item.Keys) {
                            $table[$key] = $item[$key]
                        }
                    }
                    $table
                }

                $invokeJiraMethodSplat = @{
                    Method      = 'Get'
                    URI         = "https://postman-echo.com/headers"
                    Headers     = @{
                        "X-Fake" = "lorem ipsum"
                    }
                    ErrorAction = "Stop"
                }
                $defaultResponse = Invoke-JiraMethod @invokeJiraMethodSplat

                $invokeJiraMethodSplat["Headers"] = @{
                    "X-Fake" = "dolor sum"
                }
                $changedResponse = Invoke-JiraMethod @invokeJiraMethodSplat

                $defaultResponse.headers."x-fake" | Should -Be "lorem ipsum"
                $changedResponse.headers."x-fake" | Should -Be "dolor sum"

                $assertMockCalledSplat = @{
                    CommandName = "Invoke-WebRequest"
                    ModuleName  = 'JiraPS'
                    Exactly     = $true
                    Times       = 2
                    Scope       = 'It'
                }
                Should -Invoke @assertMockCalledSplat
            }

            It "uses authenticates as anonymous when no -Credential is provided and no session exists" -Pending {
                Mock Get-JiraSession -ModuleName 'JiraPS' {
                    $null
                }

                $invokeJiraMethodSplat = @{
                    Method      = 'Get'
                    URI         = "https://postman-echo.com/headers"
                    ErrorAction = "Stop"
                }
                Invoke-JiraMethod @invokeJiraMethodSplat

                $assertMockCalledSplat = @{
                    CommandName     = "Invoke-WebRequest"
                    ModuleName      = 'JiraPS'
                    ParameterFilter = {
                        $Credential -eq $null -and
                        $WebSession -eq $null
                    }
                    Exactly         = $true
                    Times           = 2
                    Scope           = 'It'
                }
                Should -Invoke @assertMockCalledSplat
            }

            It "removes and content-type from headers and uses Invoke-WebRequest's -ContentType" {
                Mock Join-Hashtable -ModuleName 'JiraPS' {
                    $table = @{ }
                    foreach ($item in $Hashtable) {
                        foreach ($key in $item.Keys) {
                            $table[$key] = $item[$key]
                        }
                    }
                    $table
                }

                $invokeJiraMethodSplat = @{
                    Method      = 'Get'
                    URI         = "https://postman-echo.com/headers"
                    ErrorAction = "Stop"
                }
                $null = Invoke-JiraMethod @invokeJiraMethodSplat

                $invokeJiraMethodSplat["Headers"] = @{
                    "Content-Type" = "text/plain"
                }
                $null = Invoke-JiraMethod @invokeJiraMethodSplat

                $assertMockCalledSplat = @{
                    CommandName     = "Invoke-WebRequest"
                    ModuleName      = 'JiraPS'
                    ParameterFilter = {
                        $Uri -notlike "*contentType*" -and
                        $Uri -notlike "*content-Type*" -and
                        $ContentType -eq "application/json; charset=utf-8"
                    }
                    Exactly         = $true
                    Times           = 1
                    Scope           = 'It'
                }
                Should -Invoke @assertMockCalledSplat

                $assertMockCalledSplat["ParameterFilter"] = {
                    $Uri -notlike "*contentType*" -and
                    $Uri -notlike "*content-Type*" -and
                    $ContentType -eq "text/plain"
                }
                Should -Invoke @assertMockCalledSplat
            }

            It "can handle UTF-8 chars in the response" {
                $invokeJiraMethodSplat = @{
                    Method      = 'Post'
                    URI         = "https://postman-echo.com/post"
                    Body        = $utf8String
                    ErrorAction = "Stop"
                }
                $response = Invoke-JiraMethod @invokeJiraMethodSplat

                $response.data | Should -Be $utf8String
            }
        }

        Context "Paged restuls" {
            BeforeAll {
                # Offline paging mock - the previous version round-tripped through
                # postman-echo.com to obtain a "real" Invoke-WebRequest result shape
                # and then monkey-patched RawContentStream.ToArray onto it. Building
                # the response directly from a MemoryStream is simpler and avoids ~6
                # real HTTP calls that this Context used to make on every run.
                Mock Invoke-WebRequest -ModuleName 'JiraPS' {
                    Write-MockDebugInfo 'Invoke-WebRequest' -Params 'Uri', 'Method', 'Body'

                    $response = switch -Regex ([string]$Uri) {
                        'startAt=5' { $pagedResponse2; break }
                        'startAt=7' { $pagedResponse3; break }
                        default { $pagedResponse1 }
                    }

                    $bytes = [System.Text.Encoding]::UTF8.GetBytes($response)
                    [PSCustomObject]@{
                        StatusCode       = [System.Net.HttpStatusCode]::OK
                        Content          = $response
                        RawContentStream = [System.IO.MemoryStream]::new($bytes)
                    }
                }
                Mock Join-Hashtable -ModuleName 'JiraPS' {
                    $table = @{ }
                    foreach ($item in $Hashtable) {
                        foreach ($key in $item.Keys) {
                            $table[$key] = $item[$key]
                        }
                    }
                    $table
                }
                Mock Convert-Result -ModuleName 'JiraPS' {
                    $InputObject
                }
                Mock Expand-Result -ModuleName 'JiraPS' {
                    $InputObject.issues
                }
            }

            It "requests each page of the results" {
                {
                    $invokeJiraMethodSplat = @{
                        Method      = 'Get'
                        URI         = "https://postman-echo.com/Get"
                        Paging      = $true
                        ErrorAction = "Stop"
                    }
                    Invoke-JiraMethod @invokeJiraMethodSplat
                } | Should -Not -Throw

                $assertMockCalledSplat = @{
                    CommandName = 'Invoke-WebRequest'
                    ModuleName  = 'JiraPS'
                    Exactly     = $true
                    Times       = 2
                    Scope       = 'It'
                }
                Should -Invoke @assertMockCalledSplat
            }

            It "expands the data container" {
                $invokeJiraMethodSplat = @{
                    Method      = 'Get'
                    URI         = "https://postman-echo.com/Get"
                    Paging      = $true
                    ErrorAction = "Stop"
                }
                $null = Invoke-JiraMethod @invokeJiraMethodSplat

                $assertMockCalledSplat = @{
                    CommandName = 'Expand-Result'
                    ModuleName  = 'JiraPS'
                    Exactly     = $true
                    Times       = 3
                    Scope       = 'It'
                }
                Should -Invoke @assertMockCalledSplat
            }

            It "fetches only the necessary amount of pages when -First is used" {
                $invokeJiraMethodSplat = @{
                    Method      = 'Get'
                    URI         = "https://postman-echo.com/Get"
                    Paging      = $true
                    First       = 4
                    ErrorAction = "Stop"
                }
                $result = Invoke-JiraMethod @invokeJiraMethodSplat

                $result | Should -HaveCount 4

                $assertMockCalledSplat = @{
                    CommandName = 'Invoke-WebRequest'
                    ModuleName  = 'JiraPS'
                    Exactly     = $true
                    Times       = 1
                    Scope       = 'It'
                }
                Should -Invoke @assertMockCalledSplat
            }

            It "limits the number of results when -First is used" {
                $invokeJiraMethodSplat = @{
                    Method      = 'Get'
                    URI         = "https://postman-echo.com/Get"
                    Paging      = $true
                    First       = 6
                    ErrorAction = "Stop"
                }
                $result = Invoke-JiraMethod @invokeJiraMethodSplat

                $result | Should -HaveCount 6

                $assertMockCalledSplat = @{
                    CommandName = 'Invoke-WebRequest'
                    ModuleName  = 'JiraPS'
                    Exactly     = $true
                    Times       = 2
                    Scope       = 'It'
                }
                Should -Invoke @assertMockCalledSplat
            }

            It "starts looking for results with an offset when -Skip is provided" {
                $invokeJiraMethodSplat = @{
                    Method      = 'Get'
                    URI         = "https://postman-echo.com/Get"
                    Paging      = $true
                    Skip        = 5
                    ErrorAction = "Stop"
                }
                $result = Invoke-JiraMethod @invokeJiraMethodSplat

                $result | Should -HaveCount 2

                $assertMockCalledSplat = @{
                    CommandName = 'Invoke-WebRequest'
                    ModuleName  = 'JiraPS'
                    Exactly     = $true
                    Times       = 1
                    Scope       = 'It'
                }
                Should -Invoke @assertMockCalledSplat
            }

            It "-totalcount" {
                # Don't know how to test this
            }
        }

        Describe "Input Validation" {
            Context "Type Validation - Positive Cases" {}

            Context "Type Validation - Negative Cases" {}
        }

        Describe "Caching Behavior" {
            BeforeAll {
                $jiraServer = 'http://jiraserver.example.com'

                Mock Get-JiraConfigServer -ModuleName JiraPS { $jiraServer }

                Mock Invoke-WebRequest -ModuleName JiraPS {
                    $result = [PSCustomObject]@{
                        StatusCode       = 200
                        Content          = '{"id": "test-data", "name": "Test"}'
                        RawContentStream = [System.IO.MemoryStream]::new([System.Text.Encoding]::UTF8.GetBytes('{"id": "test-data", "name": "Test"}'))
                    }
                    $result
                }
            }

            BeforeEach {
                $script:JiraCache = @{}
            }

            It "caches GET responses when CacheKey is provided" {
                $null = Invoke-JiraMethod -Uri "$jiraServer/rest/api/2/field" -CacheKey 'TestCache'

                $script:JiraCache.Keys | Should -Contain "TestCache:$jiraServer"
                $script:JiraCache["TestCache:$jiraServer"].Data | Should -Not -BeNullOrEmpty
            }

            It "returns cached data on subsequent calls" {
                $null = Invoke-JiraMethod -Uri "$jiraServer/rest/api/2/field" -CacheKey 'TestCache'
                $null = Invoke-JiraMethod -Uri "$jiraServer/rest/api/2/field" -CacheKey 'TestCache'

                Should -Invoke Invoke-WebRequest -ModuleName JiraPS -Times 1 -Exactly
            }

            It "bypasses cache when -BypassCache is specified" {
                $null = Invoke-JiraMethod -Uri "$jiraServer/rest/api/2/field" -CacheKey 'TestCache'
                $null = Invoke-JiraMethod -Uri "$jiraServer/rest/api/2/field" -CacheKey 'TestCache' -BypassCache

                Should -Invoke Invoke-WebRequest -ModuleName JiraPS -Times 2 -Exactly
            }

            It "does not cache non-GET requests" {
                $null = Invoke-JiraMethod -Uri "$jiraServer/rest/api/2/issue" -Method POST -CacheKey 'TestCache' -Body '{}'

                $script:JiraCache.Keys | Should -Not -Contain "TestCache:$jiraServer"
            }

            It "sets correct expiry time based on CacheExpiry TimeSpan" {
                $null = Invoke-JiraMethod -Uri "$jiraServer/rest/api/2/field" -CacheKey 'TestCache' -CacheExpiry ([TimeSpan]::FromMinutes(30))

                $entry = $script:JiraCache["TestCache:$jiraServer"]
                $entry.Expiry | Should -BeGreaterThan (Get-Date)
                $entry.Expiry | Should -BeLessThan (Get-Date).AddMinutes(31)
            }

            It "accepts CacheExpiry in various TimeSpan units" {
                $null = Invoke-JiraMethod -Uri "$jiraServer/rest/api/2/field" -CacheKey 'TestHours' -CacheExpiry ([TimeSpan]::FromHours(2))

                $entry = $script:JiraCache["TestHours:$jiraServer"]
                $entry.Expiry | Should -BeGreaterThan (Get-Date).AddMinutes(119)
                $entry.Expiry | Should -BeLessThan (Get-Date).AddMinutes(121)
            }

            It "fetches fresh data when cache is expired" {
                $script:JiraCache["TestCache:$jiraServer"] = @{
                    Data   = @{ id = "old-data" }
                    Expiry = (Get-Date).AddMinutes(-1)
                }

                $result = Invoke-JiraMethod -Uri "$jiraServer/rest/api/2/field" -CacheKey 'TestCache'

                Should -Invoke Invoke-WebRequest -ModuleName JiraPS -Times 1 -Exactly
                $result.id | Should -Be "test-data"
            }

            It "creates separate cache entries for different servers" {
                $server1 = 'http://server1.example.com'
                $server2 = 'http://server2.example.com'

                Mock Get-JiraConfigServer -ModuleName JiraPS { $server1 }
                $null = Invoke-JiraMethod -Uri "$server1/rest/api/2/field" -CacheKey 'Fields'

                Mock Get-JiraConfigServer -ModuleName JiraPS { $server2 }
                $null = Invoke-JiraMethod -Uri "$server2/rest/api/2/field" -CacheKey 'Fields'

                $script:JiraCache.Keys | Should -HaveCount 2
                $script:JiraCache.Keys | Should -Contain "Fields:$server1"
                $script:JiraCache.Keys | Should -Contain "Fields:$server2"
            }
        }
    }
}

