. $PSScriptRoot\Shared.ps1

InModuleScope JiraPS {

    [System.Diagnostics.CodeAnalysis.SuppressMessage('PSUseDeclaredVarsMoreThanAssigments', '', Scope = '*', Target = 'SuppressImportModule')]
    $SuppressImportModule = $true
    . $PSScriptRoot\Shared.ps1

    $jiraServer = 'http://jiraserver.example.com'
    $issueKey = "FOO-123"
    $attachmentId1 = 1010
    $attachmentId2 = 1011
    $attachmentFile1 = 'foo.png'
    $attachmentFile2 = 'bar.zip'

    Describe "Remove-JiraIssueAttachment" {

        #region Mock
        Mock Get-JiraConfigServer -ModuleName JiraPS {
            Write-Output $jiraServer
        }

        Mock Get-JiraIssueAttachment -ModuleName JiraPS {
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

        Mock Invoke-JiraMethod -ModuleName JiraPS -ParameterFilter { $Method -eq 'Delete' -and $URI -eq "$jiraServer/rest/api/latest/attachment/$attachmentId1" } {
            ShowMockInfo 'Invoke-JiraMethod' 'Method', 'Uri'
        }
        Mock Invoke-JiraMethod -ModuleName JiraPS -ParameterFilter { $Method -eq 'Delete' -and $URI -eq "$jiraServer/rest/api/latest/attachment/$attachmentId2" } {
            ShowMockInfo 'Invoke-JiraMethod' 'Method', 'Uri'
        }

        # Generic catch-all. This will throw an exception if we forgot to mock something.
        Mock Invoke-JiraMethod -ModuleName JiraPS {
            ShowMockInfo 'Invoke-JiraMethod' 'Method', 'Uri'
            throw "Unidentified call to Invoke-JiraMethod"
        }
        #endregion Mock

        #region Tests
        Context "Sanity checking" {
            $command = Get-Command -Name Remove-JiraIssueAttachment

            defParam $command 'AttachmentId'
            defParam $command 'Issue'
            defParam $command 'FileName'
            defParam $command 'Credential'
            defParam $command 'Force'
        }

        Context "Behavior checking" {
            <#
            Remember to check for:
                - each ParameterSet
                - each Parameter
                - each ValueFromPipeline
                - each 'Throw'
                - each possible Output
                - each object type
            #>

            It 'validates the parameters' {
                # AttachmentId can't be null or empty
                { Remove-JiraIssueAttachment -AttachmentId $null -Force -Verbose } | Should Throw
                # Issue can't be null or empty
                { Remove-JiraIssueAttachment -Issue "" -Force -Verbose } | Should Throw
                # AttachmentId must be an Int
                { Remove-JiraIssueAttachment -AttachmentId "a" -Force -Verbose } | Should Throw
                # Issue must be an Issue or a String
                { Remove-JiraIssueAttachment -Issue (Get-Date) -Force -Verbose } | Should Throw
                # Issue can't be an array
                { Remove-JiraIssueAttachment -Issue $issueKey, $issueKey -Force -Verbose } | Should Throw

                # All Parameters for DefaultParameterSet
                { Remove-JiraIssueAttachment -AttachmentId $attachmentId1 -Force } | Should Not Throw
                { Remove-JiraIssueAttachment -AttachmentId $attachmentId1, $attachmentId2 -Force } | Should Not Throw
                { Remove-JiraIssueAttachment -Issue (Get-JiraIssue $issueKey) -Force } | Should Not Throw
                { Remove-JiraIssueAttachment -Issue $issueKey -FileName $attachmentFile1 -Force } | Should Not Throw
                { Remove-JiraIssueAttachment -Issue $issueKey -FileName $attachmentFile1, $attachmentFile2 -Credential $Cred -Force } | Should Not Throw

                # ensure the calls under the hood
                Assert-MockCalled 'Get-JiraIssue' -ModuleName JiraPS -Exactly -Times 1 -Scope It
                Assert-MockCalled 'Get-JiraIssueAttachment' -ModuleName JiraPS -Exactly -Times 3 -Scope It
                Assert-MockCalled 'Invoke-JiraMethod' -ModuleName JiraPS -ParameterFilter { $Method -eq 'Get' } -Exactly -Times 0 -Scope It
                Assert-MockCalled 'Invoke-JiraMethod' -ModuleName JiraPS -ParameterFilter { $Method -eq 'Post' } -Exactly -Times 0 -Scope It
                Assert-MockCalled 'Invoke-JiraMethod' -ModuleName JiraPS -ParameterFilter { $Method -eq 'Put' } -Exactly -Times 0 -Scope It
                Assert-MockCalled 'Invoke-JiraMethod' -ModuleName JiraPS -ParameterFilter { $Method -eq 'Delete' } -Exactly -Times 8 -Scope It
                Assert-MockCalled 'Invoke-JiraMethod' -ModuleName JiraPS -ParameterFilter { $Method -eq 'Delete' -and $URI -like "$jiraServer/rest/api/latest/attachment/$attachmentId1" } -Exactly -Times 5 -Scope It
                Assert-MockCalled 'Invoke-JiraMethod' -ModuleName JiraPS -ParameterFilter { $Method -eq 'Delete' -and $URI -like "$jiraServer/rest/api/latest/attachment/$attachmentId2" } -Exactly -Times 3 -Scope It
            }
            It 'accepts positional parameters' {
                { Remove-JiraIssueAttachment $attachmentId1 -Force } | Should Not Throw
                { Remove-JiraIssueAttachment $attachmentId1, $attachmentId2 -Force } | Should Not Throw
                { Remove-JiraIssueAttachment $issueKey -Force } | Should Not Throw

                # ensure the calls under the hood
                Assert-MockCalled 'Get-JiraIssueAttachment' -ModuleName JiraPS -Exactly -Times 1 -Scope It
                Assert-MockCalled 'Invoke-JiraMethod' -ModuleName JiraPS -ParameterFilter { $Method -eq 'Get' } -Exactly -Times 0 -Scope It
                Assert-MockCalled 'Invoke-JiraMethod' -ModuleName JiraPS -ParameterFilter { $Method -eq 'Post' } -Exactly -Times 0 -Scope It
                Assert-MockCalled 'Invoke-JiraMethod' -ModuleName JiraPS -ParameterFilter { $Method -eq 'Put' } -Exactly -Times 0 -Scope It
                Assert-MockCalled 'Invoke-JiraMethod' -ModuleName JiraPS -ParameterFilter { $Method -eq 'Delete' } -Exactly -Times 5 -Scope It
            }

            It 'has no output' {
                $result = Remove-JiraIssueAttachment -Issue $issueKey -Force
                $result | Should BeNullOrEmpty

                # ensure the calls under the hood
                Assert-MockCalled 'Get-JiraIssueAttachment' -ModuleName JiraPS -Exactly -Times 1 -Scope It
                Assert-MockCalled 'Invoke-JiraMethod' -ModuleName JiraPS -ParameterFilter { $Method -eq 'Get' } -Exactly -Times 0 -Scope It
                Assert-MockCalled 'Invoke-JiraMethod' -ModuleName JiraPS -ParameterFilter { $Method -eq 'Post' } -Exactly -Times 0 -Scope It
                Assert-MockCalled 'Invoke-JiraMethod' -ModuleName JiraPS -ParameterFilter { $Method -eq 'Put' } -Exactly -Times 0 -Scope It
                Assert-MockCalled 'Invoke-JiraMethod' -ModuleName JiraPS -ParameterFilter { $Method -eq 'Delete' } -Exactly -Times 2 -Scope It
            }
            It 'accepts input over the pipeline' {
                { Get-JiraIssueAttachment $issueKey | Remove-JiraIssueAttachment -Force } | Should Not Throw

                # ensure the calls under the hood
                Assert-MockCalled 'Get-JiraIssueAttachment' -ModuleName JiraPS -Exactly -Times 1 -Scope It
                Assert-MockCalled 'Invoke-JiraMethod' -ModuleName JiraPS -ParameterFilter { $Method -eq 'Get' } -Exactly -Times 0 -Scope It
                Assert-MockCalled 'Invoke-JiraMethod' -ModuleName JiraPS -ParameterFilter { $Method -eq 'Post' } -Exactly -Times 0 -Scope It
                Assert-MockCalled 'Invoke-JiraMethod' -ModuleName JiraPS -ParameterFilter { $Method -eq 'Put' } -Exactly -Times 0 -Scope It
                Assert-MockCalled 'Invoke-JiraMethod' -ModuleName JiraPS -ParameterFilter { $Method -eq 'Delete' } -Exactly -Times 2 -Scope It
            }
            It "assert VerifiableMock" {
                Assert-VerifiableMock
            }
        }
        #endregion Tests
    }
}
