#requires -modules @{ ModuleName = "Pester"; ModuleVersion = "5.7"; MaximumVersion = "5.999" }

BeforeDiscovery {
    . "$PSScriptRoot/../../Helpers/TestTools.ps1"

    $script:moduleToTest = Initialize-TestEnvironment
}

InModuleScope JiraPS {
    Describe "Jira scalar conversion helpers" -Tag 'Unit' {
        Context "ConvertTo-JiraNullableInt64" {
            It "returns null for null or whitespace input" {
                ConvertTo-JiraNullableInt64 $null | Should -BeNullOrEmpty
                ConvertTo-JiraNullableInt64 '' | Should -BeNullOrEmpty
            }

            It "converts numeric strings and numbers to Int64" {
                ConvertTo-JiraNullableInt64 '42' | Should -BeOfType [int64]
                ConvertTo-JiraNullableInt64 42 | Should -Be 42L
            }

            It "throws for non-numeric input" {
                { ConvertTo-JiraNullableInt64 'abc' } | Should -Throw
            }
        }

        Context "ConvertTo-JiraDateTimeOffsetValue" {
            It "returns null for null or whitespace input" {
                ConvertTo-JiraDateTimeOffsetValue $null | Should -BeNullOrEmpty
                ConvertTo-JiraDateTimeOffsetValue ' ' | Should -BeNullOrEmpty
            }

            It "passes through existing DateTimeOffset values" {
                $date = [DateTimeOffset]'2024-01-02T03:04:05+00:00'

                ConvertTo-JiraDateTimeOffsetValue $date | Should -Be $date
            }

            It "converts existing DateTime values without culture-sensitive string parsing" {
                $date = [datetime]'2024-01-02T03:04:05'

                ConvertTo-JiraDateTimeOffsetValue $date | Should -Be ([DateTimeOffset]$date)
            }

            It "converts Jira timestamp strings to DateTimeOffset" {
                $result = ConvertTo-JiraDateTimeOffsetValue '2017-05-30T11:20:34.000+0000'

                $result | Should -BeOfType [DateTimeOffset]
                $result.ToString('o') | Should -Be '2017-05-30T11:20:34.0000000+00:00'
            }

            It "preserves the source timestamp offset" {
                $result = ConvertTo-JiraDateTimeOffsetValue '2017-09-26T00:00:00.000+0200'

                $result.ToString('o') | Should -Be '2017-09-26T00:00:00.0000000+02:00'
            }

            It "throws for non-date, non-string input" {
                { ConvertTo-JiraDateTimeOffsetValue $false } | Should -Throw -ExpectedMessage "*System.Boolean*"
            }
        }

    }
}
