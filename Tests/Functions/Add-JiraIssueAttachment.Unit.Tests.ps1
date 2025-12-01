#requires -modules @{ ModuleName = "Pester"; ModuleVersion = "5.7"; MaximumVersion = "5.999" }
[Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSAvoidUsingConvertToSecureStringWithPlainText", "")]
param()

BeforeDiscovery {
    $script:ThisTest = "Add-JiraIssueAttachment"

    . "$PSScriptRoot/../Helpers/Resolve-ModuleSource.ps1"
    $script:moduleToTest = Resolve-ModuleSource

    $dependentModules = Get-Module | Where-Object { $_.RequiredModules.Name -eq 'JiraPS' }
    $dependentModules, "JiraPS" | Remove-Module -Force -ErrorAction SilentlyContinue
    Import-Module $moduleToTest -Force -ErrorAction Stop
}

InModuleScope JiraPS {
    Describe "$ThisTest" -Tag 'Unit' {
        BeforeAll {
            . "$PSScriptRoot/../Helpers/Shared.ps1"

            $pass = ConvertTo-SecureString -AsPlainText -Force -String "passowrd"
            $script:Cred = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList ("user", $pass)
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

            Set-Content $filePath -Value "my test text."

            #region Mock
            Mock ConvertTo-JiraAttachment -ModuleName JiraPS {
                $InputObject
            }

            Mock Get-JiraIssue -ModuleName JiraPS {
                $Issue = [PSCustomObject]@{
                    Key     = $issueKey
                    RestURL = "$jiraServer/rest/api/2/issue/$issueKey"
                }
                $Issue.PSObject.TypeNames.Insert(0, 'JiraPS.Issue')
                $Issue
            }

            Mock Resolve-JiraIssueObject -ModuleName JiraPS {
                Get-JiraIssue -Key $Issue
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

        #region Tests
        Describe "Signature" {
            BeforeAll {
                $script:command = Get-Command -Name $ThisTest
            }

            It "has a parameter '<parameter>' of type '<type>'" -TestCases @(
                @{ parameter = "Issue"; type = "Object" }
                @{ parameter = "FilePath"; type = "String[]" }
                @{ parameter = "Credential"; type = "System.Management.Automation.PSCredential" }
                @{ parameter = "Passthru"; type = "Switch" }
            ) {
                $command | Should -HaveParameter $parameter

                #ToDo:CustomClass
                # can't use -Type as long we are using `PSObject.TypeNames.Insert(0, 'JiraPS.Filter')`
                    (Get-Member -InputObject $command.Parameters.Item($parameter)).Attributes | Should -Contain $typeName
            }

            It "parameter '<parameter>' has a default value of '<defaultValue>'" -TestCases @(
                @{ parameter = "Credential"; defaultValue = "[System.Management.Automation.PSCredential]::Empty" }
            ) {
                $command | Should -HaveParameter $parameter -DefaultValue $defaultValue
            }

            It "parameter '<parameter>' is mandatory" -TestCases @(
                @{ parameter = "Issue" }
                @{ parameter = "FilePath" }
            ) {
                $command | Should -HaveParameter $parameter -Mandatory
            }
        }

        Context "Behavior" {
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
                { Add-JiraIssueAttachment -Issue "" -FilePath $filePath } | Should -Throw
                # Issue must be an Issue or a String
                { Add-JiraIssueAttachment -Issue (Get-Date) -FilePath $filePath -Verbose } | Should -Throw
                # Issue can't be an array
                { Add-JiraIssueAttachment -Issue $issueKey, $issueKey -FilePath $filePath } | Should -Throw
                # File must exist
                { Add-JiraIssueAttachment -Issue $issueKey -FilePath "c:\no-file.txt" } | Should -Throw
                # All Parameters for DefaultParameterSet
                { Add-JiraIssueAttachment -Issue $issueKey -FilePath $filePath } | Should -Not -Throw
                { Add-JiraIssueAttachment -Issue (Get-JiraIssue $issueKey) -FilePath $filePath -Credential $Cred } | Should -Not -Throw
                { Add-JiraIssueAttachment -Issue $issueKey -FilePath @($filePath, $filePath) -Credential $Cred -PassThru } | Should -Not -Throw

                # ensure the calls under the hood
                Assert-MockCalled 'Get-JiraIssue' -ModuleName JiraPS -Exactly -Times 4 -Scope It
                Assert-MockCalled 'Resolve-JiraIssueObject' -ModuleName JiraPS -Exactly -Times 3 -Scope It
                Assert-MockCalled 'Invoke-JiraMethod' -ModuleName JiraPS -ParameterFilter { $Method -eq 'Get' } -Exactly -Times 0 -Scope It
                Assert-MockCalled 'Invoke-JiraMethod' -ModuleName JiraPS -ParameterFilter { $Method -eq 'Post' } -Exactly -Times 4 -Scope It
                Assert-MockCalled 'Invoke-JiraMethod' -ModuleName JiraPS -ParameterFilter { $Method -eq 'Put' } -Exactly -Times 0 -Scope It
                Assert-MockCalled 'Invoke-JiraMethod' -ModuleName JiraPS -ParameterFilter { $Method -eq 'Delete' } -Exactly -Times 0 -Scope It
            }

            It 'accepts positional parameters' {
                { Add-JiraIssueAttachment $issueKey @($filePath, $filePath) } | Should -Not -Throw

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
                $result | Should -BeNullOrEmpty

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
                $result | Should -Not -BeNullOrEmpty

                # ensure the calls under the hood
                Assert-MockCalled 'Get-JiraIssue' -ModuleName JiraPS -Exactly -Times 1 -Scope It
                Assert-MockCalled 'Resolve-JiraIssueObject' -ModuleName JiraPS -Exactly -Times 1 -Scope It
                Assert-MockCalled 'Invoke-JiraMethod' -ModuleName JiraPS -ParameterFilter { $Method -eq 'Get' } -Exactly -Times 0 -Scope It
                Assert-MockCalled 'Invoke-JiraMethod' -ModuleName JiraPS -ParameterFilter { $Method -eq 'Post' } -Exactly -Times 1 -Scope It
                Assert-MockCalled 'Invoke-JiraMethod' -ModuleName JiraPS -ParameterFilter { $Method -eq 'Put' } -Exactly -Times 0 -Scope It
                Assert-MockCalled 'Invoke-JiraMethod' -ModuleName JiraPS -ParameterFilter { $Method -eq 'Delete' } -Exactly -Times 0 -Scope It
            }

            It 'accepts files over the pipeline' {
                { $filePath | Add-JiraIssueAttachment $issueKey } | Should -Not -Throw
                { @($filePath, $filePath) | Add-JiraIssueAttachment $issueKey } | Should -Not -Throw
                { Get-Item $filePath | Add-JiraIssueAttachment $issueKey } | Should -Not -Throw

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
