#requires -modules @{ ModuleName = "Pester"; ModuleVersion = "5.7"; MaximumVersion = "5.999" }

BeforeDiscovery {
    . "$PSScriptRoot/Helpers/TestTools.ps1"

    Initialize-TestEnvironment
    $script:moduleToTest = Resolve-ModuleSource
    $script:projectRoot = Resolve-ProjectRoot

    Import-Module $script:moduleToTest -Force -ErrorAction Stop
}

Describe "Help tests" -Tag "Documentation", "Build" {
    BeforeDiscovery {
        ${/} = [regex]::Escape([System.IO.Path]::DirectorySeparatorChar)

        $script:isRunningInReleaseFolder = $moduleToTest -match "${/}Release${/}"
        if (-not $isRunningInReleaseFolder) {
            Write-Warning "Tests are being run outside of the 'Release' folder. Some tests may be skipped."
        }

        # Only test public functions (those that have markdown documentation)
        $script:publicFunctions = (Get-ChildItem "$projectRoot/JiraPS/Public/*.ps1").BaseName

        $script:commands = Get-Command -Module JiraPS -CommandType Cmdlet, Function |
            Where-Object { $_.Name -in $publicFunctions } |
            ForEach-Object { @{
                    Command     = $_
                    CommandName = $_.Name
                    Help        = (Get-Help $_.Name)
                }
            }

        $script:DefaultParams = @(
            'Verbose'
            'Debug'
            'ErrorAction'
            'WarningAction'
            'InformationAction'
            'ErrorVariable'
            'WarningVariable'
            'InformationVariable'
            'OutVariable'
            'OutBuffer'
            'PipelineVariable'
            'ProgressAction'
            'WhatIf'
            'Confirm'
        )
    }
    BeforeAll {
        $script:module = Get-Module JiraPS
    }

    Describe "Public Functions" {
        Context "Command <_.CommandName>" -ForEach $commands {
            BeforeDiscovery {
                # Exclude default params and any parameter marked [Parameter(DontShow)],
                # which is the principled signal for "internal, not part of the public surface".
                $cmd = $_.Command
                $isDontShow = {
                    param($name)
                    $paramAttr = $cmd.Parameters[$name].Attributes | Where-Object { $_ -is [System.Management.Automation.ParameterAttribute] }
                    return ($paramAttr.DontShow -contains $true)
                }
                $script:parameters = $cmd.Parameters.Keys | Where-Object { $_ -notin $DefaultParams -and -not (& $isDontShow $_) }
            }
            BeforeAll {
                $script:command = $_.Command
            }

            Context "Markdown file for <_.CommandName>" {
                BeforeAll {
                    $script:markdownFile = Resolve-Path "$projectRoot/docs/en-US/commands/$($command.Name).md" -ErrorAction Stop
                }

                It "is described in a markdown file" {
                    $markdownFile | Should -Not -BeNullOrEmpty
                    Test-Path $markdownFile | Should -Be $true
                }

                It "does not have Comment-Based Help" {
                    # We use .EXAMPLE, as we test this extensivly and it is never auto-generated
                    $command.Definition | Should -Not -BeNullOrEmpty
                    $pattern = [regex]::Escape(".EXAMPLE")

                    $command.Definition | Should -Not -Match "^\s*$pattern"
                }

                It "has no platyPS template artifacts" {
                    $markdownFile | Should -Not -BeNullOrEmpty
                    $markdownFile | Should -Not -FileContentMatch '\{\{.*?\}\}'
                }

                It "has a valid online version" {
                    $pattern = [regex]::Escape("https://atlassianps.org/docs/JiraPS/commands/$($command.Name)/")

                    $markdownFile | Should -FileContentMatch $pattern
                }

                It "defines the frontmatter for the homepage" {
                    $markdownFile | Should -Not -BeNullOrEmpty
                    $markdownFile | Should -FileContentMatch "Module Name: JiraPS"
                    $markdownFile | Should -FileContentMatchExactly "layout: documentation"
                    $markdownFile | Should -FileContentMatch "permalink: /docs/JiraPS/commands/$($command.Name)/"
                }
            }

            Context "Help for <_.CommandName>" -Skip:(-not $isRunningInReleaseFolder) {
                BeforeAll {
                    $script:help = $command.Help
                }

                It "has a synopsis" {
                    $help.Synopsis | Should -Not -BeNullOrEmpty
                }

                It "has a syntax" {
                    $help.syntax | Should -Not -BeNullOrEmpty
                }

                It "has a description" {
                    $help.Description.Text -join '' | Should -Not -BeNullOrEmpty
                }

                It "has examples" {
                    ($help.Examples.Example | Select-Object -First 1).Code | Should -Not -BeNullOrEmpty
                }

                It "has desciptions for all examples" {
                    foreach ($example in ($help.Examples.Example)) {
                        $example.remarks.Text | Should -Not -BeNullOrEmpty
                    }
                }

                It "has at least as many examples as ParameterSets" {
                    ($help.Examples.Example | Measure-Object).Count | Should -BeGreaterOrEqual $command.ParameterSets.Count
                }

                It "has a link to the 'Online Version'" {
                    # PlatyPS 1.0 uses "Online Version" without colon, older versions used "Online Version:"
                    [Uri]$onlineLink = ($help.relatedLinks.navigationLink | Where-Object { $_.linkText -match "^Online Version:?$" }).Uri

                    $onlineLink.Authority | Should -Be "atlassianps.org"
                    $onlineLink.Scheme | Should -Be "https"
                    $onlineLink.PathAndQuery | Should -Be "/docs/JiraPS/commands/$($command.Name)/"
                }

                It "has a valid HelpUri" -Skip { #TODO: Fix HelpUri generation
                    $command.HelpUri | Should -Not -BeNullOrEmpty
                    $pattern = [regex]::Escape("https://atlassianps.org/docs/JiraPS/commands/$($command.Name)")

                    $command.HelpUri | Should -Match $pattern
                }

                It "does not emit mangled input/output type names" {
                    # Regression guard for PlatyPS 1.0's Markdig-based heading parser:
                    # malformed `### [...]` headings have produced single-character names
                    # ('[', ']'), Markdig internal class names (Markdig.Syntax.Inlines.*),
                    # and stray legacy `<TODO>` placeholders that leak into Get-Help.
                    $typeNames = @(
                        @($help.inputTypes.inputType) +
                        @($help.returnValues.returnValue)
                    ) | Where-Object { $_ } | ForEach-Object {
                        if ($_.type -and $_.type.name) { ($_.type.name -as [String]).Trim() }
                    }
                    foreach ($typeName in $typeNames) {
                        if ([string]::IsNullOrEmpty($typeName)) { continue }
                        $typeName | Should -Not -Match '^[\[\]]$' -Because "type names should never be a stray bracket character"
                        $typeName.Length | Should -BeGreaterThan 1 -Because "single-character type names indicate a parser regression in INPUTS/OUTPUTS"
                        $typeName | Should -Not -Match '^Markdig\.' -Because "Markdig parser internals must never appear as type names; check the markdown heading for malformed brackets"
                        $typeName | Should -Not -Match '^<' -Because "legacy '<TODO>' placeholder headings must be replaced with real type names"
                    }
                }

                # It "does not define parameter position for functions with only one ParameterSet" {
                #     if ($command.ParameterSets.Count -eq 1) {
                #         $command.Parameters.Keys | Foreach-Object {
                #             $command.Parameters[$_].ParameterSets.Values.Position | Should -BeLessThan 0
                #         }
                #     }
                # }
            }

            Context "Parameter for <_.CommandName>" -Skip:(-not $isRunningInReleaseFolder) {
                Context "Parameter: <_>" -ForEach $parameters {
                    BeforeAll {
                        $script:parameterName = $_
                        $script:parameterCode = $command.Parameters[$parameterName]
                        $script:parameterHelp = $help.Parameters.Parameter | Where-Object Name -EQ $parameterName
                    }

                    It "has a description" {
                        $parameterHelp.Description.Text | Should -Not -BeNullOrEmpty
                    }

                    It "has a mandatory flag" {
                        $isMandatory = $parameterCode.ParameterSets.Values.IsMandatory -contains "True"

                        $command | Should -HaveParameter $parameterName -Mandatory:$isMandatory
                        $parameterHelp.Required | Should -BeLike $isMandatory.ToString()
                    }

                    It "matches the type of the parameter in code and help" {
                        $codeType = $parameterCode.ParameterType.Name
                        # Parameters decorated with [PSTypeName(...)] surface as
                        # Object / Object[] at the binder level. Prefer the
                        # PSTypeName for the user-facing type (which is what the
                        # markdown / Get-Help advertises). Match both the scalar
                        # and array forms.
                        if ($codeType -eq "Object" -or $codeType -eq "Object[]") {
                            $psTypeAttr = $parameterCode.Attributes | Where-Object { $_ -is [System.Management.Automation.PSTypeNameAttribute] } | Select-Object -First 1
                            if ($psTypeAttr) {
                                # PSTypeName always carries the scalar form;
                                # preserve the [] suffix when the binder reports
                                # an array parameter so we line up with the
                                # array form advertised in the markdown.
                                $codeType = $psTypeAttr.PSTypeName
                                if ($parameterCode.ParameterType.IsArray -and $codeType -notmatch '\[\]$') {
                                    $codeType += '[]'
                                }
                            }
                        }
                        # To avoid calling Trim method on a null object.
                        $helpType = if ($parameterHelp.parameterValue) { $parameterHelp.parameterValue.Trim() }
                        if ($helpType -eq "PSCustomObject") { $helpType = "PSObject" }
                        # PlatyPS 1.0 uses "Switch" instead of "SwitchParameter"
                        if ($helpType -eq "Switch") { $helpType = "SwitchParameter" }

                        $helpType | Should -Be $codeType
                    }

                    It "preserves alias metadata in help" {
                        # Regression guard for the PlatyPS 1.0 MAML round-trip dropping every
                        # parameter's alias attribute. Compare reflected aliases against help.
                        $codeAliases = @($parameterCode.Aliases | Sort-Object)
                        if ($codeAliases.Count -eq 0) { return }

                        $helpAliasField = ($parameterHelp.aliases -as [String]).Trim()
                        $helpAliases = @()
                        if ($helpAliasField -and $helpAliasField -ne 'None' -and $helpAliasField -ne 'none') {
                            $helpAliases = @($helpAliasField -split '[,\s]+' | Where-Object { $_ } | Sort-Object)
                        }

                        $helpAliases | Should -Be $codeAliases -Because "every alias declared on the parameter must be reachable through Get-Help"
                    }

                    It "preserves pipeline input flag in help" {
                        # Regression guard for the PlatyPS 1.0 round-trip dropping the
                        # pipelineInput attribute (every parameter ended up with "false").
                        $byValue = $parameterCode.ParameterSets.Values.ValueFromPipeline -contains $true
                        $byProperty = $parameterCode.ParameterSets.Values.ValueFromPipelineByPropertyName -contains $true
                        $codeAcceptsPipeline = $byValue -or $byProperty

                        $helpField = ($parameterHelp.pipelineInput -as [String]).Trim()
                        $helpAcceptsPipeline = $helpField -match '^[Tt]rue'

                        $helpAcceptsPipeline | Should -Be $codeAcceptsPipeline -Because "Get-Help must reflect the actual pipeline-input behaviour declared by [Parameter()]"
                    }
                }

                It "does not have parameters that are not in the code" {
                    $help = $_.Help

                    $parameter = @()
                    if ($help.Parameters | Get-Member -Name Parameter) {
                        $parameter = $help.Parameters.Parameter.Name | Sort-Object -Unique
                    }

                    foreach ($helpParm in $parameter) {
                        $command.Parameters.Keys | Should -Contain $helpParm
                    }
                }
            }
        }
    }

    #region Classes
    <# foreach ($class in $classes) {
        Context "Classes $($class.BaseName) Help" {

            It "is described in a markdown file" {
                $class.FullName | Should -Not -BeNullOrEmpty
                Test-Path $class.FullName | Should -Be $true
            }

            It "has no platyPS template artifacts" {
                $class.FullName | Should -Not -BeNullOrEmpty
                $class.FullName | Should -Not -FileContentMatch '{{.*}}'
            }

            It "defines the frontmatter for the homepage" {
                $class.FullName | Should -Not -BeNullOrEmpty
                $class.FullName | Should -FileContentMatch "Module Name: JiraPS"
                $class.FullName | Should -FileContentMatchExactly "layout: documentation"
                $class.FullName | Should -FileContentMatch "permalink: /docs/JiraPS/classes/$($class.BaseName)/"
            }
        }
    }


    Context "Missing classes" {
        It "has a documentation file for every class" {
            foreach ($class in ([AtlassianPS.ServerData].Assembly.GetTypes() | Where-Object IsClass)) {
                $classes.BaseName | Should -Contain $class.FullName
            }
        }
    } #>
    #endregion Classes

    #region Enumerations
    <# foreach ($enum in $enums) {
        Context "Enumeration $($enum.BaseName) Help" {

            It "is described in a markdown file" {
                $enum.FullName | Should -Not -BeNullOrEmpty
                Test-Path $enum.FullName | Should -Be $true
            }

            It "has no platyPS template artifacts" {
                $enum.FullName | Should -Not -BeNullOrEmpty
                $enum.FullName | Should -Not -FileContentMatch '{{.*}}'
            }

            It "defines the frontmatter for the homepage" {
                $enum.FullName | Should -Not -BeNullOrEmpty
                $enum.FullName | Should -FileContentMatch "Module Name: JiraPS"
                $enum.FullName | Should -FileContentMatchExactly "layout: documentation"
                $enum.FullName | Should -FileContentMatch "permalink: /docs/JiraPS/enumerations/$($enum.BaseName)/"
            }
        }
    }

    Context "Missing enumerations" {
        It "has a documentation file for every enumeration" {
            foreach ($enum in ([AtlassianPS.ServerData].Assembly.GetTypes() | Where-Object IsEnum)) {
                $enums.BaseName | Should -Contain $enum.FullName
            }
        }
    } #>
    #endregion Enumerations
}
