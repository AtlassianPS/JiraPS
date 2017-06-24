. $PSScriptRoot\Shared.ps1

InModuleScope PSJira {

    [System.Diagnostics.CodeAnalysis.SuppressMessage('PSUseDeclaredVarsMoreThanAssigments', '', Scope='*', Target='SuppressImportModule')]
    $SuppressImportModule = $true
    . $PSScriptRoot\Shared.ps1

    $jiraServer = 'http://jiraserver.example.com'

    $testFixVersion = '1.0.0.0'
    
    $testJiraProjectKey = 'LDD'
    
    $testJson = @"
{
    "name": "$testFixVersion",
    "description": "$testFixVersion",
    "self": "$jiraServer/rest/api/2/latest/version/16809",
    "id": "16809",
    "archived" : "False",
    "released" : "False",
    "projectId" : "12101"
}
"@

    $testJiraProject = @"
{
    "ID":  "12101",
    "Key":  "LDD"
}
"@



    Describe "New-JiraFixVersion" {

        # Mock Write-Debug {
        #     if ($ShowDebugData)
        #     {
        #         Write-Host -Object "[DEBUG] $Message" -ForegroundColor Yellow
        #     }
        # }

        Mock Get-JiraConfigServer -ModuleName PSJira {
            Write-Output $jiraServer
        }

        Mock Get-JiraProject -ModuleName PSJira {
            Write-Output $testJiraProject
        }

        Mock Invoke-JiraMethod -ModuleName PSJira -ParameterFilter {$Method -eq 'POST' -and $URI -eq "$jiraServer/rest/api/latest/Version"} {
            if ($ShowMockData)
            {
                Write-Host "       Mocked Invoke-JiraMethod with POST method" -ForegroundColor Cyan
                Write-Host "         [Method]         $Method" -ForegroundColor Cyan
                Write-Host "         [URI]            $URI" -ForegroundColor Cyan
            }
            ConvertFrom-Json2 $testJson
        }

        # Generic catch-all. This will throw an exception if we forgot to mock something.
        Mock Invoke-JiraMethod -ModuleName PSJira {
            Write-Host "       Mocked Invoke-JiraMethod with no parameter filter." -ForegroundColor DarkRed
            Write-Host "         [Method]         $Method" -ForegroundColor DarkRed
            Write-Host "         [URI]            $URI" -ForegroundColor DarkRed
            throw "Unidentified call to Invoke-JiraMethod"
        }

        #############
        # Tests
        #############

        It "Creates a FixVersion in JIRA and returns a result" {
            $newResult = New-JiraFixVersion -FixVersion $testFixVersion -Description $testFixVersion -Project $testJiraProjectKey
            $newResult | Should Not BeNullOrEmpty
        }
      
        It "Uses Invoke-JiraMethod to do blast off once" {
            Assert-MockCalled 'Invoke-JiraMethod' -Times 1
        }

        It "Uses Get-JiraProject once" {
            Assert-MockCalled 'Get-JiraProject' -Times 1
        }

        It "Assert VerifiableMocks" {
            Assert-VerifiableMocks 
        }
    }
}
