#requires -modules @{ ModuleName = "Pester"; ModuleVersion = "5.7"; MaximumVersion = "5.999" }

BeforeDiscovery {
    . "$PSScriptRoot/../../Helpers/TestTools.ps1"

    $script:moduleToTest = Initialize-TestEnvironment
}

InModuleScope JiraPS {
    Describe "Invoke-JiraIssueTransition" -Tag 'Unit' {
        BeforeAll {
            . "$PSScriptRoot/../../Helpers/TestTools.ps1"
            # $VerbosePreference = 'Continue'  # Uncomment for mock debugging

            #region Definitions
            $script:jiraServer = 'http://jiraserver.example.com'
            $script:issueID = 41701
            $script:issueKey = 'IT-3676'
            #endregion Definitions

            #region Mocks
            Mock Test-JiraCloudServer -ModuleName JiraPS { $false }

            Mock Get-JiraConfigServer -ModuleName JiraPS {
                Write-MockDebugInfo 'Get-JiraConfigServer'
                $jiraServer
            }

            Mock Get-JiraField -ModuleName JiraPS {
                Write-MockDebugInfo 'Get-JiraField' 'Field', 'Credential'
                # The cmdlet pre-fetches the full field catalogue (no -Field
                # filter) and looks each requested key up in an in-memory
                # hashtable, so the mock must return everything the tests
                # reference. Schema metadata mirrors what Jira Cloud
                # actually returns (see Test-JiraRichTextField for why).
                @(
                    [PSCustomObject]@{
                        Id     = 'customfield_12345'
                        Name   = 'Custom Field 12345'
                        Schema = [PSCustomObject]@{ type = 'string'; custom = 'com.atlassian.jira.plugin.system.customfieldtypes:textfield' }
                    }
                    [PSCustomObject]@{
                        Id     = 'customfield_67890'
                        Name   = 'Custom Field 67890'
                        Schema = [PSCustomObject]@{ type = 'string'; custom = 'com.atlassian.jira.plugin.system.customfieldtypes:textfield' }
                    }
                    [PSCustomObject]@{
                        Id     = 'description'
                        Name   = 'Description'
                        Schema = [PSCustomObject]@{ type = 'string'; system = 'description' }
                    }
                ).ForEach({
                        $_.PSObject.TypeNames.Insert(0, 'JiraPS.Field')
                        $_
                    })
            }

            Mock Get-JiraIssue -ModuleName JiraPS {
                Write-MockDebugInfo 'Get-JiraIssue' 'Key'
                $t1 = [PSCustomObject] @{
                    Name = 'Start Progress'
                    ID   = 11
                }
                $t1.PSObject.TypeNames.Insert(0, 'JiraPS.Transition')
                $t2 = [PSCustomObject] @{
                    Name = 'Resolve'
                    ID   = 81
                }
                $t2.PSObject.TypeNames.Insert(0, 'JiraPS.Transition')

                $object = [AtlassianPS.JiraPS.Issue]@{
                    ID         = $issueID
                    Key        = $issueKey
                    RestUrl    = "$jiraServer/rest/api/2/issue/$issueID"
                    Transition = @($t1, $t2)
                }
                $object
            }

            Mock Resolve-JiraIssueObject -ModuleName JiraPS {
                Write-MockDebugInfo 'Resolve-JiraIssueObject' 'InputObject'
                Get-JiraIssue -Key $InputObject.Key
            }

            Mock Invoke-JiraMethod -ModuleName JiraPS -ParameterFilter {
                $Method -eq 'Get' -and
                $URI -like "*issue/$issueID/transitions*"
            } {
                Write-MockDebugInfo 'Invoke-JiraMethod' 'Method', 'Uri'
                # Return transition metadata with screen fields so that
                # -Fields resolution uses the scoped metadata path.
                [PSCustomObject]@{
                    transitions = @(
                        [PSCustomObject]@{
                            id     = '11'
                            fields = [PSCustomObject]@{
                                customfield_12345 = [PSCustomObject]@{
                                    name            = 'Custom Field 12345'
                                    hasDefaultValue = $false
                                    required        = $false
                                    schema          = [PSCustomObject]@{
                                        type   = 'string'
                                        custom = 'com.atlassian.jira.plugin.system.customfieldtypes:textfield'
                                    }
                                    operations      = @('set')
                                }
                                customfield_67890 = [PSCustomObject]@{
                                    name            = 'Custom Field 67890'
                                    hasDefaultValue = $false
                                    required        = $false
                                    schema          = [PSCustomObject]@{
                                        type   = 'string'
                                        custom = 'com.atlassian.jira.plugin.system.customfieldtypes:textfield'
                                    }
                                    operations      = @('set')
                                }
                                description       = [PSCustomObject]@{
                                    name            = 'Description'
                                    hasDefaultValue = $false
                                    required        = $false
                                    schema          = [PSCustomObject]@{
                                        type   = 'string'
                                        system = 'description'
                                    }
                                    operations      = @('set')
                                }
                            }
                        }
                    )
                }
            }

            Mock Invoke-JiraMethod -ModuleName JiraPS -ParameterFilter {
                $Method -eq 'Post' -and
                $URI -eq "$jiraServer/rest/api/2/issue/$issueID/transitions"
            } {
                Write-MockDebugInfo 'Invoke-JiraMethod' 'Method', 'Uri', 'Body'
                # This should return a 204 status code, so no data should actually be returned
            }

            # Cloud equivalent: when Test-JiraCloudServer returns $true the
            # cmdlet hits the v3 endpoint (so the API accepts ADF). The
            # mocked response is the same — only the URI changes.
            Mock Invoke-JiraMethod -ModuleName JiraPS -ParameterFilter {
                $Method -eq 'Post' -and
                $URI -eq "$jiraServer/rest/api/3/issue/$issueID/transitions"
            } {
                Write-MockDebugInfo 'Invoke-JiraMethod' 'Method', 'Uri', 'Body'
            }

            Mock Invoke-JiraMethod -ModuleName JiraPS {
                Write-MockDebugInfo 'Invoke-JiraMethod' 'Method', 'Uri'
                throw "Unidentified call to Invoke-JiraMethod: $Method $URI"
            }
            #endregion Mocks
        }

        Describe "Signature" {
            BeforeAll {
                $script:command = Get-Command -Name 'Invoke-JiraIssueTransition'
            }

            Context "Parameter Types" {
                It "has a parameter '<parameter>' of type '<type>'" -TestCases @(
                    @{ parameter = "Issue"; type = "AtlassianPS.JiraPS.Issue" }
                    @{ parameter = "Transition"; type = "Object" }
                    @{ parameter = "Comment"; type = "String" }
                    @{ parameter = "TimeSpent"; type = "TimeSpan" }
                    @{ parameter = "Assignee"; type = "User" }
                    @{ parameter = "Unassign"; type = "Switch" }
                    @{ parameter = "Fields"; type = "PSCustomObject" }
                    @{ parameter = "Passthru"; type = "Switch" }
                    @{ parameter = "Credential"; type = "System.Management.Automation.PSCredential" }
                ) {
                    $command | Should -HaveParameter $parameter
                }
            }

            Context "Mandatory Parameters" {
                It "parameter '<parameter>' is mandatory" -TestCases @(
                    @{ parameter = "Issue" }
                    @{ parameter = "Transition" }
                ) {
                    $command | Should -HaveParameter $parameter -Mandatory
                }
            }

            Context "Parameter Sets" {
                It "defines parameter set '<setName>'" -TestCases @(
                    @{ setName = 'AssignToUser' }
                    @{ setName = 'Unassign' }
                ) {
                    param($setName)
                    $command.ParameterSets.Name | Should -Contain $setName
                }

                It "uses 'AssignToUser' as the default parameter set" {
                    $command.DefaultParameterSet | Should -Be 'AssignToUser'
                }

                It "binds '<parameter>' only to parameter set '<setName>'" -TestCases @(
                    @{ parameter = 'Assignee'; setName = 'AssignToUser' }
                    @{ parameter = 'Unassign'; setName = 'Unassign' }
                ) {
                    param($parameter, $setName)
                    $sets = $command.Parameters.Item($parameter).ParameterSets.Keys
                    $sets | Should -HaveCount 1
                    $sets | Should -Contain $setName
                }
            }
        }

        Describe "Behavior" {
            Context "Transition Execution" {
                It "performs a transition when given an issue key and transition ID" {
                    { Invoke-JiraIssueTransition -Issue $issueKey -Transition 11 } | Should -Not -Throw

                    Should -Invoke Get-JiraIssue -ModuleName JiraPS -Exactly -Times 1
                    Should -Invoke Invoke-JiraMethod -ModuleName JiraPS -Exactly -Times 1
                }

                It "performs a transition when given an issue object and transition object" {
                    $issue = Get-JiraIssue -Key $issueKey
                    $transition = $issue.Transition[0]
                    { Invoke-JiraIssueTransition -Issue $issue -Transition $transition } | Should -Not -Throw

                    # Get-JiraIssue called once in test setup, once in Invoke-JiraIssueTransition
                    Should -Invoke Get-JiraIssue -ModuleName JiraPS -Exactly -Times 2
                    Should -Invoke Invoke-JiraMethod -ModuleName JiraPS -Exactly -Times 1
                }
            }

            Context "Field Updates" {
                It "updates custom fields if provided to the -Fields parameter" {
                    {
                        $parameter = @{
                            Issue      = $issueKey
                            Transition = 11
                            Fields     = @{
                                'customfield_12345' = 'foo'
                                'customfield_67890' = 'bar'
                            }
                        }
                        Invoke-JiraIssueTransition @parameter
                    } | Should -Not -Throw

                    Should -Invoke Invoke-JiraMethod -ModuleName JiraPS -Times 1 -ParameterFilter {
                        $Method -eq 'Post' -and
                        $URI -like "*/rest/api/2/issue/$issueID/transitions" -and
                        $Body -like '*customfield_12345*set*foo*'
                    }
                    Should -Invoke Invoke-JiraMethod -ModuleName JiraPS -Times 1 -ParameterFilter {
                        $Method -eq 'Post' -and
                        $URI -like "*/rest/api/2/issue/$issueID/transitions" -and
                        $Body -like '*customfield_67890*set*bar*'
                    }
                }

                It "updates assignee name if provided to the -Assignee parameter" {
                    Mock Get-JiraUser -ModuleName JiraPS {
                        Write-MockDebugInfo 'Get-JiraUser' 'UserName'
                        [PSCustomObject] @{
                            'Name'    = 'powershell-user'
                            'RestUrl' = "$jiraServer/rest/api/2/user?username=powershell-user"
                        }
                    }
                    { Invoke-JiraIssueTransition -Issue $issueKey -Transition 11 -Assignee 'powershell-user' } | Should -Not -Throw

                    Should -Invoke Invoke-JiraMethod -ModuleName JiraPS -Times 1 -ParameterFilter {
                        $Method -eq 'Post' -and
                        $URI -like "*/rest/api/2/issue/$issueID/transitions" -and
                        $Body -like '*name*powershell-user*'
                    }
                }

                It "unassigns an issue when -Unassign switch is used" {
                    { Invoke-JiraIssueTransition -Issue $issueKey -Transition 11 -Unassign } | Should -Not -Throw

                    Should -Invoke Invoke-JiraMethod -ModuleName JiraPS -Times 1 -ParameterFilter {
                        $Method -eq 'Post' -and
                        $URI -like "*/rest/api/2/issue/$issueID/transitions" -and
                        $Body -match '"name":\s*null'
                    }
                }

                It "throws when -Assignee is given an empty string" {
                    { Invoke-JiraIssueTransition -Issue $issueKey -Transition 11 -Assignee "" } | Should -Throw
                }

                It "throws when -Assignee is given a whitespace-only string" {
                    { Invoke-JiraIssueTransition -Issue $issueKey -Transition 11 -Assignee "   " } | Should -Throw -ExpectedMessage "*empty or whitespace*"
                }

                It "throws when -Assignee is given `$null" {
                    { Invoke-JiraIssueTransition -Issue $issueKey -Transition 11 -Assignee $null } | Should -Throw
                }

                It "throws when both -Unassign and -Assignee are given" {
                    { Invoke-JiraIssueTransition -Issue $issueKey -Transition 11 -Assignee "powershell-user" -Unassign } | Should -Throw
                }

                It "adds a comment if provided to the -Comment parameter" {
                    { Invoke-JiraIssueTransition -Issue $issueKey -Transition 11 -Comment 'test comment' } | Should -Not -Throw

                    Should -Invoke Invoke-JiraMethod -ModuleName JiraPS -Times 1 -ParameterFilter {
                        $Method -eq 'Post' -and
                        $URI -like "*/rest/api/2/issue/$issueID/transitions" -and
                        $Body -like '*body*test comment*'
                    }
                }

                It "adds a worklog if provided to the -TimeSpent parameter" {
                    { Invoke-JiraIssueTransition -Issue $issueKey -Transition 11 -TimeSpent ([TimeSpan]::FromMinutes(15)) } | Should -Not -Throw

                    Should -Invoke Invoke-JiraMethod -ModuleName JiraPS -Times 1 -ParameterFilter {
                        $Method -eq 'Post' -and
                        $URI -like "*/rest/api/2/issue/$issueID/transitions" -and
                        $Body -like '*worklog*timeSpentSeconds*900*' -and
                        $Body -match '"started":\s*"\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}\.\d{3}[\+\-]\d{4}"'
                    }
                }
            }

            Context "Output Behavior" {
                It "returns the Issue object when -Passthru is provided" {
                    { $null = Invoke-JiraIssueTransition -Issue $issueKey -Transition 11 -Passthru } | Should -Not -Throw
                    $result = Invoke-JiraIssueTransition -Issue $issueKey -Transition 11 -Passthru
                    $result | Should -Not -BeNullOrEmpty

                    Should -Invoke Get-JiraIssue -ModuleName JiraPS -Exactly -Times 4
                }

                It "does not return a value when -Passthru is omitted" {
                    { $null = Invoke-JiraIssueTransition -Issue $issueKey -Transition 11 } | Should -Not -Throw
                    $result = Invoke-JiraIssueTransition -Issue $issueKey -Transition 11
                    $result | Should -BeNullOrEmpty

                    Should -Invoke Get-JiraIssue -ModuleName JiraPS -Exactly -Times 2
                }
            }
        }

        Describe "Input Validation" {
            Context "Pipeline Support" {
                It "handles pipeline input from Get-JiraIssue" {
                    { Get-JiraIssue -Key $issueKey | Invoke-JiraIssueTransition -Transition 11 } | Should -Not -Throw

                    Should -Invoke Get-JiraIssue -ModuleName JiraPS -Exactly -Times 2
                    Should -Invoke Invoke-JiraMethod -ModuleName JiraPS -Exactly -Times 1
                }
            }
        }

        Describe "Cloud Deployment" {
            BeforeAll {
                $script:testAccountId = '5b10a2844c20165700ede21a'

                Mock Test-JiraCloudServer -ModuleName JiraPS { $true }

                Mock Resolve-JiraUser -ModuleName JiraPS {
                    Write-MockDebugInfo 'Resolve-JiraUser' 'InputObject', 'Credential'
                    $object = [PSCustomObject] @{
                        'Name'      = $InputObject
                        'AccountId' = $testAccountId
                        'RestUrl'   = "$jiraServer/rest/api/2/user?username=$InputObject"
                    }
                    $object.PSObject.TypeNames.Insert(0, 'AtlassianPS.JiraPS.User')
                    $object
                }
            }

            It "Uses accountId for assignee in transition body" {
                { Invoke-JiraIssueTransition -Issue $issueKey -Transition 11 -Assignee 'powershell-user' } | Should -Not -Throw

                Should -Invoke Invoke-JiraMethod -ModuleName JiraPS -Times 1 -ParameterFilter {
                    $Method -eq 'Post' -and
                    $URI -like "*/rest/api/3/issue/$issueID/transitions" -and
                    $Body -like "*accountId*$testAccountId*"
                }
            }

            It "Sends accountId:null when -Unassign on Cloud deployment" {
                { Invoke-JiraIssueTransition -Issue $issueKey -Transition 11 -Unassign } | Should -Not -Throw

                Should -Invoke Invoke-JiraMethod -ModuleName JiraPS -Times 1 -ParameterFilter {
                    $Method -eq 'Post' -and
                    $URI -like "*/rest/api/3/issue/$issueID/transitions" -and
                    $Body -match '"accountId":\s*null'
                }
            }

            It "wraps -Comment into an ADF document on Cloud deployment" {
                { Invoke-JiraIssueTransition -Issue $issueKey -Transition 11 -Comment 'transition note' } | Should -Not -Throw

                Should -Invoke Invoke-JiraMethod -ModuleName JiraPS -Times 1 -ParameterFilter {
                    $Method -eq 'Post' -and
                    $URI -like "*/rest/api/3/issue/$issueID/transitions" -and
                    ($payload = $Body | ConvertFrom-Json) -and
                    $payload.update.comment[0].add.body.type -eq 'doc' -and
                    $payload.update.comment[0].add.body.version -eq 1 -and
                    $payload.update.comment[0].add.body.content[0].type -eq 'paragraph' -and
                    $payload.update.comment[0].add.body.content[0].content[0].text -eq 'transition note'
                }
            }

            It "uses the v3 issue endpoint on Cloud" {
                { Invoke-JiraIssueTransition -Issue $issueKey -Transition 11 } | Should -Not -Throw

                Should -Invoke Invoke-JiraMethod -ModuleName JiraPS -Times 1 -ParameterFilter {
                    $Method -eq 'Post' -and
                    $URI -eq "$jiraServer/rest/api/3/issue/$issueID/transitions"
                }
            }

            It "wraps a rich-text field passed via -Fields into ADF on Cloud" {
                # Cloud's v3 transition endpoint also rejects raw strings
                # for rich-text fields supplied via -Fields. The cmdlet
                # must inspect the field schema and wrap rich-text values
                # via Resolve-JiraTextFieldPayload, matching -Comment.
                {
                    Invoke-JiraIssueTransition -Issue $issueKey -Transition 11 -Fields @{
                        description = 'transition desc'
                    }
                } | Should -Not -Throw

                Should -Invoke Invoke-JiraMethod -ModuleName JiraPS -Times 1 -ParameterFilter {
                    if ($Method -ne 'Post' -or $URI -notlike "*/rest/api/3/issue/$issueID/transitions") {
                        return $false
                    }

                    $payload = $Body | ConvertFrom-Json
                    $set = $payload.update.description[0].set

                    $set.type -eq 'doc' -and
                    $set.content[0].content[0].text -eq 'transition desc'
                }
            }

            It "leaves a non-rich-text field passed via -Fields as a plain string on Cloud" {
                # Mirrors New-/Set-JiraIssue: a single-line custom textfield
                # supplied via -Fields must NOT be ADF-wrapped on Cloud.
                {
                    Invoke-JiraIssueTransition -Issue $issueKey -Transition 11 -Fields @{
                        customfield_12345 = 'plain'
                    }
                } | Should -Not -Throw

                Should -Invoke Invoke-JiraMethod -ModuleName JiraPS -Times 1 -ParameterFilter {
                    if ($Method -ne 'Post' -or $URI -notlike "*/rest/api/3/issue/$issueID/transitions") {
                        return $false
                    }

                    $payload = $Body | ConvertFrom-Json
                    $payload.update.customfield_12345[0].set -eq 'plain'
                }
            }
        }

        Describe "Field Resolution" {
            It "resolves fields via transition screen metadata and does not call Get-JiraField" {
                Invoke-JiraIssueTransition -Issue $issueKey -Transition 11 -Fields @{
                    customfield_12345 = 'foo'
                    customfield_67890 = 'bar'
                }

                # Fields are in the transition metadata — global catalogue not needed
                Should -Invoke Get-JiraField -ModuleName JiraPS -Exactly -Times 0

                # Transition metadata GET was made exactly once
                Should -Invoke Invoke-JiraMethod -ModuleName JiraPS -Times 1 -ParameterFilter {
                    $Method -eq 'Get' -and $URI -like "*issue/$issueID/transitions*"
                }
            }

            It "falls back to Get-JiraField for fields not present in transition metadata" {
                Mock Invoke-JiraMethod -ModuleName JiraPS -ParameterFilter {
                    $Method -eq 'Get' -and $URI -like "*issue/$issueID/transitions*"
                } {
                    # Transition with an empty fields map — no scoped metadata
                    [PSCustomObject]@{
                        transitions = @([PSCustomObject]@{ id = '11'; fields = [PSCustomObject]@{} })
                    }
                }

                Invoke-JiraIssueTransition -Issue $issueKey -Transition 11 -Fields @{
                    customfield_12345 = 'foo'
                }

                Should -Invoke Get-JiraField -ModuleName JiraPS -Exactly -Times 1
            }

            It "fetches the global field list at most once when multiple unscoped keys are present" {
                Mock Invoke-JiraMethod -ModuleName JiraPS -ParameterFilter {
                    $Method -eq 'Get' -and $URI -like "*issue/$issueID/transitions*"
                } {
                    [PSCustomObject]@{
                        transitions = @([PSCustomObject]@{ id = '11'; fields = [PSCustomObject]@{} })
                    }
                }

                Invoke-JiraIssueTransition -Issue $issueKey -Transition 11 -Fields @{
                    customfield_12345 = 'foo'
                    customfield_67890 = 'bar'
                }

                Should -Invoke Get-JiraField -ModuleName JiraPS -Exactly -Times 1
            }

            It "fetches transition metadata once per call regardless of how many -Fields keys are supplied" {
                Invoke-JiraIssueTransition -Issue $issueKey -Transition 11 -Fields @{
                    customfield_12345 = 'foo'
                    customfield_67890 = 'bar'
                }

                Should -Invoke Invoke-JiraMethod -ModuleName JiraPS -Times 1 -ParameterFilter {
                    $Method -eq 'Get' -and $URI -like "*issue/$issueID/transitions*"
                }
            }

            It "sends 'expand=transitions.fields' and the transition ID as query parameters when fetching transition metadata" {
                Invoke-JiraIssueTransition -Issue $issueKey -Transition 11 -Fields @{
                    customfield_12345 = 'foo'
                }

                Should -Invoke Invoke-JiraMethod -ModuleName JiraPS -Times 1 -ParameterFilter {
                    $Method -eq 'Get' -and
                    $URI -like "*issue/$issueID/transitions*" -and
                    $GetParameter['expand'] -eq 'transitions.fields' -and
                    $GetParameter['transitionId'] -eq '11'
                }
            }
        }
    }
}
