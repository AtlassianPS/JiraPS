#requires -modules @{ ModuleName = "Pester"; ModuleVersion = "5.7"; MaximumVersion = "5.999" }

BeforeDiscovery {
    . "$PSScriptRoot/../../Helpers/TestTools.ps1"

    Initialize-TestEnvironment
    $script:moduleToTest = Resolve-ModuleSource

    Import-Module $script:moduleToTest -Force -ErrorAction Stop
}

InModuleScope JiraPS {
    Describe "ConvertTo-JiraAttachment" -Tag 'Unit' {
        BeforeAll {
            . "$PSScriptRoot/../../Helpers/TestTools.ps1"

            #region Definitions
            $jiraServer = 'http://jiraserver.example.com'

            $attachmentID = "270709"
            $attachmentName = "Nav2-HCF.PNG"

            $sampleJson = @"
[
    {
        "self":  "$jiraServer/rest/api/2/attachment/$attachmentID",
        "id":  "$attachmentID",
        "filename":  "$attachmentName",
        "author":  {
            "self":  "$jiraServer/rest/api/2/user?username=JonDoe",
            "name":  "JonDoe",
            "key":  "JonDoe",
            "emailAddress":  "JonDoe@server.com",
            "avatarUrls":  {},
            "displayName":  "Doe, Jon",
            "active":  true,
            "timeZone":  "Europe/Berlin"
        },
        "created":  "2017-05-30T11:20:34.000+0000",
        "size":  366272,
        "mimeType":  "image/png",
        "content":  "$jiraServer/secure/attachment/$attachmentID/$attachmentName",
        "thumbnail":  "$jiraServer/secure/thumbnail/$attachmentID/_thumb_$attachmentID.png"
    }
]
"@

            $script:sampleObject = ConvertFrom-Json -InputObject $sampleJson
            #endregion Definitions
        }

        Describe "Behavior" {
            BeforeAll {
                $script:result = ConvertTo-JiraAttachment -InputObject $sampleObject
            }

            Context "Object Conversion" {
                It "creates a PSObject out of JSON input" {
                    $result | Should -Not -BeNullOrEmpty
                    $result | Should -BeOfType [PSCustomObject]
                }

                It "adds the custom type name 'JiraPS.Attachment'" {
                    $result.PSObject.TypeNames[0] | Should -Be 'JiraPS.Attachment'
                }
            }

            Context "Inputs" {
                It "converts multiple attachments from array input" {
                    ConvertTo-JiraAttachment -InputObject $sampleObject, $sampleObject | Should -HaveCount 2
                }

                It "accepts input from pipeline" {
                    $sampleObject, $sampleObject | ConvertTo-JiraAttachment | Should -HaveCount 2
                }
            }

            Context "Property Mapping" {
                It "defines '<property>' of type '<type>' with value '<value>'" -TestCases @(
                    @{ property = "Id"; type = [string]; value = '270709' }
                    @{ property = "FileName"; type = [string]; value = 'Nav2-HCF.PNG' }
                    @{ property = "self"; type = [string]; value = $null }
                    @{ property = "Author"; type = 'JiraPS.User'; value = 'JonDoe' }
                    @{ property = "Created"; type = [System.DateTime]; value = (Get-Date "2017-05-30T13:20:34.0000000+02:00") }
                    @{ property = "Size"; type = [System.ValueType]; value = '366272' }
                    @{ property = "content"; type = [string]; value = $null }
                    @{ property = "mimeType"; type = [string]; value = 'image/png' }
                    @{ property = "thumbnail"; type = [string]; value = $null }
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
