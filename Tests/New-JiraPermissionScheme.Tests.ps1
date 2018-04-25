. $PSScriptRoot\Shared.ps1

InModuleScope JiraPS {

    [System.Diagnostics.CodeAnalysis.SuppressMessage('PSUseDeclaredVarsMoreThanAssigments', '', Scope = '*', Target = 'SuppressImportModule')]
    $SuppressImportModule = $true
    . $PSScriptRoot\Shared.ps1

    $jiraServer = 'http://jiraserver.example.com'

    $description2 = 'PM_Permission_Scheme'
    $name2 = 'PM'
    $id2 = 17243

    $inputObject = @"
    {
        "permissionSchemes":  [
                                    {
                                        "id":  "$ID2",
                                        "name":  "$Name2",
                                        "permissions":  [
                                                            {
                                                                "id":  "$ID2",
                                                                "holder":  "@{type=group; parameter=jira-viewonly; group=; expand=group}",
                                                                "permission":  "BROWSE_PROJECTS"
                                                            },
                                                            {
                                                                "id":  "$ID2",
                                                                "holder":  "@{type=group; parameter=jira-viewonly; group=; expand=group}",
                                                                "permission":  "TRANSITION_ISSUES"
                                                            }
                                                        ]
                                    }
                                ]
    }
"@

    $result = @"
    {
        "description":  "$description2",
        "Name":  "$name2",
        "ID":  "$id2"
    }
"@

    Describe "New-JiraPermissionScheme" {

        Mock Get-JiraConfigServer -ModuleName JiraPS {
            Write-Output $jiraServer
        }

        Mock Invoke-JiraMethod -ModuleName JiraPS -ParameterFilter {$Method -eq 'POST' -and $URI -eq "$jiraServer/rest/api/2/permissionscheme"} {
            $result | ConvertFrom-Json2
        }

        # Generic catch-all. This will throw an exception if we forgot to mock something.
        Mock Invoke-JiraMethod -ModuleName JiraPS {
            Write-Host "       Mocked Invoke-JiraMethod with no parameter filter." -ForegroundColor DarkRed
            Write-Host "         [Method]         $Method" -ForegroundColor DarkRed
            Write-Host "         [URI]            $URI" -ForegroundColor DarkRed
            throw "Unidentified call to Invoke-JiraMethod"
        }

        It "New permission Scheme should return result" {
            $newResult = New-JiraPermissionScheme -InputObject ($inputObject | ConvertFrom-Json2) -Name $name2 -Description $description2
            $newResult | Should Not BeNullOrEmpty
            $newResult.Name | Should Be $name2
            $newResult.Description | Should Be $description2
        }
    }
}

