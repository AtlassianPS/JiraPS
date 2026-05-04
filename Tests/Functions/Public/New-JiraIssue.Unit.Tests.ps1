#requires -modules @{ ModuleName = "Pester"; ModuleVersion = "5.7"; MaximumVersion = "5.999" }

BeforeDiscovery {
    . "$PSScriptRoot/../../Helpers/TestTools.ps1"

    $script:moduleToTest = Initialize-TestEnvironment
}

InModuleScope JiraPS {
    Describe "New-JiraIssue" -Tag 'Unit' {
        BeforeAll {
            . "$PSScriptRoot/../../Helpers/TestTools.ps1"
            # $VerbosePreference = 'Continue'

            #region Definitions
            $script:jiraServer = 'https://jira.example.com'
            $script:issueTypeTest = 1

            $script:newParams = @{
                'Project'     = 'TEST'
                'IssueType'   = 1
                'Priority'    = 1
                'Reporter'    = 'testUsername'
                'Summary'     = 'Test summary'
                'Description' = 'Test description'
            }

            $script:pipelineParams = New-Object -TypeName PSCustomObject -Property $newParams
            #endregion Definitions

            #region Mocks
            Mock Test-JiraCloudServer -ModuleName JiraPS { $false }

            Mock Get-JiraConfigServer -ModuleName JiraPS {
                Write-MockDebugInfo 'Get-JiraConfigServer'
                $jiraServer
            }

            # If we don't override this in a context or test, we don't want it to
            # actually try to query a JIRA instance
            Mock Invoke-JiraMethod -ModuleName JiraPS {
                Write-MockDebugInfo 'Invoke-JiraMethod' 'Method', 'Uri'
                @{ Key = "TEST-01" }
            }

            Mock Get-JiraIssue -ModuleName JiraPS {
                Write-MockDebugInfo 'Get-JiraIssue'
                [PSCustomObject] @{ Key = "TEST-01" }
            }

            Mock Get-JiraProject -ModuleName JiraPS {
                Write-MockDebugInfo 'Get-JiraProject'
                $issueObject = [PSCustomObject] @{
                    ID   = $issueTypeTest
                    Name = 'Test Issue Type'
                }
                $issueObject.PSObject.TypeNames.Insert(0, 'JiraPS.IssueType')
                $object = [PSCustomObject] @{
                    'ID'  = $Project
                    'Key' = "TEST"
                }
                Add-Member -InputObject $object -MemberType NoteProperty -Name "IssueTypes" -Value $issueObject
                $object.PSObject.TypeNames.Insert(0, 'AtlassianPS.JiraPS.Project')
                return $object
            }

            Mock Get-JiraUser -ModuleName JiraPS {
                Write-MockDebugInfo 'Get-JiraUser'
                $object = [PSCustomObject] @{
                    'Name' = $UserName
                }
                $object.PSObject.TypeNames.Insert(0, 'AtlassianPS.JiraPS.User')
                return $object
            }

            # This one needs to be able to output multiple objects
            Mock Get-JiraField -ModuleName JiraPS {
                Write-MockDebugInfo 'Get-JiraField'
                $(if ($null -eq $Field) {
                        @(
                            'Project'
                            'IssueType'
                            'Priority'
                            'Summary'
                            'Description'
                            'Reporter'
                            'CustomField'
                        )
                    }
                    else {
                        $Field
                    }) | ForEach-Object {
                    $object = [PSCustomObject] @{
                        'Id' = $_
                    }
                    $object.PSObject.TypeNames.Insert(0, 'JiraPS.Field')
                    $object
                }
            }

            Mock Get-JiraIssueCreateMetadata -ModuleName JiraPS {
                Write-MockDebugInfo 'Get-JiraIssueCreateMetadata'
                @(
                    @{Name = 'Project'; ID = 'Project'; Required = $true }
                    @{Name = 'IssueType'; ID = 'IssueType'; Required = $true }
                    @{Name = 'Priority'; ID = 'Priority'; Required = $true }
                    @{Name = 'Summary'; ID = 'Summary'; Required = $true }
                    @{Name = 'Description'; ID = 'Description'; Required = $true }
                    @{Name = 'Reporter'; ID = 'Reporter'; Required = $true }
                )
            }
            #endregion Mocks
        }

        Describe "Signature" {
            BeforeAll {
                $script:command = Get-Command -Name New-JiraIssue
            }

            Context "Parameter Types" {
                It "has a parameter '<parameter>' of type '<type>'" -TestCases @(
                    @{ parameter = 'Project'; type = 'String' }
                    @{ parameter = 'IssueType'; type = 'String' }
                    @{ parameter = 'Priority'; type = 'Int32' }
                    @{ parameter = 'Summary'; type = 'String' }
                    @{ parameter = 'Description'; type = 'String' }
                    @{ parameter = 'Reporter'; type = 'User' }
                    @{ parameter = 'Label'; type = 'String[]' }
                    @{ parameter = 'Components'; type = 'String[]' }
                    @{ parameter = 'Fields'; type = 'PSObject' }
                    @{ parameter = 'Credential'; type = 'PSCredential' }
                ) {
                    param($parameter, $type)
                    $command | Should -HaveParameter $parameter
                    $command.Parameters[$parameter].ParameterType.Name | Should -Be $type
                }

            }

            Context "Mandatory Parameters" {}

            Context "Default Values" {}
        }

        Describe "Behavior" {
            It "Creates an issue in JIRA" {
                { New-JiraIssue @newParams } | Should -Not -Throw
                # The String in the ParameterFilter is made from the keywords
                # we should expect to see in the JSON that should be sent,
                # including the summary provided in the test call above.
                Should -Invoke -CommandName Invoke-JiraMethod -ModuleName JiraPS -Times 1 -ParameterFilter { $Method -eq 'Post' -and $URI -like "/rest/api/*/issue" }
            }

            It "defers required-field validation to Jira instead of client-side createmeta checks" {
                { New-JiraIssue @newParams } | Should -Not -Throw

                Should -Invoke -CommandName Get-JiraIssueCreateMetadata -ModuleName JiraPS -Times 0
                Should -Invoke -CommandName Invoke-JiraMethod -ModuleName JiraPS -Times 1
            }

            It "populates components in the request body when -Components is supplied" {
                { New-JiraIssue @newParams -Components '10001', '10002' } | Should -Not -Throw

                Should -Invoke -CommandName Invoke-JiraMethod -ModuleName JiraPS -Times 1 -ParameterFilter {
                    $Method -eq 'Post' -and
                    $Body -match '"components"' -and
                    $Body -match '10001' -and
                    $Body -match '10002'
                }
            }

            It "populates components in the request body when the -Component short form is supplied" {
                { New-JiraIssue @newParams -Component '10003', '10004' } | Should -Not -Throw

                Should -Invoke -CommandName Invoke-JiraMethod -ModuleName JiraPS -Times 1 -ParameterFilter {
                    $Method -eq 'Post' -and
                    $Body -match '"components"' -and
                    $Body -match '10003' -and
                    $Body -match '10004'
                }
            }
            It "Creates an issue in JIRA from pipeline" {
                { $pipelineParams | New-JiraIssue } | Should -Not -Throw
                # The String in the ParameterFilter is made from the keywords
                # we should expect to see in the JSON that should be sent,
                # including the summary provided in the test call above.
                Should -Invoke -CommandName Invoke-JiraMethod -ModuleName JiraPS -Times 1 -ParameterFilter { $Method -eq 'Post' -and $URI -like "/rest/api/*/issue" }
            }

            Context "New-JiraIssue handles duplicate fields" {
                BeforeAll {
                    # Intentionally output multiple objects of different IDs but with the same name
                    Mock Get-JiraField -ModuleName JiraPS {
                        Write-MockDebugInfo 'Get-JiraField'
                        $Field | ForEach-Object {
                            $name = $_
                            if ($name -eq 'Reporter') {
                                'Reporter', 'Reporter_mismatched' | ForEach-Object {
                                    $fieldname = $_
                                    $object = [PSCustomObject] @{
                                        'Id' = "$fieldname"
                                    }
                                    $object.PSObject.TypeNames.Insert(0, 'JiraPS.Field')
                                    $object
                                }
                            }
                            else {
                                $object = [PSCustomObject] @{
                                    'Id' = "$name"
                                }
                                $object.PSObject.TypeNames.Insert(0, 'JiraPS.Field')
                                $object
                            }
                        }
                    }
                }

                It "finds the right field which has a matching name and id" {
                    Mock Get-JiraIssueCreateMetadata -ModuleName JiraPS {
                        Write-MockDebugInfo 'Get-JiraIssueCreateMetadata'
                        @(
                            @{Name = 'Project'; ID = 'Project'; Required = $true }
                            @{Name = 'IssueType'; ID = 'IssueType'; Required = $true }
                            @{Name = 'Priority'; ID = 'Priority'; Required = $true }
                            @{Name = 'Summary'; ID = 'Summary'; Required = $true }
                            @{Name = 'Description'; ID = 'Description'; Required = $true }
                            @{Name = 'Reporter'; ID = 'Reporter'; Required = $true }
                            @{Name = 'Reporter'; ID = 'Reporter_mismatch'; Required = $false }
                        )
                    }

                    { New-JiraIssue @newParams } | Should -Not -Throw
                }

                It "does not let mismatched createmeta reporter IDs block issue creation" {
                    Mock Get-JiraIssueCreateMetadata -ModuleName JiraPS {
                        Write-MockDebugInfo 'Get-JiraIssueCreateMetadata'
                        @(
                            @{Name = 'Project'; ID = 'Project'; Required = $true }
                            @{Name = 'IssueType'; ID = 'IssueType'; Required = $true }
                            @{Name = 'Priority'; ID = 'Priority'; Required = $true }
                            @{Name = 'Summary'; ID = 'Summary'; Required = $true }
                            @{Name = 'Description'; ID = 'Description'; Required = $true }
                            @{Name = 'Reporter'; ID = 'Reporter_mismatch1'; Required = $true }
                            @{Name = 'Reporter'; ID = 'Reporter_mismatch2'; Required = $false }
                        )
                    }

                    { New-JiraIssue @newParams } | Should -Not -Throw
                }
            }
        }

        Describe "Input Validation" {
            Context "Positive cases" {
                It "Accepts custom fields via -Fields parameter" {
                    Mock Get-JiraIssueCreateMetadata -ModuleName JiraPS {
                        Write-MockDebugInfo 'Get-JiraIssueCreateMetadata'
                        @(
                            @{Name = 'Project'; ID = 'Project'; Required = $true }
                            @{Name = 'IssueType'; ID = 'IssueType'; Required = $true }
                            @{Name = 'Priority'; ID = 'Priority'; Required = $true }
                            @{Name = 'Summary'; ID = 'Summary'; Required = $true }
                            @{Name = 'Description'; ID = 'Description'; Required = $true }
                            @{Name = 'Reporter'; ID = 'Reporter'; Required = $true }
                            @{Name = 'CustomField'; ID = 'CustomField'; Required = $true }
                        )
                    }

                    { New-JiraIssue @newParams -Fields @{'CustomField' = '.' } } | Should -Not -Throw
                }
            }
            Context "Negative cases" {
                It "does not reject a create when createmeta marks an omitted field as required" {
                    Mock Get-JiraIssueCreateMetadata -ModuleName JiraPS {
                        Write-MockDebugInfo 'Get-JiraIssueCreateMetadata'
                        @(
                            @{Name = 'Project'; ID = 'Project'; Required = $true }
                            @{Name = 'IssueType'; ID = 'IssueType'; Required = $true }
                            @{Name = 'Priority'; ID = 'Priority'; Required = $true }
                            @{Name = 'Summary'; ID = 'Summary'; Required = $true }
                            @{Name = 'Description'; ID = 'Description'; Required = $true }
                            @{Name = 'Reporter'; ID = 'Reporter'; Required = $true }
                            @{Name = 'CustomField'; ID = 'CustomField'; Required = $true }
                        )
                    }

                    { New-JiraIssue @newParams } | Should -Not -Throw
                    Should -Invoke -CommandName Get-JiraIssueCreateMetadata -ModuleName JiraPS -Times 0
                }
            }
        }

        Describe "Cloud Deployment" {
            BeforeAll {
                Mock Test-JiraCloudServer -ModuleName JiraPS { $true }

                Mock Resolve-JiraUser -ModuleName JiraPS {
                    $object = [PSCustomObject]@{
                        'Name'      = 'testUsername'
                        'AccountId' = '5b10ac8d82e05b22cc7d4ef5'
                    }
                    $object.PSObject.TypeNames.Insert(0, 'AtlassianPS.JiraPS.User')
                    return $object
                }
            }

            It "uses accountId for reporter on Cloud" {
                { New-JiraIssue @newParams } | Should -Not -Throw

                Should -Invoke Invoke-JiraMethod -ModuleName JiraPS -Exactly 1 -ParameterFilter {
                    $Method -eq 'Post' -and
                    $Body -match 'accountId'
                }
            }

            It "wraps -Description into an Atlassian Document Format document on Cloud" {
                { New-JiraIssue @newParams } | Should -Not -Throw

                Should -Invoke Invoke-JiraMethod -ModuleName JiraPS -Exactly 1 -ParameterFilter {
                    $payload = $Body | ConvertFrom-Json
                    $payload.fields.description.type -eq 'doc' -and
                    $payload.fields.description.version -eq 1 -and
                    $payload.fields.description.content[0].type -eq 'paragraph' -and
                    $payload.fields.description.content[0].content[0].text -eq 'Test description'
                }
            }

            It "targets the v3 create-issue endpoint on Cloud" {
                { New-JiraIssue @newParams } | Should -Not -Throw

                Should -Invoke Invoke-JiraMethod -ModuleName JiraPS -Exactly 1 -ParameterFilter {
                    $Method -eq 'Post' -and $URI -eq '/rest/api/3/issue'
                }
            }

            It "wraps a rich-text field passed via -Fields into ADF on Cloud" {
                # On Cloud, the v3 endpoint also rejects raw strings in
                # rich-text fields supplied via -Fields. The cmdlet must
                # use the field's schema (via Test-JiraRichTextField) to
                # wrap the value in ADF, matching the behaviour of the
                # explicit -Description parameter.
                Mock Get-JiraField -ModuleName JiraPS {
                    Write-MockDebugInfo 'Get-JiraField'
                    $object = [PSCustomObject]@{
                        Id     = 'description'
                        Schema = [PSCustomObject]@{ type = 'string'; system = 'description' }
                    }
                    $object.PSObject.TypeNames.Insert(0, 'JiraPS.Field')
                    $object
                }

                Mock Get-JiraIssueCreateMetadata -ModuleName JiraPS {
                    @(
                        @{Name = 'Project'; ID = 'Project'; Required = $true }
                        @{Name = 'IssueType'; ID = 'IssueType'; Required = $true }
                        @{Name = 'Priority'; ID = 'Priority'; Required = $true }
                        @{Name = 'Summary'; ID = 'Summary'; Required = $true }
                        @{Name = 'Description'; ID = 'Description'; Required = $true }
                        @{Name = 'Reporter'; ID = 'Reporter'; Required = $true }
                    )
                }

                $paramsWithoutDescription = $newParams.Clone()
                $paramsWithoutDescription.Remove('Description')

                { New-JiraIssue @paramsWithoutDescription -Fields @{ description = 'Hello via Fields' } } |
                    Should -Not -Throw

                Should -Invoke Invoke-JiraMethod -ModuleName JiraPS -Exactly 1 -ParameterFilter {
                    $payload = $Body | ConvertFrom-Json
                    $payload.fields.description.type -eq 'doc' -and
                    $payload.fields.description.content[0].content[0].text -eq 'Hello via Fields'
                }
            }

            It "leaves a non-rich-text field passed via -Fields verbatim on Cloud" {
                # Single-line / numeric / etc. fields still go to v3 as
                # their native value — wrapping would be incorrect there.
                Mock Get-JiraField -ModuleName JiraPS {
                    Write-MockDebugInfo 'Get-JiraField'
                    $object = [PSCustomObject]@{
                        Id     = 'CustomField'
                        Schema = [PSCustomObject]@{
                            type   = 'string'
                            custom = 'com.atlassian.jira.plugin.system.customfieldtypes:textfield'
                        }
                    }
                    $object.PSObject.TypeNames.Insert(0, 'JiraPS.Field')
                    $object
                }

                Mock Get-JiraIssueCreateMetadata -ModuleName JiraPS {
                    @(
                        @{Name = 'Project'; ID = 'Project'; Required = $true }
                        @{Name = 'IssueType'; ID = 'IssueType'; Required = $true }
                        @{Name = 'Priority'; ID = 'Priority'; Required = $true }
                        @{Name = 'Summary'; ID = 'Summary'; Required = $true }
                        @{Name = 'Description'; ID = 'Description'; Required = $true }
                        @{Name = 'Reporter'; ID = 'Reporter'; Required = $true }
                        @{Name = 'CustomField'; ID = 'CustomField'; Required = $false }
                    )
                }

                { New-JiraIssue @newParams -Fields @{ CustomField = 'plain' } } |
                    Should -Not -Throw

                Should -Invoke Invoke-JiraMethod -ModuleName JiraPS -Exactly 1 -ParameterFilter {
                    $payload = $Body | ConvertFrom-Json
                    $payload.fields.CustomField -is [string] -and
                    $payload.fields.CustomField -eq 'plain'
                }
            }
        }

        Describe "Description on Server / Data Center" {
            BeforeAll {
                Mock Test-JiraCloudServer -ModuleName JiraPS { $false }
            }

            It "sends -Description verbatim as a plain string" {
                { New-JiraIssue @newParams } | Should -Not -Throw

                Should -Invoke Invoke-JiraMethod -ModuleName JiraPS -Exactly 1 -ParameterFilter {
                    $payload = $Body | ConvertFrom-Json
                    $payload.fields.description -is [string] -and
                    $payload.fields.description -eq 'Test description'
                }
            }

            It "targets the v2 create-issue endpoint on Server / DC" {
                { New-JiraIssue @newParams } | Should -Not -Throw

                Should -Invoke Invoke-JiraMethod -ModuleName JiraPS -Exactly 1 -ParameterFilter {
                    $Method -eq 'Post' -and $URI -eq '/rest/api/2/issue'
                }
            }
        }

        Describe "Reporter resolution" {
            Context "Server / Data Center" {
                BeforeAll {
                    Mock Test-JiraCloudServer -ModuleName JiraPS { $false }

                    Mock Resolve-JiraUser -ModuleName JiraPS {
                        $object = [PSCustomObject]@{ 'Name' = 'testUsername' }
                        $object.PSObject.TypeNames.Insert(0, 'AtlassianPS.JiraPS.User')
                        return $object
                    }
                }

                It "resolves the -Reporter via Resolve-JiraUser before sending it" {
                    # Server used to skip resolution and forward the raw string,
                    # which silently accepted typos until the API rejected them.
                    { New-JiraIssue @newParams } | Should -Not -Throw

                    Should -Invoke Resolve-JiraUser -ModuleName JiraPS -Exactly 1 -ParameterFilter {
                        $InputObject.Name -eq 'testUsername'
                    }
                }

                It "uses the 'name' field (not 'accountId') for the reporter on Server" {
                    { New-JiraIssue @newParams } | Should -Not -Throw

                    Should -Invoke Invoke-JiraMethod -ModuleName JiraPS -Exactly 1 -ParameterFilter {
                        $Method -eq 'Post' -and
                        $Body -match '"name"\s*:\s*"testUsername"' -and
                        $Body -notmatch 'accountId'
                    }
                }
            }

            Context "Validation" {
                BeforeAll {
                    Mock Test-JiraCloudServer -ModuleName JiraPS { $false }

                    # $newParams already contains Reporter='testUsername', so
                    # splatting it AND passing -Reporter explicitly trips the
                    # "specified more than once" parameter binder on Windows
                    # PowerShell before the validators get a chance to run.
                    # These tests need a Reporter-free splat.
                    $script:noReporterParams = $newParams.Clone()
                    $noReporterParams.Remove('Reporter')
                }

                It "rejects -Reporter '' at parameter binding" {
                    { New-JiraIssue @noReporterParams -Reporter '' } | Should -Throw
                }

                It "rejects -Reporter `$null at parameter binding" {
                    { New-JiraIssue @noReporterParams -Reporter $null } | Should -Throw
                }

                It "throws a friendly error when -Reporter is whitespace-only" {
                    # Sending {name: ""} to Jira's create endpoint produces an
                    # opaque server error; rejecting at the cmdlet boundary is
                    # both clearer and consistent with Set-JiraIssue's contract.
                    { New-JiraIssue @noReporterParams -Reporter '   ' } |
                        Should -Throw -ExpectedMessage "*empty or whitespace*"
                }

                It "throws a friendly error when Resolve-JiraUser returns nothing" {
                    Mock Resolve-JiraUser -ModuleName JiraPS { $null }

                    { New-JiraIssue @newParams } | Should -Throw
                }
            }
        }

        Describe "Assignee handling" {
            BeforeAll {
                # Createmeta without Assignee; tests assert assignee shape
                # without forcing the required-field check to fire.
                Mock Get-JiraIssueCreateMetadata -ModuleName JiraPS {
                    @(
                        @{Name = 'Project'; ID = 'Project'; Required = $true }
                        @{Name = 'IssueType'; ID = 'IssueType'; Required = $true }
                        @{Name = 'Priority'; ID = 'Priority'; Required = $true }
                        @{Name = 'Summary'; ID = 'Summary'; Required = $true }
                        @{Name = 'Description'; ID = 'Description'; Required = $true }
                        @{Name = 'Reporter'; ID = 'Reporter'; Required = $true }
                    )
                }
            }

            Context "Server / Data Center" {
                BeforeAll {
                    Mock Test-JiraCloudServer -ModuleName JiraPS { $false }

                    Mock Resolve-JiraUser -ModuleName JiraPS {
                        $name = if ($InputObject -is [AtlassianPS.JiraPS.User]) { $InputObject.Name } else { [string]$InputObject }
                        $object = [PSCustomObject]@{ 'Name' = $name }
                        $object.PSObject.TypeNames.Insert(0, 'AtlassianPS.JiraPS.User')
                        return $object
                    }
                }

                It "sends the assignee 'name' field on Server when -Assignee is used" {
                    { New-JiraIssue @newParams -Assignee 'alice' } | Should -Not -Throw

                    Should -Invoke Invoke-JiraMethod -ModuleName JiraPS -Exactly 1 -ParameterFilter {
                        $Method -eq 'Post' -and
                        $Body -match '"assignee"\s*:\s*\{\s*"name"\s*:\s*"alice"\s*\}'
                    }
                }

                It "sends 'name: null' on Server when -Unassign is used" {
                    # Server/DC unassign payload differs from Cloud (accountId:null);
                    # the helper takes care of the dispatch, this asserts the wire shape.
                    { New-JiraIssue @newParams -Unassign } | Should -Not -Throw

                    Should -Invoke Invoke-JiraMethod -ModuleName JiraPS -Exactly 1 -ParameterFilter {
                        $Method -eq 'Post' -and
                        $Body -match '"assignee"\s*:\s*\{\s*"name"\s*:\s*null\s*\}'
                    }
                }
            }

            Context "Cloud" {
                BeforeAll {
                    Mock Test-JiraCloudServer -ModuleName JiraPS { $true }

                    Mock Resolve-JiraUser -ModuleName JiraPS {
                        $name = if ($InputObject -is [AtlassianPS.JiraPS.User]) { $InputObject.Name } else { [string]$InputObject }
                        $object = [PSCustomObject]@{
                            'Name'      = $name
                            'AccountId' = '5b10ac8d82e05b22cc7d4ef5'
                        }
                        $object.PSObject.TypeNames.Insert(0, 'AtlassianPS.JiraPS.User')
                        return $object
                    }
                }

                It "sends the 'accountId' field on Cloud when -Assignee is used" {
                    { New-JiraIssue @newParams -Assignee 'alice' } | Should -Not -Throw

                    Should -Invoke Invoke-JiraMethod -ModuleName JiraPS -Exactly 1 -ParameterFilter {
                        # Anchor the assignee object to its braces so we can
                        # prove the payload is exactly {accountId: "..."}
                        # with no other properties (e.g. a stray "name").
                        $Method -eq 'Post' -and
                        $Body -match '"assignee"\s*:\s*\{\s*"accountId"\s*:\s*"5b10ac8d82e05b22cc7d4ef5"\s*\}' -and
                        $Body -notmatch '"assignee"\s*:\s*\{[^}]*"name"'
                    }
                }

                It "sends 'accountId: null' on Cloud when -Unassign is used" {
                    { New-JiraIssue @newParams -Unassign } | Should -Not -Throw

                    Should -Invoke Invoke-JiraMethod -ModuleName JiraPS -Exactly 1 -ParameterFilter {
                        $Method -eq 'Post' -and
                        $Body -match '"assignee"\s*:\s*\{\s*"accountId"\s*:\s*null\s*\}' -and
                        $Body -notmatch '"assignee"\s*:\s*\{[^}]*"name"'
                    }
                }
            }

            Context "Default behavior (no assignee parameters)" {
                BeforeAll {
                    Mock Test-JiraCloudServer -ModuleName JiraPS { $false }
                }

                It "omits the assignee field entirely when neither -Assignee nor -Unassign is provided" {
                    # Jira applies the project's default assignee when 'assignee'
                    # is missing from the create payload — this is why we don't
                    # expose a -UseDefaultAssignee switch on New-JiraIssue.
                    { New-JiraIssue @newParams } | Should -Not -Throw

                    Should -Invoke Invoke-JiraMethod -ModuleName JiraPS -Exactly 1 -ParameterFilter {
                        $Method -eq 'Post' -and
                        $Body -notmatch '"assignee"'
                    }
                }
            }

            Context "Validation" {
                BeforeAll {
                    Mock Test-JiraCloudServer -ModuleName JiraPS { $false }
                }

                It "rejects -Assignee + -Unassign at parameter binding (mutually exclusive)" {
                    { New-JiraIssue @newParams -Assignee 'alice' -Unassign } | Should -Throw
                }

                It "rejects -Assignee '' at parameter binding" {
                    { New-JiraIssue @newParams -Assignee '' } | Should -Throw
                }

                It "throws a friendly error when -Assignee is whitespace-only" {
                    { New-JiraIssue @newParams -Assignee '   ' } |
                        Should -Throw -ExpectedMessage "*empty or whitespace*"
                }

                It "throws when Resolve-JiraUser returns nothing for -Assignee" {
                    Mock Resolve-JiraUser -ModuleName JiraPS { $null }

                    { New-JiraIssue @newParams -Assignee 'ghost' } | Should -Throw
                }
            }

            Context "Accepts AtlassianPS.JiraPS.User objects via -Assignee" {
                BeforeAll {
                    Mock Test-JiraCloudServer -ModuleName JiraPS { $true }

                    # Resolve-JiraUser will pass a AtlassianPS.JiraPS.User-typed input through
                    # unchanged; this mock returns a known object so the helper
                    # has a stable AccountId to dispatch on.
                    Mock Resolve-JiraUser -ModuleName JiraPS {
                        $object = [PSCustomObject]@{
                            'Name'      = 'alice'
                            'AccountId' = 'aaaa-bbbb-cccc'
                        }
                        $object.PSObject.TypeNames.Insert(0, 'AtlassianPS.JiraPS.User')
                        return $object
                    }
                }

                It "accepts a AtlassianPS.JiraPS.User object via -Assignee and extracts its AccountId" {
                    $user = [PSCustomObject]@{
                        'Name'      = 'alice'
                        'AccountId' = 'aaaa-bbbb-cccc'
                    }
                    $user.PSObject.TypeNames.Insert(0, 'AtlassianPS.JiraPS.User')

                    { New-JiraIssue @newParams -Assignee $user } | Should -Not -Throw

                    Should -Invoke Invoke-JiraMethod -ModuleName JiraPS -Exactly 1 -ParameterFilter {
                        $Body -match '"accountId"\s*:\s*"aaaa-bbbb-cccc"'
                    }
                }
            }
        }

        Describe "Field Resolution" {
            BeforeAll {
                Mock Test-JiraCloudServer -ModuleName JiraPS { $false }

                Mock Get-JiraIssueCreateMetadata -ModuleName JiraPS {
                    Write-MockDebugInfo 'Get-JiraIssueCreateMetadata'
                    @(
                        [PSCustomObject]@{ Id = 'Project'; Name = 'Project'; Required = $true }
                        [PSCustomObject]@{ Id = 'IssueType'; Name = 'IssueType'; Required = $true }
                        [PSCustomObject]@{ Id = 'Priority'; Name = 'Priority'; Required = $true }
                        [PSCustomObject]@{ Id = 'Summary'; Name = 'Summary'; Required = $true }
                        [PSCustomObject]@{ Id = 'Description'; Name = 'Description'; Required = $true }
                        [PSCustomObject]@{ Id = 'Reporter'; Name = 'Reporter'; Required = $true }
                        [PSCustomObject]@{
                            Id       = 'customfield_10001'
                            Name     = 'My Custom Field'
                            Required = $false
                            Schema   = [PSCustomObject]@{ type = 'string' }
                        }
                    ) | ForEach-Object {
                        $_.PSObject.TypeNames.Insert(0, 'JiraPS.CreateMetaField')
                        $_
                    }
                }
            }

            It "resolves a field via create metadata and does not call Get-JiraField" {
                { New-JiraIssue @newParams -Fields @{ customfield_10001 = 'scoped value' } } |
                    Should -Not -Throw

                Should -Invoke Get-JiraField -ModuleName JiraPS -Exactly -Times 0
                Should -Invoke Invoke-JiraMethod -ModuleName JiraPS -Times 1 -ParameterFilter {
                    $Body -match '"customfield_10001"'
                }
            }

            It "resolves a field by display name via create metadata" {
                { New-JiraIssue @newParams -Fields @{ 'My Custom Field' = 'named value' } } |
                    Should -Not -Throw

                Should -Invoke Get-JiraField -ModuleName JiraPS -Exactly -Times 0
                Should -Invoke Invoke-JiraMethod -ModuleName JiraPS -Times 1 -ParameterFilter {
                    $Body -match '"customfield_10001"'
                }
            }

            It "falls back to Get-JiraField for fields not present in create metadata" {
                # 'CustomField' is returned by the default Get-JiraField mock but is
                # not in the create metadata above, triggering the fallback path.
                { New-JiraIssue @newParams -Fields @{ 'CustomField' = 'fallback value' } } |
                    Should -Not -Throw

                Should -Invoke Get-JiraField -ModuleName JiraPS -Exactly -Times 1
            }

            It "fetches the global field list at most once when multiple unscoped keys are present" {
                Mock Get-JiraField -ModuleName JiraPS {
                    @(
                        [PSCustomObject]@{ Id = 'CustomField' }
                        [PSCustomObject]@{ Id = 'AnotherCustomField' }
                    ) | ForEach-Object {
                        $_.PSObject.TypeNames.Insert(0, 'JiraPS.Field')
                        $_
                    }
                }

                New-JiraIssue @newParams -Fields @{
                    'CustomField'        = 'a'
                    'AnotherCustomField' = 'b'
                }

                Should -Invoke Get-JiraField -ModuleName JiraPS -Exactly -Times 1
            }

            It "throws when a field cannot be resolved from create metadata or the global list" {
                { New-JiraIssue @newParams -Fields @{ NonExistentField_XYZ = 'value' } } |
                    Should -Throw
            }
        }
    }
}
