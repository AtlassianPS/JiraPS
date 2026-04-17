#requires -modules @{ ModuleName = "Pester"; ModuleVersion = "5.7"; MaximumVersion = "5.999" }

BeforeDiscovery {
    . "$PSScriptRoot/../../Helpers/TestTools.ps1"
    Initialize-TestEnvironment
    $script:moduleToTest = Resolve-ModuleSource
    Import-Module $script:moduleToTest -Force -ErrorAction Stop
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

            # Two-page fixtures for the multi-page walk test.
            $script:pagedResponse1 = @"
{
    "maxResults": 2,
    "startAt": 0,
    "total": 4,
    "isLast": false,
    "values": [
        { "required": true,  "schema": { "type": "string", "system": "summary" },     "name": "Summary",     "fieldId": "summary",     "hasDefaultValue": false, "operations": [ "set" ] },
        { "required": false, "schema": { "type": "string", "system": "description" }, "name": "Description", "fieldId": "description", "hasDefaultValue": false, "operations": [ "set" ] }
    ]
}
"@
            $script:pagedResponse2 = @"
{
    "maxResults": 2,
    "startAt": 2,
    "total": 4,
    "isLast": true,
    "values": [
        { "required": false, "schema": { "type": "priority", "system": "priority" }, "name": "Priority", "fieldId": "priority", "hasDefaultValue": true,  "operations": [ "set" ] },
        { "required": false, "schema": { "type": "array",    "system": "labels" },   "name": "Labels",   "fieldId": "labels",   "hasDefaultValue": false, "operations": [ "add", "set", "remove" ] }
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
                $object.PSObject.TypeNames.Insert(0, 'JiraPS.Project')
                return $object
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
                    Mock Invoke-JiraMethod -ModuleName JiraPS -ParameterFilter { $Method -eq 'Get' -and $URI -like "$jiraServer/rest/api/*/issue/createmeta/*/issuetypes/*" } {
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
                        $URI -like "$jiraServer/rest/api/*/issue/createmeta/*/issuetypes/*" -and
                        $Paging -eq $true
                    } -Exactly -Times 1
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

                It "Emits JiraPS.CreateMetaField objects with mapped properties" {
                    $result = Get-JiraIssueCreateMetadata -Project 10003 -IssueType 2

                    $result | Should -HaveCount 3
                    foreach ($field in $result) {
                        $field.PSObject.TypeNames | Should -Contain 'JiraPS.CreateMetaField'
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

            Context "Walks multiple pages of createmeta results" {
                BeforeAll {
                    # Mock the HTTP layer only so that Invoke-JiraMethod (and
                    # Invoke-PaginatedRequest) actually runs end-to-end and the
                    # second page is fetched.
                    Mock Resolve-DefaultParameterValue -ModuleName JiraPS { @{ } }
                    Mock Set-TlsLevel -ModuleName JiraPS { }
                    Mock Test-ServerResponse -ModuleName JiraPS { }
                    Mock Get-JiraSession -ModuleName JiraPS {
                        [PSCustomObject]@{
                            WebSession = New-Object -TypeName Microsoft.PowerShell.Commands.WebRequestSession
                        }
                    }

                    Mock Invoke-WebRequest -ModuleName JiraPS {
                        Write-MockDebugInfo 'Invoke-WebRequest' -Params 'Uri', 'Method'

                        $response = $pagedResponse1
                        if ("$Uri" -match "startAt=(\d+)") {
                            switch ($matches[1]) {
                                '2' { $response = $pagedResponse2; break }
                            }
                        }

                        $bytes = [System.Text.Encoding]::UTF8.GetBytes($response)
                        $stream = [PSCustomObject]@{ _bytes = $bytes }
                        $stream | Add-Member -MemberType ScriptMethod -Name 'ToArray' -Force -Value { return $this._bytes }

                        [PSCustomObject]@{
                            StatusCode       = 200
                            Content          = $response
                            RawContentStream = $stream
                        }
                    }
                }

                It "Requests all pages and returns every field" {
                    $result = Get-JiraIssueCreateMetadata -Project 10003 -IssueType 2

                    $result | Should -HaveCount 4

                    Should -Invoke Invoke-WebRequest -ModuleName JiraPS -Exactly -Times 2 -Scope It

                    # startAt=2 query should be issued for the second page request.
                    Should -Invoke Invoke-WebRequest -ModuleName JiraPS -ParameterFilter {
                        "$Uri" -match 'startAt=2'
                    } -Exactly -Times 1 -Scope It
                }
            }
        }

        Describe "Input Validation" {
            Context "Type Validation - Positive Cases" {}

            Context "Type Validation - Negative Cases" {}
        }
    }
}
