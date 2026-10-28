#requires -modules @{ ModuleName = "Pester"; ModuleVersion = "6.2.0"; MaximumVersion = "6.999" }

BeforeDiscovery {
    . "$PSScriptRoot/../../Helpers/TestTools.ps1"
    $script:moduleToTest = Initialize-TestEnvironment
}

InModuleScope JiraPS {
    Describe 'Jira deployment validation' -Tag Unit {
        BeforeAll {
            . "$PSScriptRoot/../../Helpers/TestTools.ps1"
            $script:moduleToTest = Initialize-TestEnvironment

            function Get-ValidationWebResponse {
                param([String]$Json, [System.Net.HttpStatusCode]$Status = 'OK')

                [PSCustomObject]@{
                    StatusCode       = $Status
                    Content          = $Json
                    RawContentStream = [IO.MemoryStream]::new([Text.Encoding]::UTF8.GetBytes($Json))
                    Headers          = @{ 'Content-Type' = 'application/json' }
                }
            }
        }

        BeforeEach {
            $script:previousDefault = Get-JiraConnection -Default
            $script:metadata = '{"deploymentType":"Server"}'
            $script:metadataStatus = [System.Net.HttpStatusCode]::OK
            $script:identity = '{"name":"validated-user"}'
            $script:identityStatus = [System.Net.HttpStatusCode]::OK
            $script:projects = '[{"id":"10000","key":"PUBLIC","name":"Public project","self":"https://jira.example.com/rest/api/2/project/10000"}]'
            $script:projectStatus = [System.Net.HttpStatusCode]::OK
            Mock Invoke-WebRequest {
                switch -Regex ($Uri.AbsolutePath) {
                    '/_edge/tenant_info$' {
                        Get-ValidationWebResponse '{"cloudId":"11111111-1111-1111-1111-111111111111"}'
                    }
                    '/rest/api/2/serverInfo$' { Get-ValidationWebResponse $script:metadata $script:metadataStatus }
                    '/rest/api/2/myself$' { Get-ValidationWebResponse $script:identity $script:identityStatus }
                    '/rest/api/2/project$' { Get-ValidationWebResponse $script:projects $script:projectStatus }
                    default { throw 'Unexpected validation request.' }
                }
            }
        }

        AfterEach {
            Get-JiraConnection | Where-Object Name -Like 'validation-*' | Disconnect-Jira
            if ($previousDefault -and $previousDefault.State -eq 'Active') {
                $previousDefault | Select-JiraConnection | Out-Null
            }
        }

        It 'accepts recognized deployment metadata without a version' {
            $connection = Connect-Jira -Name validation-version -Uri https://jira.example.com -PersonalAccessToken sentinel-token
            $connection.DeploymentType | Should -Be 'Server'
            $connection.Username | Should -Be 'validated-user'
            Should -Invoke Invoke-WebRequest -Exactly 1 -ParameterFilter { $Uri.AbsolutePath -eq '/rest/api/2/myself' }
        }

        It 'uses Cloud gateway and identity evidence after metadata HTTP <Status>' -ForEach @(
            @{ Status = 403 }
            @{ Status = 404 }
            @{ Status = 405 }
        ) {
            $script:metadataStatus = [System.Net.HttpStatusCode]$Status
            $script:identity = '{"accountId":"validated-account"}'
            Mock 'Microsoft.PowerShell.Utility\Invoke-WebRequest' -ParameterFilter { $Uri.AbsolutePath -eq '/_edge/tenant_info' } {
                Get-ValidationWebResponse '{"cloudId":"11111111-1111-1111-1111-111111111111"}'
            }
            $connection = Connect-Jira -Name validation-cloud -Uri https://site.atlassian.net -EmailAddress user@example.com -ApiToken sentinel-token
            $connection.DeploymentType | Should -Be 'Cloud'
            $connection.Username | Should -Be 'validated-account'
            $connection.CloudId | Should -Be '11111111-1111-1111-1111-111111111111'
            Should -Invoke 'Microsoft.PowerShell.Utility\Invoke-WebRequest' -Exactly 1 -ParameterFilter {
                $Uri.AbsolutePath -eq '/_edge/tenant_info' -and -not $Headers.Authorization -and -not $Credential
            }
            Should -Invoke Invoke-WebRequest -Exactly 2 -ParameterFilter {
                $Uri.Host -eq 'api.atlassian.com' -and $Headers.Authorization -eq 'Basic ' + [Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes('user@example.com:sentinel-token'))
            }
        }

        It 'infers Server from a validated username when metadata is absent' {
            $script:metadata = '{}'
            $connection = Connect-Jira -Name validation-server -Uri https://jira.example.com -PersonalAccessToken sentinel-token
            $connection.DeploymentType | Should -Be 'Server'
            $connection.Username | Should -Be 'validated-user'
        }

        It 'infers Cloud from accountId without a gateway when metadata is restricted' {
            $script:metadataStatus = [System.Net.HttpStatusCode]::Forbidden
            $script:identity = '{"accountId":"validated-account"}'
            $password = [SecureString]::new()
            foreach ($character in 'sentinel-token'.ToCharArray()) { $password.AppendChar($character) }
            $credential = [PSCredential]::new('user@example.com', $password)
            $connection = Connect-Jira -Name validation-cloud-credential -Uri https://site.atlassian.net -Credential $credential
            $connection.DeploymentType | Should -Be 'Cloud'
            $connection.CloudId | Should -BeNullOrEmpty
        }

        It 'supports an explicit deployment with missing metadata: <Deployment>' -ForEach @(
            @{ Deployment = 'Cloud'; Identity = '{"accountId":"validated-account"}' }
            @{ Deployment = 'Server'; Identity = '{"name":"validated-user"}' }
            @{ Deployment = 'Data Center'; Identity = '{"name":"validated-user"}' }
        ) {
            $script:metadataStatus = [System.Net.HttpStatusCode]::NotFound
            $script:identity = $Identity
            $connection = Connect-Jira -Name validation-explicit -Uri https://jira.example.com -PersonalAccessToken sentinel-token -DeploymentType $Deployment
            $connection.DeploymentType | Should -Be $Deployment
            Should -Invoke Invoke-WebRequest -Exactly 1 -ParameterFilter { $Uri.AbsolutePath -eq '/rest/api/2/myself' }
        }

        It 'preserves Server metadata when a Data Center hint agrees with its API family' {
            $connection = Connect-Jira -Name validation-family -Uri https://jira.example.com -PersonalAccessToken sentinel-token -DeploymentType 'Data Center'
            $connection.DeploymentType | Should -Be 'Server'
        }

        It 'forwards the explicit deployment through New-JiraSession' {
            $script:metadataStatus = [System.Net.HttpStatusCode]::NotFound
            $connection = New-JiraSession -Name validation-legacy -Uri https://jira.example.com -PersonalAccessToken sentinel-token -DeploymentType 'Data Center'
            $connection.DeploymentType | Should -Be 'Data Center'
        }

        It 'rejects identity denial with HTTP <Status> despite recognized metadata and an explicit deployment' -ForEach @(
            @{ Status = 401 }
            @{ Status = 403 }
        ) {
            $script:identityStatus = [System.Net.HttpStatusCode]$Status
            { Connect-Jira -Name validation-denied -Uri https://jira.example.com -PersonalAccessToken sentinel-token -DeploymentType Server -Default } |
                Should -Throw -ErrorId "InvalidResponse.Status$Status*"
            Get-JiraConnection -Name validation-denied | Should -BeNullOrEmpty
            (Get-JiraConnection -Default).InstanceId | Should -Be $previousDefault.InstanceId
        }

        It 'rejects ambiguous or invalid identities: <Identity>' -ForEach @(
            @{ Identity = '{"accountId":"account","name":"user"}' }
            @{ Identity = '{}' }
            @{ Identity = '{"name":" "}' }
            @{ Identity = '{"accountId":123}' }
        ) {
            $script:metadata = '{}'
            $script:identity = $Identity
            { Connect-Jira -Name validation-invalid -Uri https://jira.example.com -PersonalAccessToken sentinel-token -Default } | Should -Throw '*identity*'
            Get-JiraConnection -Name validation-invalid | Should -BeNullOrEmpty
            (Get-JiraConnection -Default).InstanceId | Should -Be $previousDefault.InstanceId
        }

        It 'rejects contradictory metadata, identity or explicit deployment' -ForEach @(
            @{ Metadata = 'Cloud'; Identity = '{"name":"user"}'; Deployment = 'Cloud' }
            @{ Metadata = 'Server'; Identity = '{"accountId":"account"}'; Deployment = 'Server' }
            @{ Metadata = 'Server'; Identity = '{"name":"user"}'; Deployment = 'Cloud' }
            @{ Metadata = 'Cloud'; Identity = '{"accountId":"account"}'; Deployment = 'Data Center' }
        ) {
            $script:metadata = @{ deploymentType = $Metadata } | ConvertTo-Json -Compress
            $script:identity = $Identity
            { Connect-Jira -Name validation-conflict -Uri https://jira.example.com -PersonalAccessToken sentinel-token -DeploymentType $Deployment -Default } | Should -Throw '*Conflicting*'
            Get-JiraConnection -Name validation-conflict | Should -BeNullOrEmpty
            (Get-JiraConnection -Default).InstanceId | Should -Be $previousDefault.InstanceId
        }

        It 'rejects identity evidence that contradicts the resolved Cloud gateway' {
            $script:metadataStatus = [System.Net.HttpStatusCode]::NotFound
            { Connect-Jira -Name validation-conflict -Uri https://api.atlassian.com/ex/jira/11111111-1111-1111-1111-111111111111 -EmailAddress user@example.com -ApiToken sentinel-token } | Should -Throw '*Conflicting*'
        }

        It 'preserves metadata HTTP <Status> instead of falling back' -ForEach @(
            @{ Status = 401 }
            @{ Status = 500 }
        ) {
            $script:metadataStatus = [System.Net.HttpStatusCode]$Status
            { Connect-Jira -Name validation-http -Uri https://jira.example.com -PersonalAccessToken sentinel-token } | Should -Throw -ErrorId "InvalidResponse.Status$Status*"
            Should -Invoke Invoke-WebRequest -Exactly 0 -ParameterFilter { $Uri.AbsolutePath -eq '/rest/api/2/myself' }
        }

        It 'does not turn a transport failure into a successful fallback' {
            Mock Invoke-WebRequest { throw [System.Net.WebException]::new('Connection refused sentinel') }
            { Connect-Jira -Name validation-network -Uri https://jira.example.com -Anonymous -DeploymentType Server } | Should -Throw '*Connection refused sentinel*'
            Get-JiraConnection -Name validation-network | Should -BeNullOrEmpty
            Should -Invoke Invoke-WebRequest -Exactly 1
        }

        It 'rejects an unrecognized deployment in a metadata response' {
            $script:metadata = '{"deploymentType":"Other"}'
            { Connect-Jira -Name validation-product -Uri https://jira.example.com -Anonymous -DeploymentType Server } | Should -Throw '*recognizable Jira server information*'
        }

        It 'rejects malformed deployment values without attempting a fallback: <Metadata>' -ForEach @(
            @{ Metadata = '{"deploymentType":false}' }
            @{ Metadata = '{"deploymentType":0}' }
            @{ Metadata = '{"deploymentType":["Server"]}' }
        ) {
            $script:metadata = $Metadata
            { Connect-Jira -Name validation-product -Uri https://jira.example.com -Anonymous -DeploymentType Server } | Should -Throw '*recognizable Jira server information*'
            Should -Invoke Invoke-WebRequest -Exactly 1
        }

        It 'requires an explicit deployment for anonymous fallback even with a Cloud gateway' {
            $script:metadataStatus = [System.Net.HttpStatusCode]::NotFound
            { Connect-Jira -Name validation-anonymous -Uri https://api.atlassian.com/ex/jira/11111111-1111-1111-1111-111111111111 -Anonymous } | Should -Throw '*requires DeploymentType*'
            Should -Invoke Invoke-WebRequest -Exactly 0 -ParameterFilter { $Uri.AbsolutePath -eq '/rest/api/2/project' }
        }

        It 'validates anonymous fallback through public projects for <Deployment>' -ForEach @(
            @{ Deployment = 'Cloud' }
            @{ Deployment = 'Server' }
            @{ Deployment = 'Data Center' }
        ) {
            $script:metadataStatus = [System.Net.HttpStatusCode]::NotFound
            $connection = Connect-Jira -Name validation-anonymous -Uri https://jira.example.com -Anonymous -DeploymentType $Deployment
            $connection.DeploymentType | Should -Be $Deployment
            Should -Invoke Invoke-WebRequest -Exactly 1 -ParameterFilter { $Uri.AbsolutePath -eq '/rest/api/2/project' }
            Should -Invoke Invoke-WebRequest -Exactly 0 -ParameterFilter { $Uri.AbsolutePath -eq '/rest/api/2/myself' }
            Should -Invoke Invoke-WebRequest -Exactly 0 -ParameterFilter { $Headers.Authorization -or $Headers.Cookie -or $Credential }
        }

        It 'does not require the anonymous fallback probe when deployment metadata is available' {
            Connect-Jira -Name validation-anonymous -Uri https://jira.example.com -Anonymous | Out-Null
            Should -Invoke Invoke-WebRequest -Exactly 1
        }

        It 'rejects empty or malformed anonymous project responses: <Projects>' -ForEach @(
            @{ Projects = '[]' }
            @{ Projects = '{}' }
            @{ Projects = '[{"id":"10000","key":"PUBLIC","name":"Public"}]' }
            @{ Projects = '[{"id":"bad","key":"PUBLIC","name":"Public","self":"https://jira.example.com/rest/api/2/project/10000"}]' }
            @{ Projects = '[{"id":"10000","key":{"bad":true},"name":5,"self":"/rest/api/2/project/10000"}]' }
            @{ Projects = '[{"id":["10000"],"key":"PUBLIC","name":"Public","self":"https://jira.example.com/rest/api/2/project/10000"}]' }
            @{ Projects = '[{"id":"10000","key":"PUBLIC","name":"Public","self":["https://jira.example.com/rest/api/2/project/10000"]}]' }
            @{ Projects = '[{"id":"10000","key":"PUBLIC","name":"Public","self":"/rest/api/2/project/10000"}]' }
        ) {
            $script:metadataStatus = [System.Net.HttpStatusCode]::NotFound
            $script:projects = $Projects
            { Connect-Jira -Name validation-anonymous -Uri https://jira.example.com -Anonymous -DeploymentType Server -Default } | Should -Throw '*Allow anonymous project browsing*'
            Get-JiraConnection -Name validation-anonymous | Should -BeNullOrEmpty
            (Get-JiraConnection -Default).InstanceId | Should -Be $previousDefault.InstanceId
        }

        It 'explains an inaccessible anonymous probe with HTTP <Status>' -ForEach @(
            @{ Status = 401 }
            @{ Status = 403 }
            @{ Status = 404 }
            @{ Status = 405 }
        ) {
            $script:metadataStatus = [System.Net.HttpStatusCode]::NotFound
            $script:projectStatus = [System.Net.HttpStatusCode]$Status
            { Connect-Jira -Name validation-anonymous -Uri https://jira.example.com -Anonymous -DeploymentType Server } | Should -Throw '*use authenticated Connect-Jira*'
        }

        It 'does not broaden the creation probe allowlist: <Mode> <Method> <Resource>' -ForEach @(
            @{ Mode = 'Anonymous'; Method = 'POST'; Resource = '/rest/api/2/project' }
            @{ Mode = 'PersonalAccessToken'; Method = 'GET'; Resource = '/rest/api/2/project' }
            @{ Mode = 'Anonymous'; Method = 'GET'; Resource = '/rest/api/2/issue/TEST-1' }
        ) {
            $authentication = if ($Mode -eq 'Anonymous') { @{ Anonymous = $true } }
            else { @{ PersonalAccessToken = 'sentinel-token' } }
            $candidate = AtlassianPS.Configuration\New-AtlassianConnectionContext -Name validation-probe -Product Jira -BaseUri https://jira.example.com @authentication
            try {
                { Invoke-JiraMethod -Uri $Resource -Method $Method -RequestContext $candidate } | Should -Throw '*restricted*'
                Should -Invoke Invoke-WebRequest -Exactly 0
            }
            finally { $candidate.Dispose() }
        }

        It 'rejects an invalid deployment argument before making requests' {
            { Connect-Jira -Name validation-binding -Uri https://jira.example.com -Anonymous -DeploymentType Unknown } | Should -Throw
            Should -Invoke Invoke-WebRequest -Exactly 0
        }
    }
}
