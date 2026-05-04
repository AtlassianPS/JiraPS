#requires -modules @{ ModuleName = "Pester"; ModuleVersion = "5.7"; MaximumVersion = "5.999" }

BeforeDiscovery {
    . "$PSScriptRoot/../../Helpers/TestTools.ps1"

    $script:moduleToTest = Initialize-TestEnvironment
}

InModuleScope JiraPS {
    Describe "Resolve-JiraWebResponse" -Tag 'Unit' {
        BeforeAll {
            . "$PSScriptRoot/../../Helpers/TestTools.ps1"

            function script:New-FakeWebResponse {
                param(
                    [int]$StatusCode = 200,
                    [string]$Json = '{"id":1}'
                )

                $bytes = [System.Text.Encoding]::UTF8.GetBytes($Json)
                [PSCustomObject]@{
                    StatusCode       = [System.Net.HttpStatusCode]$StatusCode
                    Content          = $Json
                    RawContentStream = [System.IO.MemoryStream]::new($bytes)
                }
            }

            function script:Invoke-ResolveJiraWebResponse {
                [CmdletBinding()]
                param(
                    [Parameter(ValueFromRemainingArguments = $true)]
                    $Remaining
                )

                Resolve-JiraWebResponse @Remaining -Cmdlet $PSCmdlet
            }
        }

        It "delegates HTTP errors to Resolve-ErrorWebResponse" {
            Mock Resolve-ErrorWebResponse -ModuleName 'JiraPS' {}

            $response = New-FakeWebResponse -StatusCode 400
            $null = Invoke-ResolveJiraWebResponse -Remaining @{ WebResponse = $response; Exception = [System.Exception]::new('boom') }

            Should -Invoke -CommandName Resolve-ErrorWebResponse -ModuleName 'JiraPS' -Exactly -Times 1 -Scope It
        }

        It "falls back to Exception.Response.StatusCode when direct status code is unavailable" {
            Mock Resolve-ErrorWebResponse -ModuleName 'JiraPS' {}
            $bytes = [System.Text.Encoding]::UTF8.GetBytes('{}')
            $response = [PSCustomObject]@{
                StatusCode       = $null
                Exception        = [PSCustomObject]@{
                    Response = [PSCustomObject]@{
                        StatusCode = [System.Net.HttpStatusCode]::BadRequest
                    }
                }
                Content          = '{}'
                RawContentStream = [System.IO.MemoryStream]::new($bytes)
            }

            $null = Invoke-ResolveJiraWebResponse -Remaining @{
                WebResponse = $response
                Exception   = [System.Exception]::new('fallback-error')
            }

            Should -Invoke -CommandName Resolve-ErrorWebResponse -ModuleName 'JiraPS' -Exactly -Times 1 -Scope It -ParameterFilter {
                $StatusCode -eq [System.Net.HttpStatusCode]::BadRequest
            }
        }

        It "returns nothing when no web response object is provided" {
            { $script:result = Invoke-ResolveJiraWebResponse -Remaining @{} } | Should -Not -Throw
            $script:result | Should -BeNullOrEmpty
        }

        It "returns transformed session when -StoreSession is set" {
            Mock ConvertTo-JiraSession -ModuleName 'JiraPS' {
                [PSCustomObject]@{
                    Username = $Username
                }
            }

            $response = New-FakeWebResponse -StatusCode 200
            $securePassword = [System.Security.SecureString]::new()
            'pw'.ToCharArray() | ForEach-Object { $securePassword.AppendChar($_) }
            $securePassword.MakeReadOnly()
            $credential = [pscredential]::new('user@example.com', $securePassword)
            $session = [Microsoft.PowerShell.Commands.WebRequestSession]::new()
            $result = Invoke-ResolveJiraWebResponse -Remaining @{
                WebResponse                 = $response
                StoreSession                = $true
                Credential                  = $credential
                SessionTransformationMethod = 'ConvertTo-JiraSession'
                Session                     = $session
            }

            $result.Username | Should -Be 'user@example.com'
        }

        It "stores cache entries for GET responses when CacheKey is provided" {
            Mock Get-JiraConfigServer -ModuleName 'JiraPS' { 'https://jira.example.com' }
            $script:JiraCache = @{}

            $response = New-FakeWebResponse -StatusCode 200 -Json '{"name":"field"}'
            $null = Invoke-ResolveJiraWebResponse -Remaining @{
                WebResponse = $response
                CacheKey    = 'Fields'
                Method      = 'GET'
                CacheExpiry = [TimeSpan]::FromMinutes(30)
            }

            $script:JiraCache.ContainsKey('Fields:https://jira.example.com') | Should -BeTrue
            $script:JiraCache['Fields:https://jira.example.com'].Data.name | Should -Be 'field'
        }

        It "does not create a cache entry for non-GET responses" {
            Mock Get-JiraConfigServer -ModuleName 'JiraPS' { 'https://jira.example.com' }
            $script:JiraCache = @{}

            $response = New-FakeWebResponse -StatusCode 200 -Json '{"name":"field"}'
            $null = Invoke-ResolveJiraWebResponse -Remaining @{
                WebResponse = $response
                CacheKey    = 'Fields'
                Method      = 'POST'
            }

            $script:JiraCache.Count | Should -Be 0
        }

        It "returns nothing when successful response has no content" {
            $response = [PSCustomObject]@{
                StatusCode       = [System.Net.HttpStatusCode]::OK
                Content          = ''
                RawContentStream = [System.IO.MemoryStream]::new(@())
            }

            $result = Invoke-ResolveJiraWebResponse -Remaining @{
                WebResponse = $response
                Method      = 'GET'
            }

            $result | Should -BeNullOrEmpty
        }

        It "returns parsed response for successful non-paging requests" {
            Mock Invoke-PaginatedRequest -ModuleName 'JiraPS' { throw 'Should not be called for non-paging response.' }

            $response = New-FakeWebResponse -StatusCode 200 -Json '{"id":42,"name":"ok"}'
            $result = Invoke-ResolveJiraWebResponse -Remaining @{
                WebResponse = $response
                Method      = 'GET'
            }

            $result.id | Should -Be 42
            $result.name | Should -Be 'ok'
            Should -Invoke -CommandName Invoke-PaginatedRequest -ModuleName 'JiraPS' -Exactly -Times 0 -Scope It
        }

        It "delegates paging results to Invoke-PaginatedRequest when -Paging is set" {
            Mock Invoke-PaginatedRequest -ModuleName 'JiraPS' { @('paged') }

            $response = New-FakeWebResponse -StatusCode 200 -Json '{"issues":[{"id":1}],"startAt":0,"maxResults":1,"total":1}'
            $result = Invoke-ResolveJiraWebResponse -Remaining @{
                WebResponse     = $response
                Paging          = $true
                BoundParameters = @{ Uri = 'https://jira.example.com' }
            }

            $result | Should -Be @('paged')
            Should -Invoke -CommandName Invoke-PaginatedRequest -ModuleName 'JiraPS' -Exactly -Times 1 -Scope It
        }
    }
}
