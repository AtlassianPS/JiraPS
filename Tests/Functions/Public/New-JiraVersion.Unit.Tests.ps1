#requires -modules @{ ModuleName = "Pester"; ModuleVersion = "5.7"; MaximumVersion = "5.999" }
[System.Diagnostics.CodeAnalysis.SuppressMessage('PSAvoidUsingConvertToSecureStringWithPlainText', '')]
param()

BeforeDiscovery {
    . "$PSScriptRoot/../../Helpers/TestTools.ps1"

    Initialize-TestEnvironment
    $script:moduleToTest = Resolve-ModuleSource

    Import-Module $script:moduleToTest -Force -ErrorAction Stop
}

InModuleScope JiraPS {
    Describe "New-JiraVersion" -Tag 'Unit' {
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
                Write-MockDebugInfo 'Get-JiraProject'
                $Projects = ConvertFrom-Json $JiraProjectData
                $Projects | ForEach-Object { $_.PSObject.TypeNames.Insert(0, 'JiraPS.Project') }
                $Projects | Where-Object { $_.Key -in $projectKey }
            }

            Mock Get-JiraVersion -ModuleName JiraPS {
                Write-MockDebugInfo 'Get-JiraVersion'
                $Version = [PSCustomObject]@{
                    Name        = "v1"
                    Description = "My Desccription"
                    Project     = (Get-JiraProject -Project $projectKey)
                    ReleaseDate = (Get-Date "2017-12-01")
                    StartDate   = (Get-Date "2017-01-01")
                    RestUrl     = "$jiraServer/rest/api/2/version/$versionID"
                }
                $Version.PSObject.TypeNames.Insert(0, 'JiraPS.Version')
                $Version
            }

            Mock ConvertTo-JiraVersion -ModuleName JiraPS {
                Write-MockDebugInfo 'ConvertTo-JiraVersion'
                $result = New-Object -TypeName PSObject -Property @{
                    Id      = $InputObject.Id
                    Name    = $InputObject.name
                    Project = $InputObject.projectId
                    self    = "$jiraServer/rest/api/2/version/$($InputObject.self)"
                }
                $result.PSObject.TypeNames.Insert(0, 'JiraPS.Version')
                $result
            }

            Mock Invoke-JiraMethod -ModuleName JiraPS -ParameterFilter { $Method -eq 'Post' -and $URI -like "$jiraServer/rest/api/*/version" } {
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
                $script:command = Get-Command -Name New-JiraVersion
            }

            Context "Parameter Types" {
                It "has a parameter '<parameter>' of type '<type>'" -TestCases @(
                    @{ parameter = 'InputObject'; type = 'Object' }
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
                    $command | Should -HaveParameter $parameter
                    $command.Parameters[$parameter].ParameterType.Name | Should -Be $type
                }
            }

            Context "Mandatory Parameters" {}

            Context "Default Values" {}
        }

        Describe "Behavior" {
            It "creates a Version from a Version Object" {
                $version = Get-JiraVersion -Project $projectKey
                $results = $version | New-JiraVersion -ErrorAction Stop
                $results | Should -Not -BeNullOrEmpty
                $results.PSObject.TypeNames[0] | Should -Be "JiraPS.Version"
                Should -Invoke 'Invoke-JiraMethod' -Times 1 -Exactly -ModuleName JiraPS -ParameterFilter { $Method -eq 'Post' -and $URI -like "$jiraServer/rest/api/2/version" }
                Should -Invoke 'ConvertTo-JiraVersion' -Times 1 -Exactly -ModuleName JiraPS
            }
            It "creates a Version using parameters" {
                $results = New-JiraVersion -Name $versionName -Project $projectKey -ErrorAction Stop
                $results | Should -Not -BeNullOrEmpty
                $results.PSObject.TypeNames[0] | Should -Be "JiraPS.Version"
                Should -Invoke 'Invoke-JiraMethod' -Times 1 -Exactly -ModuleName JiraPS -ParameterFilter { $Method -eq 'Post' -and $URI -like "$jiraServer/rest/api/2/version" }
                Should -Invoke 'ConvertTo-JiraVersion' -Times 1 -Exactly -ModuleName JiraPS
            }
            It "creates a Version using splatting" {
                $password = (ConvertTo-SecureString -AsPlainText -Force -String "password")
                $credentials = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList ("username", $password)
                $splat = @{
                    Name        = "v1"
                    Description = "A Description"
                    Archived    = $false
                    Released    = $true
                    ReleaseDate = "2017-12-01"
                    StartDate   = "2017-01-01"
                    Project     = (Get-JiraProject -Project $projectKey)
                    Credential  = $credentials
                }
                $results = New-JiraVersion @splat -ErrorAction Stop
                $results | Should -Not -BeNullOrEmpty
                $results.PSObject.TypeNames[0] | Should -Be "JiraPS.Version"
                Should -Invoke 'Invoke-JiraMethod' -Times 1 -Exactly -ModuleName JiraPS -ParameterFilter { $Method -eq 'Post' -and $URI -like "$jiraServer/rest/api/2/version" }
                Should -Invoke 'ConvertTo-JiraVersion' -Times 1 -Exactly -ModuleName JiraPS
            }
        }

        Describe "Input Validation" {
            Context "Type Validation - Positive Cases" {}

            Context "Type Validation - Negative Cases" {}
        }
    }
}
