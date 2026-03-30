#requires -modules @{ ModuleName = "Pester"; ModuleVersion = "5.7"; MaximumVersion = "5.999" }

BeforeDiscovery {
    . "$PSScriptRoot/../../Helpers/TestTools.ps1"

    Initialize-TestEnvironment
    $script:moduleToTest = Resolve-ModuleSource

    Import-Module $script:moduleToTest -Force -ErrorAction Stop
}

InModuleScope JiraPS {
    Describe "Get-JiraVersion" -Tag 'Unit' {

        BeforeAll {
            . "$PSScriptRoot/../../Helpers/TestTools.ps1"
            # $VerbosePreference = 'Continue'  # Uncomment for mock debugging

            #region Definitions
            $script:jiraServer = 'http://jiraserver.example.com'
            $script:versionName1 = 'v1.0'
            $script:versionName2 = 'v2.0'
            $script:versionName3 = 'v3.0'
            $script:versionID1 = 16740
            $script:versionID2 = 16840
            $script:versionID3 = 16940
            $script:projectKey = 'LDD'
            $script:projectId = '12101'

            $script:JiraProjectData = @"
[
    {
        "Key" : "$projectKey",
        "id": "$projectId"
    },
    {
        "Key" : "foo",
        "id": "0"
    }
]
"@
            $script:testJson1 = @"
{
    "self" : "$jiraServer/rest/api/2/version/$versionID1",
    "id" : $versionID1,
    "description" : "$versionName1",
    "name" : "$versionName1",
    "archived" : "False",
    "released" : "False",
    "projectId" : "$projectId"
}
"@
            $script:testJson2 = @"
{
    "self" : "$jiraServer/rest/api/2/version/$versionID2",
    "id" : $versionID2,
    "description" : "$versionName2",
    "name" : "$versionName2",
    "archived" : "False",
    "released" : "False",
    "projectId" : "$projectId"
}
"@
            $script:testJsonAll = @"
[
    {
        "self" : "$jiraServer/rest/api/2/version/$versionID1",
        "id" : $versionID1,
        "description" : "$versionName1",
        "name" : "$versionName1",
        "archived" : "False",
        "released" : "False",
        "projectId" : "$projectId"
    },
    {
        "self" : "$jiraServer/rest/api/2/version/$versionID2",
        "id" : $versionID2,
        "description" : "$versionName2",
        "name" : "$versionName2",
        "archived" : "False",
        "released" : "False",
        "projectId" : "$projectId"
    },
    {
        "self" : "$jiraServer/rest/api/2/version/$versionID3",
        "id" : $versionID3,
        "description" : "$versionName3",
        "name" : "$versionName3",
        "archived" : "False",
        "released" : "False",
        "projectId" : "$projectId"
    }
]
"@
            #endregion Definitions

            #region Mocks
            Mock Get-JiraConfigServer -ModuleName JiraPS {
                Write-MockDebugInfo 'Get-JiraConfigServer'
                Write-Output $jiraServer
            }

            Mock Get-JiraProject -ModuleName JiraPS {
                Write-MockDebugInfo 'Get-JiraProject'
                $json = ConvertFrom-Json $JiraProjectData
                $object = $json | Where-Object { $_.Key -in $Project }
                $object.PSObject.TypeNames.Insert(0, 'JiraPS.Project')
                return $object
            }

            Mock ConvertTo-JiraVersion -ModuleName JiraPS {
                Write-MockDebugInfo 'ConvertTo-JiraVersion'
                $result = New-Object -TypeName PSObject -Property @{
                    Id      = $InputObject.Id
                    Name    = $InputObject.name
                    Project = $InputObject.projectId
                }
                $result.PSObject.TypeNames.Insert(0, 'JiraPS.Version')
                $result
            }

            Mock Invoke-JiraMethod -ModuleName JiraPS -ParameterFilter { $Method -eq 'Get' -and $URI -like "$jiraServer/rest/api/2/version/$versionId1" } {
                Write-MockDebugInfo 'Invoke-JiraMethod' 'Method', 'Uri'
                ConvertFrom-Json $testJson1
            }

            Mock Invoke-JiraMethod -ModuleName JiraPS -ParameterFilter { $Method -eq 'Get' -and $URI -like "$jiraServer/rest/api/*/version/$versionId2" } {
                Write-MockDebugInfo 'Invoke-JiraMethod' 'Method', 'Uri'
                ConvertFrom-Json $testJson2
            }

            Mock Invoke-JiraMethod -ModuleName JiraPS -ParameterFilter { $Method -eq 'Get' -and $URI -like "$jiraServer/rest/api/*/version" } {
                Write-MockDebugInfo 'Invoke-JiraMethod' 'Method', 'Uri'
                ConvertFrom-Json $testJsonAll
            }

            Mock Invoke-JiraMethod -ModuleName JiraPS -ParameterFilter { $Method -eq 'Get' -and $URI -like "$jiraServer/rest/api/*/project/*/version" } {
                Write-MockDebugInfo 'Invoke-JiraMethod' 'Method', 'Uri', 'Paging'
                ConvertFrom-Json $testJsonAll
            }

            # Generic catch-all. This will throw an exception if we forgot to mock something.
            Mock Invoke-JiraMethod -ModuleName JiraPS {
                Write-MockDebugInfo 'Invoke-JiraMethod' 'Method', 'Uri'
                throw "Unidentified call to Invoke-JiraMethod"
            }
            #endregion Mocks
        }

        Describe "Signature" {
            Context "Parameter Types" {
                # TODO: Add parameter type validation tests
            }

            Context "Mandatory Parameters" {}

            Context "Default Values" {}
        }

        Describe "Behavior" {

            It "gets a Version using Id Parameter Set" {
                $results = Get-JiraVersion -Id $versionID1

                $results | Should -Not -BeNullOrEmpty

                Should -Invoke Invoke-JiraMethod -ModuleName JiraPS -ParameterFilter {
                    $Method -eq 'Get' -and
                    $URI -like "*/rest/api/*/version/$versionID1"
                } -Exactly 1

                Should -Invoke ConvertTo-JiraVersion -ModuleName JiraPS -Exactly 1
            }

            It "gets a Version using multiple IDs" {
                $results = Get-JiraVersion -Id $versionID1, $versionID2

                $results | Should -Not -BeNullOrEmpty

                Should -Invoke Invoke-JiraMethod -ModuleName JiraPS -ParameterFilter {
                    $Method -eq 'Get' -and
                    $URI -like "*/rest/api/*/version/$versionID1"
                } -Exactly 1

                Should -Invoke Invoke-JiraMethod -ModuleName JiraPS -ParameterFilter {
                    $Method -eq 'Get' -and
                    $URI -like "*/rest/api/*/version/$versionID2"
                } -Exactly 1

                Should -Invoke ConvertTo-JiraVersion -ModuleName JiraPS -Exactly 2
            }

            It "gets a Version using the pipeline from another Version" {
                $version1 = ConvertTo-JiraVersion ([PSCustomObject]@{Id = [int]($versionID2) })
                $version2 = ConvertTo-JiraVersion ([PSCustomObject]@{Id = [int]($versionID2); project = "lorem" })

                $results1 = ($version1 | Get-JiraVersion)
                $results2 = ($version2 | Get-JiraVersion)
                $results1 | Should -Not -BeNullOrEmpty
                $results2 | Should -Not -BeNullOrEmpty

                Should -Invoke Invoke-JiraMethod -ModuleName JiraPS -ParameterFilter {
                    $Method -eq 'Get' -and
                    $URI -like "*/rest/api/*/version/$versionID2"
                } -Exactly 2

                Should -Invoke ConvertTo-JiraVersion -ModuleName JiraPS -Exactly 4
            }

            It "gets all Versions using Project Parameter Set" {
                $results = Get-JiraVersion -Project $projectKey

                $results | Should -Not -BeNullOrEmpty

                Should -Invoke Invoke-JiraMethod -ModuleName JiraPS -ParameterFilter {
                    $Method -eq 'Get' -and
                    $URI -like "*/rest/api/*/project/$projectKey/version" -and
                    $Paging -eq $true
                } -Exactly 1

                Should -Invoke Get-JiraProject -ModuleName JiraPS -Exactly 1

                Should -Invoke ConvertTo-JiraVersion -ModuleName JiraPS -Exactly 0
            }

            It "gets all Versions using Project as pipe input" {
                $results = Get-JiraProject -Project $projectKey | Get-JiraVersion

                $results | Should -Not -BeNullOrEmpty

                Should -Invoke Invoke-JiraMethod -ModuleName JiraPS -ParameterFilter {
                    $Method -eq 'Get' -and
                    $URI -like "*/rest/api/*/project/$projectKey/version" -and
                    $Paging -eq $true
                } -Exactly 1

                # Get-JiraProject is called once in the It block
                # and once in the `Get-JiraVersion`
                Should -Invoke Get-JiraProject -ModuleName JiraPS -Exactly 2

                Should -Invoke ConvertTo-JiraVersion -ModuleName JiraPS -Exactly 0
            }

            It "gets all Versions from multiple Projects" {
                $results = Get-JiraVersion -Project $projectKey, "foo"

                $results | Should -Not -BeNullOrEmpty

                Should -Invoke Invoke-JiraMethod -ModuleName JiraPS -ParameterFilter {
                    $Method -eq 'Get' -and
                    $URI -like "*/rest/api/*/project/*/version" -and
                    $Paging -eq $true
                } -Exactly 2

                Should -Invoke Get-JiraProject -ModuleName JiraPS -Exactly 2

                Should -Invoke ConvertTo-JiraVersion -ModuleName JiraPS -Exactly 0
            }

            It "filters the Versions from a Project by Name" {
                $results = Get-JiraVersion -Project $projectKey -Name $versionName1

                $results | Should -Not -BeNullOrEmpty

                Should -Invoke Invoke-JiraMethod -ModuleName JiraPS -ParameterFilter {
                    $Method -eq 'Get' -and
                    $URI -like "*/rest/api/*/project/*/version" -and
                    $Paging -eq $true
                } -Exactly 1

                Should -Invoke Get-JiraProject -ModuleName JiraPS -Exactly 1

                Should -Invoke ConvertTo-JiraVersion -ModuleName JiraPS -Exactly 0
            }

            It "filters the Versions from a Project by multiple Names" {
                $results = Get-JiraVersion -Project $projectKey -Name $versionName1, $versionName2

                $results | Should -Not -BeNullOrEmpty

                Should -Invoke Invoke-JiraMethod -ModuleName JiraPS -ParameterFilter {
                    $Method -eq 'Get' -and
                    $URI -like "*/rest/api/*/project/*/version" -and
                    $Paging -eq $true
                } -Exactly 1

                Should -Invoke Get-JiraProject -ModuleName JiraPS -Exactly 1

                Should -Invoke ConvertTo-JiraVersion -ModuleName JiraPS -Exactly 0
            }

            It "Supports the -Skip parameters to page through search results" {
                { Get-JiraVersion -Project $projectKey -Skip 10 } | Should -Not -Throw

                Should -Invoke Invoke-JiraMethod -ModuleName JiraPS -ParameterFilter {
                    $Method -eq 'Get' -and
                    $URI -like '*/rest/api/*/project/*/version' -and
                    $Paging -eq $true -and
                    $Skip -eq 10
                } -Exactly 1
            }

            It "Supports the -First parameters to page through search results" {
                { Get-JiraVersion -Project $projectKey -First 50 } | Should -Not -Throw

                Should -Invoke Invoke-JiraMethod -ModuleName JiraPS -ParameterFilter {
                    $Method -eq 'Get' -and
                    $URI -like '*/rest/api/*/project/*/version' -and
                    $Paging -eq $true -and
                    $First -eq 50
                } -Exactly 1
            }

            It "assert VerifiableMock" {
                # Assert-VerifiableMock removed in Pester v5
            }
        }

        Describe "Input Validation" {
            Context "Type Validation - Positive Cases" {}

            Context "Type Validation - Negative Cases" {}
        }
    }
}
