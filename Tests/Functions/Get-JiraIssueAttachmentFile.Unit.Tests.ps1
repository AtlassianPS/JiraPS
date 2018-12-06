#requires -modules BuildHelpers
#requires -modules @{ ModuleName = "Pester"; ModuleVersion = "4.4.0" }

Describe "Get-JiraIssueAttachmentFile" -Tag 'Unit' {

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

        $jiraServer = 'http://jiraserver.example.com'
        $issueID = 41701
        $issueKey = 'IT-3676'

        $attachments = @"
[
    {
        "self": "$jiraServer/rest/api/2/attachment/10013",
        "id": "10013",
        "filename": "foo.pdf",
        "author": {
            "self": "$jiraServer/rest/api/2/user?username=admin",
            "name": "admin",
            "key": "admin",
            "accountId": "000000:000000-0000-0000-0000-ab899c878d00",
            "emailAddress": "admin@example.com",
            "avatarUrls": { },
            "displayName": "Admin",
            "active": true,
            "timeZone": "Europe/Berlin"
        },
        "created": "2017-10-16T10:06:29.399+0200",
        "size": 60444,
        "mimeType": "application/pdf",
        "content": "$jiraServer/secure/attachment/10013/foo.pdf"
    },
    {
        "self": "$jiraServer/rest/api/2/attachment/10010",
        "id": "10010",
        "filename": "bar.pdf",
        "author": {
            "self": "$jiraServer/rest/api/2/user?username=admin",
            "name": "admin",
            "key": "admin",
            "accountId": "000000:000000-0000-0000-0000-ab899c878d00",
            "emailAddress": "admin@example.com",
            "avatarUrls": { },
            "displayName": "Admin",
            "active": true,
            "timeZone": "Europe/Berlin"
        },
        "created": "2017-10-16T09:06:48.070+0200",
        "size": 438098,
        "mimeType": "'application/pdf'",
        "content": "$jiraServer/secure/attachment/10010/bar.pdf"
    }
]
"@

        Mock Get-JiraIssueAttachment -ModuleName JiraPS {
            $object = ConvertFrom-Json -InputObject $attachments
            $object[0].PSObject.TypeNames.Insert(0, 'JiraPS.Attachment')
            $object[1].PSObject.TypeNames.Insert(0, 'JiraPS.Attachment')
            $object
        }

        Mock Invoke-JiraMethod -ModuleName JiraPS -ParameterFilter {
            $Method -eq 'Get' -and
            $URI -like "$jiraServer/secure/attachment/*"
        } {
            ShowMockInfo 'Invoke-JiraMethod' 'Method', 'Uri', 'OutFile'
        }

        # Generic catch-all. This will throw an exception if we forgot to mock something.
        Mock Invoke-JiraMethod -ModuleName JiraPS {
            ShowMockInfo 'Invoke-JiraMethod' 'Method', 'Uri'
            throw "Unidentified call to Invoke-JiraMethod"
        }

        #############
        # Tests
        #############

        It 'only accepts JiraPS.Attachment as input' {
            { Get-JiraIssueAttachmentFile -Attachment (Get-Date) } | Should Throw
            { Get-JiraIssueAttachmentFile -Attachment (Get-ChildItem) } | Should Throw
            { Get-JiraIssueAttachmentFile -Attachment @('foo', 'bar') } | Should Throw
            { Get-JiraIssueAttachmentFile -Attachment (Get-JiraIssueAttachment -Issue "Foo") } | Should Not Throw
        }

        It 'takes the issue input over the pipeline' {
            { Get-JiraIssueAttachment -Issue "Foo" | Get-JiraIssueAttachmentFile } | Should Not Throw
        }

        It 'uses Invoke-JiraMethod for saving to disk' {
            $script:ShowMockData = $true
            Get-JiraIssueAttachment -Issue "Foo" | Get-JiraIssueAttachmentFile
            Get-JiraIssueAttachment -Issue "Foo" | Get-JiraIssueAttachmentFile -Path "../"

            $assertMockCalledSplat = @{
                CommandName     = 'Invoke-JiraMethod'
                ModuleName      = "JiraPS"
                ParameterFilter = {
                    $OutFile -in @("foo.pdf", "bar.pdf")
                }
                Exactly         = $true
                Times           = 2
                Scope           = 'It'
            }
            Assert-MockCalled @assertMockCalledSplat

            $assertMockCalledSplat = @{
                CommandName     = 'Invoke-JiraMethod'
                ModuleName      = "JiraPS"
                ParameterFilter = {
                    $OutFile -like "..*.pdf"
                }
                Exactly         = $true
                Times           = 2
                Scope           = 'It'
            }
            Assert-MockCalled @assertMockCalledSplat
        }
    }
}
