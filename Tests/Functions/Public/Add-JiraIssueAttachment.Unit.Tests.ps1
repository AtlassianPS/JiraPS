#requires -modules @{ ModuleName = "Pester"; ModuleVersion = "5.7"; MaximumVersion = "5.999" }
[Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSAvoidUsingConvertToSecureStringWithPlainText", "")]
param()

BeforeDiscovery {
    . "$PSScriptRoot/../../Helpers/TestTools.ps1"

    $script:moduleToTest = Initialize-TestEnvironment
}

InModuleScope JiraPS {
    Describe "Add-JiraIssueAttachment" -Tag 'Unit' {
        BeforeAll {
            . "$PSScriptRoot/../../Helpers/TestTools.ps1"

            #region Definitions
            $pass = ConvertTo-SecureString -AsPlainText -Force -String "password"
            $script:Cred = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList ("user", $pass)
            $jiraServer = 'http://jiraserver.example.com'
            $script:issueKey = "FOO-1234"
            $script:file = New-Item -Path "TestDrive:\MyFile.txt" -ItemType File -Force
            $script:fileName = $file.Name
            $script:filePath = $file.FullName
            $script:attachmentId = 10010

            $script:attachmentJson = @"
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
    "mimeType": "'application/pdf'",
    "content": "$jiraServer/secure/attachment/$attachmentId/$fileName"
}
"@

            Set-Content $filePath -Value "my test text."
            #endregion Definitions

            #region Mocks
            Mock ConvertTo-JiraAttachment -ModuleName JiraPS {
                Write-MockDebugInfo 'ConvertTo-JiraAttachment' 'InputObject'
                $InputObject
            }

            Mock Get-JiraIssue -ModuleName JiraPS {
                Write-MockDebugInfo 'Get-JiraIssue' 'Key'
                $Issue = [AtlassianPS.JiraPS.Issue]@{
                    Key     = $issueKey
                    RestURL = "$jiraServer/rest/api/2/issue/$issueKey"
                }
                $Issue
            }

            Mock Resolve-JiraIssueObject -ModuleName JiraPS {
                Write-MockDebugInfo 'Resolve-JiraIssueObject' 'InputObject'
                Get-JiraIssue -Key $InputObject.Key
            }

            Mock Invoke-JiraMethod -ModuleName JiraPS -ParameterFilter { $Method -eq 'Post' -and $URI -eq "$jiraServer/rest/api/2/issue/$issueKey/attachments" } {
                Write-MockDebugInfo 'Invoke-JiraMethod' 'Method', 'Uri'
                ConvertFrom-Json -InputObject $attachmentJson
            }

            # Generic catch-all. This will throw an exception if we forgot to mock something.
            Mock Invoke-JiraMethod -ModuleName JiraPS {
                Write-MockDebugInfo 'Invoke-JiraMethod' 'Method', 'Uri'
                throw "Unidentified call to Invoke-JiraMethod"
            }
            #endregion Mocks
        }

        #region Tests
        Describe "Signature" {
            BeforeAll {
                $script:command = Get-Command -Name "Add-JiraIssueAttachment"
            }

            Context "Parameter Types" {
                It "has a parameter '<parameter>' of type '<type>'" -TestCases @(
                    @{ parameter = "Issue"; type = "Object" }
                    @{ parameter = "FilePath"; type = "String[]" }
                    @{ parameter = "Credential"; type = "System.Management.Automation.PSCredential" }
                    @{ parameter = "Passthru"; type = "Switch" }
                ) {
                    $command | Should -HaveParameter $parameter

                    #ToDo:CustomClass
                    # can't use -Type as long we are using `PSObject.TypeNames.Insert(0, 'AtlassianPS.JiraPS.Filter')`
                    (Get-Member -InputObject $command.Parameters.Item($parameter)).Attributes | Should -Contain $typeName
                }
            }

            Context "Default Values" {
                It "parameter '<parameter>' has a default value of '<defaultValue>'" -TestCases @(
                    @{ parameter = "Credential"; defaultValue = "[System.Management.Automation.PSCredential]::Empty" }
                ) {
                    $command | Should -HaveParameter $parameter -DefaultValue $defaultValue
                }
            }

            Context "Mandatory Parameters" {
                It "parameter '<parameter>' is mandatory" -TestCases @(
                    @{ parameter = "Issue" }
                    @{ parameter = "FilePath" }
                ) {
                    $command | Should -HaveParameter $parameter -Mandatory
                }
            }
        }

        Describe "Behavior" {
            It "calls all necessary functions under the hood" {
                $null = Add-JiraIssueAttachment -Issue (Get-JiraIssue $issueKey) -FilePath $filePath

                Should -Invoke 'Get-JiraIssue' -ModuleName JiraPS -Exactly -Times 2
                Should -Invoke 'Resolve-JiraIssueObject' -ModuleName JiraPS -Exactly -Times 1
                Should -Invoke 'Invoke-JiraMethod' -ModuleName JiraPS -ParameterFilter { $Method -eq 'Post' } -Exactly -Times 1
                Should -Invoke 'Invoke-JiraMethod' -ModuleName JiraPS -ParameterFilter { $Method -ne 'Post' } -Exactly -Times 0
            }

            It 'uploads attachments via Invoke-JiraMethod -InFile' {
                $null = Add-JiraIssueAttachment -Issue $issueKey -FilePath $filePath

                Should -Invoke 'Invoke-JiraMethod' -ModuleName JiraPS -ParameterFilter {
                    $Method -eq 'Post' -and
                    $URI -eq "$jiraServer/rest/api/2/issue/$issueKey/attachments" -and
                    $InFile -eq $filePath -and
                    $Headers['X-Atlassian-Token'] -eq 'nocheck' -and
                    -not $Headers.ContainsKey('Content-Type') -and
                    -not $Body -and
                    -not $RawBody
                } -Exactly -Times 1
            }

            It 'has no output by default' {
                $result = Add-JiraIssueAttachment -Issue $issueKey -FilePath $filePath
                $result | Should -BeNullOrEmpty
            }

            It 'returns an object when specified' {
                $result = Add-JiraIssueAttachment -Issue $issueKey -FilePath $filePath -PassThru
                $result | Should -Not -BeNullOrEmpty
            }
        }

        Describe "Input Validation" {
            Context "Type Validation - Positive Cases" {
                It "issue can be a String" {
                    { Add-JiraIssueAttachment -Issue $issueKey -FilePath $filePath } | Should -Not -Throw
                }

                It "issue can be an Issue object" {
                    { Add-JiraIssueAttachment -Issue (Get-JiraIssue $issueKey) -FilePath $filePath } | Should -Not -Throw
                }

                It "filePath can be a single file" {
                    { Add-JiraIssueAttachment -Issue $issueKey -FilePath $filePath } | Should -Not -Throw
                }

                It "filePath can be multiple files" {
                    { Add-JiraIssueAttachment -Issue $issueKey -FilePath @($filePath, $filePath) } | Should -Not -Throw
                }

                It 'accepts positional parameters' {
                    { Add-JiraIssueAttachment $issueKey @($filePath, $filePath) } | Should -Not -Throw
                }

                It 'accepts files over the pipeline' {
                    { $filePath | Add-JiraIssueAttachment $issueKey } | Should -Not -Throw
                    { @($filePath, $filePath) | Add-JiraIssueAttachment $issueKey } | Should -Not -Throw
                    { Get-Item $filePath | Add-JiraIssueAttachment $issueKey } | Should -Not -Throw
                }
            }

            Context "Type Validation - Negative Cases" {
                It "issue can't be null or empty" {
                    { Add-JiraIssueAttachment -Issue "" -FilePath $filePath } | Should -Throw -ExpectedMessage "*'Issue'*"
                }

                It "issue must be an Issue or a String" {
                    { Add-JiraIssueAttachment -Issue (Get-Date) -FilePath $filePath -Verbose } | Should -Throw -ExpectedMessage "*to AtlassianPS.JiraPS.Issue*"
                }

                It "issue can't be an array passed directly (use the pipeline instead)" {
                    { Add-JiraIssueAttachment -Issue $issueKey, $issueKey -FilePath $filePath } | Should -Throw -ExpectedMessage "*to AtlassianPS.JiraPS.Issue*"
                }

                It "file must exist" {
                    { Add-JiraIssueAttachment -Issue $issueKey -FilePath "c:\no-file.txt" } | Should -Throw -ExpectedMessage "*File not found*"
                }
            }
        }
        #endregion Tests
    }
}
