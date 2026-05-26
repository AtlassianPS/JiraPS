#requires -modules @{ ModuleName = "Pester"; ModuleVersion = "5.7"; MaximumVersion = "5.999" }

Describe 'Tools/update.dependencies.ps1' -Tag Unit {
    It 'delegates dependency updates to the shared standards updater with expected paths and switches' {
        $projectRoot = if (
            $env:BHProjectPath -and
            (Test-Path -LiteralPath (Join-Path -Path $env:BHProjectPath -ChildPath 'CODEOWNERS'))
        ) {
            (Resolve-Path -LiteralPath $env:BHProjectPath).ProviderPath
        }
        else {
            $candidate = (Resolve-Path -LiteralPath $PSScriptRoot).ProviderPath
            while ($candidate -and ($candidate -ne [System.IO.Path]::GetPathRoot($candidate))) {
                if (Test-Path -LiteralPath (Join-Path -Path $candidate -ChildPath 'CODEOWNERS')) {
                    break
                }

                $candidate = Split-Path -Path $candidate -Parent
            }

            if (-not $candidate -or -not (Test-Path -LiteralPath (Join-Path -Path $candidate -ChildPath 'CODEOWNERS'))) {
                throw "Could not resolve repository root from '$PSScriptRoot'."
            }

            $candidate
        }

        $sourceToolsPath = Join-Path -Path $projectRoot -ChildPath 'Tools'
        $harnessRoot = Join-Path -Path $TestDrive -ChildPath ([Guid]::NewGuid().ToString())
        $toolsPath = Join-Path -Path $harnessRoot -ChildPath 'Tools'
        $modulePath = Join-Path -Path $harnessRoot -ChildPath 'JiraPS'
        $mockModulePath = Join-Path -Path $harnessRoot -ChildPath 'mockModules/AtlassianPS.Standards/0.1.9'
        $scriptPath = Join-Path -Path $toolsPath -ChildPath 'update.dependencies.ps1'
        $capturePath = Join-Path -Path $TestDrive -ChildPath 'update-deps.json'
        $escapedCapturePath = $capturePath.Replace("'", "''")

        $null = New-Item -Path $toolsPath -ItemType Directory -Force
        $null = New-Item -Path $modulePath -ItemType Directory -Force
        $null = New-Item -Path $mockModulePath -ItemType Directory -Force

        Copy-Item -LiteralPath (Join-Path -Path $sourceToolsPath -ChildPath 'update.dependencies.ps1') -Destination $scriptPath

        Set-Content -LiteralPath (Join-Path -Path $toolsPath -ChildPath 'build.requirements.psd1') -Value @'
@(
    @{ ModuleName = "AtlassianPS.Standards"; RequiredVersion = "0.1.9" }
    @{ ModuleName = "InvokeBuild"; RequiredVersion = "5.14.23" }
)
'@

        Set-Content -LiteralPath (Join-Path -Path $modulePath -ChildPath 'JiraPS.psd1') -Value @'
@{
    RootModule      = 'JiraPS.psm1'
    ModuleVersion   = '3.0'
    RequiredModules = @()
}
'@

        Set-Content -LiteralPath (Join-Path -Path $mockModulePath -ChildPath 'AtlassianPS.Standards.psm1') -Value @"
function Update-AtlassianPSDependencyReference {
    [CmdletBinding()]
    param(
        [String]`$BuildRequirementsPath,
        [String]`$ManifestPath,
        [Switch]`$SkipBuildRequirement,
        [Switch]`$SkipManifestRequirement
    )

    [PSCustomObject]@{
        BuildRequirementsPath   = `$BuildRequirementsPath
        ManifestPath            = `$ManifestPath
        SkipBuildRequirement    = [Boolean]`$SkipBuildRequirement
        SkipManifestRequirement = [Boolean]`$SkipManifestRequirement
    } | ConvertTo-Json -Compress | Set-Content -LiteralPath '$escapedCapturePath'

    return [PSCustomObject]@{
        SkipBuildRequirement    = [Boolean]`$SkipBuildRequirement
        SkipManifestRequirement = [Boolean]`$SkipManifestRequirement
    }
}

Export-ModuleMember -Function Update-AtlassianPSDependencyReference
"@

        Set-Content -LiteralPath (Join-Path -Path $mockModulePath -ChildPath 'AtlassianPS.Standards.psd1') -Value @'
@{
    RootModule        = 'AtlassianPS.Standards.psm1'
    ModuleVersion     = '0.1.9'
    GUID              = 'c72f680f-a8f2-434e-8b70-80e0099f90d7'
    FunctionsToExport = @('*')
}
'@

        Mock -CommandName Get-PSRepository -MockWith {
            [PSCustomObject]@{
                Name               = 'PSGallery'
                SourceLocation     = 'https://www.powershellgallery.com/api/v2/'
                InstallationPolicy = 'Trusted'
            }
        }
        Mock -CommandName Register-PSRepository -MockWith {}
        Mock -CommandName Get-PackageProvider -MockWith { [PSCustomObject]@{ Name = 'NuGet'; Version = [Version] '2.8.5.208' } }
        Mock -CommandName Install-PackageProvider -MockWith {}
        Mock -CommandName Set-PSRepository -MockWith {}
        Mock -CommandName Install-Module -MockWith {}

        $moduleSearchPath = Join-Path -Path $harnessRoot -ChildPath 'mockModules'
        $originalModulePath = $env:PSModulePath
        $env:PSModulePath = "$moduleSearchPath$([System.IO.Path]::PathSeparator)$originalModulePath"
        try {
            $result = & $scriptPath -SkipBuildRequirement -SkipManifestRequirement
        }
        finally {
            $env:PSModulePath = $originalModulePath
            Remove-Module -Name 'AtlassianPS.Standards' -Force -ErrorAction SilentlyContinue
        }

        $captured = Get-Content -LiteralPath $capturePath -Raw | ConvertFrom-Json

        $captured.BuildRequirementsPath | Should -Be (Join-Path -Path $harnessRoot -ChildPath 'Tools/build.requirements.psd1')
        $captured.ManifestPath | Should -Be (Join-Path -Path $harnessRoot -ChildPath 'JiraPS/JiraPS.psd1')
        $captured.SkipBuildRequirement | Should -BeTrue
        $captured.SkipManifestRequirement | Should -BeTrue
        $result.SkipBuildRequirement | Should -BeTrue
        $result.SkipManifestRequirement | Should -BeTrue
    }

    It 'installs the required standards version from build.requirements when not present locally' {
        $projectRoot = if (
            $env:BHProjectPath -and
            (Test-Path -LiteralPath (Join-Path -Path $env:BHProjectPath -ChildPath 'CODEOWNERS'))
        ) {
            (Resolve-Path -LiteralPath $env:BHProjectPath).ProviderPath
        }
        else {
            $candidate = (Resolve-Path -LiteralPath $PSScriptRoot).ProviderPath
            while ($candidate -and ($candidate -ne [System.IO.Path]::GetPathRoot($candidate))) {
                if (Test-Path -LiteralPath (Join-Path -Path $candidate -ChildPath 'CODEOWNERS')) {
                    break
                }

                $candidate = Split-Path -Path $candidate -Parent
            }

            if (-not $candidate -or -not (Test-Path -LiteralPath (Join-Path -Path $candidate -ChildPath 'CODEOWNERS'))) {
                throw "Could not resolve repository root from '$PSScriptRoot'."
            }

            $candidate
        }

        $sourceToolsPath = Join-Path -Path $projectRoot -ChildPath 'Tools'
        $harnessRoot = Join-Path -Path $TestDrive -ChildPath ([Guid]::NewGuid().ToString())
        $toolsPath = Join-Path -Path $harnessRoot -ChildPath 'Tools'
        $modulePath = Join-Path -Path $harnessRoot -ChildPath 'JiraPS'
        $mockModulePath = Join-Path -Path $harnessRoot -ChildPath 'mockModules/AtlassianPS.Standards/9.9.9'
        $scriptPath = Join-Path -Path $toolsPath -ChildPath 'update.dependencies.ps1'

        $null = New-Item -Path $toolsPath -ItemType Directory -Force
        $null = New-Item -Path $modulePath -ItemType Directory -Force
        $null = New-Item -Path $mockModulePath -ItemType Directory -Force

        Copy-Item -LiteralPath (Join-Path -Path $sourceToolsPath -ChildPath 'update.dependencies.ps1') -Destination $scriptPath

        Set-Content -LiteralPath (Join-Path -Path $toolsPath -ChildPath 'build.requirements.psd1') -Value @'
@(
    @{ ModuleName = "AtlassianPS.Standards"; RequiredVersion = "9.9.9" }
)
'@

        Set-Content -LiteralPath (Join-Path -Path $modulePath -ChildPath 'JiraPS.psd1') -Value @'
@{
    RootModule      = 'JiraPS.psm1'
    ModuleVersion   = '3.0'
    RequiredModules = @()
}
'@

        Set-Content -LiteralPath (Join-Path -Path $mockModulePath -ChildPath 'AtlassianPS.Standards.psm1') -Value @'
function Update-AtlassianPSDependencyReference {
    [CmdletBinding()]
    param(
        [String]$BuildRequirementsPath,
        [String]$ManifestPath,
        [Switch]$SkipBuildRequirement,
        [Switch]$SkipManifestRequirement
    )

    return [PSCustomObject]@{
        Installed = $true
        BuildRequirementsPath = $BuildRequirementsPath
        ManifestPath = $ManifestPath
        SkipBuildRequirement = [Boolean]$SkipBuildRequirement
        SkipManifestRequirement = [Boolean]$SkipManifestRequirement
    }
}

Export-ModuleMember -Function Update-AtlassianPSDependencyReference
'@

        Set-Content -LiteralPath (Join-Path -Path $mockModulePath -ChildPath 'AtlassianPS.Standards.psd1') -Value @'
@{
    RootModule        = 'AtlassianPS.Standards.psm1'
    ModuleVersion     = '9.9.9'
    GUID              = 'e61a3f95-a8d0-40ff-92cb-9e792ebd7d9f'
    FunctionsToExport = @('*')
}
'@

        Mock -CommandName Get-PSRepository -MockWith {
            [PSCustomObject]@{
                Name               = 'PSGallery'
                SourceLocation     = 'https://www.powershellgallery.com/api/v2/'
                InstallationPolicy = 'Untrusted'
            }
        }
        Mock -CommandName Register-PSRepository -MockWith {}
        Mock -CommandName Get-PackageProvider -MockWith { [PSCustomObject]@{ Name = 'NuGet'; Version = [Version] '2.8.5.100' } }
        Mock -CommandName Install-Module -MockWith {}

        $installPackageProviderCapturePath = Join-Path -Path $TestDrive -ChildPath 'update.installpackageprovider.called'
        $setPSRepositoryCapturePath = Join-Path -Path $TestDrive -ChildPath 'update.setpsrepository.called'
        $installPackageProviderCapturePathEscaped = $installPackageProviderCapturePath.Replace("'", "''")
        $setPSRepositoryCapturePathEscaped = $setPSRepositoryCapturePath.Replace("'", "''")
        Set-Item -Path Function:Global:Install-PackageProvider -Value ([scriptblock]::Create(@"
param([String]`$Name, [String]`$MinimumVersion, [String]`$Scope, [Switch]`$Force)
Set-Content -LiteralPath '$installPackageProviderCapturePathEscaped' -Value 'called'
"@))
        Set-Item -Path Function:Global:Set-PSRepository -Value ([scriptblock]::Create(@"
param([String]`$Name, [String]`$InstallationPolicy)
Set-Content -LiteralPath '$setPSRepositoryCapturePathEscaped' -Value 'called'
"@))

        $moduleSearchPath = Join-Path -Path $harnessRoot -ChildPath 'mockModules'
        $originalModulePath = $env:PSModulePath
        $env:PSModulePath = "$moduleSearchPath$([System.IO.Path]::PathSeparator)$originalModulePath"
        try {
            $result = & $scriptPath -RuntimePSEdition Desktop -ForceDesktopBootstrapRemediation
        }
        finally {
            $env:PSModulePath = $originalModulePath
            Remove-Module -Name 'AtlassianPS.Standards' -Force -ErrorAction SilentlyContinue
            if (Test-Path -LiteralPath Function:Global:Install-PackageProvider) {
                Remove-Item -LiteralPath Function:Global:Install-PackageProvider
            }

            if (Test-Path -LiteralPath Function:Global:Set-PSRepository) {
                Remove-Item -LiteralPath Function:Global:Set-PSRepository
            }
        }

        Test-Path -LiteralPath $installPackageProviderCapturePath | Should -BeTrue
        Test-Path -LiteralPath $setPSRepositoryCapturePath | Should -BeTrue
        Should -Invoke -CommandName Install-Module -Exactly -Times 1 -ParameterFilter {
            $Name -eq 'AtlassianPS.Standards' -and
            $RequiredVersion -eq '9.9.9' -and
            $Scope -eq 'CurrentUser' -and
            $Repository -eq 'PSGallery' -and
            [Boolean]$AllowClobber -and
            [Boolean]$Force
        }
        $result.Installed | Should -BeTrue
    }

    It 'honors -WhatIf and does not call the shared dependency updater' {
        $projectRoot = if (
            $env:BHProjectPath -and
            (Test-Path -LiteralPath (Join-Path -Path $env:BHProjectPath -ChildPath 'CODEOWNERS'))
        ) {
            (Resolve-Path -LiteralPath $env:BHProjectPath).ProviderPath
        }
        else {
            $candidate = (Resolve-Path -LiteralPath $PSScriptRoot).ProviderPath
            while ($candidate -and ($candidate -ne [System.IO.Path]::GetPathRoot($candidate))) {
                if (Test-Path -LiteralPath (Join-Path -Path $candidate -ChildPath 'CODEOWNERS')) {
                    break
                }

                $candidate = Split-Path -Path $candidate -Parent
            }

            if (-not $candidate -or -not (Test-Path -LiteralPath (Join-Path -Path $candidate -ChildPath 'CODEOWNERS'))) {
                throw "Could not resolve repository root from '$PSScriptRoot'."
            }

            $candidate
        }

        $sourceToolsPath = Join-Path -Path $projectRoot -ChildPath 'Tools'
        $harnessRoot = Join-Path -Path $TestDrive -ChildPath ([Guid]::NewGuid().ToString())
        $toolsPath = Join-Path -Path $harnessRoot -ChildPath 'Tools'
        $modulePath = Join-Path -Path $harnessRoot -ChildPath 'JiraPS'
        $scriptPath = Join-Path -Path $toolsPath -ChildPath 'update.dependencies.ps1'

        $null = New-Item -Path $toolsPath -ItemType Directory -Force
        $null = New-Item -Path $modulePath -ItemType Directory -Force

        Copy-Item -LiteralPath (Join-Path -Path $sourceToolsPath -ChildPath 'update.dependencies.ps1') -Destination $scriptPath

        Set-Content -LiteralPath (Join-Path -Path $toolsPath -ChildPath 'build.requirements.psd1') -Value @'
@(
    @{ ModuleName = "AtlassianPS.Standards"; RequiredVersion = "0.1.9" }
)
'@

        Set-Content -LiteralPath (Join-Path -Path $modulePath -ChildPath 'JiraPS.psd1') -Value @'
@{
    RootModule      = 'JiraPS.psm1'
    ModuleVersion   = '3.0'
    RequiredModules = @()
}
'@

        Mock -CommandName Get-PSRepository -MockWith {
            [PSCustomObject]@{
                Name               = 'PSGallery'
                SourceLocation     = 'https://www.powershellgallery.com/api/v2/'
                InstallationPolicy = 'Trusted'
            }
        }
        Mock -CommandName Register-PSRepository -MockWith {}
        Mock -CommandName Install-Module -MockWith {}
        Mock -CommandName Import-Module -MockWith {}

        $result = & $scriptPath -WhatIf

        Should -Invoke -CommandName Install-Module -Exactly -Times 0
        $result.Skipped | Should -BeTrue
    }

    It 'fails with clear guidance when PSGallery is unavailable after registration attempt' {
        $projectRoot = if (
            $env:BHProjectPath -and
            (Test-Path -LiteralPath (Join-Path -Path $env:BHProjectPath -ChildPath 'CODEOWNERS'))
        ) {
            (Resolve-Path -LiteralPath $env:BHProjectPath).ProviderPath
        }
        else {
            $candidate = (Resolve-Path -LiteralPath $PSScriptRoot).ProviderPath
            while ($candidate -and ($candidate -ne [System.IO.Path]::GetPathRoot($candidate))) {
                if (Test-Path -LiteralPath (Join-Path -Path $candidate -ChildPath 'CODEOWNERS')) {
                    break
                }

                $candidate = Split-Path -Path $candidate -Parent
            }

            if (-not $candidate -or -not (Test-Path -LiteralPath (Join-Path -Path $candidate -ChildPath 'CODEOWNERS'))) {
                throw "Could not resolve repository root from '$PSScriptRoot'."
            }

            $candidate
        }

        $sourceToolsPath = Join-Path -Path $projectRoot -ChildPath 'Tools'
        $harnessRoot = Join-Path -Path $TestDrive -ChildPath ([Guid]::NewGuid().ToString())
        $toolsPath = Join-Path -Path $harnessRoot -ChildPath 'Tools'
        $modulePath = Join-Path -Path $harnessRoot -ChildPath 'JiraPS'
        $scriptPath = Join-Path -Path $toolsPath -ChildPath 'update.dependencies.ps1'

        $null = New-Item -Path $toolsPath -ItemType Directory -Force
        $null = New-Item -Path $modulePath -ItemType Directory -Force

        Copy-Item -LiteralPath (Join-Path -Path $sourceToolsPath -ChildPath 'update.dependencies.ps1') -Destination $scriptPath

        Set-Content -LiteralPath (Join-Path -Path $toolsPath -ChildPath 'build.requirements.psd1') -Value @'
@(
    @{ ModuleName = "AtlassianPS.Standards"; RequiredVersion = "0.1.9" }
)
'@

        Set-Content -LiteralPath (Join-Path -Path $modulePath -ChildPath 'JiraPS.psd1') -Value @'
@{
    RootModule      = 'JiraPS.psm1'
    ModuleVersion   = '3.0'
    RequiredModules = @()
}
'@

        Mock -CommandName Get-PSRepository -MockWith { $null }
        Mock -CommandName Register-PSRepository -MockWith {}
        Mock -CommandName Install-Module -MockWith {}

        {
            & $scriptPath
        } | Should -Throw -ExpectedMessage '*PSGallery repository is unavailable*'
    }

    It 'fails fast when shared updater emits a non-terminating error' {
        $projectRoot = if (
            $env:BHProjectPath -and
            (Test-Path -LiteralPath (Join-Path -Path $env:BHProjectPath -ChildPath 'CODEOWNERS'))
        ) {
            (Resolve-Path -LiteralPath $env:BHProjectPath).ProviderPath
        }
        else {
            $candidate = (Resolve-Path -LiteralPath $PSScriptRoot).ProviderPath
            while ($candidate -and ($candidate -ne [System.IO.Path]::GetPathRoot($candidate))) {
                if (Test-Path -LiteralPath (Join-Path -Path $candidate -ChildPath 'CODEOWNERS')) {
                    break
                }

                $candidate = Split-Path -Path $candidate -Parent
            }

            if (-not $candidate -or -not (Test-Path -LiteralPath (Join-Path -Path $candidate -ChildPath 'CODEOWNERS'))) {
                throw "Could not resolve repository root from '$PSScriptRoot'."
            }

            $candidate
        }

        $sourceToolsPath = Join-Path -Path $projectRoot -ChildPath 'Tools'
        $harnessRoot = Join-Path -Path $TestDrive -ChildPath ([Guid]::NewGuid().ToString())
        $toolsPath = Join-Path -Path $harnessRoot -ChildPath 'Tools'
        $modulePath = Join-Path -Path $harnessRoot -ChildPath 'JiraPS'
        $mockModulePath = Join-Path -Path $harnessRoot -ChildPath 'mockModules/AtlassianPS.Standards/0.1.9'
        $scriptPath = Join-Path -Path $toolsPath -ChildPath 'update.dependencies.ps1'

        $null = New-Item -Path $toolsPath -ItemType Directory -Force
        $null = New-Item -Path $modulePath -ItemType Directory -Force
        $null = New-Item -Path $mockModulePath -ItemType Directory -Force

        Copy-Item -LiteralPath (Join-Path -Path $sourceToolsPath -ChildPath 'update.dependencies.ps1') -Destination $scriptPath

        Set-Content -LiteralPath (Join-Path -Path $toolsPath -ChildPath 'build.requirements.psd1') -Value @'
@(
    @{ ModuleName = "AtlassianPS.Standards"; RequiredVersion = "0.1.9" }
    @{ ModuleName = "InvokeBuild"; RequiredVersion = "5.14.23" }
)
'@

        Set-Content -LiteralPath (Join-Path -Path $modulePath -ChildPath 'JiraPS.psd1') -Value @'
@{
    RootModule      = 'JiraPS.psm1'
    ModuleVersion   = '3.0'
    RequiredModules = @()
}
'@

        Set-Content -LiteralPath (Join-Path -Path $mockModulePath -ChildPath 'AtlassianPS.Standards.psm1') -Value @'
function Update-AtlassianPSDependencyReference {
    [CmdletBinding()]
    param(
        [String]$BuildRequirementsPath,
        [String]$ManifestPath,
        [Switch]$SkipBuildRequirement,
        [Switch]$SkipManifestRequirement
    )

    Write-Error -Message "simulated updater failure"
}

Export-ModuleMember -Function Update-AtlassianPSDependencyReference
'@

        Set-Content -LiteralPath (Join-Path -Path $mockModulePath -ChildPath 'AtlassianPS.Standards.psd1') -Value @'
@{
    RootModule        = 'AtlassianPS.Standards.psm1'
    ModuleVersion     = '0.1.9'
    GUID              = 'c72f680f-a8f2-434e-8b70-80e0099f90d7'
    FunctionsToExport = @('*')
}
'@

        Mock -CommandName Get-PSRepository -MockWith {
            [PSCustomObject]@{
                Name               = 'PSGallery'
                SourceLocation     = 'https://www.powershellgallery.com/api/v2/'
                InstallationPolicy = 'Trusted'
            }
        }
        Mock -CommandName Register-PSRepository -MockWith {}
        Mock -CommandName Get-PackageProvider -MockWith { [PSCustomObject]@{ Name = 'NuGet'; Version = [Version] '2.8.5.208' } }
        Mock -CommandName Install-PackageProvider -MockWith {}
        Mock -CommandName Set-PSRepository -MockWith {}
        Mock -CommandName Install-Module -MockWith {}

        $moduleSearchPath = Join-Path -Path $harnessRoot -ChildPath 'mockModules'
        $originalModulePath = $env:PSModulePath
        $env:PSModulePath = "$moduleSearchPath$([System.IO.Path]::PathSeparator)$originalModulePath"
        try {
            {
                & $scriptPath -SkipBuildRequirement -SkipManifestRequirement | Out-Null
            } | Should -Throw -ExpectedMessage '*simulated updater failure*'
        }
        finally {
            $env:PSModulePath = $originalModulePath
            Remove-Module -Name 'AtlassianPS.Standards' -Force -ErrorAction SilentlyContinue
        }
    }
}
