#requires -modules Metadata

Import-Module $PSScriptRoot/BuildTools.psm1 -Force
Import-Module Metadata -Force

$modules = Get-Dependency
$output = "@(`n"

foreach ($module in $modules) {
    Write-Output "Checking for module: $($module.Name)"
    $source = Find-Module $module.Name -Repository PSGallery -ErrorAction SilentlyContinue

    if ($source.version -gt $module.RequiredVersion) {
        Write-Output "updating $($module.Name): v$($module.RequiredVersion) --> $($source.Version)"
        $output += "    @{ ModuleName = `"$($module.Name)`"; RequiredVersion = `"$($source.Version)`" }`n"
    }
    else {
        $output += "    @{ ModuleName = `"$($module.Name)`"; RequiredVersion = `"$($module.RequiredVersion)`" }`n"
    }
}
$output += ")`n"

Set-Content -Value $output -Path "$PSScriptRoot/build.requirements.psd1" -Force

function Update-PinnedPSScriptAnalyzerSettingsUri {
    [CmdletBinding(SupportsShouldProcess = $true)]
    param()

    $settingsFilePath = 'standards/PSScriptAnalyzerSettings.psd1'
    $setupScriptPath = Join-Path $PSScriptRoot 'setup.ps1'
    $commitApiUri = "https://api.github.com/repos/AtlassianPS/.github/commits?path=$settingsFilePath&sha=master&per_page=1"

    Write-Output "Checking pinned .github commit for $settingsFilePath"
    try {
        $response = Invoke-RestMethod -Uri $commitApiUri -Method Get -ErrorAction Stop
    }
    catch {
        throw "Unable to query latest commit for shared PSScriptAnalyzer settings. $($_.Exception.Message)"
    }

    if (-not $response -or -not $response[0] -or -not $response[0].sha) {
        throw "No commit data returned for shared PSScriptAnalyzer settings."
    }

    $latestCommit = $response[0].sha
    $newUri = "https://raw.githubusercontent.com/AtlassianPS/.github/$latestCommit/$settingsFilePath"
    $setupContent = [System.IO.File]::ReadAllText($setupScriptPath)
    $oldUriPattern = "(?m)^\$psScriptAnalyzerSettingsUri = 'https://raw\.githubusercontent\.com/AtlassianPS/\.github/[^']+/standards/PSScriptAnalyzerSettings\.psd1'$"
    $newUriLine = "`$psScriptAnalyzerSettingsUri = '$newUri'"

    if ($setupContent -notmatch $oldUriPattern) {
        Write-Warning "Unable to locate pinned PSScriptAnalyzer URI in setup.ps1; skipping."
        return
    }

    $updatedContent = [System.Text.RegularExpressions.Regex]::Replace($setupContent, $oldUriPattern, $newUriLine, [System.Text.RegularExpressions.RegexOptions]::Multiline)
    if ($updatedContent -eq $setupContent) {
        Write-Output "Pinned PSScriptAnalyzer URI already up to date."
        return
    }

    if ($PSCmdlet.ShouldProcess($setupScriptPath, "Update pinned PSScriptAnalyzer settings URI")) {
        $updatedContent = $updatedContent -replace "`r?`n", "`r`n"
        [System.IO.File]::WriteAllText($setupScriptPath, $updatedContent, [System.Text.UTF8Encoding]::new($true))
        Write-Output "Updated pinned PSScriptAnalyzer URI to commit $latestCommit"
    }
}

Update-PinnedPSScriptAnalyzerSettingsUri
