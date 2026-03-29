#requires -modules @{ ModuleName = "Pester"; ModuleVersion = "5.7"; MaximumVersion = "5.999" }

BeforeDiscovery {
    . "$PSScriptRoot/../../Helpers/TestTools.ps1"

    Initialize-TestEnvironment
    $script:moduleToTest = Resolve-ModuleSource

    Import-Module $script:moduleToTest -Force -ErrorAction Stop
}

InModuleScope JiraPS {
    Describe "Remove-JiraVersion" -Tag 'Unit' {

        BeforeAll {
            . "$PSScriptRoot/../../Helpers/TestTools.ps1"
            # $VerbosePreference = 'Continue'

            #region Definitions
            $script:jiraServer = 'http://jiraserver.example.com'
            $script:versionName = '$versionName'
            $script:versionID1 = 16840
            $script:versionID2 = 16940
            $script:projectKey = 'LDD'
            $script:projectId = '12101'

            $script:JiraProjectData = @"
[
    {
        "Key" : "$projectKey",
        "Id": "$projectId"
    },
    {
        "Key" : "foo",
        "Id": "99"
    }
]
"@
            #endregion Definitions

            #region Mocks
            Mock Get-JiraConfigServer -ModuleName JiraPS {
                Write-MockDebugInfo 'Get-JiraConfigServer'
                $jiraServer
            }

            Mock Get-JiraProject -ModuleName JiraPS {
                Write-MockDebugInfo 'Get-JiraProject' 'Project'
                $Projects = ConvertFrom-Json $JiraProjectData
                $Projects.PSObject.TypeNames.Insert(0, 'JiraPS.Project')
                $Projects | Where-Object { $_.Key -in $Project }
            }

            Mock Get-JiraVersion -ModuleName JiraPS {
                Write-MockDebugInfo 'Get-JiraVersion' 'Id'
                foreach ($_id in $Id) {
                    $Version = [PSCustomObject]@{
                        Id          = $_Id
                        Name        = "v1"
                        Description = "My Desccription"
                        Project     = (Get-JiraProject -Project $projectKey)
                        ReleaseDate = (Get-Date "2017-12-01")
                        StartDate   = (Get-Date "2017-01-01")
                        RestUrl     = "$jiraServer/rest/api/2/version/$_Id"
                    }
                    $Version.PSObject.TypeNames.Insert(0, 'JiraPS.Version')
                    $Version
                }
            }

            Mock ConvertTo-JiraVersion -ModuleName JiraPS {
                Write-MockDebugInfo 'ConvertTo-JiraVersion' 'InputObject'
                $result = New-Object -TypeName PSObject -Property @{
                    Id      = $InputObject.Id
                    Name    = $InputObject.name
                    Project = $InputObject.projectId
                    RestUrl = $InputObject.self
                }
                $result.PSObject.TypeNames.Insert(0, 'JiraPS.Version')
                $result
            }

            Mock Invoke-JiraMethod -ModuleName JiraPS -ParameterFilter { $Method -eq 'Delete' -and $URI -like "$jiraServer/rest/api/*/version/$versionID1" } {
                Write-MockDebugInfo 'Invoke-JiraMethod' 'Method', 'Uri'
            }

            Mock Invoke-JiraMethod -ModuleName JiraPS -ParameterFilter { $Method -eq 'Delete' -and $URI -like "$jiraServer/rest/api/*/version/$versionID2" } {
                Write-MockDebugInfo 'Invoke-JiraMethod' 'Method', 'Uri'
            }

            # Generic catch-all. This will throw an exception if we forgot to mock something.
            Mock Invoke-JiraMethod -ModuleName JiraPS {
                Write-MockDebugInfo 'Invoke-JiraMethod' 'Method', 'Uri'
                throw "Unidentified call to Invoke-JiraMethod"
            }
            #endregion Mocks
        }

        Describe "Signature" {
            BeforeAll {
                $script:command = Get-Command -Name Remove-JiraVersion
            }

            Context "Parameter Types" {
                It "has a parameter '<parameter>' of type '<type>'" -TestCases @(
                    @{ parameter = 'Version'; type = 'Object[]' }
                    @{ parameter = 'Credential'; type = 'PSCredential' }
                    @{ parameter = 'Force'; type = 'Switch' }
                ) {
                    param($parameter, $type)
                    $command | Should -HaveParameter $parameter -Type $type
                }
            }

            Context "Mandatory Parameters" {}

            Context "Default Values" {}
        }

        Describe "Behavior" {
            Context "Version Deletion" {
                It 'removes a Version using its ID' {
                    { Remove-JiraVersion -Version $versionID1 -Force -ErrorAction Stop } | Should -Not -Throw
                    Should -Invoke 'Get-JiraVersion' -Times 1 -Scope It -ModuleName JiraPS -Exactly
                    Should -Invoke 'Get-JiraProject' -Times 1 -Scope It -ModuleName JiraPS -Exactly
                    Should -Invoke 'Invoke-JiraMethod' -Times 1 -Scope It -ModuleName JiraPS -Exactly -ParameterFilter { $Method -eq 'Delete' -and $URI -like "$jiraServer/rest/api/2/version/$versionID1" }
                }

                It 'removes a Version using the Version Object' {
                    {
                        $version = Get-JiraVersion -Id $versionID1
                        Remove-JiraVersion $version -Force -ErrorAction Stop
                    } | Should -Not -Throw
                    Should -Invoke 'Get-JiraVersion' -Times 2 -Scope It -ModuleName JiraPS -Exactly
                    Should -Invoke 'Get-JiraProject' -Times 2 -Scope It -ModuleName JiraPS -Exactly
                    Should -Invoke 'Invoke-JiraMethod' -Times 1 -Scope It -ModuleName JiraPS -Exactly -ParameterFilter { $Method -eq 'Delete' -and $URI -like "$jiraServer/rest/api/2/version/$versionID1" }
                }

                It 'removes a Version using several Version Objects' {
                    {
                        $version = Get-JiraVersion -Id $versionID1, $versionID2
                        Remove-JiraVersion -Version $version -Force -ErrorAction Stop
                    } | Should -Not -Throw
                    Should -Invoke 'Get-JiraVersion' -Times 3 -Scope It -ModuleName JiraPS -Exactly
                    Should -Invoke 'Get-JiraProject' -Times 4 -Scope It -ModuleName JiraPS -Exactly
                    Should -Invoke 'Invoke-JiraMethod' -Times 1 -Scope It -ModuleName JiraPS -Exactly -ParameterFilter { $Method -eq 'Delete' -and $URI -like "$jiraServer/rest/api/2/version/$versionID1" }
                    Should -Invoke 'Invoke-JiraMethod' -Times 1 -Scope It -ModuleName JiraPS -Exactly -ParameterFilter { $Method -eq 'Delete' -and $URI -like "$jiraServer/rest/api/2/version/$versionID2" }
                }

                It 'removes a Version using Version as input over the pipeline' {
                    { Get-JiraVersion -Id $versionID1, $versionID2 | Remove-JiraVersion -Force -ErrorAction Stop } | Should -Not -Throw
                    Should -Invoke 'Get-JiraVersion' -Times 3 -Scope It -ModuleName JiraPS -Exactly
                    Should -Invoke 'Get-JiraProject' -Times 4 -Scope It -ModuleName JiraPS -Exactly
                    Should -Invoke 'Invoke-JiraMethod' -Times 1 -Scope It -ModuleName JiraPS -Exactly -ParameterFilter { $Method -eq 'Delete' -and $URI -like "$jiraServer/rest/api/2/version/$versionID1" }
                    Should -Invoke 'Invoke-JiraMethod' -Times 1 -Scope It -ModuleName JiraPS -Exactly -ParameterFilter { $Method -eq 'Delete' -and $URI -like "$jiraServer/rest/api/2/version/$versionID2" }
                }
            }
        }

        Describe "Input Validation" {
            Context "Type Validation - Positive Cases" {}

            Context "Type Validation - Negative Cases" {}
        }
    }
}
