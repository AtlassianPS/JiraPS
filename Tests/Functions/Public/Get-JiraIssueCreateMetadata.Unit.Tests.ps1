#requires -modules @{ ModuleName = "Pester"; ModuleVersion = "6.2.0"; MaximumVersion = "6.999" }

BeforeDiscovery {
    . "$PSScriptRoot/../../Helpers/TestTools.ps1"
    $script:moduleToTest = Initialize-TestEnvironment
}

InModuleScope JiraPS {
    Describe "Get-JiraIssueCreateMetadata" -Tag 'Unit' {
        BeforeAll {
            . "$PSScriptRoot/../../Helpers/TestTools.ps1"
            # $VerbosePreference = 'Continue'  # Uncomment for mock debugging

            #region Definitions
            $script:jiraServer = 'https://jira.example.com'

            # Paginated PageOfCreateMetaIssueTypeWithField response shape
            # returned by GET /rest/api/2/issue/createmeta/{project}/issuetypes/{issueType}
            $script:restResult = @"
{
    "maxResults": 50,
    "startAt": 0,
    "total": 3,
    "isLast": true,
    "values": [
        {
            "required": true,
            "schema": { "type": "string", "system": "summary" },
            "name": "Summary",
            "fieldId": "summary",
            "hasDefaultValue": false,
            "operations": [ "set" ]
        },
        {
            "required": false,
            "schema": { "type": "string", "system": "description" },
            "name": "Description",
            "fieldId": "description",
            "hasDefaultValue": false,
            "operations": [ "set" ]
        },
        {
            "required": false,
            "schema": { "type": "priority", "system": "priority" },
            "name": "Priority",
            "fieldId": "priority",
            "hasDefaultValue": true,
            "operations": [ "set" ],
            "allowedValues": [ { "id": "1", "name": "Blocker" } ]
        }
    ]
}
"@

            #endregion Definitions

            Mock Get-JiraConfigServer -ModuleName JiraPS {
                Write-MockDebugInfo 'Get-JiraConfigServer'
                $jiraServer
            }

            Mock Get-JiraProject -ModuleName JiraPS {
                Write-MockDebugInfo 'Get-JiraProject'
                $issueObject = [PSCustomObject] @{
                    ID   = 2
                    Name = 'Test Issue Type'
                }
                $issueObject.PSObject.TypeNames.Insert(0, 'JiraPS.IssueType')
                $object = [PSCustomObject] @{
                    ID   = 10003
                    Name = 'Test Project'
                }
                Add-Member -InputObject $object -MemberType NoteProperty -Name "IssueTypes" -Value $issueObject
                $object.PSObject.TypeNames.Insert(0, 'AtlassianPS.JiraPS.Project')
                return $object
            }

            Mock Test-JiraCloudServer -ModuleName JiraPS {
                Write-MockDebugInfo 'Test-JiraCloudServer'
                $false
            }
        }

        Describe "Signature" {
            BeforeAll {
                $script:command = Get-Command -Name Get-JiraIssueCreateMetadata
            }

            Context "Parameter Types" {
                It "opts into SupportsPaging" {
                    $command.Parameters.Keys | Should -Contain 'First'
                    $command.Parameters.Keys | Should -Contain 'Skip'
                    $command.Parameters.Keys | Should -Contain 'IncludeTotalCount'
                }
            }

            Context "Mandatory Parameters" {}

            Context "Default Values" {}
        }

        Describe "Behavior" {
            Context "Behavior testing" {
                BeforeAll {
                    # Default mock: Invoke-JiraMethod -Paging would yield the
                    # expanded field items, so the mock returns values directly.
                    Mock Invoke-JiraMethod -ModuleName JiraPS -ParameterFilter { $Method -eq 'Get' -and $URI -like "/rest/api/*/issue/createmeta/*/issuetypes/*" } {
                        Write-MockDebugInfo 'Invoke-JiraMethod' 'Method', 'Uri'
                        (ConvertFrom-Json $restResult).values
                    }

                    Mock Invoke-JiraMethod -ModuleName JiraPS {
                        Write-MockDebugInfo 'Invoke-JiraMethod' 'Method', 'Uri'
                        throw "Unidentified call to Invoke-JiraMethod"
                    }
                }

                It "Queries Jira for metadata information about creating an issue" {
                    { Get-JiraIssueCreateMetadata -Project 10003 -IssueType 2 } | Should -Not -Throw

                    Should -Invoke Invoke-JiraMethod -ModuleName JiraPS -ParameterFilter {
                        $Method -eq 'Get' -and
                        $URI -like "/rest/api/*/issue/createmeta/*/issuetypes/*" -and
                        $Paging -eq $true
                    } -Exactly -Times 1
                }

                It "Uses the REST API v2 endpoint on Data Center" {
                    # Test-JiraCloudServer is already mocked to $false in BeforeAll.
                    { Get-JiraIssueCreateMetadata -Project 10003 -IssueType 2 } | Should -Not -Throw

                    Should -Invoke Invoke-JiraMethod -ModuleName JiraPS -ParameterFilter {
                        $Method -eq 'Get' -and $URI -like "/rest/api/2/issue/createmeta/*"
                    } -Exactly -Times 1
                }

                It "Uses the REST API v3 endpoint on Jira Cloud" {
                    Mock Test-JiraCloudServer -ModuleName JiraPS { $true }

                    { Get-JiraIssueCreateMetadata -Project 10003 -IssueType 2 } | Should -Not -Throw

                    Should -Invoke Invoke-JiraMethod -ModuleName JiraPS -ParameterFilter {
                        $Method -eq 'Get' -and $URI -like "/rest/api/3/issue/createmeta/*"
                    } -Exactly -Times 1

                    Should -Invoke Invoke-JiraMethod -ModuleName JiraPS -ParameterFilter {
                        $Method -eq 'Get' -and $URI -like "/rest/api/2/issue/createmeta/*"
                    } -Exactly -Times 0
                }

                It "Streams each field through ConvertTo-JiraCreateMetaField" {
                    Mock ConvertTo-JiraCreateMetaField -ModuleName JiraPS {
                        Write-MockDebugInfo 'ConvertTo-JiraCreateMetaField' 'InputObject'
                        $InputObject
                    }

                    $result = Get-JiraIssueCreateMetadata -Project 10003 -IssueType 2

                    $result | Should -HaveCount 3

                    # With pagination the converter is invoked once per streamed item.
                    Should -Invoke ConvertTo-JiraCreateMetaField -ModuleName JiraPS -Exactly -Times 3
                }

                It "Emits AtlassianPS.JiraPS.CreateMetaField objects with mapped properties" {
                    $result = Get-JiraIssueCreateMetadata -Project 10003 -IssueType 2

                    $result | Should -HaveCount 3
                    foreach ($field in $result) {
                        $field.PSObject.TypeNames | Should -Contain 'AtlassianPS.JiraPS.CreateMetaField'
                    }

                    $summary = $result | Where-Object { $_.Id -eq 'summary' }
                    $summary.Name | Should -Be 'Summary'
                    $summary.Required | Should -BeTrue
                    $summary.HasDefaultValue | Should -BeFalse

                    $priority = $result | Where-Object { $_.Id -eq 'priority' }
                    $priority.HasDefaultValue | Should -BeTrue
                    $priority.AllowedValues | Should -Not -BeNullOrEmpty
                }
            }

            Context "Pages <deployment> create metadata" -ForEach @(
                @{ deployment = 'Cloud'; isCloud = $true; container = 'fields'; apiVersion = 3 }
                @{ deployment = 'Data Center'; isCloud = $false; container = 'values'; apiVersion = 2 }
            ) {
                BeforeAll {
                    $script:metadataIsCloud = $isCloud
                    $script:metadataContainer = $container
                    $script:metadataApiVersion = $apiVersion
                    $script:metadataFields = @((ConvertFrom-Json $restResult).values) + @(
                        [PSCustomObject]@{
                            fieldId = 'labels'; name = 'Labels'; required = $false
                            hasDefaultValue = $false; schema = @{ type = 'array'; system = 'labels' }
                            operations = @('add', 'set', 'remove')
                        }
                    )

                    Mock Test-JiraCloudServer -ModuleName JiraPS { $metadataIsCloud }
                    Mock Resolve-DefaultParameterValue -ModuleName JiraPS { @{} }
                    Mock Set-TlsLevel -ModuleName JiraPS {}
                    Mock Test-ServerResponse -ModuleName JiraPS {}
                    Mock Get-JiraSession -ModuleName JiraPS {
                        [PSCustomObject]@{
                            WebSession = [Microsoft.PowerShell.Commands.WebRequestSession]::new()
                        }
                    }

                    Mock Invoke-WebRequest -ModuleName JiraPS {
                        $startAt = 0
                        $maxResults = 2
                        if ("$Uri" -match 'startAt=(\d+)') { $startAt = [int]$matches[1] }
                        if ("$Uri" -match 'maxResults=(\d+)') { $maxResults = [Math]::Min(2, [int]$matches[1]) }
                        $page = @($metadataFields | Select-Object -Skip $startAt -First $maxResults)
                        $response = @{
                            startAt = $startAt; maxResults = $maxResults; total = $metadataFields.Count
                            $metadataContainer = $page
                        }
                        if (-not $metadataIsCloud) {
                            $response.isLast = ($startAt + $page.Count) -ge $metadataFields.Count
                        }
                        $json = ConvertTo-Json $response -Depth 10
                        [PSCustomObject]@{
                            StatusCode       = [System.Net.HttpStatusCode]::OK
                            Content          = $json
                            RawContentStream = [System.IO.MemoryStream]::new([System.Text.Encoding]::UTF8.GetBytes($json))
                        }
                    }
                }

                It "returns every typed field across offset pages without an extra request" {
                    $result = @(Get-JiraIssueCreateMetadata -Project 10003 -IssueType 2 -ErrorAction Stop)

                    $result | Should -HaveCount 4
                    ($result.Id -join ',') | Should -Be 'summary,description,priority,labels'
                    foreach ($field in $result) {
                        $field | Should -BeOfType ([AtlassianPS.JiraPS.CreateMetaField])
                        $field.Name | Should -Not -BeNullOrEmpty
                    }
                    $result[0].Required | Should -BeTrue
                    $result[2].AllowedValues[0].name | Should -Be 'Blocker'
                    Should -Invoke Invoke-WebRequest -ModuleName JiraPS -Exactly -Times 2 -Scope It
                    Should -Invoke Invoke-WebRequest -ModuleName JiraPS -Exactly -Times 1 -Scope It -ParameterFilter {
                        "$Uri" -match "/rest/api/$metadataApiVersion/issue/createmeta/10003/issuetypes/2" -and
                        "$Uri" -match 'startAt=2' -and "$Uri" -notmatch 'nextPageToken'
                    }
                }

                It "honors First and Skip across page boundaries" -ForEach @(
                    @{ first = 1; skip = 0; ids = 'summary'; requests = 1 }
                    @{ first = 3; skip = 0; ids = 'summary,description,priority'; requests = 2 }
                    @{ first = 3; skip = 1; ids = 'description,priority,labels'; requests = 2 }
                    @{ first = 2; skip = 1; ids = 'description,priority'; requests = 1 }
                ) {
                    $result = @(Get-JiraIssueCreateMetadata -Project 10003 -IssueType 2 -First $first -Skip $skip -ErrorAction Stop)

                    ($result.Id -join ',') | Should -Be $ids
                    Should -Invoke Invoke-WebRequest -ModuleName JiraPS -Exactly -Times $requests -Scope It
                }

                It "returns no fields when the offset is past the last field" {
                    $result = @(Get-JiraIssueCreateMetadata -Project 10003 -IssueType 2 -Skip 10 -ErrorAction Stop)

                    $result | Should -HaveCount 0
                    Should -Invoke Invoke-WebRequest -ModuleName JiraPS -Exactly -Times 1 -Scope It
                }
            }
        }

        Describe "Input Validation" {
            Context "Type Validation - Positive Cases" {}

            Context "Type Validation - Negative Cases" {}
        }
    }
}
