#requires -modules @{ ModuleName = "Pester"; ModuleVersion = "5.7"; MaximumVersion = "5.999" }

BeforeDiscovery {
    . "$PSScriptRoot/../../Helpers/TestTools.ps1"

    Initialize-TestEnvironment
    $script:moduleToTest = Resolve-ModuleSource

    Import-Module $script:moduleToTest -Force -ErrorAction Stop
}

InModuleScope JiraPS {
    Describe "Remove-JiraIssueAttachment" -Tag 'Unit' {

        BeforeAll {
            . "$PSScriptRoot/../../Helpers/TestTools.ps1"
            # $VerbosePreference = 'Continue'

            #region Definitions
            $script:jiraServer = 'http://jiraserver.example.com'
            $script:issueKey = "FOO-123"
            $script:attachmentId1 = 1010
            $script:attachmentId2 = 1011
            $script:attachmentFile1 = 'foo.png'
            $script:attachmentFile2 = 'bar.zip'
            #endregion Definitions

            #region Mocks
            Mock Get-JiraConfigServer -ModuleName JiraPS {
                Write-MockDebugInfo 'Get-JiraConfigServer'
                $jiraServer
            }

            Mock Get-JiraIssueAttachment -ModuleName JiraPS {
                Write-MockDebugInfo 'Get-JiraIssueAttachment' 'Issue'
                $all = @()
                $Attachment = [PSCustomObject]@{
                    id       = $attachmentId1
                    fileName = $attachmentFile1
                }
                $Attachment.PSObject.TypeNames.Insert(0, 'JiraPS.Attachment')
                $all += $Attachment

                $Attachment = [PSCustomObject]@{
                    id       = $attachmentId2
                    fileName = $attachmentFile2
                }
                $Attachment.PSObject.TypeNames.Insert(0, 'JiraPS.Attachment')
                $all += $Attachment
                $all
            }

            Mock Get-JiraIssue -ModuleName JiraPS {
                Write-MockDebugInfo 'Get-JiraIssue' 'Key'
                $Attachment = [PSCustomObject]@{
                    id       = $attachmentId1
                    fileName = $attachmentFile1
                }
                $Attachment.PSObject.TypeNames.Insert(0, 'JiraPS.Attachment')

                $IssueObj = [PSCustomObject]@{
                    Key        = $issueKey
                    attachment = $Attachment
                }
                $IssueObj.PSObject.TypeNames.Insert(0, 'JiraPS.Issue')
                $IssueObj
            }

            Mock Resolve-JiraIssueObject -ModuleName JiraPS {
                Write-MockDebugInfo 'Resolve-JiraIssueObject' 'Issue'
                Get-JiraIssue -Key $Issue
            }

            Mock Invoke-JiraMethod -ModuleName JiraPS -ParameterFilter { $Method -eq 'Delete' -and $URI -eq "$jiraServer/rest/api/2/attachment/$attachmentId1" } {
                Write-MockDebugInfo 'Invoke-JiraMethod' 'Method', 'Uri'
            }

            Mock Invoke-JiraMethod -ModuleName JiraPS -ParameterFilter { $Method -eq 'Delete' -and $URI -eq "$jiraServer/rest/api/2/attachment/$attachmentId2" } {
                Write-MockDebugInfo 'Invoke-JiraMethod' 'Method', 'Uri'
            }

            # Generic catch-all. This will throw an exception if we forgot to mock something.
            Mock Invoke-JiraMethod -ModuleName JiraPS {
                Write-MockDebugInfo 'Invoke-JiraMethod' 'Method', 'Uri'
                throw "Unidentified call to Invoke-JiraMethod"
            }
            #endregion Mocks
        }

        Describe "Signature" {
            BeforeAll {
                $script:command = Get-Command -Name Remove-JiraIssueAttachment
            }

            Context "Parameter Types" {
                It "has a parameter '<parameter>' of type '<type>'" -TestCases @(
                    @{ parameter = 'AttachmentId'; type = 'Int32[]' }
                    @{ parameter = 'Issue'; type = 'Object' }
                    @{ parameter = 'FileName'; type = 'String[]' }
                    @{ parameter = 'Credential'; type = 'PSCredential' }
                    @{ parameter = 'Force'; type = 'Switch' }
                ) {
                    param($parameter, $type)
                    $command | Should -HaveParameter $parameter -Type $type
                }
            }

            Context "Mandatory Parameters" {}

            Context "Default Values" {}
        }

        Describe "Behavior" {
            Context "Attachment Deletion" {
                It 'validates the parameters' {
                    # AttachmentId can't be null or empty
                    { Remove-JiraIssueAttachment -AttachmentId $null -Force } | Should -Throw
                    # Issue can't be null or empty
                    { Remove-JiraIssueAttachment -Issue "" -Force } | Should -Throw
                    # AttachmentId must be an Int
                    { Remove-JiraIssueAttachment -AttachmentId "a" -Force } | Should -Throw
                    # Issue must be an Issue or a String
                    { Remove-JiraIssueAttachment -Issue (Get-Date) -Force } | Should -Throw
                    # Issue can't be an array
                    { Remove-JiraIssueAttachment -Issue $issueKey, $issueKey -Force } | Should -Throw

                    # All Parameters for DefaultParameterSet
                    { Remove-JiraIssueAttachment -AttachmentId $attachmentId1 -Force } | Should -Not -Throw
                    { Remove-JiraIssueAttachment -AttachmentId $attachmentId1, $attachmentId2 -Force } | Should -Not -Throw
                    { Remove-JiraIssueAttachment -Issue (Get-JiraIssue $issueKey) -Force } | Should -Not -Throw
                    { Remove-JiraIssueAttachment -Issue $issueKey -FileName $attachmentFile1 -Force } | Should -Not -Throw
                    { Remove-JiraIssueAttachment -Issue $issueKey -FileName $attachmentFile1, $attachmentFile2 -Force } | Should -Not -Throw

                    # ensure the calls under the hood
                    Should -Invoke 'Get-JiraIssue' -ModuleName JiraPS -Exactly -Times 4 -Scope It
                    Should -Invoke 'Get-JiraIssueAttachment' -ModuleName JiraPS -Exactly -Times 3 -Scope It
                    Should -Invoke 'Invoke-JiraMethod' -ModuleName JiraPS -ParameterFilter { $Method -eq 'Get' } -Exactly -Times 0 -Scope It
                    Should -Invoke 'Invoke-JiraMethod' -ModuleName JiraPS -ParameterFilter { $Method -eq 'Post' } -Exactly -Times 0 -Scope It
                    Should -Invoke 'Invoke-JiraMethod' -ModuleName JiraPS -ParameterFilter { $Method -eq 'Put' } -Exactly -Times 0 -Scope It
                    Should -Invoke 'Invoke-JiraMethod' -ModuleName JiraPS -ParameterFilter { $Method -eq 'Delete' } -Exactly -Times 8 -Scope It
                    Should -Invoke 'Invoke-JiraMethod' -ModuleName JiraPS -ParameterFilter { $Method -eq 'Delete' -and $URI -like "$jiraServer/rest/api/2/attachment/$attachmentId1" } -Exactly -Times 5 -Scope It
                    Should -Invoke 'Invoke-JiraMethod' -ModuleName JiraPS -ParameterFilter { $Method -eq 'Delete' -and $URI -like "$jiraServer/rest/api/2/attachment/$attachmentId2" } -Exactly -Times 3 -Scope It
                }

                It 'accepts positional parameters' {
                    { Remove-JiraIssueAttachment $attachmentId1 -Force } | Should -Not -Throw
                    { Remove-JiraIssueAttachment $attachmentId1, $attachmentId2 -Force } | Should -Not -Throw
                    { Remove-JiraIssueAttachment $issueKey -Force } | Should -Not -Throw

                    # ensure the calls under the hood
                    Should -Invoke 'Get-JiraIssueAttachment' -ModuleName JiraPS -Exactly -Times 1 -Scope It
                    Should -Invoke 'Invoke-JiraMethod' -ModuleName JiraPS -ParameterFilter { $Method -eq 'Get' } -Exactly -Times 0 -Scope It
                    Should -Invoke 'Invoke-JiraMethod' -ModuleName JiraPS -ParameterFilter { $Method -eq 'Post' } -Exactly -Times 0 -Scope It
                    Should -Invoke 'Invoke-JiraMethod' -ModuleName JiraPS -ParameterFilter { $Method -eq 'Put' } -Exactly -Times 0 -Scope It
                    Should -Invoke 'Invoke-JiraMethod' -ModuleName JiraPS -ParameterFilter { $Method -eq 'Delete' } -Exactly -Times 5 -Scope It
                }

                It 'has no output' {
                    $result = Remove-JiraIssueAttachment -Issue $issueKey -Force
                    $result | Should -BeNullOrEmpty

                    # ensure the calls under the hood
                    Should -Invoke 'Get-JiraIssueAttachment' -ModuleName JiraPS -Exactly -Times 1 -Scope It
                    Should -Invoke 'Invoke-JiraMethod' -ModuleName JiraPS -ParameterFilter { $Method -eq 'Get' } -Exactly -Times 0 -Scope It
                    Should -Invoke 'Invoke-JiraMethod' -ModuleName JiraPS -ParameterFilter { $Method -eq 'Post' } -Exactly -Times 0 -Scope It
                    Should -Invoke 'Invoke-JiraMethod' -ModuleName JiraPS -ParameterFilter { $Method -eq 'Put' } -Exactly -Times 0 -Scope It
                    Should -Invoke 'Invoke-JiraMethod' -ModuleName JiraPS -ParameterFilter { $Method -eq 'Delete' } -Exactly -Times 2 -Scope It
                }

                It 'accepts input over the pipeline' {
                    { Get-JiraIssueAttachment $issueKey | Remove-JiraIssueAttachment -Force } | Should -Not -Throw

                    # ensure the calls under the hood
                    Should -Invoke 'Get-JiraIssueAttachment' -ModuleName JiraPS -Exactly -Times 1 -Scope It
                    Should -Invoke 'Invoke-JiraMethod' -ModuleName JiraPS -ParameterFilter { $Method -eq 'Get' } -Exactly -Times 0 -Scope It
                    Should -Invoke 'Invoke-JiraMethod' -ModuleName JiraPS -ParameterFilter { $Method -eq 'Post' } -Exactly -Times 0 -Scope It
                    Should -Invoke 'Invoke-JiraMethod' -ModuleName JiraPS -ParameterFilter { $Method -eq 'Put' } -Exactly -Times 0 -Scope It
                    Should -Invoke 'Invoke-JiraMethod' -ModuleName JiraPS -ParameterFilter { $Method -eq 'Delete' } -Exactly -Times 2 -Scope It
                }
            }
        }

        Describe "Input Validation" {
            Context "Type Validation - Positive Cases" {}

            Context "Type Validation - Negative Cases" {}
        }
    }
}
