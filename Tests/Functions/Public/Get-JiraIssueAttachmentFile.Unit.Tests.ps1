#requires -modules @{ ModuleName = "Pester"; ModuleVersion = "5.7"; MaximumVersion = "5.999" }

BeforeDiscovery {
    . "$PSScriptRoot/../../Helpers/TestTools.ps1"
    $script:moduleToTest = Initialize-TestEnvironment
}

InModuleScope JiraPS {
    Describe "Get-JiraIssueAttachmentFile" -Tag 'Unit' {
        BeforeAll {
            . "$PSScriptRoot/../../Helpers/TestTools.ps1"
            # $VerbosePreference = 'Continue'  # Uncomment for mock debugging

            #region Definitions
            $script:jiraServer = 'http://jiraserver.example.com'
            $script:issueID = 41701
            $script:issueKey = 'IT-3676'

            $script:attachments = @"
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
            #endregion Definitions

            #region Mocks
            Mock Get-JiraIssueAttachment -ModuleName JiraPS {
                Write-MockDebugInfo 'Get-JiraIssueAttachment'
                $object = ConvertFrom-Json -InputObject $attachments
                $object[0].PSObject.TypeNames.Insert(0, 'JiraPS.Attachment')
                $object[1].PSObject.TypeNames.Insert(0, 'JiraPS.Attachment')
                $object
            }

            Mock Invoke-JiraMethod -ModuleName JiraPS -ParameterFilter {
                $Method -eq 'Get' -and
                $URI -like "$jiraServer/secure/attachment/*"
            } {
                Write-MockDebugInfo 'Invoke-JiraMethod' 'Method', 'Uri', 'OutFile'
            }

            # Generic catch-all. This will throw an exception if we forgot to mock something.
            Mock Invoke-JiraMethod -ModuleName JiraPS {
                Write-MockDebugInfo 'Invoke-JiraMethod' 'Method', 'Uri'
                throw "Unidentified call to Invoke-JiraMethod"
            }
            #endregion Mocks
        }

        Describe "Input Validation" {
            BeforeAll {
                # Pester 5 strips ArgumentTransformationAttribute from mocked
                # parameter signatures, so feeding the upstream mock a bare
                # issue-key string trips the [AtlassianPS.JiraPS.Issue] cast.
                # Build a real Issue instance once and reuse it.
                $script:fooIssue = [AtlassianPS.JiraPS.Issue]@{ Key = 'Foo' }
            }

            It 'only accepts JiraPS.Attachment as input' {
                { Get-JiraIssueAttachmentFile -Attachment (Get-Date) } | Should -Throw -ExpectedMessage "*'Attachment'*"
                { Get-JiraIssueAttachmentFile -Attachment (Get-ChildItem) } | Should -Throw -ExpectedMessage "*'Attachment'*"
                { Get-JiraIssueAttachmentFile -Attachment @('foo', 'bar') } | Should -Throw -ExpectedMessage "*'Attachment'*"
                { Get-JiraIssueAttachmentFile -Attachment (Get-JiraIssueAttachment -Issue $fooIssue) } | Should -Not -Throw
            }

            It 'takes the issue input over the pipeline' {
                { Get-JiraIssueAttachment -Issue $fooIssue | Get-JiraIssueAttachmentFile } | Should -Not -Throw
            }
        }

        Describe "Signature" {
            Context "Parameter Types" {
                # TODO: Add parameter type validation tests
            }

            Context "Mandatory Parameters" {}

            Context "Default Values" {}
        }

        Describe "Behavior" {
            It 'uses Invoke-JiraMethod for saving to disk' {
                $fooIssue = [AtlassianPS.JiraPS.Issue]@{ Key = 'Foo' }

                Get-JiraIssueAttachment -Issue $fooIssue | Get-JiraIssueAttachmentFile
                Get-JiraIssueAttachment -Issue $fooIssue | Get-JiraIssueAttachmentFile -Path "../"

                Should -Invoke Invoke-JiraMethod -ModuleName JiraPS -ParameterFilter {
                    $OutFile -in @("foo.pdf", "bar.pdf")
                } -Exactly 2

                Should -Invoke Invoke-JiraMethod -ModuleName JiraPS -ParameterFilter {
                    $OutFile -like "..*.pdf"
                } -Exactly 2
            }

            It 'does not force an Accept header for attachment downloads' {
                $fooIssue = [AtlassianPS.JiraPS.Issue]@{ Key = 'Foo' }

                Get-JiraIssueAttachment -Issue $fooIssue | Get-JiraIssueAttachmentFile

                Should -Invoke Invoke-JiraMethod -ModuleName JiraPS -ParameterFilter {
                    -not $PSBoundParameters.ContainsKey('Headers')
                } -Exactly 2
            }
        }

        Describe "Input Validation" {
            Context "Type Validation - Positive Cases" {}

            Context "Type Validation - Negative Cases" {}
        }
    }
}
