#requires -modules @{ ModuleName = "Pester"; ModuleVersion = "5.7"; MaximumVersion = "5.999" }

BeforeDiscovery {
    . "$PSScriptRoot/../../Helpers/TestTools.ps1"

    $script:moduleToTest = Initialize-TestEnvironment
}

InModuleScope JiraPS {
    Describe "Resolve-JiraField" -Tag 'Unit' {
        BeforeAll {
            . "$PSScriptRoot/../../Helpers/TestTools.ps1"

            # Minimal field objects that replicate the shape returned by
            # ConvertTo-JiraField / ConvertTo-JiraEditMetaField.
            $script:fieldSummary = [PSCustomObject]@{ Id = 'summary'; Name = 'Summary' }
            $script:fieldCustom = [PSCustomObject]@{ Id = 'customfield_10001'; Name = 'Story Points' }
            $script:fieldDupe1 = [PSCustomObject]@{ Id = 'customfield_10010'; Name = 'Sprint' }
            $script:fieldDupe2 = [PSCustomObject]@{ Id = 'customfield_10011'; Name = 'Sprint' }

            # Helper: build the grouped hashtable the callers produce via Group-Object.
            function script:MakeById {
                param([PSCustomObject[]]$Fields)
                $ht = @{}
                foreach ($f in $Fields) { $ht[$f.Id] = @($f) }
                $ht
            }
            function script:MakeByName {
                param([PSCustomObject[]]$Fields)
                $ht = @{}
                foreach ($f in $Fields) {
                    if (-not $ht.ContainsKey($f.Name)) { $ht[$f.Name] = [System.Collections.Generic.List[PSCustomObject]]::new() }
                    $ht[$f.Name].Add($f)
                }
                $ht
            }

            $script:scopedById = MakeById @($fieldSummary, $fieldCustom)
            $script:scopedByName = MakeByName @($fieldSummary, $fieldCustom)

            $script:fallbackById = MakeById @($fieldSummary, $fieldCustom, $fieldDupe1, $fieldDupe2)
            $script:fallbackByName = MakeByName @($fieldSummary, $fieldCustom, $fieldDupe1, $fieldDupe2)

            $script:emptyHt = @{}
        }

        Context "Resolution via scoped metadata" {
            It "1. Resolves by exact scoped field ID" {
                $result = Resolve-JiraField `
                    -Name 'summary' `
                    -ScopedById $scopedById -ScopedByName $scopedByName `
                    -FallbackById $emptyHt -FallbackByName $emptyHt

                $result.Id | Should -Be 'summary'
            }

            It "2. Resolves by numeric custom field ID prefix (customfield_NNNNN)" {
                # Caller passes the bare number; function prepends 'customfield_'.
                $result = Resolve-JiraField `
                    -Name '10001' `
                    -ScopedById $scopedById -ScopedByName $scopedByName `
                    -FallbackById $emptyHt -FallbackByName $emptyHt

                $result.Id | Should -Be 'customfield_10001'
            }

            It "3. Resolves by unambiguous scoped field name" {
                $result = Resolve-JiraField `
                    -Name 'Summary' `
                    -ScopedById $emptyHt -ScopedByName $scopedByName `
                    -FallbackById $emptyHt -FallbackByName $emptyHt

                $result.Id | Should -Be 'summary'
            }

            It "4. Throws ambiguity error when scoped name matches multiple fields" {
                $ambiguousByName = MakeByName @($fieldDupe1, $fieldDupe2)

                {
                    Resolve-JiraField `
                        -Name 'Sprint' `
                        -ScopedById $emptyHt -ScopedByName $ambiguousByName `
                        -FallbackById $emptyHt -FallbackByName $emptyHt `
                        -ErrorAction Stop
                } | Should -Throw

                {
                    Resolve-JiraField `
                        -Name 'Sprint' `
                        -ScopedById $emptyHt -ScopedByName $ambiguousByName `
                        -FallbackById $emptyHt -FallbackByName $emptyHt `
                        -ErrorAction Stop
                } | Should -Throw -ExceptionType ([System.ArgumentException])
            }

            It "4. Ambiguity error for scoped name has expected ErrorId" {
                $ambiguousByName = MakeByName @($fieldDupe1, $fieldDupe2)
                $threw = $false
                try {
                    Resolve-JiraField `
                        -Name 'Sprint' `
                        -ScopedById $emptyHt -ScopedByName $ambiguousByName `
                        -FallbackById $emptyHt -FallbackByName $emptyHt `
                        -ErrorAction Stop
                }
                catch {
                    $threw = $true
                    $_.FullyQualifiedErrorId | Should -Match 'ParameterValue\.AmbiguousParameter'
                }
                $threw | Should -Be $true
            }
        }

        Context "Resolution via fallback (global field list)" {
            It "5. Resolves by exact fallback field ID when absent from scoped" {
                $result = Resolve-JiraField `
                    -Name 'summary' `
                    -ScopedById $emptyHt -ScopedByName $emptyHt `
                    -FallbackById $fallbackById -FallbackByName $fallbackByName

                $result.Id | Should -Be 'summary'
            }

            It "6. Resolves by unambiguous fallback field name" {
                $unambiguousById = MakeById @($fieldSummary)
                $unambiguousByName = MakeByName @($fieldSummary)

                $result = Resolve-JiraField `
                    -Name 'Summary' `
                    -ScopedById $emptyHt -ScopedByName $emptyHt `
                    -FallbackById $unambiguousById -FallbackByName $unambiguousByName

                $result.Id | Should -Be 'summary'
            }

            It "7. Throws ambiguity error when fallback name matches multiple fields" {
                $unambiguousScoped = MakeByName @($fieldSummary)  # 'Sprint' not in scoped
                $ambiguousFallback = MakeByName @($fieldDupe1, $fieldDupe2)

                {
                    Resolve-JiraField `
                        -Name 'Sprint' `
                        -ScopedById $emptyHt -ScopedByName $unambiguousScoped `
                        -FallbackById $emptyHt -FallbackByName $ambiguousFallback `
                        -ErrorAction Stop
                } | Should -Throw
            }

            It "7. Fallback ambiguity error has expected ErrorId" {
                $ambiguousFallback = MakeByName @($fieldDupe1, $fieldDupe2)
                $threw = $false
                try {
                    Resolve-JiraField `
                        -Name 'Sprint' `
                        -ScopedById $emptyHt -ScopedByName $emptyHt `
                        -FallbackById $emptyHt -FallbackByName $ambiguousFallback `
                        -ErrorAction Stop
                }
                catch {
                    $threw = $true
                    $_.FullyQualifiedErrorId | Should -Match 'ParameterValue\.AmbiguousParameter'
                }
                $threw | Should -Be $true
            }
        }

        Context "Not-found error" {
            It "8. Throws not-found error when key is absent from both scoped and fallback" {
                {
                    Resolve-JiraField `
                        -Name 'nonexistent_field' `
                        -ScopedById $emptyHt -ScopedByName $emptyHt `
                        -FallbackById $emptyHt -FallbackByName $emptyHt `
                        -ErrorAction Stop
                } | Should -Throw
            }

            It "8. Not-found error has expected ErrorId" {
                $threw = $false
                try {
                    Resolve-JiraField `
                        -Name 'nonexistent_field' `
                        -ScopedById $emptyHt -ScopedByName $emptyHt `
                        -FallbackById $emptyHt -FallbackByName $emptyHt `
                        -ErrorAction Stop
                }
                catch {
                    $threw = $true
                    $_.FullyQualifiedErrorId | Should -Match 'ParameterValue\.InvalidFields'
                }
                $threw | Should -Be $true
            }
        }
    }
}
