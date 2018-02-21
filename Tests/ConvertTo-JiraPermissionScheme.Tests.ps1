. $PSScriptRoot\Shared.ps1

InModuleScope JiraPS {
    Describe "ConvertTo-JiraPermissionSchema" {
        . $PSScriptRoot\Shared.ps1

        $Name = 'PM'
        $ID = 17243

        $sampleJson = @"
        {
            "permissionSchemas":  [
                                        {
                                            "id":  "$ID",
                                            "name":  "$Name",
                                            "permissions":  [
                                                                {
                                                                    "id":  "$ID",
                                                                    "holder":  "@{type=group; parameter=jira-viewonly; group=; expand=group}",
                                                                    "permission":  "BROWSE_PROJECTS"
                                                                },
                                                                {
                                                                    "id":  "$ID",
                                                                    "holder":  "@{type=group; parameter=jira-viewonly; group=; expand=group}",
                                                                    "permission":  "TRANSITION_ISSUES"
                                                                }
                                                            ]
                                        }
                                    ]
        }
"@
        $sampleObject = ConvertFrom-Json2 -InputObject $sampleJson
        $r = ConvertTo-JiraPermissionSchema -InputObject $sampleObject
        It "Creates a PSObject out of JSON input" {
            $r.permissionSchema | Should Not BeNullOrEmpty
        }
        checkPsType $r.permissionSchema 'JiraPS.JiraPermissionSchemaProperty'
        defProp $r 'Name' $Name
        defProp $r 'ID' $ID
    }
}
