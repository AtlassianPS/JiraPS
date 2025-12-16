#requires -modules BuildHelpers
#requires -modules @{ ModuleName = "Pester"; ModuleVersion = "5.7.1" }

Describe "Remove-JiraIssueAttachment" -Tag 'Unit' {

    BeforeAll {
        Remove-Item -Path Env:\BH*
        $projectRoot = (Resolve-Path "$PSScriptRoot/../..").Path
        if ($projectRoot -like "*Release") {
            $projectRoot = (Resolve-Path "$projectRoot/..").Path
        }

        Import-Module BuildHelpers
        Set-BuildEnvironment -BuildOutput '$ProjectPath/Release' -Path $projectRoot -ErrorAction SilentlyContinue

        $env:BHManifestToTest = $env:BHPSModuleManifest
        $script:isBuild = $PSScriptRoot -like "$env:BHBuildOutput*"
        if ($script:isBuild) {
            $Pattern = [regex]::Escape($env:BHProjectPath)

            $env:BHBuildModuleManifest = $env:BHPSModuleManifest -replace $Pattern, $env:BHBuildOutput
            $env:BHManifestToTest = $env:BHBuildModuleManifest
        }

        Import-Module "$env:BHProjectPath/Tools/BuildTools.psm1"

        Remove-Module $env:BHProjectName -ErrorAction SilentlyContinue
        Import-Module $env:BHManifestToTest

        . "$PSScriptRoot/../Shared.ps1"  # helpers used by tests (defParam / ShowMockInfo)

        $jiraServer = 'http://jiraserver.example.com'
        $issueKey = "FOO-123"
        $attachmentId1 = 1010
        $attachmentId2 = 1011
        $attachmentFile1 = 'foo.png'
        $attachmentFile2 = 'bar.zip'


        #region Mock

        #helper function to generate test JiraIssue object
        function Get-TestJiraIssue {
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

        function Get-TestJiraIssueAttachment {
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

        Mock Get-JiraConfigServer -ModuleName JiraPS {
            Write-Output $jiraServer
        }

        Mock Get-JiraIssueAttachment -ModuleName JiraPS {
            Get-TestJiraIssueAttachment
        }

        Mock Get-JiraIssue -ModuleName JiraPS {
            Get-TestJiraIssue
        }

        <# Mock Resolve-JiraIssueObject -ModuleName JiraPS {
            Get-JiraIssue -Key $Issue
        } #>

        Mock Invoke-JiraMethod -ModuleName JiraPS -ParameterFilter { $Method -eq 'Delete' -and $URI -eq "$jiraServer/rest/api/2/attachment/$attachmentId1" } {
            ShowMockInfo 'Invoke-JiraMethod' 'Method', 'Uri'
        }
        Mock Invoke-JiraMethod -ModuleName JiraPS -ParameterFilter { $Method -eq 'Delete' -and $URI -eq "$jiraServer/rest/api/2/attachment/$attachmentId2" } {
            ShowMockInfo 'Invoke-JiraMethod' 'Method', 'Uri'
        }

        # Generic catch-all. This will throw an exception if we forgot to mock something.
        Mock Invoke-JiraMethod -ModuleName JiraPS {
            ShowMockInfo 'Invoke-JiraMethod' 'Method', 'Uri'
            throw "Unidentified call to Invoke-JiraMethod"
        }
        #endregion Mock
    }
    AfterAll {
        Remove-Module $env:BHProjectName -ErrorAction SilentlyContinue
        Remove-Module BuildHelpers -ErrorAction SilentlyContinue
        Remove-Item -Path Env:\BH*
    }

    #region Tests
    Context "Sanity checking" {
        It "Has expected parameters" {
            $command = Get-Command -Name Remove-JiraIssueAttachment

            defParam $command 'AttachmentId'
            defParam $command 'Issue'
            defParam $command 'FileName'
            defParam $command 'Credential'
            defParam $command 'Force'
        }
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

            #NOTE: Dude, this SERIOUSLY needs to be broken up into different contexts
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
                { Remove-JiraIssueAttachment -Issue (Get-TestJiraIssue $issueKey) -Force } | Should -Not -Throw
                { Remove-JiraIssueAttachment -Issue $issueKey -FileName $attachmentFile1 -Force } | Should -Not -Throw
                { Remove-JiraIssueAttachment -Issue $issueKey -FileName $attachmentFile1, $attachmentFile2 -Force } | Should -Not -Throw

                # ensure the calls under the hood
                Should -Invoke 'Get-JiraIssue' -ModuleName JiraPS -Exactly -Times 3
                Should -Invoke 'Get-JiraIssueAttachment' -ModuleName JiraPS -Exactly -Times 3
                Should -Invoke 'Invoke-JiraMethod' -ModuleName JiraPS -ParameterFilter { $Method -eq 'Get' } -Exactly -Times 0
                Should -Invoke 'Invoke-JiraMethod' -ModuleName JiraPS -ParameterFilter { $Method -eq 'Post' } -Exactly -Times 0
                Should -Invoke 'Invoke-JiraMethod' -ModuleName JiraPS -ParameterFilter { $Method -eq 'Put' } -Exactly -Times 0
                Should -Invoke 'Invoke-JiraMethod' -ModuleName JiraPS -ParameterFilter { $Method -eq 'Delete' } -Exactly -Times 8
                Should -Invoke 'Invoke-JiraMethod' -ModuleName JiraPS -ParameterFilter { $Method -eq 'Delete' -and $URI -like "$jiraServer/rest/api/2/attachment/$attachmentId1" } -Exactly -Times 5
                Should -Invoke 'Invoke-JiraMethod' -ModuleName JiraPS -ParameterFilter { $Method -eq 'Delete' -and $URI -like "$jiraServer/rest/api/2/attachment/$attachmentId2" } -Exactly -Times 3
            }
            It 'accepts positional parameters' {
                { Remove-JiraIssueAttachment $attachmentId1 -Force } | Should -Not -Throw
                { Remove-JiraIssueAttachment $attachmentId1, $attachmentId2 -Force } | Should -Not -Throw
                { Remove-JiraIssueAttachment $issueKey -Force } | Should -Not -Throw

                # ensure the calls under the hood
                Should -Invoke 'Get-JiraIssueAttachment' -ModuleName JiraPS -Exactly -Times 1
                Should -Invoke 'Invoke-JiraMethod' -ModuleName JiraPS -ParameterFilter { $Method -eq 'Get' } -Exactly -Times 0
                Should -Invoke 'Invoke-JiraMethod' -ModuleName JiraPS -ParameterFilter { $Method -eq 'Post' } -Exactly -Times 0
                Should -Invoke 'Invoke-JiraMethod' -ModuleName JiraPS -ParameterFilter { $Method -eq 'Put' } -Exactly -Times 0
                Should -Invoke 'Invoke-JiraMethod' -ModuleName JiraPS -ParameterFilter { $Method -eq 'Delete' } -Exactly -Times 5
            }

            It 'has no output' {
                $result = Remove-JiraIssueAttachment -Issue $issueKey -Force
                $result | Should -BeNullOrEmpty

                # ensure the calls under the hood
                Should -Invoke 'Get-JiraIssueAttachment' -ModuleName JiraPS -Exactly -Times 1
                Should -Invoke 'Invoke-JiraMethod' -ModuleName JiraPS -ParameterFilter { $Method -eq 'Get' } -Exactly -Times 0
                Should -Invoke 'Invoke-JiraMethod' -ModuleName JiraPS -ParameterFilter { $Method -eq 'Post' } -Exactly -Times 0
                Should -Invoke 'Invoke-JiraMethod' -ModuleName JiraPS -ParameterFilter { $Method -eq 'Put' } -Exactly -Times 0
                Should -Invoke 'Invoke-JiraMethod' -ModuleName JiraPS -ParameterFilter { $Method -eq 'Delete' } -Exactly -Times 2
            }
            It 'accepts input over the pipeline' {
                { Get-TestJiraIssueAttachment | Remove-JiraIssueAttachment -Force } | Should -Not -Throw

                # ensure the calls under the hood
                Should -Invoke 'Invoke-JiraMethod' -ModuleName JiraPS -ParameterFilter { $Method -eq 'Get' } -Exactly -Times 0
                Should -Invoke 'Invoke-JiraMethod' -ModuleName JiraPS -ParameterFilter { $Method -eq 'Post' } -Exactly -Times 0
                Should -Invoke 'Invoke-JiraMethod' -ModuleName JiraPS -ParameterFilter { $Method -eq 'Put' } -Exactly -Times 0
                Should -Invoke 'Invoke-JiraMethod' -ModuleName JiraPS -ParameterFilter { $Method -eq 'Delete' } -Exactly -Times 2
            }
        }
        #endregion Tests
}
