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
            Mock Invoke-WebRequest {
                switch -Regex ($Uri.AbsolutePath) {
                    '/_edge/tenant_info$' {
                        Get-ValidationWebResponse '{"cloudId":"11111111-1111-1111-1111-111111111111"}'
                    }
                    '/rest/api/2/serverInfo$' { Get-ValidationWebResponse $script:metadata $script:metadataStatus }
                    '/rest/api/2/myself$' { Get-ValidationWebResponse $script:identity $script:identityStatus }
                    '/rest/api/2/project$' { Get-ValidationWebResponse $script:projects }
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

        It 'accepts recognized <Deployment> metadata without a version' -ForEach @(
            @{ Deployment = 'Cloud'; Identity = '{"accountId":"validated-user"}' }
            @{ Deployment = 'Server'; Identity = '{"name":"validated-user"}' }
            @{ Deployment = 'Data Center'; Identity = '{"name":"validated-user"}' }
        ) {
            $script:metadata = @{ deploymentType = $Deployment } | ConvertTo-Json -Compress
            $script:identity = $Identity
            $connection = Connect-Jira -Name validation-version -Uri https://jira.example.com -PersonalAccessToken sentinel-token
            $connection.DeploymentType | Should -Be $Deployment
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

        It 'uses explicit gateway resources without site metadata: <Self>' -ForEach @(
            @{ Self = $null }
            @{ Self = 'https://api.atlassian.com/ex/jira/11111111-1111-1111-1111-111111111111/rest/api/2/user?accountId=validated-account' }
        ) {
            $script:metadataStatus = [System.Net.HttpStatusCode]::NotFound
            $script:identity = @{ accountId = 'validated-account'; self = $Self } | ConvertTo-Json -Compress
            $connection = Connect-Jira -Name validation-gateway -Uri https://api.atlassian.com/ex/jira/11111111-1111-1111-1111-111111111111 -EmailAddress user@example.com -ApiToken sentinel-token

            $projects = @(Invoke-JiraMethod -Uri '/rest/api/2/project' -Connection $connection)

            $connection.SiteUri | Should -BeNullOrEmpty
            $connection.DeploymentType | Should -Be 'Cloud'
            $projects[0].key | Should -Be 'PUBLIC'
            Should -Invoke Invoke-WebRequest -Exactly 3 -ParameterFilter {
                $Uri.Host -eq 'api.atlassian.com' -and
                $Uri.AbsolutePath.StartsWith('/ex/jira/11111111-1111-1111-1111-111111111111/')
            }
        }

        It 'infers Server from a validated username after metadata HTTP <Status>' -ForEach @(
            @{ Status = 200 }
            @{ Status = 403 }
            @{ Status = 404 }
            @{ Status = 405 }
        ) {
            $script:metadata = '{}'
            $script:metadataStatus = [System.Net.HttpStatusCode]$Status
            $connection = Connect-Jira -Name validation-server -Uri https://jira.example.com -PersonalAccessToken sentinel-token
            $connection.DeploymentType | Should -Be 'Server'
            $connection.Username | Should -Be 'validated-user'
            Should -Invoke Invoke-WebRequest -Exactly 1 -ParameterFilter { $Uri.AbsolutePath -eq '/rest/api/2/myself' }
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

        It 'rejects identity denial with HTTP <Status> despite recognized metadata' -ForEach @(
            @{ Status = 401 }
            @{ Status = 403 }
        ) {
            $script:identityStatus = [System.Net.HttpStatusCode]$Status
            { Connect-Jira -Name validation-denied -Uri https://jira.example.com -PersonalAccessToken sentinel-token -Default } |
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

        It 'rejects contradictory metadata and identity' -ForEach @(
            @{ Metadata = 'Cloud'; Identity = '{"name":"user"}' }
            @{ Metadata = 'Server'; Identity = '{"accountId":"account"}' }
            @{ Metadata = 'Data Center'; Identity = '{"accountId":"account"}' }
        ) {
            $script:metadata = @{ deploymentType = $Metadata } | ConvertTo-Json -Compress
            $script:identity = $Identity
            { Connect-Jira -Name validation-conflict -Uri https://jira.example.com -PersonalAccessToken sentinel-token -Default } | Should -Throw '*Conflicting*'
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

        It 'rejects an unrecognized deployment in a metadata response' {
            $script:metadata = '{"deploymentType":"Other"}'
            { Connect-Jira -Name validation-product -Uri https://jira.example.com -Anonymous } | Should -Throw '*recognizable Jira server information*'
        }

        It 'rejects malformed deployment values without attempting a fallback: <Metadata>' -ForEach @(
            @{ Metadata = '{"deploymentType":false}' }
            @{ Metadata = '{"deploymentType":0}' }
            @{ Metadata = '{"deploymentType":["Server"]}' }
        ) {
            $script:metadata = $Metadata
            { Connect-Jira -Name validation-product -Uri https://jira.example.com -Anonymous } | Should -Throw '*recognizable Jira server information*'
            Should -Invoke Invoke-WebRequest -Exactly 1
        }

        It 'requires deployment metadata for anonymous connections even with a Cloud gateway' {
            $script:metadataStatus = [System.Net.HttpStatusCode]::NotFound
            { Connect-Jira -Name validation-anonymous -Uri https://api.atlassian.com/ex/jira/11111111-1111-1111-1111-111111111111 -Anonymous } | Should -Throw '*require deployment metadata*'
            Should -Invoke Invoke-WebRequest -Exactly 0 -ParameterFilter { $Uri.AbsolutePath -eq '/rest/api/2/project' }
        }

        It 'validates anonymous connections through recognized <Deployment> metadata' -ForEach @(
            @{ Deployment = 'Cloud' }
            @{ Deployment = 'Server' }
            @{ Deployment = 'Data Center' }
        ) {
            $script:metadata = @{ deploymentType = $Deployment } | ConvertTo-Json -Compress
            $connection = Connect-Jira -Name validation-anonymous -Uri https://jira.example.com -Anonymous
            $connection.DeploymentType | Should -Be $Deployment
            Should -Invoke Invoke-WebRequest -Exactly 1 -ParameterFilter { $Uri.AbsolutePath -eq '/rest/api/2/serverInfo' }
            Should -Invoke Invoke-WebRequest -Exactly 0 -ParameterFilter { $Uri.AbsolutePath -eq '/rest/api/2/project' }
            Should -Invoke Invoke-WebRequest -Exactly 0 -ParameterFilter { $Uri.AbsolutePath -eq '/rest/api/2/myself' }
            Should -Invoke Invoke-WebRequest -Exactly 0 -ParameterFilter { $Headers.Authorization -or $Headers.Cookie -or $Credential }
        }

        It 'rejects anonymous connections with missing deployment metadata after HTTP <Status>: <Metadata>' -ForEach @(
            @{ Status = 200; Metadata = '{}' }
            @{ Status = 200; Metadata = '{"deploymentType":" "}' }
            @{ Status = 403; Metadata = '{}' }
            @{ Status = 404; Metadata = '{}' }
            @{ Status = 405; Metadata = '{}' }
        ) {
            $script:metadataStatus = [System.Net.HttpStatusCode]$Status
            $script:metadata = $Metadata
            { Connect-Jira -Name validation-anonymous -Uri https://jira.example.com -Anonymous -Default } | Should -Throw '*Allow anonymous access to that endpoint or use authenticated Connect-Jira*'
            Get-JiraConnection -Name validation-anonymous | Should -BeNullOrEmpty
            (Get-JiraConnection -Default).InstanceId | Should -Be $previousDefault.InstanceId
            Should -Invoke Invoke-WebRequest -Exactly 1
            Should -Invoke Invoke-WebRequest -Exactly 0 -ParameterFilter { $Uri.AbsolutePath -eq '/rest/api/2/project' -or $Uri.AbsolutePath -eq '/rest/api/2/myself' }
        }

        It 'does not broaden the creation probe allowlist: <Mode> <Method> <Resource>' -ForEach @(
            @{ Mode = 'Anonymous'; Method = 'GET'; Resource = '/rest/api/2/project' }
            @{ Mode = 'Anonymous'; Method = 'POST'; Resource = '/rest/api/2/project' }
            @{ Mode = 'PersonalAccessToken'; Method = 'GET'; Resource = '/rest/api/2/project' }
            @{ Mode = 'Anonymous'; Method = 'GET'; Resource = '/rest/api/2/issue/TEST-1' }
        ) {
            $authentication = if ($Mode -eq 'Anonymous') { @{ Anonymous = $true } }
            else { @{ PersonalAccessToken = 'sentinel-token' } }
            $candidate = AtlassianPS.Configuration\New-AtlassianConnectionContext -Name validation-probe -Product Jira -BaseUri https://jira.example.com @authentication
            try {
                { Invoke-JiraRequest -Uri $Resource -Method $Method -RequestContext $candidate } | Should -Throw '*restricted*'
                Should -Invoke Invoke-WebRequest -Exactly 0
            }
            finally { $candidate.Dispose() }
        }

        It '<CommandName> rejects a deployment argument before making requests' -ForEach @(
            @{ CommandName = 'Connect-Jira' }
        ) {
            { & $CommandName -Name validation-binding -Uri https://jira.example.com -Anonymous -DeploymentType Server } | Should -Throw -ErrorId 'NamedParameterNotFound,*'
            Should -Invoke Invoke-WebRequest -Exactly 0
        }
    }
}
