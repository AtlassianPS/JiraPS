. $PSScriptRoot\Shared.ps1

InModuleScope JiraPS {
    [System.Diagnostics.CodeAnalysis.SuppressMessage('PSUseDeclaredVarsMoreThanAssigments', '', Scope='*', Target='SuppressImportModule')]
    $SuppressImportModule = $true
    . $PSScriptRoot\Shared.ps1

    $ProjectName = 'LDD'
    $jiraServer = 'http://jiraserver.example.com'
    $Name = '1.0.0.0'
    $ID = '16840'

    $JiraProjectData = @"
    {
        "Key" : "LDD"
    }
"@
    $testJsonOne = @"
    {
        "self" : "$jiraServer/rest/api/2/version/16840",
        "id" : 16840,
        "description" : "1.0.0.0",
        "name" : "1.0.0.0",
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

        Mock Get-JiraProject -ModuleName JiraPS {
            ConvertFrom-Json2 $JiraProjectData
        }

        Mock Invoke-JiraMethod -ModuleName JiraPS -ParameterFilter { $Method -eq 'Get' -and $URI -like "$jiraServer/rest/api/2/project/$ProjectName/versions" } {
            ConvertFrom-Json2 $testJsonOne
        }

        Mock Invoke-JiraMethod -ModuleName JiraPS -ParameterFilter { $Method -eq 'Delete' -and $URI -like "$jiraServer/rest/api/2/version/$ID" } {
        }        
        
        Mock Invoke-JiraMethod -ModuleName JiraPS -ParameterFilter { $Method -eq 'Delete' -and $URI -like "$jiraServer/rest/api/2/version/16840" } {
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

            function defParam($name) {
                It "Has a -$name parameter" {
                    $command.Parameters.Item($name) | Should Not BeNullOrEmpty
                }
            }

            defParam 'Name'
            defParam 'Description'
            defParam 'Archived'
            defParam 'Released'
            defParam 'ReleaseDate'
            defParam 'UserReleaseDate'
            defParam 'Project'
            defParam 'Credential'
        }

        Context "Behavior checking" {
            It "Creates a Version using Release Parameter Set" {
                #$results = New-JiraVersion -ID $ID
                #$results | Should BeNullOrEmpty
                #Assert-MockCalled 'Invoke-JiraMethod' -Times 1 -Scope It -ModuleName JiraPS -Exactly -ParameterFilter { $Method -eq 'Delete' -and $URI -like "$jiraServer/rest/api/2/version/$ID" }
            }

            It "Assert VerifiableMocks" {
                Assert-VerifiableMocks
            }
        }
    }
}