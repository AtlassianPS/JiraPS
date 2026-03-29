#requires -modules @{ ModuleName = "Pester"; ModuleVersion = "5.7"; MaximumVersion = "5.999" }

BeforeDiscovery {
    . "$PSScriptRoot/../../Helpers/TestTools.ps1"

    Initialize-TestEnvironment
    $script:moduleToTest = Resolve-ModuleSource

    Import-Module $script:moduleToTest -Force -ErrorAction Stop
}

InModuleScope JiraPS {
    Describe "Set-JiraVersion" -Tag 'Unit' {

        BeforeAll {
            . "$PSScriptRoot/../../Helpers/TestTools.ps1"
            # $VerbosePreference = 'Continue'

            #region Definitions
            $script:jiraServer = 'http://jiraserver.example.com'
            $script:versionName = '1.0.0.0'
            $script:versionID = '16840'
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
            $script:testJsonOne = @"
{
    "self" : "$jiraServer/rest/api/2/version/$versionID",
    "id" : $versionID,
    "description" : "$versionName",
    "name" : "$versionName",
    "archived" : "False",
    "released" : "False",
    "projectId" : "12101"
}
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
                Write-MockDebugInfo 'Get-JiraVersion' 'Project', 'Name'
                ConvertTo-JiraVersion -InputObject (ConvertFrom-Json $testJsonOne)
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

            Mock Invoke-JiraMethod -ModuleName JiraPS -ParameterFilter { $Method -eq 'Put' -and $URI -like "$jiraServer/rest/api/*/version/$versionID" } {
                Write-MockDebugInfo 'Invoke-JiraMethod' 'Method', 'Uri'
                ConvertFrom-Json $testJsonOne
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
                $script:command = Get-Command -Name Set-JiraVersion
            }

            Context "Parameter Types" {
                It "has a parameter '<parameter>' of type '<type>'" -TestCases @(
                    @{ parameter = 'Version'; type = 'Object[]' }
                    @{ parameter = 'Name'; type = 'String' }
                    @{ parameter = 'Description'; type = 'String' }
                    @{ parameter = 'Archived'; type = 'Boolean' }
                    @{ parameter = 'Released'; type = 'Boolean' }
                    @{ parameter = 'ReleaseDate'; type = 'DateTime' }
                    @{ parameter = 'StartDate'; type = 'DateTime' }
                    @{ parameter = 'Project'; type = 'Object' }
                    @{ parameter = 'Credential'; type = 'PSCredential' }
                ) {
                    param($parameter, $type)
                    $command | Should -HaveParameter $parameter -Type $type
                }
            }

            Context "Mandatory Parameters" {}

            Context "Default Values" {}
        }

        Describe "Behavior" {
            Context "Version Update" {
                It "sets an Issue's Version Name" {
                    $version = Get-JiraVersion -Project $projectKey -Name $versionName
                    $results = Set-JiraVersion -Version $version -Name "NewName" -ErrorAction Stop
                    $results | Should -Not -BeNullOrEmpty
                    $results.PSObject.TypeNames[0] | Should -Be 'JiraPS.Version'
                    Should -Invoke 'Get-JiraVersion' -Times 2 -Scope It -ModuleName JiraPS -Exactly
                    Should -Invoke 'Get-JiraProject' -Times 0 -Scope It -ModuleName JiraPS -Exactly
                    Should -Invoke 'ConvertTo-JiraVersion' -Times 3 -Scope It -ModuleName JiraPS -Exactly
                    Should -Invoke 'Invoke-JiraMethod' -Times 1 -Scope It -ModuleName JiraPS -Exactly -ParameterFilter { $Method -eq 'Put' -and $URI -like "$jiraServer/rest/api/*/version/$versionID" }
                }

                It "sets an Issue's Version Name using the pipeline" {
                    $results = Get-JiraVersion -Project $projectKey | Set-JiraVersion -Name "NewName" -ErrorAction Stop
                    $results | Should -Not -BeNullOrEmpty
                    $results.PSObject.TypeNames[0] | Should -Be 'JiraPS.Version'
                    Should -Invoke 'Get-JiraVersion' -Times 2 -Scope It -ModuleName JiraPS -Exactly
                    Should -Invoke 'Get-JiraProject' -Times 0 -Scope It -ModuleName JiraPS -Exactly
                    Should -Invoke 'ConvertTo-JiraVersion' -Times 3 -Scope It -ModuleName JiraPS -Exactly
                    Should -Invoke 'Invoke-JiraMethod' -Times 1 -Scope It -ModuleName JiraPS -Exactly -ParameterFilter { $Method -eq 'Put' -and $URI -like "$jiraServer/rest/api/*/version/$versionID" }
                }
            }
        }

        Describe "Input Validation" {
            Context "Type Validation - Positive Cases" {}

            Context "Type Validation - Negative Cases" {}
        }
    }
}
