#requires -modules BuildHelpers
#requires -modules @{ ModuleName = "Pester"; ModuleVersion = "4.4.0" }

[Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSAvoidUsingConvertToSecureStringWithPlainText", "")]
param()

Describe "Add-JiraIssueAttachment" -Tag 'Unit' {

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
    }
    AfterAll {
        Remove-Module $env:BHProjectName -ErrorAction SilentlyContinue
        Remove-Module BuildHelpers -ErrorAction SilentlyContinue
        Remove-Item -Path Env:\BH*
    }

    InModuleScope JiraPS {

        . "$PSScriptRoot/../Shared.ps1"

        $pass = ConvertTo-SecureString -AsPlainText -Force -String "passowrd"
        $Cred = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList ("user", $pass)
        $jiraServer = 'http://jiraserver.example.com'
        $issueKey = "FOO-1234"
        $file = New-Item -Path "TestDrive:\MyFile.txt" -ItemType File -Force
        $fileName = $file.Name
        $filePath = $file.FullName
        $attachmentId = 10010

        $attachmentJson = @"
{
    "self": "$jiraServer/rest/api/2/attachment/$attachmentId",
    "id": "$attachmentId",
    "filename": "$fileName",
    "author": {
        "self": "$jiraServer/rest/api/2/user?username=admin",
        "name": "admin",
        "key": "admin",
        "accountId": "0000:000000-0000-0000-0000-ab899c878d00",
        "emailAddress": "admin@example.com",
        "avatarUrls": { },
        "displayName": "Admin",
        "active": true,
        "timeZone": "Europe/Berlin"
    },
    "created": "2017-10-16T09:06:48.070+0200",
    "size": 438098,
    "mimeType": "'applation/pdf'",
    "content": "$jiraServer/secure/attachment/$attachmentId/$fileName"
}
"@

        Set-Content $filePath -value "my test text."

        #region Mock
        Mock ConvertTo-JiraAttachment -ModuleName JiraPS {
            $InputObject
        }

        Mock Get-JiraIssue -ModuleName JiraPS {
            $Issue = [PSCustomObject]@{
                Key     = $issueKey
                RestURL = "$jiraServer/rest/api/latest/issue/$issueKey"
            }
            $Issue.PSObject.TypeNames.Insert(0, 'JiraPS.Issue')
            $Issue
        }

        Mock Resolve-JiraIssueObject -ModuleName JiraPS {
            Get-JiraIssue -Key $Issue
        }

        Mock Invoke-JiraMethod -ModuleName JiraPS -ParameterFilter { $Method -eq 'Post' -and $URI -eq "$jiraServer/rest/api/latest/issue/$issueKey/attachments" } {
            ShowMockInfo 'Invoke-JiraMethod' 'Method', 'Uri'
            ConvertFrom-Json -InputObject $attachmentJson
        }

        # Generic catch-all. This will throw an exception if we forgot to mock something.
        Mock Invoke-JiraMethod -ModuleName JiraPS {
            ShowMockInfo 'Invoke-JiraMethod' 'Method', 'Uri'
            throw "Unidentified call to Invoke-JiraMethod"
        }
        #endregion Mock

        #region Tests
        Context "Sanity checking" {
            $command = Get-Command -Name Add-JiraIssueAttachment

            defParam $command 'Issue'
            defParam $command 'FilePath'
            defParam $command 'Credential'
            defParam $command 'PassThru'
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
                # Issue can't be null or empty
                { Add-JiraIssueAttachment -Issue "" -FilePath $filePath } | Should Throw
                # Issue must be an Issue or a String
                { Add-JiraIssueAttachment -Issue (Get-Date) -FilePath $filePath -verbose } | Should Throw
                # Issue can't be an array
                { Add-JiraIssueAttachment -Issue $issueKey, $issueKey -FilePath $filePath } | Should Throw
                # File must exist
                { Add-JiraIssueAttachment -Issue $issueKey -FilePath "c:\no-file.txt" } | Should Throw
                # All Parameters for DefaultParameterSet
                { Add-JiraIssueAttachment -Issue $issueKey -FilePath $filePath } | Should Not Throw
                { Add-JiraIssueAttachment -Issue (Get-JiraIssue $issueKey) -FilePath $filePath -Credential $Cred } | Should Not Throw
                { Add-JiraIssueAttachment -Issue $issueKey -FilePath @($filePath, $filePath) -Credential $Cred -PassThru } | Should Not Throw

                # ensure the calls under the hood
                Assert-MockCalled 'Get-JiraIssue' -ModuleName JiraPS -Exactly -Times 4 -Scope It
                Assert-MockCalled 'Resolve-JiraIssueObject' -ModuleName JiraPS -Exactly -Times 3 -Scope It
                Assert-MockCalled 'Invoke-JiraMethod' -ModuleName JiraPS -ParameterFilter { $Method -eq 'Get' } -Exactly -Times 0 -Scope It
                Assert-MockCalled 'Invoke-JiraMethod' -ModuleName JiraPS -ParameterFilter { $Method -eq 'Post' } -Exactly -Times 4 -Scope It
                Assert-MockCalled 'Invoke-JiraMethod' -ModuleName JiraPS -ParameterFilter { $Method -eq 'Put' } -Exactly -Times 0 -Scope It
                Assert-MockCalled 'Invoke-JiraMethod' -ModuleName JiraPS -ParameterFilter { $Method -eq 'Delete' } -Exactly -Times 0 -Scope It
            }
            It 'accepts positional parameters' {
                { Add-JiraIssueAttachment $issueKey @($filePath, $filePath) } | Should Not Throw

                # ensure the calls under the hood
                Assert-MockCalled 'Get-JiraIssue' -ModuleName JiraPS -Exactly -Times 1 -Scope It
                Assert-MockCalled 'Resolve-JiraIssueObject' -ModuleName JiraPS -Exactly -Times 1 -Scope It
                Assert-MockCalled 'Invoke-JiraMethod' -ModuleName JiraPS -ParameterFilter { $Method -eq 'Get' } -Exactly -Times 0 -Scope It
                Assert-MockCalled 'Invoke-JiraMethod' -ModuleName JiraPS -ParameterFilter { $Method -eq 'Post' } -Exactly -Times 2 -Scope It
                Assert-MockCalled 'Invoke-JiraMethod' -ModuleName JiraPS -ParameterFilter { $Method -eq 'Put' } -Exactly -Times 0 -Scope It
                Assert-MockCalled 'Invoke-JiraMethod' -ModuleName JiraPS -ParameterFilter { $Method -eq 'Delete' } -Exactly -Times 0 -Scope It
            }
            It 'has no output by default' {
                $result = Add-JiraIssueAttachment -Issue $issueKey -FilePath $filePath
                $result | Should BeNullOrEmpty

                # ensure the calls under the hood
                Assert-MockCalled 'Get-JiraIssue' -ModuleName JiraPS -Exactly -Times 1 -Scope It
                Assert-MockCalled 'Resolve-JiraIssueObject' -ModuleName JiraPS -Exactly -Times 1 -Scope It
                Assert-MockCalled 'Invoke-JiraMethod' -ModuleName JiraPS -ParameterFilter { $Method -eq 'Get' } -Exactly -Times 0 -Scope It
                Assert-MockCalled 'Invoke-JiraMethod' -ModuleName JiraPS -ParameterFilter { $Method -eq 'Post' } -Exactly -Times 1 -Scope It
                Assert-MockCalled 'Invoke-JiraMethod' -ModuleName JiraPS -ParameterFilter { $Method -eq 'Put' } -Exactly -Times 0 -Scope It
                Assert-MockCalled 'Invoke-JiraMethod' -ModuleName JiraPS -ParameterFilter { $Method -eq 'Delete' } -Exactly -Times 0 -Scope It
            }
            It 'returns an object when specified' {
                $result = Add-JiraIssueAttachment -Issue $issueKey -FilePath $filePath -PassThru
                $result | Should Not BeNullOrEmpty

                # ensure the calls under the hood
                Assert-MockCalled 'Get-JiraIssue' -ModuleName JiraPS -Exactly -Times 1 -Scope It
                Assert-MockCalled 'Resolve-JiraIssueObject' -ModuleName JiraPS -Exactly -Times 1 -Scope It
                Assert-MockCalled 'Invoke-JiraMethod' -ModuleName JiraPS -ParameterFilter { $Method -eq 'Get' } -Exactly -Times 0 -Scope It
                Assert-MockCalled 'Invoke-JiraMethod' -ModuleName JiraPS -ParameterFilter { $Method -eq 'Post' } -Exactly -Times 1 -Scope It
                Assert-MockCalled 'Invoke-JiraMethod' -ModuleName JiraPS -ParameterFilter { $Method -eq 'Put' } -Exactly -Times 0 -Scope It
                Assert-MockCalled 'Invoke-JiraMethod' -ModuleName JiraPS -ParameterFilter { $Method -eq 'Delete' } -Exactly -Times 0 -Scope It
            }
            It 'accepts files over the pipeline' {
                { $filePath | Add-JiraIssueAttachment $issueKey  } | Should Not Throw
                { @($filePath, $filePath) | Add-JiraIssueAttachment $issueKey  } | Should Not Throw
                { Get-Item $filePath | Add-JiraIssueAttachment $issueKey  } | Should Not Throw

                # ensure the calls under the hood
                Assert-MockCalled 'Get-JiraIssue' -ModuleName JiraPS -Exactly -Times 4 -Scope It
                Assert-MockCalled 'Resolve-JiraIssueObject' -ModuleName JiraPS -Exactly -Times 4 -Scope It
                Assert-MockCalled 'Invoke-JiraMethod' -ModuleName JiraPS -ParameterFilter { $Method -eq 'Get' } -Exactly -Times 0 -Scope It
                Assert-MockCalled 'Invoke-JiraMethod' -ModuleName JiraPS -ParameterFilter { $Method -eq 'Post' } -Exactly -Times 4 -Scope It
                Assert-MockCalled 'Invoke-JiraMethod' -ModuleName JiraPS -ParameterFilter { $Method -eq 'Put' } -Exactly -Times 0 -Scope It
                Assert-MockCalled 'Invoke-JiraMethod' -ModuleName JiraPS -ParameterFilter { $Method -eq 'Delete' } -Exactly -Times 0 -Scope It
            }
            It "assert VerifiableMock" {
                Assert-VerifiableMock
            }
        }
        #endregion Tests
    }
}
