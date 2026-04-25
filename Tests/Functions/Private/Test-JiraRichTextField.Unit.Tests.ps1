#requires -modules @{ ModuleName = "Pester"; ModuleVersion = "5.7"; MaximumVersion = "5.999" }

BeforeDiscovery {
    . "$PSScriptRoot/../../Helpers/TestTools.ps1"

    $script:moduleToTest = Initialize-TestEnvironment
}

InModuleScope JiraPS {
    Describe "Test-JiraRichTextField" -Tag 'Unit' {

        Context "When -Field is `$null" {
            It "returns `$false" {
                Test-JiraRichTextField -Field $null | Should -Be $false
            }
        }

        Context "When schema is missing" {
            It "returns `$true for the system 'description' id" {
                $field = [PSCustomObject]@{ Id = 'description'; Schema = $null }
                Test-JiraRichTextField -Field $field | Should -Be $true
            }

            It "returns `$true for the system 'environment' id" {
                $field = [PSCustomObject]@{ Id = 'environment'; Schema = $null }
                Test-JiraRichTextField -Field $field | Should -Be $true
            }

            It "returns `$false for an unknown id without schema info" {
                $field = [PSCustomObject]@{ Id = 'summary'; Schema = $null }
                Test-JiraRichTextField -Field $field | Should -Be $false
            }
        }

        Context "When schema is present" {
            It "returns `$true when schema.type is 'doc' (Cloud ADF marker)" {
                $field = [PSCustomObject]@{
                    Id     = 'description'
                    Schema = [PSCustomObject]@{ type = 'doc' }
                }
                Test-JiraRichTextField -Field $field | Should -Be $true
            }

            It "returns `$true when schema.system is 'description'" {
                $field = [PSCustomObject]@{
                    Id     = 'description'
                    Schema = [PSCustomObject]@{ type = 'string'; system = 'description' }
                }
                Test-JiraRichTextField -Field $field | Should -Be $true
            }

            It "returns `$true when schema.system is 'environment'" {
                $field = [PSCustomObject]@{
                    Id     = 'environment'
                    Schema = [PSCustomObject]@{ type = 'string'; system = 'environment' }
                }
                Test-JiraRichTextField -Field $field | Should -Be $true
            }

            It "returns `$true for the built-in textarea custom field type" {
                $field = [PSCustomObject]@{
                    Id     = 'customfield_10010'
                    Schema = [PSCustomObject]@{
                        type   = 'string'
                        custom = 'com.atlassian.jira.plugin.system.customfieldtypes:textarea'
                    }
                }
                Test-JiraRichTextField -Field $field | Should -Be $true
            }

            It "returns `$false for a single-line string field (summary)" {
                $field = [PSCustomObject]@{
                    Id     = 'summary'
                    Schema = [PSCustomObject]@{ type = 'string'; system = 'summary' }
                }
                Test-JiraRichTextField -Field $field | Should -Be $false
            }

            It "returns `$false for a numeric field" {
                $field = [PSCustomObject]@{
                    Id     = 'customfield_10020'
                    Schema = [PSCustomObject]@{
                        type   = 'number'
                        custom = 'com.atlassian.jira.plugin.system.customfieldtypes:float'
                    }
                }
                Test-JiraRichTextField -Field $field | Should -Be $false
            }

            It "returns `$false for an unrelated single-line custom field" {
                $field = [PSCustomObject]@{
                    Id     = 'customfield_10030'
                    Schema = [PSCustomObject]@{
                        type   = 'string'
                        custom = 'com.atlassian.jira.plugin.system.customfieldtypes:textfield'
                    }
                }
                Test-JiraRichTextField -Field $field | Should -Be $false
            }
        }
    }
}
