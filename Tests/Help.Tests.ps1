#requires -modules @{ ModuleName = "Pester"; ModuleVersion = "5.7"; MaximumVersion = "5.999" }

Describe "Help tests" -Tag "Documentation", "Build" {
    BeforeDiscovery {
        . "$PSScriptRoot/Helpers/Resolve-ModuleSource.ps1"
        $script:moduleToTest = Resolve-ModuleSource

        $dependentModules = Get-Module | Where-Object { $_.RequiredModules.Name -eq 'JiraPS' }
    $dependentModules, "JiraPS" | Remove-Module -Force -ErrorAction SilentlyContinue
        Import-Module $moduleToTest -Force -ErrorAction Stop

        $script:commands = Get-Command -Module JiraPS -CommandType Cmdlet, Function | ForEach-Object { @{
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
        Describe "Command <_.CommandName>" -ForEach $commands {
            BeforeDiscovery {
                $script:parameters = $_.Command.Parameters.Keys | Where-Object { $_ -NotIn $DefaultParams }
            }
            BeforeAll {
                $script:command = $_.Command
                $script:commandName = $_.CommandName
                $script:help = $_.Help
                $script:commandName = $command.Name -replace $module.Prefix, ''
                $script:markdownFile = Resolve-Path "$moduleToTest/../../docs/en-US/commands/$commandName.md"
            }

            It "is described in a markdown file" {
                $markdownFile | Should -Not -BeNullOrEmpty
                Test-Path $markdownFile | Should -Be $true
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
                [Uri]$onlineLink = ($help.relatedLinks.navigationLink | Where-Object linkText -EQ "Online Version:").Uri

                $onlineLink.Authority | Should -Be "atlassianps.org"
                $onlineLink.Scheme | Should -Be "https"
                $onlineLink.PathAndQuery | Should -Be "/docs/JiraPS/commands/$commandName/"
            }

            It "has a valid HelpUri" {
                $command.HelpUri | Should -Not -BeNullOrEmpty
                $Pattern = [regex]::Escape("https://atlassianps.org/docs/JiraPS/commands/$commandName")

                $command.HelpUri | Should -Match $Pattern
            }

            It "defines the frontmatter for the homepage" {
                $markdownFile | Should -Not -BeNullOrEmpty
                $markdownFile | Should -FileContentMatch "Module Name: JiraPS"
                $markdownFile | Should -FileContentMatchExactly "layout: documentation"
                $markdownFile | Should -FileContentMatch "permalink: /docs/JiraPS/commands/$commandName/"
            }

            It "has a synopsis" {
                $help.Synopsis | Should -Not -BeNullOrEmpty
            }

            It "has a syntax" {
                # syntax is starting with a small case as all the standard powershell commands have syntax with lower case, see (Get-Help Get-ChildItem) | gm
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

            # It "does not define parameter position for functions with only one ParameterSet" {
            #     if ($command.ParameterSets.Count -eq 1) {
            #         $command.Parameters.Keys | Foreach-Object {
            #             $command.Parameters[$_].ParameterSets.Values.Position | Should -BeLessThan 0
            #         }
            #     }
            # }

            Describe "Parameter: <_>" -ForEach $parameters {
                BeforeAll {
                    $script:parameterName = $_
                    $script:parameterCode = $command.Parameters[$parameterName]
                    $script:parameterHelp = $help.Parameters.Parameter | Where-Object Name -EQ $parameterName
                }

                It "has a description for parameter [-<_>] in $commandName" {
                    $parameterHelp.Description.Text | Should -Not -BeNullOrEmpty
                }

                It "has a mandatory flag for parameter [-<_>] in $commandName" {
                    $isMandatory = $parameterCode.ParameterSets.Values.IsMandatory -contains "True"

                    $command | Should -HaveParameter $parameterName -Mandatory:$isMandatory
                    $parameterHelp.Required | Should -BeLike $isMandatory.ToString()
                }

                It "matches the type of the parameter in code and help" {
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
