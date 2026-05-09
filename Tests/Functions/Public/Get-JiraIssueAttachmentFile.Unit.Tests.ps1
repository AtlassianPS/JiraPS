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

            $script:attachmentFixtures = @(
                [AtlassianPS.JiraPS.Attachment]@{
                    ID       = '10013'
                    Self     = [uri]"$jiraServer/rest/api/2/attachment/10013"
                    FileName = 'foo.pdf'
                    Author   = [AtlassianPS.JiraPS.User]@{
                        Name         = 'admin'
                        Key          = 'admin'
                        AccountId    = '000000:000000-0000-0000-0000-ab899c878d00'
                        EmailAddress = 'admin@example.com'
                        DisplayName  = 'Admin'
                        Active       = $true
                        TimeZone     = 'Europe/Berlin'
                    }
                    Created  = [DateTimeOffset]'2017-10-16T10:06:29.399+02:00'
                    Size     = 60444
                    MimeType = 'application/pdf'
                    Content  = [uri]"$jiraServer/secure/attachment/10013/foo.pdf"
                }
                [AtlassianPS.JiraPS.Attachment]@{
                    ID       = '10010'
                    Self     = [uri]"$jiraServer/rest/api/2/attachment/10010"
                    FileName = 'bar.pdf'
                    Author   = [AtlassianPS.JiraPS.User]@{
                        Name         = 'admin'
                        Key          = 'admin'
                        AccountId    = '000000:000000-0000-0000-0000-ab899c878d00'
                        EmailAddress = 'admin@example.com'
                        DisplayName  = 'Admin'
                        Active       = $true
                        TimeZone     = 'Europe/Berlin'
                    }
                    Created  = [DateTimeOffset]'2017-10-16T09:06:48.070+02:00'
                    Size     = 438098
                    MimeType = 'application/pdf'
                    Content  = [uri]"$jiraServer/secure/attachment/10010/bar.pdf"
                }
            )
            #endregion Definitions

            #region Mocks
            Mock Get-JiraIssueAttachment -ModuleName JiraPS {
                Write-MockDebugInfo 'Get-JiraIssueAttachment'
                $script:attachmentFixtures
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

            It 'only accepts AtlassianPS.JiraPS.Attachment as input' {
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
                It 'types the Attachment parameter as AtlassianPS.JiraPS.Attachment[]' {
                    $command = Get-Command -Name Get-JiraIssueAttachmentFile

                    $command.Parameters['Attachment'].ParameterType.FullName | Should -Be 'AtlassianPS.JiraPS.Attachment[]'
                }
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
