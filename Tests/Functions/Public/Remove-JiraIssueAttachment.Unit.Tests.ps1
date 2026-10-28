#requires -modules @{ ModuleName = "Pester"; ModuleVersion = "6.2.0"; MaximumVersion = "6.999" }

BeforeDiscovery {
    . "$PSScriptRoot/../../Helpers/TestTools.ps1"

    $script:moduleToTest = Initialize-TestEnvironment
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
            Mock Get-JiraIssueAttachmentOperation -ModuleName JiraPS {
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

            Mock Get-JiraIssueOperation -ModuleName JiraPS {
                Write-MockDebugInfo 'Get-JiraIssue' 'Key'
                $Attachment = [PSCustomObject]@{
                    id       = $attachmentId1
                    fileName = $attachmentFile1
                }
                $Attachment.PSObject.TypeNames.Insert(0, 'JiraPS.Attachment')

                $IssueObj = [AtlassianPS.JiraPS.Issue]@{
                    Key        = $issueKey
                    attachment = $Attachment
                }
                $IssueObj
            }

            Mock Resolve-JiraIssueObject -ModuleName JiraPS {
                Write-MockDebugInfo 'Resolve-JiraIssueObject' 'InputObject'
                Get-JiraIssue -Key $InputObject.Key
            }

            Mock Invoke-JiraRequest -ModuleName JiraPS -ParameterFilter { $Method -eq 'Delete' -and $URI -eq "/rest/api/2/attachment/$attachmentId1" } {
                Write-MockDebugInfo 'Invoke-JiraRequest' 'Method', 'Uri'
            }

            Mock Invoke-JiraRequest -ModuleName JiraPS -ParameterFilter { $Method -eq 'Delete' -and $URI -eq "/rest/api/2/attachment/$attachmentId2" } {
                Write-MockDebugInfo 'Invoke-JiraRequest' 'Method', 'Uri'
            }

            # Generic catch-all. This will throw an exception if we forgot to mock something.
            Mock Invoke-JiraRequest -ModuleName JiraPS {
                Write-MockDebugInfo 'Invoke-JiraRequest' 'Method', 'Uri'
                throw "Unidentified call to Invoke-JiraRequest"
            }
            #endregion Mocks
        }

        Describe "Signature" {
            BeforeAll {
                $script:command = Get-Command -Name Remove-JiraIssueAttachment
            }

            Context "Parameter Types" {
                It "has a parameter '<parameter>' of type '<type>'" -TestCases @(
                    @{ parameter = 'Attachment'; type = 'AtlassianPS.JiraPS.Attachment[]' }
                    @{ parameter = 'Issue'; type = 'AtlassianPS.JiraPS.Issue' }
                    @{ parameter = 'FileName'; type = 'String[]' }
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
                    { Remove-JiraIssueAttachment -AttachmentId $null -Confirm:$false } | Should -Throw -ExpectedMessage "*Attachment*"
                    # Issue can't be null or empty
                    { Remove-JiraIssueAttachment -Issue "" -Confirm:$false } | Should -Throw -ExpectedMessage "*'Issue'*"
                    # AttachmentId must be an Int
                    { Remove-JiraIssueAttachment -AttachmentId "a" -Confirm:$false } | Should -Throw -ExpectedMessage "*Attachment*"
                    # Issue must be an Issue or a String
                    { Remove-JiraIssueAttachment -Issue (Get-Date) -Confirm:$false } | Should -Throw -ExpectedMessage "*to AtlassianPS.JiraPS.Issue*"
                    # Issue can't be an array passed directly (use the pipeline instead)
                    { Remove-JiraIssueAttachment -Issue $issueKey, $issueKey -Confirm:$false } | Should -Throw -ExpectedMessage "*to AtlassianPS.JiraPS.Issue*"

                    # All Parameters for DefaultParameterSet
                    { Remove-JiraIssueAttachment -AttachmentId $attachmentId1 -Confirm:$false } | Should -Not -Throw
                    { Remove-JiraIssueAttachment -AttachmentId $attachmentId1, $attachmentId2 -Confirm:$false } | Should -Not -Throw
                    { Remove-JiraIssueAttachment -Issue (Get-JiraIssue $issueKey) -Confirm:$false } | Should -Not -Throw
                    { Remove-JiraIssueAttachment -Issue $issueKey -FileName $attachmentFile1 -Confirm:$false } | Should -Not -Throw
                    { Remove-JiraIssueAttachment -Issue $issueKey -FileName $attachmentFile1, $attachmentFile2 -Confirm:$false } | Should -Not -Throw

                    # ensure the calls under the hood
                    Should -Invoke 'Get-JiraIssueOperation' -ModuleName JiraPS -Exactly -Times 4
                    Should -Invoke 'Get-JiraIssueAttachmentOperation' -ModuleName JiraPS -Exactly -Times 3
                    Should -Invoke 'Invoke-JiraRequest' -ModuleName JiraPS -ParameterFilter { $Method -ne 'Delete' } -Exactly -Times 0
                    Should -Invoke 'Invoke-JiraRequest' -ModuleName JiraPS -ParameterFilter { $Method -eq 'Delete' } -Exactly -Times 8
                    Should -Invoke 'Invoke-JiraRequest' -ModuleName JiraPS -ParameterFilter { $Method -eq 'Delete' -and $URI -like "/rest/api/2/attachment/$attachmentId1" } -Exactly -Times 5
                    Should -Invoke 'Invoke-JiraRequest' -ModuleName JiraPS -ParameterFilter { $Method -eq 'Delete' -and $URI -like "/rest/api/2/attachment/$attachmentId2" } -Exactly -Times 3
                }

                It 'accepts positional parameters' {
                    { Remove-JiraIssueAttachment -Attachment $attachmentId1 -Confirm:$false } | Should -Not -Throw
                    { Remove-JiraIssueAttachment -Attachment $attachmentId1, $attachmentId2 -Confirm:$false } | Should -Not -Throw
                    { Remove-JiraIssueAttachment -Issue $issueKey -Confirm:$false } | Should -Not -Throw

                    # ensure the calls under the hood
                    Should -Invoke 'Get-JiraIssueAttachmentOperation' -ModuleName JiraPS -Exactly -Times 1
                    Should -Invoke 'Invoke-JiraRequest' -ModuleName JiraPS -ParameterFilter { $Method -ne 'Delete' } -Exactly -Times 0
                    Should -Invoke 'Invoke-JiraRequest' -ModuleName JiraPS -ParameterFilter { $Method -eq 'Delete' } -Exactly -Times 5
                }

                It 'has no output' {
                    $result = Remove-JiraIssueAttachment -Issue $issueKey -Confirm:$false
                    $result | Should -BeNullOrEmpty

                    # ensure the calls under the hood
                    Should -Invoke 'Get-JiraIssueAttachmentOperation' -ModuleName JiraPS -Exactly -Times 1
                    Should -Invoke 'Invoke-JiraRequest' -ModuleName JiraPS -ParameterFilter { $Method -ne 'Delete' } -Exactly -Times 0
                    Should -Invoke 'Invoke-JiraRequest' -ModuleName JiraPS -ParameterFilter { $Method -eq 'Delete' } -Exactly -Times 2
                }

                It 'accepts input over the pipeline' {
                    $issue = [AtlassianPS.JiraPS.Issue]@{ Key = $issueKey }
                    { Get-JiraIssueAttachment $issue | Remove-JiraIssueAttachment -Confirm:$false } | Should -Not -Throw

                    # ensure the calls under the hood
                    Should -Invoke 'Get-JiraIssueAttachmentOperation' -ModuleName JiraPS -Exactly -Times 1
                    Should -Invoke 'Invoke-JiraRequest' -ModuleName JiraPS -ParameterFilter { $Method -ne 'Delete' } -Exactly -Times 0
                    Should -Invoke 'Invoke-JiraRequest' -ModuleName JiraPS -ParameterFilter { $Method -eq 'Delete' } -Exactly -Times 2
                }
            }
        }

        Describe "Input Validation" {
            Context "Type Validation - Positive Cases" {}

            Context "Type Validation - Negative Cases" {}
        }
    }
}
