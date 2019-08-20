#requires -modules BuildHelpers
#requires -modules @{ ModuleName = "Pester"; ModuleVersion = "4.4.0" }

Describe "ConvertTo-JiraSession" -Tag 'Unit' {

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

        $sampleSessionName = "SessionOne"
        $sampleUsername = 'powershell-test'

        $props = @{
            Name = $sampleSessionName
            WebSession = (New-Object -TypeName Microsoft.PowerShell.Commands.WebRequestSession)
            ServerConfig = $null
        }

        $sampleSession = New-Object -TypeName psobject -Property $props

        $script:JiraSessions = @{
            $sampleSessionName = $sampleSession
        }

        $sampleCredential = New-Object -TypeName pscredential -ArgumentList "test",(ConvertTo-SecureString -String "test" -AsPlainText -Force)
        $sampleServerConfig = New-Object -TypeName psobject

        It "converts string to existing session" {
            $r = ConvertTo-JiraSession -InputObject $sampleSessionName
            $r | Should BeExactly $sampleSession
        }

        It "throws terminate error if it can not convert string" {
            { ConvertTo-JiraSession -InputObject "AnyOtherName" } | Should -Throw
        }

        It "converts credential" {
            $r = ConvertTo-JiraSession -InputObject $sampleCredential
            $r | Should Not BeNullOrEmpty
            $r.PSObject.TypeNames | Should Contain "JiraPS.Session"
            $r.WebSession | Should BeOfType Microsoft.PowerShell.Commands.WebRequestSession
            $r.WebSession.Credential | Should BeNullOrEmpty
        }

        It "creates new session be parameters provided" {
            $r = ConvertTo-JiraSession -Name $sampleSessionName -Credential $sampleCredential -ServerConfig $sampleServerConfig
            $r | Should Not BeNullOrEmpty
            $r.PSObject.TypeNames | Should Contain "JiraPS.Session"
            $r.WebSession | Should BeOfType Microsoft.PowerShell.Commands.WebRequestSession
            $r.WebSession.Credential | Should BeNullOrEmpty
            $r.ServerConfig | Should BeExactly $sampleServerConfig
        }
    }
}
