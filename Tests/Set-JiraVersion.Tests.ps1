. $PSScriptRoot\Shared.ps1

InModuleScope JiraPS {
    [System.Diagnostics.CodeAnalysis.SuppressMessage('PSUseDeclaredVarsMoreThanAssigments', '', Scope='*', Target='SuppressImportModule')]
    $SuppressImportModule = $true
    . $PSScriptRoot\Shared.ps1

    $jiraServer = 'http://jiraserver.example.com'
    $issueKey = 'LDD-4060'
    $Name = '1.0.0.0'
    
    $issueJson = @"
{
    "Key" : $issueKey
}
"@

    Describe "Set-JiraVersion" {
#region Mock
        Mock Get-JiraConfigServer -ModuleName JiraPS {
            Write-Output $jiraServer
        }
        Mock Get-JiraIssue -ModuleName JiraPS -ParameterFilter { $Method -eq 'Get' -and $URI -like "$jiraServer/rest/api/2/version/$ID" } {
            ConvertFrom-Json2 $issueJson
        }
        Mock Invoke-JiraMethod -ModuleName JiraPS -ParameterFilter { $Method -eq 'Get' -and $URI -like "$jiraServer/rest/api/2/version/$ID" } {
            ConvertFrom-Json2 $testJsonOne
        }
        Mock Invoke-JiraMethod -ModuleName JiraPS {
            Write-Host "       Mocked Invoke-JiraMethod with no parameter filter." -ForegroundColor DarkRed
            Write-Host "         [Method]         $Method" -ForegroundColor DarkRed
            Write-Host "         [URI]            $URI" -ForegroundColor DarkRed
            throw "Unidentified call to Invoke-JiraMethod"
        }
#endregion Mock
        Context "Sanity checking" {
            $command = Get-Command -Name Set-JiraVersion

            function defParam($name) {
                It "Has a -$name parameter" {
                    $command.Parameters.Item($name) | Should Not BeNullOrEmpty
                }
            }

            defParam 'Issue'
            defParam 'Name'
            defParam 'Credential'
        }
        Context "Behavior checking" {
            It "Sets an Issue's Version" {
                #$Results = Set-JiraVersion -Issue $IssueKey -Name $Name | Should Not Throw
                #Assert-MockCalled 'Invoke-JiraMethod' -Times 1 -Scope It -ModuleName JiraPS -Exactly -ParameterFilter { $Method -eq 'Get' -and $URI -like "$jiraServer/rest/api/2/version/$ID" }
            }
            
            It "Assert VerifiableMocks" {
                Assert-VerifiableMocks
            }
        }        
    }
}