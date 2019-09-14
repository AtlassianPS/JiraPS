#requires -modules BuildHelpers
#requires -modules @{ ModuleName = "Pester"; ModuleVersion = "4.4.0" }

Describe "Remove-JiraSession" -Tag 'Unit' {

    BeforeAll {
        Remove-Item -Path Env:\BH*
        $projectRoot = (Resolve-Path "$PSScriptRoot/../..").Path
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
    AfterAll {
        Remove-Module $env:BHProjectName -ErrorAction SilentlyContinue
        Remove-Module BuildHelpers -ErrorAction SilentlyContinue
        Remove-Item -Path Env:\BH*
    }

    . "$PSScriptRoot/../Shared.ps1"

    $newObjectSplat = @{
        Name = "One"
    }

    $sampleSession = New-Object -TypeName PSObject -Property $newObjectSplat
    $sampleSession.PSObject.TypeNames.Insert(0, 'JiraPS.Session')

    #region Mocks
    Mock Get-JiraSession -ModuleName JiraPS {
        (Get-Module JiraPS).PrivateData.Session
    }
    #endregion Mocks

    Context "Sanity checking" {
        $command = Get-Command -Name Remove-JiraSession

        defParam $command 'Session'
    }

    InModuleScope JiraPS {
        Context "Behavior testing" {
            It "removes default session" {
                $script:JiraSessions = @{
                    "Default" = $sampleSession
                }

                Remove-JiraSession

                $script:JiraSessions["Default"] | Should -BeNullOrEmpty
            }

            It "removes the session by name" {
                $script:JiraSessions = @{
                    "One" = $sampleSession
                }

                Remove-JiraSession -Session "One"

                $script:JiraSessions["One"] | Should -BeNullOrEmpty
            }

            It "removes the session by instance of JiraPS.Session" {
                $script:JiraSessions = @{
                    "One" = $sampleSession
                }

                Remove-JiraSession -Session $sampleSession

                $script:JiraSessions["One"] | Should -BeNullOrEmpty
            }
        }
    }
}
