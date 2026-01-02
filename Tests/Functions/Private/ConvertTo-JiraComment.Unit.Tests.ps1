#requires -modules @{ ModuleName = "Pester"; ModuleVersion = "5.7"; MaximumVersion = "5.999" }

BeforeDiscovery {
    . "$PSScriptRoot/../../Helpers/TestTools.ps1"

    Initialize-TestEnvironment
    $script:moduleToTest = Resolve-ModuleSource

    Import-Module $script:moduleToTest -Force -ErrorAction Stop
}

InModuleScope JiraPS {
    Describe "ConvertTo-JiraComment" -Tag 'Unit' {
        BeforeAll {
            . "$PSScriptRoot/../../Helpers/TestTools.ps1"

            #region Definitions
            $jiraServer = 'http://jiraserver.example.com'

            $jiraUsername = 'powershell-test'
            $jiraUserDisplayName = 'PowerShell Test User'
            $jiraUserEmail = 'noreply@example.com'
            $commentId = 90730
            $commentBody = "Test comment"

            $sampleJson = @"
{
    "self": "$jiraServer/rest/api/2/issue/41701/comment/90730",
    "id": "$commentId",
    "author": {
    "self": "$jiraServer/rest/api/2/user?username=powershell-test",
    "name": "$jiraUsername",
    "emailAddress": "$jiraUserEmail",
    "avatarUrls": {
        "48x48": "$jiraServer/secure/useravatar?avatarId=10202",
        "24x24": "$jiraServer/secure/useravatar?size=small&avatarId=10202",
        "16x16": "$jiraServer/secure/useravatar?size=xsmall&avatarId=10202",
        "32x32": "$jiraServer/secure/useravatar?size=medium&avatarId=10202"
    },
    "displayName": "$jiraUserDisplayName",
    "active": true
    },
    "body": "$commentBody",
    "updateAuthor": {
    "self": "$jiraServer/rest/api/2/user?username=powershell-test",
    "name": "powershell-test",
    "emailAddress": "$jiraUserEmail",
    "avatarUrls": {
        "48x48": "$jiraServer/secure/useravatar?avatarId=10202",
        "24x24": "$jiraServer/secure/useravatar?size=small&avatarId=10202",
        "16x16": "$jiraServer/secure/useravatar?size=xsmall&avatarId=10202",
        "32x32": "$jiraServer/secure/useravatar?size=medium&avatarId=10202"
    },
    "displayName": "$jiraUserDisplayName",
    "active": true
    },
    "created": "2015-05-01T16:24:38.000-0500",
    "updated": "2015-05-01T16:24:38.000-0500",
    "visibility": {
    "type": "role",
    "value": "Developers"
    }
}
"@
            $script:sampleObject = ConvertFrom-Json -InputObject $sampleJson
            #endregion Definitions
        }

        Describe "Behavior" {
            BeforeAll {
                $script:result = ConvertTo-JiraComment -InputObject $sampleObject
            }

            Context "Object Conversion" {
                It "creates a PSObject out of JSON input" {
                    $result | Should -Not -BeNullOrEmpty
                    $result | Should -BeOfType [PSCustomObject]
                }

                It "adds custom type 'JiraPS.Comment'" {
                    $result.PSObject.TypeNames[0] | Should -Be 'JiraPS.Comment'
                }
            }

            Context "Inputs" {
                It "converts multiple attachments from array input" {
                    ConvertTo-JiraComment -InputObject $sampleObject, $sampleObject | Should -HaveCount 2
                }

                It "accepts input from pipeline" {
                    $sampleObject, $sampleObject | ConvertTo-JiraComment | Should -HaveCount 2
                }
            }

            Context "Property Mapping" {
                It "defines '<property>' of type '<type>' with value '<value>'" -TestCases @(
                    @{ property = "Id"; type = [string]; value = 90730 }
                    @{ property = "Body"; type = [string]; value = 'Test comment' }
                    @{ property = "RestUrl"; type = [string]; value = $null }
                    @{ property = "Created"; type = [System.DateTime]; value = (Get-Date "2015-05-01T16:24:38.000-0500") }
                    @{ property = "Updated"; type = [System.DateTime]; value = (Get-Date "2015-05-01T16:24:38.000-0500") }
                ) {
                    if ($value) { $result.$($property) | Should -Be $value }
                    else { $result.$($property) | Should -Not -BeNullOrEmpty }

                    if ($type -is [string]) {
                        $result.$($property).PSObject.TypeNames[0] | Should -Be $type
                    }
                    else { $result.$($property) | Should -BeOfType $type }
                }
            }
        }
    }
}
