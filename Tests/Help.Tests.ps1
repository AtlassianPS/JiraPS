#requires -modules BuildHelpers
#requires -modules Pester

BeforeDiscovery {
    #NOTE: Unsure if full clean/build is needed here, but keeping it anyway
    $projectRoot = (Resolve-Path "$PSScriptRoot/..").Path
    if ($projectRoot -like "*Release") {
        $projectRoot = (Resolve-Path "$projectRoot/..").Path
    }

    Import-Module BuildHelpers
    Set-BuildEnvironment -BuildOutput '$ProjectPath/Release' -Path $projectRoot -ErrorAction SilentlyContinue

    $env:BHManifestToTest = $env:BHPSModuleManifest
    $script:isBuild = $PSScriptRoot -like "$env:BHBuildOutput*"
    if ($script:isBuild) {
        $Pattern = [regex]::Escape($env:BHProjectPath)

        $env:BHBuildModuleManifest = $env:BHPSModuleManifest -replace $Pattern, $env:BHBuildOutput
        $env:BHManifestToTest = $env:BHBuildModuleManifest
    }

    Import-Module "$env:BHProjectPath/Tools/BuildTools.psm1"

    Remove-Module $env:BHProjectName -ErrorAction SilentlyContinue
    $module = Import-Module $env:BHManifestToTest -PassThru -Force

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
        'ProgressAction'
        'WhatIf'
        'Confirm'
    )
    $commandList = @(Get-Command -Module $module.Name -CommandType Cmdlet, Function | # Not alias
        ForEach-Object {
            @{
                CommandName = $_.Name -replace $module.Prefix, ''
                Command = $_
                Help = Get-Help $_.Name -ErrorAction SilentlyContinue
                Parameters = @($_.Parameters.GetEnumerator() |
                    Where-Object { $_.Value.Name -notin $DefaultParams} |
                    ForEach-Object {
                        @{
                            ParameterName = $_.Value.Name
                            Parameter = $_.Value
                        }
                    }
                )
            }
        }
    )
    # $classes = Get-ChildItem "$env:BHProjectPath/docs/en-US/classes/*"
    # $enums = Get-ChildItem "$env:BHProjectPath/docs/en-US/enumerations/*"
}

Describe "Help tests" -Tag Documentation {
    BeforeAll {
        Remove-Item -Path Env:\BH*
        $projectRoot = (Resolve-Path "$PSScriptRoot/..").Path
        if ($projectRoot -like "*Release") {
            $projectRoot = (Resolve-Path "$projectRoot/..").Path
        }

        Import-Module BuildHelpers
        Set-BuildEnvironment -BuildOutput '$ProjectPath/Release' -Path $projectRoot -ErrorAction SilentlyContinue

        $env:BHManifestToTest = $env:BHPSModuleManifest
        $script:isBuild = $PSScriptRoot -like "$env:BHBuildOutput*"
        if ($script:isBuild) {
            $Pattern = [regex]::Escape($env:BHProjectPath)

            $env:BHBuildModuleManifest = $env:BHPSModuleManifest -replace $Pattern, $env:BHBuildOutput
            $env:BHManifestToTest = $env:BHBuildModuleManifest
        }

        Import-Module "$env:BHProjectPath/Tools/BuildTools.psm1"

        Remove-Module $env:BHProjectName -ErrorAction SilentlyContinue
        Import-Module $env:BHManifestToTest
    }

    #region Public Functions
    Context "<CommandName> Function" -ForEach $commandList {
        Context "Overall Help Contents" {
            BeforeAll {
                $markdownFile = Resolve-Path "$env:BHProjectPath/docs/en-US/commands/$CommandName.md"
            }

            It "is described in a markdown file" {
                $markdownFile | Should -Not -BeNullOrEmpty
                Test-Path $markdownFile | Should -Be $true
            }

            It "does not have Comment-Based Help" {
                # We use .EXAMPLE, as we test this extensively and it is never auto-generated
                $Command.Definition | Should -Not -BeNullOrEmpty
                $Pattern = [regex]::Escape(".EXAMPLE")

                $Command.Definition | Should -Not -Match "^\s*$Pattern"
            }

            It "has no platyPS template artifacts" {
                $markdownFile | Should -Not -BeNullOrEmpty
                $markdownFile | Should -Not -FileContentMatch '{{.*}}'
            }

            It "has a link to the 'Online Version'" {
                [Uri]$onlineLink = ($Help.relatedLinks.navigationLink |
                    Where-Object linkText -eq "Online Version:").Uri

                $onlineLink.Authority | Should -Be "atlassianps.org"
                $onlineLink.Scheme | Should -Be "https"
                $onlineLink.PathAndQuery | Should -Be "/docs/$env:BHProjectName/commands/$CommandName/"
            }

            It "has a valid HelpUri" {
                $Command.HelpUri | Should -Not -BeNullOrEmpty
                $Pattern = [regex]::Escape("https://atlassianps.org/docs/$env:BHProjectName/commands/$CommandName")

                $Command.HelpUri | Should -Match $Pattern
            }

            It "defines the frontmatter for the homepage" {
                $markdownFile | Should -Not -BeNullOrEmpty
                $markdownFile | Should -FileContentMatch "Module Name: $env:BHProjectName"
                $markdownFile | Should -FileContentMatchExactly "layout: documentation"
                $markdownFile | Should -FileContentMatch "permalink: /docs/$env:BHProjectName/commands/$CommandName/"
            }

            # Should be a synopsis for every function
            It "has a synopsis" {
                $Help.Synopsis | Should -Not -BeNullOrEmpty
            }

            # Should be a syntax for every function
            It "has a syntax" {
                # syntax is starting with a small case as all the standard powershell commands have syntax with lower case, see (Get-Help Get-ChildItem) | gm
                $Help.syntax | Should -Not -BeNullOrEmpty
            }

            # Should be a description for every function
            It "has a description" {
                $Help.Description.Text -join '' | Should -Not -BeNullOrEmpty
            }

            # Should be at least one example
            It "has examples" {
                ($Help.Examples.Example | Select-Object -First 1).Code | Should -Not -BeNullOrEmpty
            }

            # Should be at least one example description
            It "has descriptions for all examples" {
                foreach ($example in ($Help.Examples.Example)) {
                    $Example.remarks.Text | Should -Not -BeNullOrEmpty
                }
            }

            It "has at least as many examples as ParameterSets" {
                ($Help.Examples.Example | Measure-Object).Count |
                    Should -BeGreaterOrEqual $Command.ParameterSets.Count
            }
        }

        Context "Parameters" -Skip:(-NOT ($Help.Parameters | Get-Member -Name Parameter)) {
            Context "<ParameterName> parameter" -ForEach $Parameters {
                BeforeAll {
                    $parameterCode = $Command.Parameters[$ParameterName]
                    $parameterHelp = $Help.Parameters.Parameter |
                        Where-Object Name -EQ $ParameterName
                }

                It "has a description for parameter [-$ParameterName] in $CommandName" {
                    $parameterHelp.Description.Text | Should -Not -BeNullOrEmpty
                }

                It "has a mandatory flag for parameter [-$ParameterName] in $CommandName" {
                    $isMandatory = $parameterCode.ParameterSets.Values.IsMandatory -contains "True"

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
                if ($Help.Parameters | Get-Member -Name Parameter) {
                    $parameter = $Help.Parameters.Parameter.Name | Sort-Object -Unique
                }
                foreach ($helpParam in $parameter) {
                    $Command.Parameters.Keys | Should -Contain $helpParam
                }
            }
        }
    }
    #endregion Public Functions

    #region Classes
    #NOTE: Not currently in use. If wanting to reuse later, will need to be converted to Pester v5

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
                $class.FullName | Should -FileContentMatch "Module Name: $env:BHProjectName"
                $class.FullName | Should -FileContentMatchExactly "layout: documentation"
                $class.FullName | Should -FileContentMatch "permalink: /docs/$env:BHProjectName/classes/$($class.BaseName)/"
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
    #NOTE: Not currently in use. If wanting to reuse later, will need to be converted to Pester v5

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
                $enum.FullName | Should -FileContentMatch "Module Name: $env:BHProjectName"
                $enum.FullName | Should -FileContentMatchExactly "layout: documentation"
                $enum.FullName | Should -FileContentMatch "permalink: /docs/$env:BHProjectName/enumerations/$($enum.BaseName)/"
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

    AfterAll {
        Remove-Module $env:BHProjectName -ErrorAction SilentlyContinue
        Remove-Module BuildHelpers -ErrorAction SilentlyContinue
        Remove-Item -Path Env:\BH*
    }
}
