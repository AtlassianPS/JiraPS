. $PSScriptRoot\Shared.ps1

InModuleScope JiraPS {

    [System.Diagnostics.CodeAnalysis.SuppressMessage('PSUseDeclaredVarsMoreThanAssigments', '', Scope = '*', Target = 'SuppressImportModule')]
    $SuppressImportModule = $true
    . $PSScriptRoot\Shared.ps1

    $jiraServer = 'http://jiraserver.example.com'
    $id = 10101
    $name = 'My Permission Schema'
    $description = 'My Description'

    $restResultOne = @"
    {
        "permissionSchemas":  [
                                    {
                                        "expand":  "permissions,user,group,projectRole,field,all",
                                        "id":  "$id",
                                        "name":  "$name",
                                        "description":  "$description"
                                    }
                                ]
    }
"@
    Describe "Remove-JiraPermissionSchema" {

        Mock Get-JiraConfigServer -ModuleName JiraPS {
            Write-Output $jiraServer
        }

        Mock Get-JiraPermissionSchema -ModuleName JiraPS {
            Write-Output $restResultOne | ConvertFrom-Json
        }

        Mock Invoke-JiraMethod -ModuleName JiraPS -ParameterFilter {$Method -eq 'DELETE' -and $URI -eq "$jiraServer/rest/api/2/permissionSchema/$ID"} {
            if ($ShowMockData) {
                Write-Host "       Mocked Invoke-JiraMethod with DELETE method" -ForegroundColor Cyan
                Write-Host "         [Method]         $Method" -ForegroundColor Cyan
                Write-Host "         [URI]            $URI" -ForegroundColor Cyan
            }
        }

        Mock Invoke-JiraMethod -ModuleName JiraPS -ParameterFilter {$Method -eq 'DELETE' -and $URI -eq "$jiraServer/rest/api/2/permissionSchema"} {
            if ($ShowMockData) {
                Write-Host "       Mocked Invoke-JiraMethod with DELETE method" -ForegroundColor Cyan
                Write-Host "         [Method]         $Method" -ForegroundColor Cyan
                Write-Host "         [URI]            $URI" -ForegroundColor Cyan
            }
        }

        Mock Get-JiraPermissionSchema -ModuleName JiraPS {
            $restResultOne | ConvertFrom-Json2 | ConvertTo-JiraPermissionSchema
        }

        # Generic catch-all. This will throw an exception if we forgot to mock something.
        Mock Invoke-JiraMethod -ModuleName JiraPS {
            Write-Host "       Mocked Invoke-JiraMethod with no parameter filter." -ForegroundColor DarkRed
            Write-Host "         [Method]         $Method" -ForegroundColor DarkRed
            Write-Host "         [URI]            $URI" -ForegroundColor DarkRed
            throw "Unidentified call to Invoke-JiraMethod"
        }

        It "Accepts -ID parameter" {
            { Remove-JiraPermissionSchema -ID $id } | Should Not Throw
            Assert-MockCalled -CommandName Invoke-JiraMethod -Exactly -Times 1 -Scope It
        }

        It "Accepts -Name parameter" {
            { Remove-JiraPermissionSchema -Name $name } | Should Not Throw
        }
    <#
        It "Accepts pipeline input from Get-JiraUser" {
            { Get-JiraUser -UserName $testUsername | Remove-JiraPermissionSchema -Force } | Should Not Throw
            Assert-MockCalled -CommandName Invoke-JiraMethod -Exactly -Times 1 -Scope It
        }

        It "Removes a user from JIRA" {
            { Remove-JiraPermissionSchema -User $testUsername -Force } | Should Not Throw
            Assert-MockCalled -CommandName Invoke-JiraMethod -Exactly -Times 1 -Scope It
        }

        It "Provides no output" {
            Remove-JiraPermissionSchema -User $testUsername -Force | Should BeNullOrEmpty
        }
        #>
    }
}
