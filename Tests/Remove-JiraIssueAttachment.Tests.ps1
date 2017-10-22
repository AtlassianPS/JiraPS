. $PSScriptRoot\Shared.ps1

InModuleScope JiraPS {
    [System.Diagnostics.CodeAnalysis.SuppressMessage('PSUseDeclaredVarsMoreThanAssigments', '', Scope = '*', Target = 'SuppressImportModule')]
    $SuppressImportModule = $true
    . $PSScriptRoot\Shared.ps1

    $jiraServer = 'http://jiraserver.example.com'
    $issueKey = "FOO-123"
    $attachmentId1 = 1010
    $attachmentId2 = 1011
    $attchmentFile1 = 'foo.png'
    $attchmentFile2 = 'bar.zip'

    Describe "Get-JiraIssueAttachment" {
        #region Mock
        Mock Get-JiraConfigServer -ModuleName JiraPS {
            Write-Output $jiraServer
        }

        Mock Get-JiraIssueAttachment -ModuleName JiraPS {
            $Attachment = [PSCustomObject]@{
                id   = $attachmentId1
                fileName   = $attchmentFile1
                author     = "admin"
            }
            $Attachment.PSObject.TypeNames.Insert(0, 'JiraPS.Attachment')
            $Attachment

            $Attachment = [PSCustomObject]@{
                id   = $attachmentId2
                fileName   = $attchmentFile2
                author     = "admin"
            }
            $Attachment.PSObject.TypeNames.Insert(0, 'JiraPS.Attachment')
            $Attachment
        }

        Mock Invoke-JiraMethod -ModuleName JiraPS -ParameterFilter { $Method -eq 'Delete' -and $URI -eq "$jiraServer/rest/api/latest/attachment/$attachmentId1" } { }
        Mock Invoke-JiraMethod -ModuleName JiraPS -ParameterFilter { $Method -eq 'Delete' -and $URI -eq "$jiraServer/rest/api/latest/attachment/$attachmentId2" } { }

        # Generic catch-all. This will throw an exception if we forgot to mock something.
        Mock Invoke-JiraMethod -ModuleName JiraPS {
            Write-Output "       Mocked Invoke-JiraMethod with no parameter filter." -ForegroundColor DarkRed
            Write-Output "         [Method]         $Method" -ForegroundColor DarkRed
            Write-Output "         [URI]            $URI" -ForegroundColor DarkRed
            throw "Unidentified call to Invoke-JiraMethod"
        }
        #endregion Mock

        Context "Sanity checking" {
            $command = Get-Command -Name Remove-JiraIssueAttachment

            defParam $command 'Id'
            defParam $command 'Issue'
            defParam $command 'FileName'
            defParam $command 'Credential'
            defParam $command 'Force'
        }

        Context "Behavior checking" {
            It 'removes an Attachment using its ID' {
                { Remove-JiraIssueAttachment -Id $attachmentId1 -ErrorAction Stop -Force } | Should Not Throw
                { Get-JiraIssueAttachment -Issue $issueKey | Remove-JiraIssueAttachment -ErrorAction Stop -Force } | Should Not Throw
                Assert-MockCalled 'Get-JiraIssueAttachment' -ModuleName JiraPS -Exactly -Times 1 -Scope It
                Assert-MockCalled 'Invoke-JiraMethod' -ModuleName JiraPS -ParameterFilter { $Method -eq 'Delete' -and $URI -like "$jiraServer/rest/api/latest/attachment/$attachmentId1" } -Exactly -Times 2 -Scope It
                Assert-MockCalled 'Invoke-JiraMethod' -ModuleName JiraPS -ParameterFilter { $Method -eq 'Delete' -and $URI -like "$jiraServer/rest/api/latest/attachment/$attachmentId2" } -Exactly -Times 1 -Scope It
                Assert-MockCalled 'Invoke-JiraMethod' -ModuleName JiraPS -ParameterFilter { $Method -eq 'Delete' -and $URI -like "$jiraServer/rest/api/latest/attachment/*" } -Exactly -Times 3 -Scope It
            }
            It 'removes all Attachment from an Issue' {
                { Remove-JiraIssueAttachment -Issue $issueKey -ErrorAction Stop -Force } | Should Not Throw
                { Get-JiraIssueAttachment -Issue $issueKey | Remove-JiraIssueAttachment -ErrorAction Stop -Force } | Should Not Throw
                Assert-MockCalled 'Get-JiraIssueAttachment' -ModuleName JiraPS -Exactly -Times 2 -Scope It
                Assert-MockCalled 'Invoke-JiraMethod' -ModuleName JiraPS -ParameterFilter { $Method -eq 'Delete' -and $URI -like "$jiraServer/rest/api/latest/attachment/$attachmentId1" } -Exactly -Times 2 -Scope It
                Assert-MockCalled 'Invoke-JiraMethod' -ModuleName JiraPS -ParameterFilter { $Method -eq 'Delete' -and $URI -like "$jiraServer/rest/api/latest/attachment/$attachmentId2" } -Exactly -Times 2 -Scope It
            }
            It 'removes only the specified file' {
                { Remove-JiraIssueAttachment -Issue $issueKey -FileName $attchmentFile1 -ErrorAction Stop -Force } | Should Not Throw
                Assert-MockCalled 'Get-JiraIssueAttachment' -ModuleName JiraPS -Exactly -Times 1 -Scope It
                Assert-MockCalled 'Invoke-JiraMethod' -ModuleName JiraPS -ParameterFilter { $Method -eq 'Delete' -and $URI -like "$jiraServer/rest/api/latest/attachment/$attachmentId1" } -Exactly -Times 1 -Scope It
            }
            It "assert VerifiableMocks" {
                Assert-VerifiableMocks
            }
        }
    }
}
