. $PSScriptRoot\Shared.ps1

InModuleScope JiraPS {
    [System.Diagnostics.CodeAnalysis.SuppressMessage('PSUseDeclaredVarsMoreThanAssigments', '', Scope = '*', Target = 'SuppressImportModule')]
    $SuppressImportModule = $true
    . $PSScriptRoot\Shared.ps1

    $jiraServer = 'http://jiraserver.example.com'
    $versionName1 = '1.0.0.0'
    $versionName2 = '2.0.0.0'
    $versionName3 = '3.0.0.0'
    $versionID1 = 16740
    $versionID2 = 16840
    $versionID3 = 16940
    $projectKey = 'LDD'
    $projectId = '12101'

    $JiraProjectData = @"
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
    $testJson1 = @"
{
    "self" : "$jiraServer/rest/api/latest/version/$versionID1",
    "id" : $versionID1,
    "description" : "$versionName1",
    "name" : "$versionName1",
    "archived" : "False",
    "released" : "False",
    "projectId" : "$projectId"
}
"@
    $testJson2 = @"
{
    "self" : "$jiraServer/rest/api/latest/version/$versionID2",
    "id" : $versionID2,
    "description" : "$versionName2",
    "name" : "$versionName2",
    "archived" : "False",
    "released" : "False",
    "projectId" : "$projectId"
}
"@
    $testJsonAll = @"
[
    {
        "self" : "$jiraServer/rest/api/latest/version/$versionID1",
        "id" : $versionID1,
        "description" : "$versionName1",
        "name" : "$versionName1",
        "archived" : "False",
        "released" : "False",
        "projectId" : "$projectId"
    },
    {
        "self" : "$jiraServer/rest/api/latest/version/$versionID2",
        "id" : $versionID2,
        "description" : "$versionName2",
        "name" : "$versionName2",
        "archived" : "False",
        "released" : "False",
        "projectId" : "$projectId"
    },
    {
        "self" : "$jiraServer/rest/api/latest/version/$versionID3",
        "id" : $versionID3,
        "description" : "$versionName2",
        "name" : "$versionName2",
        "archived" : "False",
        "released" : "False",
        "projectId" : "$projectId"
    }
}
"@

    Describe "Get-JiraVersion" {
        #region Mock
        Mock Get-JiraConfigServer -ModuleName JiraPS {
            Write-Output $jiraServer
        }

        Mock Get-JiraProject -ModuleName JiraPS {
            ConvertFrom-Json2 $JiraProjectData | Where-Object {$_.Key -in $Project}
        }

        Mock ConvertTo-JiraVersion -ModuleName JiraPS {
            $result = New-Object -TypeName PSObject -Property @{
                Id      = $InputObject.Id
                Name    = $InputObject.name
                Project = $InputObject.projectId
            }
            $result.PSObject.TypeNames.Insert(0, 'JiraPS.Version')
            $result
        }

        Mock Invoke-JiraMethod -ModuleName JiraPS -ParameterFilter { $Method -eq 'Get' -and $URI -like "$jiraServer/rest/api/latest/version/$versionId1" } {
            ConvertFrom-Json2 $testJson1
        }

        Mock Invoke-JiraMethod -ModuleName JiraPS -ParameterFilter { $Method -eq 'Get' -and $URI -like "$jiraServer/rest/api/latest/version/$versionId2" } {
            ConvertFrom-Json2 $testJson2
        }

        Mock Invoke-JiraMethod -ModuleName JiraPS -ParameterFilter { $Method -eq 'Get' -and $URI -like "$jiraServer/rest/api/latest/version" } {
            ConvertFrom-Json2 $testJsonAll
        }

        Mock Invoke-JiraMethod -ModuleName JiraPS -ParameterFilter { $Method -eq 'Get' -and $URI -like "$jiraServer/rest/api/latest/project/*/versions" } {
            ConvertFrom-Json2 $testJson1
        }

        # Generic catch-all. This will throw an exception if we forgot to mock something.
        Mock Invoke-JiraMethod -ModuleName JiraPS {
            Write-Host "       Mocked Invoke-JiraMethod with no parameter filter." -ForegroundColor DarkRed
            Write-Host "         [Method]         $Method" -ForegroundColor DarkRed
            Write-Host "         [URI]            $URI" -ForegroundColor DarkRed
            throw "Unidentified call to Invoke-JiraMethod"
        }
        #endregion Mock

        Context "Sanity checking" {
            $command = Get-Command -Name Get-JiraVersion

            defParam $command 'Project'
            defParam $command 'Name'
            defParam $command 'ID'
            defParam $command 'Credential'
        }

        Context "Behavior checking" {
            It "gets a Version using Id Parameter Set" {
                $results = Get-JiraVersion -Id $versionID1
                $results | Should Not BeNullOrEmpty
                Assert-MockCalled 'Invoke-JiraMethod' -Times 1 -Scope It -ModuleName JiraPS -Exactly -ParameterFilter { $Method -eq 'Get' -and $URI -like "$jiraServer/rest/api/latest/version/$versionID1" }
                Assert-MockCalled 'ConvertTo-JiraVersion' -Times 1 -Scope It -ModuleName JiraPS -Exactly
            }
            It "gets a Version using multiple IDs" {
                $results = Get-JiraVersion -ID $versionID1, $versionID2
                $results | Should Not BeNullOrEmpty
                Assert-MockCalled 'Invoke-JiraMethod' -Times 1 -Scope It -ModuleName JiraPS -Exactly -ParameterFilter { $Method -eq 'Get' -and $URI -like "$jiraServer/rest/api/latest/version/$versionID1" }
                Assert-MockCalled 'Invoke-JiraMethod' -Times 1 -Scope It -ModuleName JiraPS -Exactly -ParameterFilter { $Method -eq 'Get' -and $URI -like "$jiraServer/rest/api/latest/version/$versionID2" }
                Assert-MockCalled 'ConvertTo-JiraVersion' -Times 2 -Scope It -ModuleName JiraPS -Exactly
            }
            It "gets a Version using the pipeline from another Version" {
                $version = [PSCustomObject]@{Id = [int]($versionID2)}
                $results = ($version | Get-JiraVersion)
                $results | Should Not BeNullOrEmpty
                Assert-MockCalled 'Invoke-JiraMethod' -Times 1 -Scope It -ModuleName JiraPS -Exactly -ParameterFilter { $Method -eq 'Get' -and $URI -like "$jiraServer/rest/api/latest/version/$versionID2" }
                Assert-MockCalled 'ConvertTo-JiraVersion' -Times 1 -Scope It -ModuleName JiraPS -Exactly
            }
            It "gets all Versions using Project Parameter Set" {
                $results = Get-JiraVersion -Project $projectKey
                $results | Should Not BeNullOrEmpty
                Assert-MockCalled 'Invoke-JiraMethod' -Times 1 -Scope It -ModuleName JiraPS -Exactly -ParameterFilter { $Method -eq 'Get' -and $URI -like "$jiraServer/rest/api/latest/project/$projectKey/versions" }
                Assert-MockCalled 'Get-JiraProject' -Times 1 -Scope It -ModuleName JiraPS
                Assert-MockCalled 'ConvertTo-JiraVersion' -Times 1 -Scope It -ModuleName JiraPS -Exactly
            }
            It "gets all Versions using Project as pipe input" {
                $results = Get-JiraProject -Project $projectKey | Get-JiraVersion
                $results | Should Not BeNullOrEmpty
                Assert-MockCalled 'Invoke-JiraMethod' -Times 1 -Scope It -ModuleName JiraPS -Exactly -ParameterFilter { $Method -eq 'Get' -and $URI -like "$jiraServer/rest/api/latest/project/$projectKey/versions" }
                Assert-MockCalled 'Get-JiraProject' -Times 1 -Scope It -ModuleName JiraPS
                Assert-MockCalled 'ConvertTo-JiraVersion' -Times 1 -Scope It -ModuleName JiraPS -Exactly
            }
            It "gets all Versions from multiple Projects" {
                $results = Get-JiraVersion -Project $projectKey, "foo"
                $results | Should Not BeNullOrEmpty
                Assert-MockCalled 'Invoke-JiraMethod' -Times 2 -Scope It -ModuleName JiraPS -Exactly -ParameterFilter { $Method -eq 'Get' -and $URI -like "$jiraServer/rest/api/latest/project/*/versions" }
                Assert-MockCalled 'Get-JiraProject' -Times 2 -Scope It -ModuleName JiraPS
                Assert-MockCalled 'ConvertTo-JiraVersion' -Times 2 -Scope It -ModuleName JiraPS -Exactly
            }
            It "filters the Versions from a Project by Name" {
                $results = Get-JiraVersion -Project $projectKey -Name $versionName1
                $results | Should Not BeNullOrEmpty
                Assert-MockCalled 'Invoke-JiraMethod' -Times 1 -Scope It -ModuleName JiraPS -Exactly -ParameterFilter { $Method -eq 'Get' -and $URI -like "$jiraServer/rest/api/latest/project/$projectKey/versions" }
                Assert-MockCalled 'Get-JiraProject' -Times 1 -Scope It -ModuleName JiraPS
                Assert-MockCalled 'ConvertTo-JiraVersion' -Times 1 -Scope It -ModuleName JiraPS -Exactly
            }
            It "filters the Versions from a Project by multiple Names" {
                $results = Get-JiraVersion -Project $projectKey -Name $versionName1, $versionName2
                $results | Should Not BeNullOrEmpty
                Assert-MockCalled 'Invoke-JiraMethod' -Times 1 -Scope It -ModuleName JiraPS -Exactly -ParameterFilter { $Method -eq 'Get' -and $URI -like "$jiraServer/rest/api/latest/project/$projectKey/versions" }
                Assert-MockCalled 'Get-JiraProject' -Times 1 -Scope It -ModuleName JiraPS
                Assert-MockCalled 'ConvertTo-JiraVersion' -Times 1 -Scope It -ModuleName JiraPS -Exactly
            }
            It "assert VerifiableMock" {
                Assert-VerifiableMock
            }
        }
    }
}
