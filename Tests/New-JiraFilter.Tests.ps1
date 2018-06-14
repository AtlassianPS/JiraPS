Describe 'New-JiraFilter' {
    BeforeAll {
        Remove-Module JiraPS -ErrorAction SilentlyContinue
        Import-Module "$PSScriptRoot/../JiraPS" -Force -ErrorAction Stop
    }

    InModuleScope JiraPS {

        . "$PSScriptRoot/Shared.ps1"

        #region Definitions
        $jiraServer = "https://jira.example.com"

        $responseFilter = @"
{
    "self": "$jiraServer/rest/api/latest/filter/12844",
    "id": "12844",
    "name": "{0}",
    "jql": "{1}",
    "favourite": false
}
"@
        #endregion Definitions

        #region Mocks
        Mock Get-JiraConfigServer -ModuleName JiraPS {
            $jiraServer
        }

        Mock ConvertTo-JiraFilter -ModuleName JiraPS {
            $i = (ConvertFrom-Json $responseFilter)
            $i.PSObject.TypeNames.Insert(0, 'JiraPS.Filter')
            $i | Add-Member -MemberType AliasProperty -Name 'RestURL' -Value 'self'
            $i
        }

        Mock Get-JiraFilter -ModuleName JiraPS {
            ConvertTo-JiraFilter
        }

        Mock Invoke-JiraMethod -ModuleName JiraPS -ParameterFilter {$Method -eq 'Post' -and $URI -like "$jiraServer/rest/api/*/filter"} {
            ShowMockInfo 'Invoke-JiraMethod' 'Method', 'Uri', 'Body'
            ConvertFrom-Json $responseFilter
        }

        Mock Invoke-JiraMethod -ModuleName JiraPS {
            ShowMockInfo 'Invoke-JiraMethod' 'Method', 'Uri'
            throw "Unidentified call to Invoke-JiraMethod"
        }
        #endregion Mocks

        Context "Sanity checking" {
            $command = Get-Command -Name New-JiraFilter

            defParam $command 'Name'
            defParam $command 'Description'
            defParam $command 'JQL'
            defParam $command 'Favorite'
            defParam $command 'Credential'

            defAlias $command 'Favourite' 'Favorite'
        }

        Context "Behavior testing" {
            It "Invokes the Jira API to create a filter" {
                {
                    $newData = @{
                        Name        = "myName"
                        Description = "myDescription"
                        JQL         = "myJQL"
                        Favorite    = $true
                    }
                    New-JiraFilter @newData
                } | Should Not Throw

                Assert-MockCalled -CommandName Invoke-JiraMethod -ModuleName JiraPS -Exactly -Times 1 -Scope It -ParameterFilter {
                    $Method -eq 'Post' -and
                    $URI -like '*/rest/api/*/filter' -and
                    $Body -match "`"name`":\s*`"myName`"" -and
                    $Body -match "`"description`":\s*`"myDescription`"" -and
                    $Body -match "`"jql`":\s*`"myJQL`"" -and
                    $Body -match "`"favourite`":\s*true"
                }
            }
        }

        Context "Input testing" {
            It "-Name and -JQL" {
                {
                    $parameter = @{
                        Name        = "newName"
                        JQL         = "newJQL"
                    }
                    New-JiraFilter @parameter
                } | Should Not Throw

                Assert-MockCalled -CommandName Invoke-JiraMethod -ModuleName JiraPS -Exactly -Times 1 -Scope It
            }
            It "-Name and -Description and -JQL" {
                {
                    $parameter = @{
                        Name        = "newName"
                        Description = "newDescription"
                        JQL         = "newJQL"
                    }
                    New-JiraFilter @parameter
                } | Should Not Throw

                Assert-MockCalled -CommandName Invoke-JiraMethod -ModuleName JiraPS -Exactly -Times 1 -Scope It
            }
            It "-Name and -Description and -JQL and -Favorite" {
                {
                    $parameter = @{
                        Name        = "newName"
                        Description = "newDescription"
                        JQL         = "newJQL"
                        Favorite    = $true
                    }
                    New-JiraFilter @parameter
                } | Should Not Throw

                Assert-MockCalled -CommandName Invoke-JiraMethod -ModuleName JiraPS -Exactly -Times 1 -Scope It
            }
            It "maps the properties of an object to the parameters" {
                { Get-JiraFilter "12345" | New-JiraFilter } | Should Not Throw
            }
        }
    }
}
