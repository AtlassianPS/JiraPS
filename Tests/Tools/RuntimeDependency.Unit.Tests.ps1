#requires -modules @{ ModuleName = "Pester"; ModuleVersion = "6.2.0"; MaximumVersion = "6.999" }

Describe 'Numeric runtime dependency bounds' -Tag Unit {
    BeforeAll {
        . "$PSScriptRoot/../Helpers/TestTools.ps1"
        $root = Resolve-ProjectRoot
        $moduleName = if (Test-Path (Join-Path $root 'JiraPS/JiraPS.psd1')) { 'JiraPS' }
        else { 'AtlassianPS.Configuration' }
        $script:requirements = (Import-PowerShellDataFile (Join-Path $root "$moduleName/$moduleName.psd1")).RequiredModules
        $script:engine = [Diagnostics.Process]::GetCurrentProcess().MainModule.FileName
        $script:runner = Join-Path $TestDrive 'import-fixture.ps1'
        Set-Content $script:runner @'
param($ModuleRoot, $Manifest, [string]$Expected)
$env:PSModulePath = $ModuleRoot
try {
    Import-Module $Manifest -ErrorAction Stop
    $actual = $true
}
catch { $actual = $false }
if ($actual -ne ($Expected -eq 'True')) { exit 1 }
exit 0
'@
    }

    It 'accepts compatible versions and rejects lower or next-major-only installations' {
        foreach ($requirement in $script:requirements) {
            $minimum = [Version]$requirement.ModuleVersion
            $lower = if ($minimum.Build -gt 0) { [Version]::new($minimum.Major, $minimum.Minor, $minimum.Build - 1) }
            else { [Version]::new($minimum.Major, $minimum.Minor - 1, 99) }
            $later = [Version]::new($minimum.Major, $minimum.Minor + 1, 0)
            $nextMajor = [Version]::new($minimum.Major + 1, 0, 0)
            foreach ($case in @(
                    @{ Versions = @($minimum); Expected = $true }
                    @{ Versions = @($later); Expected = $true }
                    @{ Versions = @($lower); Expected = $false }
                    @{ Versions = @($nextMajor); Expected = $false }
                    @{ Versions = @($lower, $later, $nextMajor); Expected = $true }
                )) {
                $fixtureRoot = Join-Path $TestDrive ([Guid]::NewGuid().ToString())
                $null = New-Item $fixtureRoot -ItemType Directory
                foreach ($version in $case.Versions) {
                    $dependencyRoot = Join-Path $fixtureRoot "FixtureDependency/$version"
                    $null = New-Item $dependencyRoot -ItemType Directory -Force
                    New-ModuleManifest -Path (Join-Path $dependencyRoot 'FixtureDependency.psd1') -ModuleVersion $version
                }
                $spec = @{
                    ModuleName     = 'FixtureDependency'
                    ModuleVersion  = $requirement.ModuleVersion
                    MaximumVersion = $requirement.MaximumVersion
                }
                $parent = Join-Path $fixtureRoot 'FixtureParent.psd1'
                New-ModuleManifest -Path $parent -ModuleVersion 1.0 -RequiredModules @($spec)
                & $script:engine -NoLogo -NonInteractive -NoProfile -File $script:runner $fixtureRoot $parent $case.Expected

                $LASTEXITCODE | Should -Be 0 -Because "$($requirement.ModuleName) versions $($case.Versions -join ', ') should resolve=$($case.Expected)"
            }
        }
    }
}
