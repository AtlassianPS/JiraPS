#requires -modules BuildHelpers
#requires -modules @{ ModuleName = "Pester"; ModuleVersion = "5.7.1" }
#NOTE: Advanced refactor

[Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSAvoidUsingConvertToSecureStringWithPlainText", "")]
param()

Describe "Add-JiraIssueAttachment" -Tag 'Unit' {

    BeforeAll {
        Remove-Item -Path Env:\BH* -ErrorAction SilentlyContinue
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

        Import-Module "$env:BHProjectPath/Tools/BuildTools.psm1" -ErrorAction Stop

        Remove-Module $env:BHProjectName -ErrorAction SilentlyContinue
        Import-Module $env:BHManifestToTest -ErrorAction Stop

        # helpers used by tests (defParam / ShowMockInfo)
        . "$PSScriptRoot/../Shared.ps1"
    }

    #region Tests
    Context "Sanity checking" {
        It "Has expected parameters" {
            $command = Get-Command -Name Add-JiraIssueAttachment
            $command.Parameters.Item('Issue') | Should -Not -BeNullOrEmpty
            $command.Parameters.Item('FilePath') | Should -Not -BeNullOrEmpty
            $command.Parameters.Item('Credential') | Should -Not -BeNullOrEmpty
            $command.Parameters.Item('PassThru') | Should -Not -BeNullOrEmpty
        }
    }

    Context "Behavior checking" {
        BeforeAll {
            $pass = ConvertTo-SecureString -AsPlainText -Force -String "password"
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

            # Helper functions for test objects
            function New-TestJiraIssue {
                param($Key = $issueKey)
                $Issue = [PSCustomObject]@{
                    Key     = $Key
                    RestURL = "$jiraServer/rest/api/2/issue/$Key"
                }
                $Issue.PSObject.TypeNames.Insert(0, 'JiraPS.Issue')
                $Issue
            }

            #region Mock
            Mock ConvertTo-JiraAttachment -ModuleName JiraPS {
                $InputObject
            }

            Mock Get-JiraIssue -ModuleName JiraPS {
                New-TestJiraIssue -Key $Key
            }

            Mock Invoke-JiraMethod -ModuleName JiraPS -ParameterFilter { $Method -eq 'Post' -and $URI -eq "$jiraServer/rest/api/2/issue/$issueKey/attachments" } {
                ShowMockInfo 'Invoke-JiraMethod' 'Method', 'Uri'
                ConvertFrom-Json -InputObject $attachmentJson
            }

            # Generic catch-all. This will throw an exception if we forgot to mock something.
            Mock Invoke-JiraMethod -ModuleName JiraPS {
                ShowMockInfo 'Invoke-JiraMethod' 'Method', 'Uri'
                throw "Unidentified call to Invoke-JiraMethod"
            }
            #endregion Mock
        }
        <#
        Remember to check for:
            - each ParameterSet
            - each Parameter
            - each ValueFromPipeline
            - each 'Throw'
            - each possible Output
            - each object type
        #>
        #NOTE: These really should be broken up into separate context blocks, like 'Parameter Validation' and 'Positional Parameters' and 'Internal call verification' etc. The tests as-is are doing way too much and it's extremely difficult to identify individual issues.
        Context "Intended Processing" {
            It "Does not throw with an Issue key string" {
                { Add-JiraIssueAttachment -Issue $issueKey -FilePath $filePath } |
                    Should -Not -Throw
            }

            It "Does not throw with a JiraPS.Issue object" {
                { Add-JiraIssueAttachment -Issue (New-TestJiraIssue) -FilePath $filePath -Credential $Cred } |
                    Should -Not -Throw
            }

            It "Accepts positional parameters" {
                { Add-JiraIssueAttachment $issueKey @($filePath, $filePath) } |
                    Should -Not -Throw
            }

            It "has no output by default" {
                $result = Add-JiraIssueAttachment -Issue $issueKey -FilePath $filePath
                $result | Should -BeNullOrEmpty
            }

            It "Returns an object when specified" {
                $result = Add-JiraIssueAttachment -Issue $issueKey -FilePath $filePath -PassThru
                $result | Should -Not -BeNullOrEmpty
            }

            It "Accepts files over the pipeline" {
                { $filePath | Add-JiraIssueAttachment $issueKey  } | Should -Not -Throw
                { @($filePath, $filePath) | Add-JiraIssueAttachment $issueKey  } | Should -Not -Throw
                { Get-Item $filePath | Add-JiraIssueAttachment $issueKey  } | Should -Not -Throw
            }
        }

        Context "Parameter Validation" {
            It "Throws if -Issue is empty" {
                { Add-JiraIssueAttachment -Issue "" -FilePath $filePath } | Should -Throw
            }
            It "Throws if -Issue is not an issue object or string" {
                { Add-JiraIssueAttachment -Issue (Get-Date) -FilePath $filePath } | Should -Throw
            }
            It "Throws if -Issue is an array" {
                { Add-JiraIssueAttachment -Issue $issueKey, $issueKey -FilePath $filePath } | Should -Throw
            }
            It "Throws if the file doesn't exist" {
                { Add-JiraIssueAttachment -Issue $issueKey -FilePath "c:\no-file.txt" } | Should -Throw
            }
        }

        Context "Internal Call Validation" {
            Context "Invoke-JiraMethod" {
                It "Did not call Invoke-JiraMethod with GET,PUT, or DELETE methods at all" {
                    $verifyParams = @{
                        Invoke = $true
                        CommandName = "Invoke-JiraMethod"
                        ModuleName = 'JiraPS'
                        Times = 0
                        Exactly = $true
                        Scope = "Describe"
                    }
                    Should @verifyParams -ParameterFilter { $Method -eq 'Get' }
                    Should @verifyParams -ParameterFilter { $Method -eq 'Put' }
                    Should @verifyParams -ParameterFilter { $Method -eq 'Delete' }
                }

                It "Only calls Invoke-JiraMethod with POST method" {
                    Should -Invoke 'Invoke-JiraMethod' -ModuleName JiraPS -ParameterFilter { $Method -eq 'Post' } -Times 1 -Scope Describe
                }

                It "Only calls Invoke-JiraMethod once for a single file" {
                    Add-JiraIssueAttachment -Issue $issueKey -FilePath $filePath

                    Should -Invoke "Invoke-JiraMethod" -ModuleName JiraPS -Times 1 -Exactly
                }

                It "Calls Invoke-JiraMethod once for each file" {
                    Add-JiraIssueAttachment $issueKey @($filePath, $filePath, $filePath)

                    Should -Invoke "Invoke-JiraMethod" -ModuleName JiraPS -Times 3 -Exactly
                }
            }

            Context "Resolve-JiraIssueObject" {
                BeforeAll {
                    Mock Resolve-JiraIssueObject -ModuleName JiraPS {
                        New-TestJiraIssue -Key $issueKey
                    }
                }

                It "Calls Resolve-JiraIssueObject once when adding a single file" {
                    Add-JiraIssueAttachment -Issue $issueKey -FilePath $filePath

                    Should -Invoke "Resolve-JiraIssueObject" -ModuleName JiraPS -Times 1 -Exactly
                }

                It "Calls Resolve-JiraIssueObject once even when adding multiple files" {
                    Add-JiraIssueAttachment -Issue $issueKey -FilePath @($filePath,$filePath)

                    Should -Invoke "Resolve-JiraIssueObject" -ModuleName JiraPS -Times 1 -Exactly
                }
            }
        }
    }
    #endregion Tests

    AfterAll {
        Remove-Module $env:BHProjectName -ErrorAction SilentlyContinue
        Remove-Module BuildHelpers -ErrorAction SilentlyContinue
        Remove-Item -Path Env:\BH* -ErrorAction SilentlyContinue
    }
}
