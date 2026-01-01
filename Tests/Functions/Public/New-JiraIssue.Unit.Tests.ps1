#requires -modules @{ ModuleName = "Pester"; ModuleVersion = "5.7"; MaximumVersion = "5.999" }

BeforeDiscovery {
    . "$PSScriptRoot/../../Helpers/TestTools.ps1"

    Initialize-TestEnvironment
    $script:moduleToTest = Resolve-ModuleSource

    Import-Module $script:moduleToTest -Force -ErrorAction Stop
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
                $object.PSObject.TypeNames.Insert(0, 'JiraPS.Project')
                return $object
            }

            Mock Get-JiraUser -ModuleName JiraPS {
                Write-MockDebugInfo 'Get-JiraUser'
                $object = [PSCustomObject] @{
                    'Name' = $UserName
                }
                $object.PSObject.TypeNames.Insert(0, 'JiraPS.User')
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
                    @{ parameter = 'Reporter'; type = 'String' }
                    @{ parameter = 'Label'; type = 'String[]' }
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
                Should -Invoke -CommandName Invoke-JiraMethod -ModuleName JiraPS -Times 1 -ParameterFilter { $Method -eq 'Post' -and $URI -like "$jiraServer/rest/api/*/issue" }
            }
            It "Creates an issue in JIRA from pipeline" {
                { $pipelineParams | New-JiraIssue } | Should -Not -Throw
                # The String in the ParameterFilter is made from the keywords
                # we should expect to see in the JSON that should be sent,
                # including the summary provided in the test call above.
                Should -Invoke -CommandName Invoke-JiraMethod -ModuleName JiraPS -Times 1 -ParameterFilter { $Method -eq 'Post' -and $URI -like "$jiraServer/rest/api/*/issue" }
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

                It "throws when a field name return multiple fields without a field has matching name and id" {
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

                    { New-JiraIssue @newParams } | Should -Throw
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
                It "Checks to make sure all required fields are provided" {
                    # We'll create a custom field that's required, then see what happens when we don't provide it
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

                    { New-JiraIssue @newParams } | Should -Throw
                }
            }
        }
    }
}
