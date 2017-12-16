. $PSScriptRoot\Shared.ps1

InModuleScope JiraPS {
    [System.Diagnostics.CodeAnalysis.SuppressMessage('PSUseDeclaredVarsMoreThanAssigments', '', Scope = '*', Target = 'SuppressImportModule')]
    $SuppressImportModule = $true
    . $PSScriptRoot\Shared.ps1

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

    Describe "Set-JiraVersion" {
        #region Mock
        Mock Get-JiraConfigServer -ModuleName JiraPS {
            Write-Output $jiraServer
        }

        Mock Get-JiraProject -ModuleName JiraPS {
            $Projects = ConvertFrom-Json $JiraProjectData
            $Projects.PSObject.TypeNames.Insert(0, 'JiraPS.Project')
            $Projects | Where-Object {$_.Key -in $Project}
        }

        Mock Get-JiraVersion -ModuleName JiraPS {
            ConvertTo-JiraVersion -InputObject (ConvertFrom-Json $testJsonOne)
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

        Mock Invoke-JiraMethod -ModuleName JiraPS -ParameterFilter { $Method -eq 'Put' -and $URI -like "$jiraServer/rest/api/latest/version/$versionID" } {
            ShowMockInfo 'Invoke-JiraMethod' 'Method', 'Uri'
            ConvertFrom-Json2 $testJsonOne
        }

        # Generic catch-all. This will throw an exception if we forgot to mock something.
        Mock Invoke-JiraMethod -ModuleName JiraPS {
            ShowMockInfo 'Invoke-JiraMethod' 'Method', 'Uri'
            throw "Unidentified call to Invoke-JiraMethod"
        }
        #endregion Mock

        Context "Sanity checking" {
            $command = Get-Command -Name Set-JiraVersion

            defParam $command 'Version'
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
            It "sets an Issue's Version Name" {
                $version = Get-JiraVersion -Project $projectKey -Name $versionName
                $results = Set-JiraVersion -Version $version -Name "NewName" -ErrorAction Stop
                $results | Should Not BeNullOrEmpty
                checkType $results "JiraPS.Version"
                Assert-MockCalled 'Get-JiraVersion' -Times 1 -Scope It -ModuleName JiraPS -Exactly
                Assert-MockCalled 'Get-JiraProject' -Times 0 -Scope It -ModuleName JiraPS -Exactly
                Assert-MockCalled 'ConvertTo-JiraVersion' -Times 2 -Scope It -ModuleName JiraPS -Exactly
                Assert-MockCalled 'Invoke-JiraMethod' -Times 1 -Scope It -ModuleName JiraPS -Exactly -ParameterFilter { $Method -eq 'Put' -and $URI -like "$jiraServer/rest/api/latest/version/$versionID" }
            }
            It "sets an Issue's Version Name using the pipeline" {
                $results = Get-JiraVersion -Project $projectKey | Set-JiraVersion -Name "NewName" -ErrorAction Stop
                $results | Should Not BeNullOrEmpty
                checkType $results "JiraPS.Version"
                Assert-MockCalled 'Get-JiraVersion' -Times 1 -Scope It -ModuleName JiraPS -Exactly
                Assert-MockCalled 'Get-JiraProject' -Times 0 -Scope It -ModuleName JiraPS -Exactly
                Assert-MockCalled 'ConvertTo-JiraVersion' -Times 2 -Scope It -ModuleName JiraPS -Exactly
                Assert-MockCalled 'Invoke-JiraMethod' -Times 1 -Scope It -ModuleName JiraPS -Exactly -ParameterFilter { $Method -eq 'Put' -and $URI -like "$jiraServer/rest/api/latest/version/$versionID" }
            }
            It "assert VerifiableMock" {
                Assert-VerifiableMock
            }
        }
    }
}
