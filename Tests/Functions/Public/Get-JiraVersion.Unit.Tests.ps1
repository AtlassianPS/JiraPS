#requires -modules @{ ModuleName = "Pester"; ModuleVersion = "6.2.0"; MaximumVersion = "6.999" }

BeforeDiscovery {
    . "$PSScriptRoot/../../Helpers/TestTools.ps1"

    $script:moduleToTest = Initialize-TestEnvironment
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

            Mock Get-JiraProjectOperation -ModuleName JiraPS {
                Write-MockDebugInfo 'Get-JiraProject'
                $json = ConvertFrom-Json $JiraProjectData
                $object = $json | Where-Object { $_.Key -in $Project }
                $object.PSObject.TypeNames.Insert(0, 'AtlassianPS.JiraPS.Project')
                return $object
            }

            Mock ConvertTo-JiraVersion -ModuleName JiraPS {
                Write-MockDebugInfo 'ConvertTo-JiraVersion'
                $result = New-Object -TypeName PSObject -Property @{
                    Id      = $InputObject.Id
                    Name    = $InputObject.name
                    Project = $InputObject.projectId
                }
                $result.PSObject.TypeNames.Insert(0, 'AtlassianPS.JiraPS.Version')
                $result
            }

            Mock Invoke-JiraMethod -ModuleName JiraPS -ParameterFilter { $Method -eq 'Get' -and $URI -like "/rest/api/2/version/$versionId1" } {
                Write-MockDebugInfo 'Invoke-JiraMethod' 'Method', 'Uri'
                ConvertFrom-Json $testJson1
            }

            Mock Invoke-JiraMethod -ModuleName JiraPS -ParameterFilter { $Method -eq 'Get' -and $URI -like "/rest/api/*/version/$versionId2" } {
                Write-MockDebugInfo 'Invoke-JiraMethod' 'Method', 'Uri'
                ConvertFrom-Json $testJson2
            }

            Mock Invoke-JiraMethod -ModuleName JiraPS -ParameterFilter { $Method -eq 'Get' -and $URI -like "/rest/api/*/version" } {
                Write-MockDebugInfo 'Invoke-JiraMethod' 'Method', 'Uri'
                ConvertFrom-Json $testJsonAll
            }

            Mock Invoke-JiraMethod -ModuleName JiraPS -ParameterFilter { $Method -eq 'Get' -and $URI -like "/rest/api/*/project/*/version" } {
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

            It 'gets versions from piped <shape> without resolving a project' -TestCases @(
                @{ shape = 'integer IDs' }
                @{ shape = 'string IDs' }
                @{ shape = 'typed versions' }
            ) {
                param($shape)

                $inputs = foreach ($versionId in $versionID1, $versionID2) {
                    switch ($shape) {
                        'integer IDs' { $versionId }
                        'string IDs' { [string]$versionId }
                        'typed versions' { [AtlassianPS.JiraPS.Version]@{ Id = "$versionId" } }
                    }
                }

                $results = @($inputs | Get-JiraVersion -ErrorAction Stop)

                $results.Id | Should -Be @($versionID1, $versionID2)
                Should -Invoke Get-JiraProjectOperation -ModuleName JiraPS -Times 0 -Exactly
                foreach ($versionId in $versionID1, $versionID2) {
                    Should -Invoke Invoke-JiraMethod -ModuleName JiraPS -Times 1 -Exactly -ParameterFilter {
                        $Method -eq 'Get' -and $URI -eq "/rest/api/2/version/$versionId"
                    }
                }
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

            It "rejects a name-only Version stub where an ID is required" {
                { [AtlassianPS.JiraPS.Version]::new('My Version') | Get-JiraVersion -ErrorAction Stop } |
                    Should -Throw '*version ID*'

                Should -Invoke Invoke-JiraMethod -ModuleName JiraPS -Times 0 -ParameterFilter {
                    $Method -eq 'Get' -and $URI -like '*/rest/api/*/version/*'
                }
            }

            It "gets all Versions using Project Parameter Set" {
                $results = Get-JiraVersion -Project $projectKey

                $results | Should -Not -BeNullOrEmpty

                Should -Invoke Invoke-JiraMethod -ModuleName JiraPS -ParameterFilter {
                    $Method -eq 'Get' -and
                    $URI -like "*/rest/api/*/project/$projectKey/version" -and
                    $Paging -eq $true
                } -Exactly 1

                Should -Invoke Get-JiraProjectOperation -ModuleName JiraPS -Exactly 1

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
                Should -Invoke Get-JiraProjectOperation -ModuleName JiraPS -Exactly 2

                Should -Invoke ConvertTo-JiraVersion -ModuleName JiraPS -Exactly 0
            }

            Context 'CLR project and version parameter binding' {
                BeforeAll {
                    Mock Get-JiraProjectOperation -ModuleName JiraPS -ParameterFilter {
                        $Project -eq $projectKey -or $Project -eq $projectId
                    } {
                        Write-MockDebugInfo 'Get-JiraProject' 'Project'
                        [AtlassianPS.JiraPS.Project]@{
                            Key = $projectKey
                            Id  = $projectId
                        }
                    }
                }

                It 'gets versions from a typed <identity> project using <binding>' -TestCases @(
                    @{ identity = 'keyed'; binding = 'pipeline' }
                    @{ identity = 'ID-only'; binding = 'pipeline' }
                    @{ identity = 'keyed'; binding = '-InputProject' }
                    @{ identity = 'ID-only'; binding = '-InputProject' }
                ) {
                    param($identity, $binding)

                    $typedProject = [AtlassianPS.JiraPS.Project]@{ Id = $projectId }
                    $expectedProject = $projectId
                    if ($identity -eq 'keyed') {
                        $typedProject.Key = $projectKey
                        $expectedProject = $projectKey
                    }

                    $results = if ($binding -eq 'pipeline') {
                        @($typedProject | Get-JiraVersion -ErrorAction Stop)
                    }
                    else {
                        @(Get-JiraVersion -InputProject $typedProject -ErrorAction Stop)
                    }

                    @($results).Count | Should -Be 3
                    $results.Id | Should -Be @($versionID1, $versionID2, $versionID3)
                    Should -Invoke Get-JiraProjectOperation -ModuleName JiraPS -Times 1 -Exactly -ParameterFilter {
                        $Project -eq $expectedProject
                    }
                    Should -Invoke Invoke-JiraMethod -ModuleName JiraPS -Times 1 -Exactly -ParameterFilter {
                        $Method -eq 'Get' -and $URI -eq "/rest/api/2/project/$projectKey/version" -and $Paging
                    }
                    Should -Invoke Invoke-JiraMethod -ModuleName JiraPS -Times 0 -Exactly -ParameterFilter {
                        $URI -like '/rest/api/*/version/*'
                    }
                    Should -Invoke Invoke-JiraMethod -ModuleName JiraPS -Times 1 -Exactly
                }

                It 'routes mixed typed <identity> project and version input with project first <projectFirst>' -TestCases @(
                    @{ identity = 'keyed'; projectFirst = $true }
                    @{ identity = 'keyed'; projectFirst = $false }
                    @{ identity = 'ID-only'; projectFirst = $true }
                    @{ identity = 'ID-only'; projectFirst = $false }
                ) {
                    param($identity, $projectFirst)

                    $typedProject = [AtlassianPS.JiraPS.Project]@{ Id = $projectId }
                    $expectedProject = $projectId
                    if ($identity -eq 'keyed') {
                        $typedProject.Key = $projectKey
                        $expectedProject = $projectKey
                    }
                    $typedVersion = [AtlassianPS.JiraPS.Version]@{ Id = "$versionID2" }

                    $inputs = if ($projectFirst) { @($typedProject, $typedVersion) }
                    else { @($typedVersion, $typedProject) }
                    $expectedIds = if ($projectFirst) { @($versionID1, $versionID2, $versionID3, $versionID2) }
                    else { @($versionID2, $versionID1, $versionID2, $versionID3) }

                    $results = @($inputs | Get-JiraVersion -ErrorAction Stop)

                    $results.Count | Should -Be 4
                    $results.Id | Should -Be $expectedIds
                    Should -Invoke Get-JiraProjectOperation -ModuleName JiraPS -Times 1 -Exactly -ParameterFilter {
                        $Project -eq $expectedProject
                    }
                    Should -Invoke Invoke-JiraMethod -ModuleName JiraPS -Times 1 -Exactly -ParameterFilter {
                        $Method -eq 'Get' -and $URI -eq "/rest/api/2/project/$projectKey/version" -and $Paging
                    }
                    Should -Invoke Invoke-JiraMethod -ModuleName JiraPS -Times 1 -Exactly -ParameterFilter {
                        $Method -eq 'Get' -and $URI -eq "/rest/api/2/version/$versionID2"
                    }
                    Should -Invoke Invoke-JiraMethod -ModuleName JiraPS -Times 2 -Exactly
                }
            }

            It "gets all Versions from multiple Projects" {
                $results = Get-JiraVersion -Project $projectKey, "foo"

                $results | Should -Not -BeNullOrEmpty

                Should -Invoke Invoke-JiraMethod -ModuleName JiraPS -ParameterFilter {
                    $Method -eq 'Get' -and
                    $URI -like "*/rest/api/*/project/*/version" -and
                    $Paging -eq $true
                } -Exactly 2

                Should -Invoke Get-JiraProjectOperation -ModuleName JiraPS -Exactly 2

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

                Should -Invoke Get-JiraProjectOperation -ModuleName JiraPS -Exactly 1

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

                Should -Invoke Get-JiraProjectOperation -ModuleName JiraPS -Exactly 1

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
