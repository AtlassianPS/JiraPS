#requires -modules BuildHelpers
#requires -modules @{ ModuleName = "Pester"; ModuleVersion = "4.4.0" }

Describe "New-JiraVersion" -Tag 'Unit' {

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
    }
    AfterAll {
        Remove-Module $env:BHProjectName -ErrorAction SilentlyContinue
        Remove-Module BuildHelpers -ErrorAction SilentlyContinue
        Remove-Item -Path Env:\BH*
    }

    InModuleScope JiraPS {

        . "$PSScriptRoot/../Shared.ps1"

        $jiraServer = 'http://jiraserver.example.com'
        $versionName = '1.0.0.0'
        $versionID = '16840'
        $projectKey = 'LDD'
        $projectId = '12101'

        $JiraProjectData = @"
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
        $testJsonOne = @"
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

        #region Mock
        Mock Get-JiraConfigServer -ModuleName JiraPS {
            Write-Output $jiraServer
        }

        Mock Get-JiraProject -ModuleName JiraPS {
            $Projects = ConvertFrom-Json $JiraProjectData
            $Projects | ForEach-Object { $_.PSObject.TypeNames.Insert(0, 'JiraPS.Project') }
            $Projects | Where-Object {$_.Key -in $projectKey}
        }

        Mock Get-JiraVersion -ModuleName JiraPS {
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
            ShowMockInfo 'Invoke-JiraMethod' 'Method', 'Uri'
            ConvertFrom-Json $testJsonOne
        }

        # Generic catch-all. This will throw an exception if we forgot to mock something.
        Mock Invoke-JiraMethod -ModuleName JiraPS {
            ShowMockInfo 'Invoke-JiraMethod' 'Method', 'Uri'
            throw "Unidentified call to Invoke-JiraMethod"
        }
        #endregion Mock

        Context "Sanity checking" {
            $command = Get-Command -Name New-JiraVersion

            defParam $command 'InputObject'
            defParam $command 'Name'
            defParam $command 'Description'
            defParam $command 'Archived'
            defParam $command 'Released'
            defParam $command 'ReleaseDate'
            defParam $command 'StartDate'
            defParam $command 'Project'
            defParam $command 'Credential'
        }

        Context "Behavior checking" {
            It "creates a Version from a Version Object" {
                $version = Get-JiraVersion -Project $projectKey
                $results = $version | New-JiraVersion -ErrorAction Stop
                $results | Should Not BeNullOrEmpty
                checkType $results "JiraPS.Version"
                Assert-MockCalled 'Invoke-JiraMethod' -Times 1 -Scope It -ModuleName JiraPS -Exactly -ParameterFilter { $Method -eq 'Post' -and $URI -like "$jiraServer/rest/api/latest/version" }
                Assert-MockCalled 'ConvertTo-JiraVersion' -Times 1 -Scope It -ModuleName JiraPS -Exactly
            }
            It "creates a Version using parameters" {
                $results = New-JiraVersion -Name $versionName -Project $projectKey -ErrorAction Stop
                $results | Should Not BeNullOrEmpty
                checkType $results "JiraPS.Version"
                Assert-MockCalled 'Invoke-JiraMethod' -Times 1 -Scope It -ModuleName JiraPS -Exactly -ParameterFilter { $Method -eq 'Post' -and $URI -like "$jiraServer/rest/api/latest/version" }
                Assert-MockCalled 'ConvertTo-JiraVersion' -Times 1 -Scope It -ModuleName JiraPS -Exactly
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
                $results | Should Not BeNullOrEmpty
                checkType $results "JiraPS.Version"
                Assert-MockCalled 'Invoke-JiraMethod' -Times 1 -Scope It -ModuleName JiraPS -Exactly -ParameterFilter { $Method -eq 'Post' -and $URI -like "$jiraServer/rest/api/latest/version" }
                Assert-MockCalled 'ConvertTo-JiraVersion' -Times 1 -Scope It -ModuleName JiraPS -Exactly
            }

            It "assert VerifiableMock" {
                Assert-VerifiableMock
            }
        }
    }
}
