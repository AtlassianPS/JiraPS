#requires -modules BuildHelpers
#requires -modules Pester

Describe "Help tests" -Tag Documentation {

    BeforeAll {
        Import-Module BuildHelpers
        Remove-Item -Path Env:\BH*

        $projectRoot = (Resolve-Path "$PSScriptRoot/..").Path
        if ($projectRoot -like "*Release") {
            $projectRoot = (Resolve-Path "$projectRoot/..").Path
        }
        Set-BuildEnvironment -BuildOutput '$ProjectPath/Release' -Path $projectRoot -ErrorAction SilentlyContinue
        $env:BHManifestToTest = $env:BHPSModuleManifest
        $isBuild = $PSScriptRoot -like "$env:BHBuildOutput*"
        if ($isBuild) {
            $Pattern = [regex]::Escape($env:BHProjectPath)

            $env:BHBuildModuleManifest = $env:BHPSModuleManifest -replace $Pattern, $env:BHBuildOutput
            $env:BHManifestToTest = $env:BHBuildModuleManifest
        }

        Remove-Module $env:BHProjectName -ErrorAction SilentlyContinue
        Import-Module $env:BHManifestToTest
    }
    AfterAll {
        Remove-Module $env:BHProjectName -ErrorAction SilentlyContinue
        Remove-Module BuildHelpers -ErrorAction SilentlyContinue
        Remove-Item -Path Env:\BH*
    }

    $DefaultParams = @(
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
        'WhatIf'
        'Confirm'
    )

    $module = Get-Module $env:BHProjectName
    $commands = Get-Command -Module $module -CommandType Cmdlet, Function, Workflow  # Not alias
    $classes = Get-ChildItem "$env:BHProjectPath/docs/en-US/classes/*" -ErrorAction SilentlyContinue
    $enums = Get-ChildItem "$env:BHProjectPath/docs/en-US/enumerations/*" -ErrorAction SilentlyContinue

    #region Public Functions
    foreach ($command in $commands) {
        $commandName = $command.Name -replace $module.Prefix, ''
        $markdownFile = Resolve-Path "$env:BHProjectPath/docs/en-US/commands/$commandName.md"

        # The module-qualified command fails on Microsoft.PowerShell.Archive cmdlets
        $help = Get-Help $command.Name -ErrorAction Stop

        Context "Function $commandName's Help" {

            #region PlatyPS external Help
            It "is described in a markdown file" {
                $markdownFile | Should -Not -BeNullOrEmpty
                Test-Path $markdownFile | Should -Be $true
            }

            It "links the function to the external help" {
                # required for PowerShell v3
                $Pattern = [regex]::Escape("# .ExternalHelp ..\JiraPS-help.xml")
                $command.Definition -match $Pattern
            }

            It "does not have Comment-Based Help" {
                # We use .EXAMPLE, as we test this extensivly and it is never auto-generated
                $command.Definition | Should -Not -BeNullOrEmpty
                $Pattern = [regex]::Escape(".EXAMPLE")

                $command.Definition | Should -Not -Match "^\s*$Pattern"
            }

            It "has no platyPS template artifacts" {
                $markdownFile | Should -Not -BeNullOrEmpty
                $markdownFile | Should -Not -FileContentMatch '{{.*}}'
            }

            It "has a link to the 'Online Version'" {
                [Uri]$onlineLink = ($help.relatedLinks.navigationLink | Where-Object linkText -eq "Online Version:").Uri

                $onlineLink.Authority | Should -Be "atlassianps.org"
                $onlineLink.Scheme | Should -Be "https"
                $onlineLink.PathAndQuery | Should -Be "/docs/$env:BHProjectName/commands/$commandName/"
            }

            it "has a valid HelpUri" {
                $command.HelpUri | Should -Not -BeNullOrEmpty
                $Pattern = [regex]::Escape("https://atlassianps.org/docs/$env:BHProjectName/commands/$commandName")

                $command.HelpUri | Should -Match $Pattern
            }

            It "defines the frontmatter for the homepage" {
                $markdownFile | Should -Not -BeNullOrEmpty
                $markdownFile | Should -FileContentMatch "Module Name: $env:BHProjectName"
                $markdownFile | Should -FileContentMatchExactly "layout: documentation"
                $markdownFile | Should -FileContentMatch "permalink: /docs/$env:BHProjectName/commands/$commandName/"
            }
            #endregion PlatyPS external Help

            #region Help Content
            It "has a synopsis" {
                $help.Synopsis | Should -Not -BeNullOrEmpty
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
            #endregion Help Content

            #region Consistency with Code
            # It "does not define parameter position for functions with only one ParameterSet" {
            #     if ($command.ParameterSets.Count -eq 1) {
            #         $command.Parameters.Keys | Foreach-Object {
            #             $command.Parameters[$_].ParameterSets.Values.Position | Should -BeLessThan 0
            #         }
            #     }
            # }

            It "has all ParameterSets in the Help" {
                # @($command.ParameterSets).Count | Should -Be @($help.Syntax.SyntaxItem).Count
            }

            #region Parameters
            foreach ($parameterName in $command.Parameters.Keys) {
                $parameterCode = $command.Parameters[$parameterName]

                if ($help.Parameters | Get-Member -Name Parameter) {
                    $parameterHelp = $help.Parameters.Parameter | Where-Object Name -EQ $parameterName

                    if ($parameterName -notin $DefaultParams) {
                        It "has a description for parameter [-$parameterName] in $commandName" {
                            $parameterHelp.Description.Text | Should -Not -BeNullOrEmpty
                        }

                        It "has a mandatory flag for parameter [-$parameterName] in $commandName" {
                            $isMandatory = $parameterCode.ParameterSets.Values.IsMandatory -contains "True"

                            $parameterHelp.Required | Should -BeLike $isMandatory.ToString()
                        }

                        It "matches the type of the parameter [-$parameterName] in code and help of $commandName" {
                            $codeType = $parameterCode.ParameterType.Name
                            if ($codeType -eq "Object") {
                                if (($parameterCode.Attributes) -and ($parameterCode.Attributes | Get-Member -Name PSTypeName)) {
                                    $codeType = $parameterCode.Attributes[0].PSTypeName
                                }
                            }
                            # To avoid calling Trim method on a null object.
                            $helpType = if ($parameterHelp.parameterValue) { $parameterHelp.parameterValue.Trim() }
                            if ($helpType -eq "PSCustomObject") { $helpType = "PSObject" }

                            $helpType | Should -Be $codeType
                        }
                    }
                }

                It "does not have parameters that are not in the code" {
                    $parameter = @()
                    if ($help.Parameters | Get-Member -Name Parameter) {
                        $parameter = $help.Parameters.Parameter.Name | Sort-Object -Unique
                    }
                    foreach ($helpParm in $parameter) {
                        $command.Parameters.Keys | Should -Contain $helpParm
                    }
                }
            }
            #endregion Parameters
            #endregion Consistency with Code
        }
    }
    #endregion Public Functions

    #region Classes
    if ($classes) {
        foreach ($class in $classes) {
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
                    $class.FullName | Should -FileContentMatch "Module Name: $env:BHProjectName"
                    $class.FullName | Should -FileContentMatchExactly "layout: documentation"
                    $class.FullName | Should -FileContentMatch "permalink: /docs/$env:BHProjectName/classes/$commandName/"
                }
            }
        }

        Context "Missing classes" {
            It "has a documentation file for every class" {
                foreach ($class in ([AtlassianPS.ServerData].Assembly.GetTypes() | Where-Object IsClass)) {
                    $classes.BaseName | Should -Contain $class.FullName
                }
            }
        }
    }
    #endregion Classes

    #region Enumerations
    if ($enums) {
        foreach ($enum in $enums) {
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
                    $enum.FullName | Should -FileContentMatch "Module Name: $env:BHProjectName"
                    $enum.FullName | Should -FileContentMatchExactly "layout: documentation"
                    $enum.FullName | Should -FileContentMatch "permalink: /docs/$env:BHProjectName/enumerations/$commandName/"
                }
            }
        }

        Context "Missing classes" {
            It "has a documentation file for every class" {
                foreach ($enum in ([AtlassianPS.ServerData].Assembly.GetTypes() | Where-Object IsEnum)) {
                    $enums.BaseName | Should -Contain $enum.FullName
                }
            }
        }
    }
    #endregion Enumerations
}
