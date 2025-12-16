#requires -modules BuildHelpers
#requires -modules @{ ModuleName = "Pester"; ModuleVersion = "5.7.1" }

Describe "Add-JiraIssueComment" -Tag 'Unit' {

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

        $jiraServer = 'http://jiraserver.example.com'
        $issueID = 41701
        $issueKey = 'IT-3676'

        $restResponse = @"
{
    "self": "$jiraServer/rest/api/2/issue/$issueID/comment/90730",
    "id": "90730",
    "body": "Test comment",
    "created": "2015-05-01T16:24:38.000-0500",
    "updated": "2015-05-01T16:24:38.000-0500"
}
"@

        # Helper function for creating issue objects
        function New-TestJiraIssue {
            param($Key = $issueKey)
            $object = [PSCustomObject] @{
                ID      = $issueID
                Key     = $Key
                RestUrl = "$jiraServer/rest/api/2/issue/$issueID"
            }
            $object.PSObject.TypeNames.Insert(0, 'JiraPS.Issue')
            return $object
        }

        Mock Get-JiraConfigServer -ModuleName JiraPS {
            Write-Output $jiraServer
        }

        Mock Get-JiraIssue -ModuleName JiraPS {
            New-TestJiraIssue -Key $Key
        }

        Mock Invoke-JiraMethod -ModuleName JiraPS -ParameterFilter {$Method -eq 'POST' -and $URI -eq "$jiraServer/rest/api/2/issue/$issueID/comment"} {
            ShowMockInfo 'Invoke-JiraMethod' 'Method', 'Uri'
            ConvertFrom-Json $restResponse
        }

        # Generic catch-all. This will throw an exception if we forgot to mock something.
        Mock Invoke-JiraMethod -ModuleName JiraPS {
            ShowMockInfo 'Invoke-JiraMethod' 'Method', 'Uri'
            throw "Unidentified call to Invoke-JiraMethod"
        }
    }

    #############
    # Tests
    #############

    Context "Sanity checking" {
        It "Has expected parameters" {
            $command = Get-Command -Name Add-JiraIssueComment

            defParam $command 'Comment'
            defParam $command 'Issue'
            defParam $command 'VisibleRole'
            defParam $command 'Credential'
        }
    }

    Context "Behavior testing" {
        Context "Intended Processing" {
            It "Adds a comment to an issue in JIRA" {
                $commentResult = Add-JiraIssueComment -Comment 'This is a test comment from Pester.' -Issue $issueKey
                $commentResult | Should -Not -BeNullOrEmpty
            }

            It "Accepts pipeline input from Get-JiraIssue" {
                # Mock for when Get-JiraIssue is called directly in tests (outside module scope)
                Mock Invoke-JiraMethod -ModuleName JiraPS -ParameterFilter {$Method -eq 'GET' -and $URI -like "$jiraServer/rest/api/2/issue/$issueKey*"} {
                    ShowMockInfo 'Invoke-JiraMethod' 'Method', 'Uri'
                    @{
                        id = $issueID
                        key = $issueKey
                        self = "$jiraServer/rest/api/2/issue/$issueID"
                        fields = @{}
                    }
                }

                $commentResult = Get-JiraIssue -Key $IssueKey |
                    Add-JiraIssueComment -Comment 'This is a test comment from Pester, using the pipeline!'
                $commentResult | Should -Not -BeNullOrEmpty
            }
        }

        Context "Output checking" {
            BeforeAll {
                Mock ConvertTo-JiraComment -ModuleName JiraPS {
                    $InputObject
                }
            }

            It "Uses ConvertTo-JiraComment to beautify output" {
                Add-JiraIssueComment -Comment 'This is a test comment from Pester.' -Issue $issueKey | Out-Null

                Should -Invoke 'ConvertTo-JiraComment' -ModuleName JiraPS -Exactly -Times 1
            }
        }

        Context "Internal Call Validation" {
            It "Executes actual API call using Invoke-JiraMethod" {
                Add-JiraIssueComment -Comment 'This is a test comment from Pester.' -Issue $issueKey | Out-Null

                Should -Invoke 'Invoke-JiraMethod' -ModuleName JiraPS -Exactly -Times 1
            }

            It "Uses ConvertTo-JiraComment to beutify output" {
                Mock ConvertTo-JiraComment -ModuleName JiraPS {
                    $InputObject
                }

                Add-JiraIssueComment -Comment 'This is a test comment from Pester.' -Issue $issueKey | Out-Null

                Should -Invoke 'ConvertTo-JiraComment' -ModuleName JiraPS -Exactly -Times 1
            }

            It "Calls Resolve-JiraIssueObject to set the issue object" {
                Mock Resolve-JiraIssueObject -ModuleName JiraPS {
                    New-TestJiraIssue -Key $issueKey
                }

                Add-JiraIssueComment -Comment 'This is a test comment from Pester.' -Issue $issueKey | Out-Null

                Should -Invoke 'Resolve-JiraIssueObject' -ModuleName JiraPS -Exactly -Times 1
            }
        }
    }

    AfterAll {
        Remove-Module $env:BHProjectName -ErrorAction SilentlyContinue
        Remove-Module BuildHelpers -ErrorAction SilentlyContinue
        Remove-Item -Path Env:\BH* -ErrorAction SilentlyContinue
    }
}
