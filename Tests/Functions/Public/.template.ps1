#requires -modules @{ ModuleName = "Pester"; ModuleVersion = "5.7"; MaximumVersion = "5.999" }

BeforeDiscovery {
    . "$PSScriptRoot/../../Helpers/TestTools.ps1"

    Initialize-TestEnvironment
    $script:moduleToTest = Resolve-ModuleSource

    Import-Module $moduleToTest -Force -ErrorAction Stop
}

InModuleScope JiraPS {
    # TODO: replace %RESOURCE% and %RESOURCEJSON% with the actual resource name and JSON used in the tests
    Describe "%NAME OF THE FUNCTION TO TEST%" -Tag 'Unit' {
        BeforeAll {
            . "$PSScriptRoot/../../Helpers/TestTools.ps1"
            # $VerbosePreference = 'Continue'  # Uncomment for mock debugging

            #region Definitions
            $script:jiraServer = "https://jira.example.com"

            $%RESOURCEJSON% = @"
%ADD A REAL JSON RESPONSE HERE BUT REMOVE PERSONAL DATA%
"@
            #endregion Definitions

            #region Mocks
            Mock Get-JiraConfigServer -ModuleName JiraPS {
                Write-MockDebugInfo 'Get-JiraConfigServer'
                $jiraServer
            }

            # TODO: Adjust the mock to return a valid %RESOURCE% object
            Mock ConvertTo-Jira%RESOURCE% -ModuleName JiraPS {
                Write-MockDebugInfo 'ConvertTo-Jira%RESOURCE'
                $i = New-Object -TypeName PSCustomObject
                $i.PSObject.TypeNames.Insert(0, 'JiraPS.%RESOURCE')
                $i
            }

            # TODO: Add a mock for every function used by the function under test

            # TODO: Adjust ParameterFilter to match the expected calls
            Mock Invoke-JiraMethod -ModuleName JiraPS -ParameterFilter {
                $Method -eq 'Post' -and $URI -like "$jiraServer/rest/api/*/filter/*/permission"
            } {
                Write-MockDebugInfo 'Invoke-JiraMethod' 'Method', 'Uri', 'Body'
                ConvertFrom-Json $permissionJSON
            }

            Mock Invoke-JiraMethod -ModuleName JiraPS {
                # Generic catch-all mock to identify unhandled calls
                Write-MockDebugInfo 'Invoke-JiraMethod' 'Method', 'Uri'
                throw "Unidentified call to Invoke-JiraMethod: $Method $URI"
            }
            #endregion Mocks
        }

        Describe "Signature" {
            <#
            Signature tests the function parameters, their types, default values and mandatory status.
            By testing this, we ensure that the function interface remains consistent and any changes are intentional.
            #>
            BeforeAll {
                $script:command = Get-Command -Name '%FUNCTION-NAME%'
            }

            Context "Parameter Types" {
                It "has a parameter '<parameter>' of type '<type>'" -TestCases @(
                    @{ parameter = "%PARAMETER1%"; type = "%DATA TYPE%" }
                    @{ parameter = "%PARAMETER2%"; type = "%DATA TYPE%" }
                    @{ parameter = "Credential"; type = "System.Management.Automation.PSCredential" }
                ) {
                    $command | Should -HaveParameter $parameter

                    (Get-Member -InputObject $command.Parameters.Item($parameter)).Attributes | Should -Contain $typeName
                }
            }

            Context "Default Values" {
                It "parameter '<parameter>' has a default value of '<defaultValue>'" -TestCases @(
                    @{ parameter = "%PARAMETER1%"; defaultValue = "%DEFAULT VALUE%" }
                    @{ parameter = "Credential"; defaultValue = "[System.Management.Automation.PSCredential]::Empty" }
                ) {
                    $command | Should -HaveParameter $parameter -DefaultValue $defaultValue
                }
            }

            Context "Mandatory Parameters" {
                It "parameter '<parameter>' is mandatory" -TestCases @(
                    @{ parameter = "%PARAMETER1%" }
                ) {
                    $command | Should -HaveParameter $parameter -Mandatory
                }
            }
        }

        Describe "Behavior" {
            <#
            Behavior tests the actual functionality of the function.
            This includes:
              * Testing each "if" or "switch" branch.
              * Testing that each function used within the function is called as expected (with correct parameters and number of times) by using `Should -Invoke`.
              * Testing all possible output scenarios.
              * Testing edge cases and expected outputs.
            #>
            # TODO: These are examples for inspiration
            Context "Resolves inputs" {
                It "resolves input string to object" {
                    { %FUNCTION-NAME% -Id '12345' -Type "Global" } | Should -Not -Throw

                    Should -Invoke 'Get-Jira%RESOURCE%' -ModuleName 'JiraPS' -Exactly -Times 1 -Scope It
                }
            }

            Context "invokes Jira API" {
                It "calls Invoke-JiraMethod with correct parameters" {
                    { %FUNCTION-NAME% -Id 12844 -Type "Global" } | Should -Not -Throw

                    Should -Invoke -CommandName Invoke-JiraMethod -ModuleName JiraPS -Exactly -Times 1 -Scope It -ParameterFilter {
                        $Method -eq 'Post' -and
                        $URI -like '*/rest/api/*/filter/12844/permission'
                    }
                }
            }

            Context "returns an object" {
                It "returns a JiraPS.%RESOURCE% object" {
                    { %FUNCTION-NAME% -Id '12345' -Type "Global" } | Should -Not -Throw

                    Should -Invoke 'ConvertTo-Jira%RESOURCE%' -ModuleName 'JiraPS' -Exactly -Times 1 -Scope It
                }
            }
        }

        Describe "Input Validation" {
            <#
            Input Validation tests the different combinations of inputs - usasualy each parameter set.
            This includes:
              * Testing that invalid inputs are rejected with meaningful error messages.
              * Testing that valid inputs are accepted and processed correctly.
            #>
            # TODO: These are examples for inspiration
            Context "%PARAMETER SET 1% - Negative Cases" {
                It "rejects ..." {
                    { %COMMAND% } | Should -Throw -ExpectedMessage "%ERROR MESSAGE%"
                }
            }

            Context "%PARAMETER SET 1% - Positive Cases" {
                It "accepts ..." {
                    { %COMMAND% } | Should -Not -Throw
                }
            }

            Context "Pipeline Support" {
                It "..." {
                    { %COMMAND% | %COMMAND% } | Should -Not -Throw
                }
            }

            Context "Multiple Items" {
                It "can process a collection" {
                    # prepare a collection
                    $collection = 1..5 | ForEach-Object { Get-Jira%RESOURCE% -Id 1 }

                    { %FUNCTION-NAME% -%RESOURCE% $collection } | Should -Not -Throw

                    Should -Invoke -CommandName Invoke-JiraMethod -ModuleName JiraPS -Exactly -Times 5 -Scope It
                }

                It "can process a list" {
                    { %FUNCTION-NAME% -Id 1, 2, 3, 4, 5 } | Should -Not -Throw

                    Should -Invoke -CommandName Invoke-JiraMethod -ModuleName JiraPS -Exactly -Times 5 -Scope It
                }
            }
        }
    }
}
