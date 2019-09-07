#requires -modules BuildHelpers
#requires -modules @{ ModuleName = "Pester"; ModuleVersion = "4.4.0" }

Describe "New-JiraSession" -Tag 'Unit' {

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

    InModuleScope JiraPS {

        . "$PSScriptRoot/../Shared.ps1"

        #region Definitions

        $sampleCredential = [System.Management.Automation.PSCredential]::Empty
        $sampleServerConfig = New-Object -TypeName psobject
        $sampleSession = New-Object -TypeName psobject

        #endregion Definitions

        #region Mocks
        Mock Get-JiraConfigServer -ModuleName JiraPS {
            ShowMockInfo 'Get-JiraConfigServer' 'Name'
            Write-Output $sampleServerConfig
        }

        Mock ConvertTo-JiraSession -ModuleName JiraPS -ParameterFilter { $Credential -eq $sampleCredential -and $ServerConfig -eq $sampleServerConfig } {
            ShowMockInfo 'ConvertTo-JiraSession'
            Write-Output $sampleSession
        }

        Mock Invoke-JiraMethod -ModuleName JiraPS {
            ShowMockInfo 'ConvertTo-JiraSession'
            throw "Unidentified call to ConvertTo-JiraSession"
        }

        Mock Invoke-JiraMethod -ModuleName JiraPS -ParameterFilter {$Method -eq 'Get' -and $Uri -ilike "rest/api/*/mypermissions" -and $Session -eq $sampleSession } {
            ShowMockInfo 'Invoke-JiraMethod' 'Method', 'Uri', 'Session'
            New-Object -TypeName psobject
        }

        Mock Invoke-JiraMethod -ModuleName JiraPS {
            ShowMockInfo 'Invoke-JiraMethod' 'Method', 'Uri', 'Session'
            throw "Unidentified call to Invoke-JiraMethod"
        }
        #endregion Mocks

        Context "Sanity checking" {
            $command = Get-Command -Name New-JiraSession

            defParam $command 'Session'
            defParam $command 'Headers'
            defParam $command 'SessionName'
            defParam $command 'ServerName'
        }

        Context "Behavior testing" {
            It "uses Basic Authentication to generate a session" {
                { New-JiraSession -Credential $sampleCredential } | Should -Not -Throw

                $assertMockCalledSplat = @{
                    CommandName     = 'Invoke-JiraMethod'
                    ModuleName      = 'JiraPS'
                    Exactly         = $true
                    Times           = 1
                    Scope           = 'It'
                }
                Assert-MockCalled @assertMockCalledSplat
            }

            It "can influence the Headers used in the request" {
                { New-JiraSession -Credential $sampleCredential -Headers @{ "X-Header" = $true } } | Should -Not -Throw

                $assertMockCalledSplat = @{
                    CommandName     = 'Invoke-JiraMethod'
                    ModuleName      = 'JiraPS'
                    ParameterFilter = {
                        $Headers.ContainsKey("X-Header")
                    }
                    Exactly         = $true
                    Times           = 1
                    Scope           = 'It'
                }
                Assert-MockCalled @assertMockCalledSplat
            }

            It "stores the session in the module's variable" {
                New-JiraSession -Credential $sampleCredential

                $script:JiraSessions["Default"] | Should -BeExactly $sampleSession
            }

            It "stores the named session in the module's variable" {
                New-JiraSession -Credential $sampleCredential -SessionName "Test"

                $script:JiraSessions["Test"] | Should -BeExactly $sampleSession
            }

            It "it gets right server config" {
                New-JiraSession -Credential $sampleCredential -ServerName "Test"

                $assertMockCalledSplat = @{
                    CommandName     = 'Get-JiraConfigServer'
                    ModuleName      = 'JiraPS'
                    ParameterFilter = {
                        $Name -eq "Test"
                    }
                    Exactly         = $true
                    Times           = 1
                    Scope           = 'It'
                }
                Assert-MockCalled @assertMockCalledSplat
            }
        }

        Context "Input testing" { }
    }
}
