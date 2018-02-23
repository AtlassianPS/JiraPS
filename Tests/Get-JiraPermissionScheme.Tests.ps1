. $PSScriptRoot\Shared.ps1

InModuleScope JiraPS {

    [System.Diagnostics.CodeAnalysis.SuppressMessage('PSUseDeclaredVarsMoreThanAssigments', '', Scope = '*', Target = 'SuppressImportModule')]
    $SuppressImportModule = $true
    . $PSScriptRoot\Shared.ps1

    $jiraServer = 'http://jiraserver.example.com'

    $description1 = 'AP_Permission_Scheme'
    $Name1 = 'AP'
    $ID1 = 13241

    $description2 = 'PM_Permission_Scheme'
    $Name2 = 'PM'
    $ID2 = 17243

    $restResultAll = @"
    {
        "permissionSchemes":  [
                                  {
                                      "expand":  "permissions,user,group,projectRole,field,all",
                                      "id":  "$ID1",
                                      "name":  "$Name1",
                                      "description":  "$description1"
                                  },
                                  {
                                      "expand":  "permissions,user,group,projectRole,field,all",
                                      "id":  "$ID2",
                                      "name":  "$Name2",
                                      "description":  "$description2"
                                  }
                              ]
    }
"@

    $restResultOne = @"
    {
        "permissionSchemes":  [
                                    {
                                        "expand":  "permissions,user,group,projectRole,field,all",
                                        "id":  "$ID1",
                                        "name":  "$Name1",
                                        "description":  "$description1"
                                    }
                                ]
    }
"@

    $restResultTwo = @"
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

    Describe "Get-JiraPermissionScheme" {
        Mock Get-JiraConfigServer -ModuleName JiraPS {
            Write-Output $jiraServer
        }

        Mock Invoke-JiraMethod -ModuleName JiraPS -ParameterFilter {$Method -eq 'Get' -and $URI -eq "$jiraServer/rest/api/2/permissionscheme"} {
            $restResultAll | ConvertFrom-Json2
        }
        Mock Invoke-JiraMethod -ModuleName JiraPS -ParameterFilter {$Method -eq 'Get' -and $URI -eq "$jiraServer/rest/api/2/permissionscheme/$ID1"} {
            $restResultOne | ConvertFrom-Json2
        }
        Mock Invoke-JiraMethod -ModuleName JiraPS -ParameterFilter {$Method -eq 'Get' -and $URI -eq "$jiraServer/rest/api/2/permissionscheme/17243?expand=all"} {
            $restResultTwo | ConvertFrom-Json2
        }

#>
        # Generic catch-all. This will throw an exception if we forgot to mock something.
        Mock Invoke-JiraMethod -ModuleName JiraPS {
            Write-Host "       Mocked Invoke-JiraMethod with no parameter filter." -ForegroundColor DarkRed
            Write-Host "         [Method]         $Method" -ForegroundColor DarkRed
            Write-Host "         [URI]            $URI" -ForegroundColor DarkRed
            throw "Unidentified call to Invoke-JiraMethod"
        }

        # Tests
        It "Returns all Schemes if called with no parameters" {
            $allResults = Get-JiraPermissionScheme
            $allResults | Should Not BeNullOrEmpty
            @($allResults).Count | Should Be ($restResultAll | ConvertFrom-Json2).PermissionSchemes.count
        }

        It "Returns a specific Scheme if the ID is supplied" {
            $oneResult = Get-JiraPermissionScheme -Id $ID1
            $oneResult | Should Not BeNullOrEmpty
            $oneResult.ID | Should be $ID1
        }

        It "Returns a permission Scheme object if expand switch is provided" {
            $twoResult = Get-JiraPermissionScheme -Id $ID2 -Expand
            $twoResult.PermissionScheme | Should Not BeNullOrEmpty
        }
    }
}
