#requires -modules @{ ModuleName = "Pester"; ModuleVersion = "5.7"; MaximumVersion = "5.999" }

BeforeDiscovery {
    . "$PSScriptRoot/../../Helpers/TestTools.ps1"

    $script:moduleToTest = Initialize-TestEnvironment
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

                It "adds custom type 'AtlassianPS.JiraPS.Comment'" {
                    $result.PSObject.TypeNames[0] | Should -Be 'AtlassianPS.JiraPS.Comment'
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
                    @{ property = "RestUrl"; type = [uri]; value = $null }
                    @{ property = "Created"; type = [System.DateTimeOffset]; value = [System.DateTimeOffset](Get-Date "2015-05-01T16:24:38.000-0500") }
                    @{ property = "Updated"; type = [System.DateTimeOffset]; value = [System.DateTimeOffset](Get-Date "2015-05-01T16:24:38.000-0500") }
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

        Context "Jira Cloud — ADF body" {
            BeforeAll {
                # On Jira Cloud (API v3), comment body is returned as ADF JSON
                $adfCommentJson = @"
{
    "self": "$jiraServer/rest/api/3/issue/41701/comment/90731",
    "id": "90731",
    "author": {
        "self": "$jiraServer/rest/api/3/user?accountId=abc123",
        "accountId": "abc123",
        "displayName": "$jiraUserDisplayName",
        "active": true,
        "avatarUrls": {}
    },
    "body": {
        "type": "doc",
        "version": 1,
        "content": [
            {
                "type": "paragraph",
                "content": [
                    { "type": "text", "text": "ADF comment body" }
                ]
            }
        ]
    },
    "updateAuthor": {
        "self": "$jiraServer/rest/api/3/user?accountId=abc123",
        "accountId": "abc123",
        "displayName": "$jiraUserDisplayName",
        "active": true,
        "avatarUrls": {}
    },
    "created": "2015-05-01T16:24:38.000-0500",
    "updated": "2015-05-01T16:24:38.000-0500"
}
"@
                $script:adfCommentObject = ConvertFrom-Json -InputObject $adfCommentJson
                $script:adfResult = ConvertTo-JiraComment -InputObject $adfCommentObject
            }

            It "extracts plain text from an ADF body" {
                $adfResult.Body | Should -Be "ADF comment body"
            }

            It "Body is a plain string, not a PSCustomObject" {
                $adfResult.Body | Should -BeOfType [string]
            }
        }

        Context "expand=renderedBody and Cloud properties" {
            It "exposes 'RenderedBody' as a string when the payload provides it (DC v2)" {
                $payload = ConvertFrom-Json '{"id":"1","body":"plain","renderedBody":"<p>plain</p>"}'
                $result = ConvertTo-JiraComment -InputObject $payload
                $result.RenderedBody | Should -BeOfType [string]
                $result.RenderedBody | Should -Be '<p>plain</p>'
            }

            It "leaves 'RenderedBody' null when the payload omits it" {
                $payload = ConvertFrom-Json '{"id":"1","body":"plain"}'
                $result = ConvertTo-JiraComment -InputObject $payload
                $result.RenderedBody | Should -BeNullOrEmpty
            }

            It "exposes Cloud comment 'properties' as an array" {
                $payload = ConvertFrom-Json '{"id":"1","body":"plain","properties":[{"key":"sd.public.comment","value":{"internal":false}}]}'
                $result = ConvertTo-JiraComment -InputObject $payload
                $result.Properties | Should -Not -BeNullOrEmpty
                @($result.Properties).Count | Should -Be 1
                $result.Properties[0].key | Should -Be 'sd.public.comment'
            }
        }
    }
}

