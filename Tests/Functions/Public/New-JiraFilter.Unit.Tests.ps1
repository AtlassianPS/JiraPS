#requires -modules @{ ModuleName = "Pester"; ModuleVersion = "6.2.0"; MaximumVersion = "6.999" }

BeforeDiscovery {
    . "$PSScriptRoot/../../Helpers/TestTools.ps1"

    $script:moduleToTest = Initialize-TestEnvironment
}

InModuleScope JiraPS {
    Describe "New-JiraFilter" -Tag 'Unit' {
        BeforeAll {
            . "$PSScriptRoot/../../Helpers/TestTools.ps1"
            # $VerbosePreference = 'Continue'

            #region Definitions
            $script:jiraServer = "https://jira.example.com"

            $script:responseFilter = @"
{
    "self": "$jiraServer/rest/api/2/filter/12844",
    "id": "12844",
    "name": "{0}",
    "jql": "{1}",
    "favourite": false
}
"@
            #endregion Definitions

            #region Mocks
            Mock ConvertTo-JiraFilter -ModuleName JiraPS {
                Write-MockDebugInfo 'ConvertTo-JiraFilter'
                $i = (ConvertFrom-Json $responseFilter)
                $i.PSObject.TypeNames.Insert(0, 'AtlassianPS.JiraPS.Filter')
                $i | Add-Member -MemberType AliasProperty -Name 'RestURL' -Value 'self'
                $i
            }

            Mock Get-JiraFilter -ModuleName JiraPS {
                Write-MockDebugInfo 'Get-JiraFilter'
                ConvertTo-JiraFilter
            }

            Mock Invoke-JiraRequest -ModuleName JiraPS -ParameterFilter { $Method -eq 'Post' -and $URI -like "/rest/api/*/filter" } {
                Write-MockDebugInfo 'Invoke-JiraRequest' 'Method', 'Uri', 'Body'
                ConvertFrom-Json $responseFilter
            }

            Mock Invoke-JiraRequest -ModuleName JiraPS {
                Write-MockDebugInfo 'Invoke-JiraRequest' 'Method', 'Uri'
                throw "Unidentified call to Invoke-JiraRequest"
            }
            #endregion Mocks
        }

        Describe "Signature" {
            BeforeAll {
                $script:command = Get-Command -Name New-JiraFilter
            }

            Context "Parameter Types" {

                It "has an alias '<alias>' for parameter '<parameter>'" -TestCases @(
                    @{ parameter = 'Favorite'; alias = 'Favourite' }
                ) {
                    param($parameter, $alias)
                    $command.Parameters[$parameter].Aliases | Should -Contain $alias
                }
            }

        }

        Describe "Behavior" {
            It "Invokes the Jira API to create a filter" {
                {
                    $newData = @{
                        Name        = "myName"
                        Description = "myDescription"
                        JQL         = "myJQL"
                        Favorite    = $true
                    }
                    New-JiraFilter @newData
                } | Should -Not -Throw

                Should -Invoke -CommandName Invoke-JiraRequest -ModuleName JiraPS -Exactly -Times 1 -ParameterFilter {
                    $Method -eq 'Post' -and
                    $URI -like '*/rest/api/*/filter' -and
                    $Body -match "`"name`":\s*`"myName`"" -and
                    $Body -match "`"description`":\s*`"myDescription`"" -and
                    $Body -match "`"jql`":\s*`"myJQL`"" -and
                    $Body -match "`"favourite`":\s*true"
                }
            }
        }

        Describe "Input Validation" {
            Context "Positive cases" {
                It "-Name and -JQL" {
                    {
                        $parameter = @{
                            Name = "newName"
                            JQL  = "newJQL"
                        }
                        New-JiraFilter @parameter
                    } | Should -Not -Throw

                    Should -Invoke Invoke-JiraRequest -Exactly -Times 1 -ParameterFilter {
                        $payload = $Body | ConvertFrom-Json
                        $payload.name -eq 'newName' -and $payload.jql -eq 'newJQL' -and
                        $payload.favourite -eq $false -and -not $payload.PSObject.Properties['description']
                    }
                }

                It "maps the properties of an object to the parameters" {
                    $filter = Get-JiraFilter '12345'
                    $filter | New-JiraFilter

                    Should -Invoke Invoke-JiraRequest -Exactly -Times 1 -ParameterFilter {
                        $payload = $Body | ConvertFrom-Json
                        $payload.name -eq $filter.Name -and $payload.jql -eq $filter.JQL
                    }
                }
            }
        }
    }
}
