#requires -modules BuildHelpers
#requires -modules @{ ModuleName = "Pester"; ModuleVersion = "5.7.1" }

Describe "Get-JiraGroupMember" -Tag 'Unit' {

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

        # helpers used by tests (defParam / ShowMockInfo)
        . "$PSScriptRoot/../Shared.ps1"

        #region Mocks

        $testGroupName = "testgroup"

        #helper function to simulate Get-JiraGroup
        function Get-TestJiraGroup {
            param([string]$GroupName = $testGroupName)
            $obj = [PSCustomObject] @{
                'Name'    = $GroupName
                'RestUrl' = 'https://jira.example.com/rest/api/2/group?groupname=testgroup'
                'Size'    = 2
            }
            $obj.PSObject.TypeNames.Insert(0, 'JiraPS.Group')
            $obj
        }

        Mock Get-JiraConfigServer -ModuleName JiraPS {
            'https://jira.example.com'
        }

        Mock Get-JiraUser -ModuleName JiraPS {
            $object = [PSCustomObject] @{
                'Name' = 'username'
            }
            $object.PSObject.TypeNames.Insert(0, 'JiraPS.User')
            return $object
        }

        Mock Get-JiraGroup -ModuleName JiraPS {
            Get-TestJiraGroup -GroupName $testGroupName
        }

        Mock Invoke-JiraMethod -ModuleName JiraPS -ParameterFilter { $Method -eq 'Get' -and $URI -like '*/rest/api/*/group/member' -and $GetParameter["groupname"] -eq "testgroup" } {
            ShowMockInfo 'Invoke-JiraMethod' 'Method', 'Uri'
            ConvertFrom-Json @'
{
"Name":  "testgroup",
"RestUrl":  "https://jira.example.com/rest/api/2/group?groupname=testgroup",
"Size":  2
}
'@
        }

        # If we don't override this in a context or test, we don't want it to
        # actually try to query a JIRA instance
        Mock Invoke-JiraMethod -ModuleName JiraPS {
            ShowMockInfo 'Invoke-JiraMethod' 'Method', 'Uri'
            throw "Unidentified call to Invoke-JiraMethod"
        }
        #endregion Mocks
    }

    Context "Sanity checking" {
        It "Has expected parameters" {
            $command = Get-Command -Name Get-JiraGroupMember

            defParam $command 'Group'
            defParam $command 'IncludeInactive'
            defParam $command 'StartIndex'
            defParam $command 'MaxResults'
            defParam $command 'Credential'
        }
    }

    Context "Behavior testing" {
        It "Obtains members about a provided group in JIRA" {
            { Get-JiraGroupMember -Group testgroup } | Should -Not -Throw

            $assertMockCalledSplat = @{
                CommandName     = 'Invoke-JiraMethod'
                ModuleName      = 'JiraPS'
                ParameterFilter = {
                    $Method -eq 'Get' -and
                    $URI -like '*/rest/api/*/group/member'
                }
                Scope           = 'It'
                Exactly         = $true
                Times           = 1
            }
            Should -Invoke @assertMockCalledSplat
        }

        It "Supports the -StartIndex parameters to page through search results" {
            { Get-JiraGroupMember -Group testgroup -StartIndex 10 } | Should -Not -Throw

            $assertMockCalledSplat = @{
                CommandName     = 'Invoke-JiraMethod'
                ModuleName      = 'JiraPS'
                ParameterFilter = {
                    $Method -eq 'Get' -and
                    $URI -like '*/rest/api/*/group/member' -and
                    $Skip -eq 10
                }
                Exactly         = $true
                Times           = 1
            }
            Should -Invoke @assertMockCalledSplat
        }

        It "Supports the -MaxResults parameters to page through search results" {
            { Get-JiraGroupMember -Group testgroup -MaxResults 50 } | Should -Not -Throw

            $assertMockCalledSplat = @{
                CommandName     = 'Invoke-JiraMethod'
                ModuleName      = 'JiraPS'
                ParameterFilter = {
                    $Method -eq 'Get' -and
                    $URI -like '*/rest/api/*/group/member' -and
                    $First -eq 50
                }
                Scope           = 'It'
                Exactly         = $true
                Times           = 1
            }
            Should -Invoke @assertMockCalledSplat
        }
    }

    Context "Input testing" {
        It "Accepts a group name for the -Group parameter" {
            { Get-JiraGroupMember -Group testgroup } | Should -Not -Throw

            $assertMockCalledSplat = @{
                CommandName     = 'Invoke-JiraMethod'
                ModuleName      = 'JiraPS'
                ParameterFilter = {
                    $Method -eq 'Get' -and
                    $URI -like '*/rest/api/*/group/member' -and
                    $GetParameter["groupname"] -eq "testgroup"
                }
                Scope           = 'It'
                Exactly         = $true
                Times           = 1
            }
            Should -Invoke @assertMockCalledSplat
        }

        It "Accepts a group object for the -InputObject parameter" {
            $group = Get-TestJiraGroup

            { Get-JiraGroupMember -Group $group } | Should -Not -Throw

            $assertMockCalledSplat = @{
                CommandName     = 'Invoke-JiraMethod'
                ModuleName      = 'JiraPS'
                ParameterFilter = {
                    $Method -eq 'Get' -and
                    $URI -like '*/rest/api/*/group/member' -and
                    $GetParameter["groupname"] -eq "testgroup"
                }
                Exactly         = $true
                Times           = 1
            }
            Should -Invoke @assertMockCalledSplat

            # We called Get-JiraGroup once manually, and it should be
            # called once by Get-JiraGroupMember.
            Should -Invoke -CommandName Get-JiraGroup -ModuleName JiraPS -Times 1 -Exactly
        }
    }

    AfterAll {
        Remove-Module $env:BHProjectName -ErrorAction SilentlyContinue
        Remove-Module BuildHelpers -ErrorAction SilentlyContinue
        Remove-Item -Path Env:\BH*
    }
}
