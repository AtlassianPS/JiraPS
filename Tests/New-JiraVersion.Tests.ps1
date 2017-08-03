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

    Describe "New-JiraVersion" {
        #region Mock
        Mock Get-JiraConfigServer -ModuleName JiraPS {
            Write-Output $jiraServer
        }

        Mock Get-JiraProject -Project $Project -ModuleName JiraPS {
            $Projects = ConvertFrom-Json2 $JiraProjectData
            $Projects.PSObject.TypeNames.Insert(0, 'JiraPS.Project')
            $Projects | Where-Object {$_.Key -in $Project}
        }

        Mock Get-JiraVersion -ModuleName JiraPS {
            $Version = [PSCustomObject]@{
                Name        = "v1"
                Description = "My Desccription"
                Project     = (Get-JiraProject -Project $projectKey)
                ReleaseDate = (Get-Date "2017-12-01")
                StartDate   = (Get-Date "2017-01-01")
            }
            $Version.PSObject.TypeNames.Insert(0, 'JiraPS.Version')
            $Version
        }

        Mock ConvertTo-JiraVersion -InputObject $InoutObject -ModuleName JiraPS {
            $result = New-Object -TypeName PSObject -Property @{
                Id      = $InputObject.Id
                Name    = $InputObject.name
                Project = $InputObject.projectId
            }
            $result.PSObject.TypeNames.Insert(0, 'JiraPS.Version')
            $result
        }

        Mock Invoke-JiraMethod -ModuleName JiraPS -ParameterFilter { $Method -eq 'Post' -and $URI -like "$jiraServer/rest/api/latest/version" } {
            ConvertFrom-Json2 $testJsonOne
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
                ($result = { $version | New-JiraVersion }) | Should Not Throw
                $results | Should BeNullOrEmpty
                Assert-MockCalled 'Invoke-JiraMethod' -Times 1 -Scope It -ModuleName JiraPS -Exactly -ParameterFilter { $Method -eq 'Post' -and $URI -like "$jiraServer/rest/api/latest/version" }
                Assert-MockCalled 'ConvertTo-JiraVersion' -Times 1 -Scope It -ModuleName JiraPS -Exactly
            }
            It "creates a Version using parameters" {
                ($result = { New-JiraVersion -Name $versionName -Project $projectKey }) | Should Not Throw
                $results | Should BeNullOrEmpty
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
                ($result = { New-JiraVersion @splat }) | Should Not Throw
                $results | Should BeNullOrEmpty
                Assert-MockCalled 'Invoke-JiraMethod' -Times 1 -Scope It -ModuleName JiraPS -Exactly -ParameterFilter { $Method -eq 'Post' -and $URI -like "$jiraServer/rest/api/latest/version" }
                Assert-MockCalled 'ConvertTo-JiraVersion' -Times 1 -Scope It -ModuleName JiraPS -Exactly
            }

            It "assert VerifiableMocks" {
                Assert-VerifiableMocks
            }
        }
    }
}
