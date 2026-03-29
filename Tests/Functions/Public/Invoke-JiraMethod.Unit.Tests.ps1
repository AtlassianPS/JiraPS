#requires -modules @{ ModuleName = "Pester"; ModuleVersion = "5.7"; MaximumVersion = "5.999" }

[Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSAvoidUsingConvertToSecureStringWithPlainText", "")]
param()

BeforeDiscovery {
    . "$PSScriptRoot/../../Helpers/TestTools.ps1"

    Initialize-TestEnvironment
    $script:moduleToTest = Resolve-ModuleSource

    Import-Module $script:moduleToTest -Force -ErrorAction Stop
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
            Mock Invoke-WebRequest -ModuleName 'JiraPS' {
                Write-MockDebugInfo 'Invoke-WebRequest' 'Uri', 'Method', 'Body', 'Headers', 'ContentType', 'SessionVariable', 'WebSession'
                $InvokeWebRequestSplat = @{
                    Uri             = $Uri
                    Method          = $Method
                    Body            = $Body
                    Headers         = $Headers
                    WebSession      = $WebSession
                    ContentType     = $ContentType
                    UseBasicParsing = $true
                }
                if ($SessionVariable) {
                    $InvokeWebRequestSplat["SessionVariable"] = $SessionVariable
                }

                Microsoft.PowerShell.Utility\Invoke-WebRequest @InvokeWebRequestSplat

                if ($SessionVariable) {
                    Set-Variable -Name $SessionVariable -Value (Get-Variable $SessionVariable).Value -Scope 3 # Pester adds 2 levels of nesting
                }
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

                Should -Invoke -CommandName Resolve-ErrorWebResponse -ModuleName 'JiraPS' -Exactly -Times 1 -Scope It
            }

            It "supports TLS1.2 connections" {
                Invoke-JiraMethod -URI "https://postman-echo.com/get?test=123" -ErrorAction Stop

                Should -Invoke -CommandName Set-TlsLevel -ModuleName 'JiraPS' -Exactly -Times 2 -Scope It
                Should -Invoke -CommandName Set-TlsLevel -ModuleName 'JiraPS' -ParameterFilter { $Tls12 -eq $true } -Exactly -Times 1 -Scope It
                Should -Invoke -CommandName Set-TlsLevel -ModuleName 'JiraPS' -ParameterFilter { $Revert -eq $true } -Exactly -Times 1 -Scope It
            }

            It "uses global default values for parameters" {
                Invoke-JiraMethod -URI "https://postman-echo.com/get?test=123" -ErrorAction Stop

                Should -Invoke -CommandName Resolve-DefaultParameterValue -ModuleName 'JiraPS' -Exactly -Times 1 -Scope It
            }
        }

        Context "Input testing" {
            It "parses a string to URi" {
                [Uri]$Uri = "https://postman-echo.com/get?test=123"
                $Uri | Should -BeOfType [Uri]

                { Invoke-JiraMethod -URI "https://postman-echo.com/get?test=123" -ErrorAction Stop } | Should -Not -Throw
                { Invoke-JiraMethod -URI $Uri -ErrorAction Stop } | Should -Not -Throw

                { Invoke-JiraMethod -URI "hello" -ErrorAction Stop } | Should -Throw
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

            It "overwrites module default headers with global PSDefaultParameterValues" {}

            It "overwrites global PSDefaultParameterValues with -Headers" {}

            It "overwrites module default headers with -Headers" {}

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
                Should -Invoke -CommandName ConvertTo-JiraSession -ModuleName 'JiraPS' -Exactly -Times 1 -Scope It
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
                Should -Invoke -CommandName Get-JiraSession -ModuleName 'JiraPS' -Exactly -Times 1 -Scope It
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
                Should -Invoke -CommandName Get-JiraSession -ModuleName 'JiraPS' -Exactly -Times 0 -Scope It
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
                Mock Invoke-WebRequest -ModuleName 'JiraPS' {
                    Write-MockDebugInfo 'Invoke-WebRequest' -Params 'Uri', 'Method', 'Body'

                    $response = ""
                    if ($Uri -match "startAt\=(\d+)") {
                        switch ($matches[1]) {
                            5 { $response = $pagedResponse2; break }
                            7 { $response = $pagedResponse3; break }
                        }
                    }
                    if (-not $response) {
                        $response = $pagedResponse1
                    }

                    $InvokeWebRequestSplat = @{
                        Uri             = "https://postman-echo.com/post"
                        Method          = "Post"
                        Body            = $response
                        UseBasicParsing = $true

                    }
                    $result = Microsoft.PowerShell.Utility\Invoke-WebRequest @InvokeWebRequestSplat

                    $scriptBlock = "`$response = @`"`n$response`n`"@;Write-Output ([System.Text.Encoding]::UTF8.GetBytes(`$response))"
                    $result.RawContentStream | Add-Member -MemberType ScriptMethod -Name "ToArray" -Force -Value ([Scriptblock]::Create($scriptBlock))
                    $result
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
    }
}

