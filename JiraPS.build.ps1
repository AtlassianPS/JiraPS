[CmdletBinding()]
param(
    [ValidateSet('None', 'Normal' , 'Detailed', 'Diagnostic')]
    [String] $PesterVerbosity = 'Normal',

    [Parameter()]
    [String] $VersionToPublish,

    [Parameter()]
    [String] $PSGalleryAPIKey,

    # Test filtering parameters
    [Parameter()]
    [String[]] $Tag,

    [Parameter()]
    [String[]] $ExcludeTag,

    # Integration test parameters
    [Parameter()]
    [ValidateRange(1, 16)]
    [Int] $ThrottleLimit = 4
)

Import-Module "$PSScriptRoot/Tools/BuildTools.psm1" -Force
Remove-Item -Path env:\BH* -ErrorAction SilentlyContinue
Set-BuildEnvironment -BuildOutput '$ProjectPath/Release' -ErrorAction SilentlyContinue

#region HarmonizeVariables
switch ($true) {
    { $IsWindows } {
        $OS = "Windows"
        if (-not ($IsCoreCLR)) {
            $OSVersion = $PSVersionTable.BuildVersion.ToString()
        }
    }
    { $IsLinux } {
        $OS = "Linux"
    }
    { $IsMacOs } {
        $OS = "OSX"
    }
    { $IsCoreCLR } {
        $OSVersion = $PSVersionTable.OS
    }
}
#endregion HarmonizeVariables

if ($VersionToPublish) {
    $VersionToPublish = $VersionToPublish.TrimStart('v')
}
$builtManifestPath = "$env:BHBuildOutput/$env:BHProjectName/$env:BHProjectName.psd1"

Task ShowDebugInfo {
    Write-Build Gray
    Write-Build Gray ('BHBuildSystem:              {0}' -f $env:BHBuildSystem)
    Write-Build Gray '-------------------------------------------------------'
    Write-Build Gray ('BHProjectName               {0}' -f $env:BHProjectName)
    Write-Build Gray ('BHProjectPath:              {0}' -f $env:BHProjectPath)
    Write-Build Gray ('BHModulePath:               {0}' -f $env:BHModulePath)
    Write-Build Gray ('BHPSModuleManifest:         {0}' -f $env:BHPSModuleManifest)
    Write-Build Gray ('BHBuildOutput:              {0}' -f $env:BHBuildOutput)
    Write-Build Gray ('builtManifestPath:          {0}' -f $builtManifestPath)
    Write-Build Gray '-------------------------------------------------------'
    Write-Build Gray ('BHBranchName:               {0}' -f $env:BHBranchName)
    Write-Build Gray ('BHCommitHash:               {0}' -f $env:BHCommitHash)
    Write-Build Gray ('BHCommitMessage:            {0}' -f $env:BHCommitMessage)
    Write-Build Gray ('BHBuildNumber               {0}' -f $env:BHBuildNumber)
    Write-Build Gray ('VersionToPublish            {0}' -f $VersionToPublish)
    Write-Build Gray '-------------------------------------------------------'
    Write-Build Gray ('PowerShell version:         {0}' -f $PSVersionTable.PSVersion.ToString())
    Write-Build Gray ('OS:                         {0}' -f $OS)
    Write-Build Gray ('OS Version:                 {0}' -f $OSVersion)
    Write-Build Gray
}

# Synopsis: Run style checks and PSScriptAnalyzer. Collects both result sets
# before throwing so a single run surfaces every issue. Emits GitHub Actions
# workflow commands when running under CI so violations appear as inline
# annotations on the PR diff.
Task Lint {
    $isGitHubActions = [bool]$env:GITHUB_ACTIONS
    ${/} = [System.IO.Path]::DirectorySeparatorChar
    $failures = [System.Collections.Generic.List[String]]::new()

    Write-Build Gray "Running style tests..."

    $pesterConfigHash = @{
        Run    = @{
            PassThru = $true
            Path     = "$env:BHProjectPath/Tests/Style.Tests.ps1"
        }
        Output = @{
            Verbosity = $PesterVerbosity
        }
    }

    $pesterConfig = New-PesterConfiguration -Hashtable $pesterConfigHash
    $testResults = Invoke-Pester -Configuration $pesterConfig
    if ($testResults.FailedCount -gt 0) {
        $failures.Add("$($testResults.FailedCount) style test(s) failed.")
    }
    else {
        Write-Build Green "Style tests: passed."
    }

    Write-Build Gray "Running PSScriptAnalyzer..."

    # Filter Release/* client-side rather than via -ExcludePath: the latter
    # requires wildcard syntax that's easy to get subtly wrong, and Release/
    # only matters for local devs (CI runs Lint before Build).
    $analyzerParams = @{
        Path     = $env:BHProjectPath
        Settings = "$env:BHProjectPath/PSScriptAnalyzerSettings.psd1"
        Severity = @('Error', 'Warning')
        Recurse  = $true
    }

    $results = @(
        Invoke-ScriptAnalyzer @analyzerParams |
            Where-Object { $_.ScriptPath -notlike "*${/}Release${/}*" -and $_.ScriptPath -notlike "*${/}experiment${/}*" }
    )

    if ($results.Count -gt 0) {
        foreach ($result in $results) {
            $color = if ($result.Severity -eq 'Error') { 'Red' } else { 'Yellow' }
            $location = if ($result.ScriptName) { $result.ScriptName } else { '<unknown>' }
            Write-Build $color "[$($result.Severity)] ${location}:$($result.Line) - $($result.RuleName): $($result.Message)"

            if ($isGitHubActions -and $result.ScriptPath) {
                $level = if ($result.Severity -eq 'Error') { 'error' } else { 'warning' }
                $relPath = [System.IO.Path]::GetRelativePath($env:BHProjectPath, $result.ScriptPath)
                # Workflow command escaping per
                # https://docs.github.com/actions/using-workflows/workflow-commands-for-github-actions
                $msg = ($result.Message -replace '%', '%25' -replace "`r", '%0D' -replace "`n", '%0A')
                Write-WorkflowCommand "::${level} file=$relPath,line=$($result.Line),col=$($result.Column),title=$($result.RuleName)::$msg"
            }
        }
        $failures.Add("$($results.Count) PSScriptAnalyzer issue(s) found.")
    }
    else {
        Write-Build Green "PSScriptAnalyzer: no issues found."
    }

    if ($failures.Count -gt 0) {
        throw ("Lint failed:`n  - " + ($failures -join "`n  - "))
    }
}

Task Clean {
    Remove-Item $env:BHBuildOutput -Force -Recurse -ErrorAction SilentlyContinue
    Remove-Item "Test*.xml" -Force -ErrorAction SilentlyContinue
    Remove-Item "$env:BHModulePath/en-US" -Recurse -Force -ErrorAction SilentlyContinue
}

Task Build Clean, {
    if (-not (Test-Path "$env:BHBuildOutput/$env:BHProjectName")) {
        $null = New-Item -Path "$env:BHBuildOutput", "$env:BHBuildOutput/$env:BHProjectName" -ItemType Directory
    }
}, GenerateExternalHelp, CopyModuleFiles, CompileModule, UpdateManifest

# Synopsis: Generate ./Release structure
Task CopyModuleFiles {
    Copy-Item -Path "$env:BHModulePath/*" -Destination "$env:BHBuildOutput/$env:BHProjectName" -Recurse -Force
    Copy-Item -Path @(
        "$env:BHProjectPath/CHANGELOG.md"
        "$env:BHProjectPath/LICENSE"
        "$env:BHProjectPath/README.md"
    ) -Destination "$env:BHBuildOutput/$env:BHProjectName" -Force

    $null = New-Item -Path "$env:BHBuildOutput/Tests" -ItemType Directory -ErrorAction SilentlyContinue
    Copy-Item -Path "$env:BHProjectPath/Tests" -Destination $env:BHBuildOutput -Recurse -Force
    Copy-Item -Path "$env:BHProjectPath/PSScriptAnalyzerSettings.psd1" -Destination $env:BHBuildOutput -Force
}

# Synopsis: Compile all functions into the .psm1 file
Task CompileModule {
    $regionsToKeep = @('Dependencies', 'Configuration')

    $targetFile = "$env:BHBuildOutput/$env:BHProjectName/$env:BHProjectName.psm1"
    $content = Get-Content -Encoding UTF8 -LiteralPath $targetFile
    $capture = $false
    $compiled = ""

    foreach ($line in $content) {
        if ($line -match "^#region ($($regionsToKeep -join "|"))$") {
            $capture = $true
        }
        if (($capture -eq $true) -and ($line -match "^#endregion")) {
            $capture = $false
        }

        if ($capture) {
            $compiled += "$line`r`n"
        }
    }

    $PublicFunctions = @( Get-ChildItem -Path "$env:BHBuildOutput/$env:BHProjectName/Public/*.ps1" -ErrorAction SilentlyContinue )
    $PrivateFunctions = @( Get-ChildItem -Path "$env:BHBuildOutput/$env:BHProjectName/Private/*.ps1" -ErrorAction SilentlyContinue )

    foreach ($function in @($PublicFunctions + $PrivateFunctions)) {
        $compiled += (Get-Content -Path $function.FullName -Raw)
        $compiled += "`r`n"
    }

    $utf8Bom = [System.Text.UTF8Encoding]::new($true)
    [System.IO.File]::WriteAllText($targetFile, $compiled, $utf8Bom)

    "Private", "Public" | ForEach-Object { Remove-Item -Path "$env:BHBuildOutput/$env:BHProjectName/$_" -Recurse -Force }
}

# Synopsis: Use PlatyPS to generate External-Help
Task GenerateExternalHelp {
    Import-Module Microsoft.PowerShell.PlatyPS -Force

    try {
        foreach ($locale in (Get-ChildItem "$env:BHProjectPath/docs" -Attribute Directory)) {
            $outputPath = "$env:BHModulePath/$($locale.Basename)"
            $null = New-Item -ItemType Directory -Path $outputPath -Force

            $commandHelpFiles = Get-ChildItem "$($locale.FullName)/commands/*.md" -File |
                Where-Object { $_.Name -ne 'index.md' }

            if ($commandHelpFiles) {
                $commandHelp = @($commandHelpFiles | Import-MarkdownCommandHelp)
                $commandHelp | Export-MamlCommandHelp -OutputFolder $outputPath -Force

                # PlatyPS 1.0 still drops the per-command MAML into a nested
                # <ModuleName>/ subdirectory; flatten so the help loader finds it.
                $nestedPath = Join-Path $outputPath $env:BHProjectName
                if (Test-Path $nestedPath) {
                    Get-ChildItem $nestedPath -Filter '*.xml' | Move-Item -Destination $outputPath -Force
                    Remove-Item $nestedPath -Recurse -Force
                }

                $mamlFile = Join-Path $outputPath "$env:BHProjectName-help.xml"
                Assert-True (Test-Path $mamlFile) "Expected MAML help file was not created: $mamlFile"

                # Export-MamlCommandHelp drops `aliases` / `pipelineInput` /
                # `<dev:defaultValue>` even though the markdown YAML and the
                # parsed CommandHelp object both carry them. Splice them back
                # in from the in-memory CommandHelp objects so Get-Help -Full
                # surfaces the same data Import-MarkdownCommandHelp captured.
                $xml = [xml](Get-Content $mamlFile -Raw)
                $ns = [System.Xml.XmlNamespaceManager]::new($xml.NameTable)
                $ns.AddNamespace('command', 'http://schemas.microsoft.com/maml/dev/command/2004/10')
                $ns.AddNamespace('dev', 'http://schemas.microsoft.com/maml/dev/2004/10')
                $ns.AddNamespace('maml', 'http://schemas.microsoft.com/maml/2004/10')
                foreach ($help in $commandHelp) {
                    $cmdNode = $xml.SelectSingleNode("//command:command[command:details/command:name='$($help.Title)']", $ns)
                    if (-not $cmdNode) { continue }

                    # Export-MamlCommandHelp dumps every example's full markdown
                    # (fence + prose) into <maml:introduction> and leaves
                    # <dev:code> / <dev:remarks> empty. Get-Help only reads
                    # those two elements, so split the markdown on the first
                    # fenced code block and re-populate them.
                    $exNodes = @($cmdNode.SelectNodes('command:examples/command:example', $ns))
                    for ($i = 0; $i -lt $exNodes.Count -and $i -lt $help.Examples.Count; $i++) {
                        $ex = $exNodes[$i]
                        $remarksMd = $help.Examples[$i].Remarks
                        if (-not $remarksMd) { continue }
                        $codeText = ''
                        $proseText = $remarksMd
                        $fence = [regex]::Match($remarksMd, '(?s)```[a-zA-Z0-9_+\-]*\r?\n(.*?)\r?\n```')
                        if ($fence.Success) {
                            $codeText = $fence.Groups[1].Value.TrimEnd()
                            $proseText = ($remarksMd.Substring(0, $fence.Index) + $remarksMd.Substring($fence.Index + $fence.Length)).Trim()
                        }
                        $intro = $ex.SelectSingleNode('maml:introduction', $ns)
                        if ($intro) { [void]$ex.RemoveChild($intro) }
                        $codeNode = $ex.SelectSingleNode('dev:code', $ns)
                        if (-not $codeNode) {
                            $codeNode = $xml.CreateElement('dev', 'code', 'http://schemas.microsoft.com/maml/dev/2004/10')
                            [void]$ex.AppendChild($codeNode)
                        }
                        $codeNode.InnerText = $codeText
                        $remarksNode = $ex.SelectSingleNode('dev:remarks', $ns)
                        if (-not $remarksNode) {
                            $remarksNode = $xml.CreateElement('dev', 'remarks', 'http://schemas.microsoft.com/maml/dev/2004/10')
                            [void]$ex.AppendChild($remarksNode)
                        }
                        # Strip any existing children, then add a maml:para per
                        # paragraph so Get-Help renders blank lines between them.
                        while ($remarksNode.HasChildNodes) { [void]$remarksNode.RemoveChild($remarksNode.FirstChild) }
                        foreach ($para in ($proseText -split "\r?\n\r?\n")) {
                            if (-not $para.Trim()) { continue }
                            $pn = $xml.CreateElement('maml', 'para', 'http://schemas.microsoft.com/maml/2004/10')
                            $pn.InnerText = $para
                            [void]$remarksNode.AppendChild($pn)
                        }
                    }

                    $paramMap = @{}
                    foreach ($p in $help.Parameters) { $paramMap[$p.Name] = $p }
                    foreach ($pNode in $cmdNode.SelectNodes('.//command:parameter', $ns)) {
                        $pName = $pNode.SelectSingleNode('maml:name', $ns).InnerText
                        if (-not $paramMap.ContainsKey($pName)) { continue }
                        $p = $paramMap[$pName]
                        $aliasText = if ($p.Aliases) { $p.Aliases -join ', ' } else { 'none' }
                        $pNode.SetAttribute('aliases', $aliasText)
                        $byVal = $false; $byName = $false
                        foreach ($set in $p.ParameterSets) {
                            if ($set.ValueFromPipeline) { $byVal = $true }
                            if ($set.ValueFromPipelineByPropertyName) { $byName = $true }
                        }
                        $pipelineText = if ($byVal -and $byName) {
                            'True (ByValue, ByPropertyName)'
                        }
                        elseif ($byVal) { 'True (ByValue)' }
                        elseif ($byName) { 'True (ByPropertyName)' }
                        else { 'False' }
                        $pNode.SetAttribute('pipelineInput', $pipelineText)
                        # <dev:defaultValue> only lives in the flat <command:parameters>
                        # block, not in syntax items. Identify by parent element.
                        if ($pNode.ParentNode.LocalName -eq 'parameters' -and $p.DefaultValue) {
                            $existing = $pNode.SelectSingleNode('dev:defaultValue', $ns)
                            if ($existing) { $pNode.RemoveChild($existing) | Out-Null }
                            $dv = $xml.CreateElement('dev', 'defaultValue', 'http://schemas.microsoft.com/maml/dev/2004/10')
                            $dv.InnerText = $p.DefaultValue
                            $null = $pNode.AppendChild($dv)
                        }
                    }
                }
                $xml.Save($mamlFile)
            }

            # Copy about topics as help text files. UTF-8 with BOM for PowerShell 5
            # compatibility (matches the CompileModule convention introduced in 3107e3a).
            $utf8Bom = [System.Text.UTF8Encoding]::new($true)
            Get-ChildItem "$($locale.FullName)/about_*.md" -File | ForEach-Object {
                $helpTxtName = $_.BaseName + '.help.txt'
                $content = [System.IO.File]::ReadAllText($_.FullName)
                # Tolerate files where the closing `---` is the final line (no trailing newline).
                $content = $content -replace '\A---\r?\n[\s\S]*?\r?\n---\r?\n?', ''
                [System.IO.File]::WriteAllText((Join-Path $outputPath $helpTxtName), $content, $utf8Bom)
            }
        }
    }
    finally {
        Remove-Module Microsoft.PowerShell.PlatyPS -ErrorAction SilentlyContinue
    }
}

# Synopsis: Update the manifest of the module
Task UpdateManifest {
    Remove-Module $env:BHProjectName -ErrorAction SilentlyContinue
    Import-Module $env:BHPSModuleManifest -Force

    $moduleFunctions = (Get-ChildItem "$env:BHModulePath/Public/*.ps1").BaseName
    Metadata\Update-Metadata -Path $builtManifestPath -PropertyName "FunctionsToExport" -Value @($moduleFunctions)

    Metadata\Update-Metadata -Path $builtManifestPath -PropertyName "AliasesToExport" -Value ''
    $moduleAlias = Get-Alias | Where-Object { $_.ModuleName -eq "$env:BHProjectName" }
    if ($moduleAlias) {
        Metadata\Update-Metadata -Path $builtManifestPath -PropertyName "AliasesToExport" -Value @($moduleAlias.Name)
    }
}

Task SetVersion {
    [System.Management.Automation.SemanticVersion]$versionToPublish = $VersionToPublish

    $published = Find-Module -Name $env:BHProjectName -ErrorAction SilentlyContinue
    if ($published) {
        [System.Management.Automation.SemanticVersion]$latestPublished = $published.Version
        Write-Build Gray "Latest published version: $latestPublished"
        Assert-True { $versionToPublish -gt $latestPublished } "Version must be greater than latest published version: $latestPublished"
    }
    else {
        Write-Build Gray "No published version found in PSGallery; skipping version guard"
    }

    $versionString = "{0}.{1}.{2}" -f $versionToPublish.Major, $versionToPublish.Minor, $versionToPublish.Patch
    Metadata\Update-Metadata -Path $builtManifestPath -PropertyName "ModuleVersion" -Value $versionString

    if ($versionToPublish.PreReleaseLabel) {
        Write-Build Gray "Setting Prerelease label: $($versionToPublish.PreReleaseLabel)"
        Metadata\Update-Metadata -Path $builtManifestPath -PropertyName "Prerelease" -Value $versionToPublish.PreReleaseLabel
    }
    else {
        Write-Build Gray "Removing Prerelease label (stable release)"
        Metadata\Update-Metadata -Path $builtManifestPath -PropertyName "Prerelease" -Value ''
    }
}

Task Test {
    # Skip the Integration folder at discovery time so Pester does not run
    # its BeforeDiscovery blocks (which read .env and warn when integration
    # secrets are missing). Use TestIntegration task to run them.
    $integrationPath = Join-Path $env:BHBuildOutput 'Tests/Integration'

    $pesterConfigHash = @{
        Run        = @{
            PassThru    = $true
            Path        = "$env:BHBuildOutput/Tests"
            ExcludePath = @($integrationPath)
        }
        TestResult = @{
            Enabled      = $true
            OutputFormat = 'NUnitXml'
            OutputPath   = "Test-$OS-$($PSVersionTable.PSVersion.ToString()).xml"
        }
        Output     = @{
            Verbosity = $PesterVerbosity
        }
        Filter     = @{
            # Also exclude by tag, in case any integration-tagged tests live
            # outside Tests/Integration. In Pester 5, ExcludeTag takes
            # precedence over Tag, so the -Tag handling below has to remove
            # user-requested tags from this list (and clear ExcludePath) for
            # `Invoke-Build -Task Test -Tag 'Integration'` to do anything.
            ExcludeTag = @('Integration')
        }
        <# CodeCoverage = @{
            Path = $codeCoverageFiles
        } #>
    }

    if ($Tag) {
        $pesterConfigHash.Filter.Tag = $Tag
        $pesterConfigHash.Filter.ExcludeTag = @($pesterConfigHash.Filter.ExcludeTag | Where-Object { $_ -notin $Tag })
        if ('Integration' -in $Tag) {
            $pesterConfigHash.Run.ExcludePath = @()
        }
        Write-Build Gray "Filtering tests by tag(s): $($Tag -join ', ')"
    }

    if ($ExcludeTag) {
        # Merge with default exclusions, then re-apply the Tag intersection
        # so an explicit -Tag still wins over the default ExcludeTag entry.
        $merged = @($pesterConfigHash.Filter.ExcludeTag) + @($ExcludeTag) | Select-Object -Unique
        if ($Tag) {
            $merged = @($merged | Where-Object { $_ -notin $Tag })
        }
        $pesterConfigHash.Filter.ExcludeTag = $merged
        Write-Build Gray "Excluding tests by tag(s): $($pesterConfigHash.Filter.ExcludeTag -join ', ')"
    }

    $pesterConfig = New-PesterConfiguration -Hashtable $pesterConfigHash
    $testResults = Invoke-Pester -Configuration $pesterConfig
    Assert-True ($testResults.FailedCount -eq 0) "$($testResults.FailedCount) Pester test(s) failed."
}

# Synopsis: Run integration tests against live Jira Cloud (no build required)
Task TestIntegration {
    # Validate required environment variables (secrets in CI, env vars locally)
    $requiredEnvVars = @(
        'JIRA_CLOUD_URL'
        'JIRA_CLOUD_USERNAME'
        'JIRA_CLOUD_PASSWORD'
        'JIRA_TEST_PROJECT'
        'JIRA_TEST_ISSUE'
    )
    $missing = $requiredEnvVars | Where-Object {
        [string]::IsNullOrEmpty([Environment]::GetEnvironmentVariable($_))
    }
    if ($missing) {
        throw @"
Required environment variables are not set: $($missing -join ', ')

For CI: Configure these as repository secrets under Settings -> Secrets and variables -> Actions.
For local development: Set these environment variables before running integration tests.
See Tests/README.md for integration test configuration details.
"@
    }

    # Validate runner exists
    $runnerPath = "$env:BHProjectPath/Tests/Invoke-ParallelPester.ps1"
    if (-not (Test-Path $runnerPath)) {
        throw "Integration test runner not found: $runnerPath"
    }

    # NOTE: High ThrottleLimit values (e.g., 6+) may trigger Jira Cloud rate limiting
    # (HTTP 429 + Retry-After). The runner does not currently handle 429 retries.
    # If you experience rate limiting, reduce ThrottleLimit or add delays between tests.
    $runnerParams = @{
        ThrottleLimit = $ThrottleLimit
        Output        = $PesterVerbosity
        OutputPath    = "IntegrationTests.xml"
    }

    # Default to Integration tag if no tag specified
    if ($Tag) {
        $runnerParams.Tag = $Tag
        Write-Build Gray "Running integration tests with tag(s): $($Tag -join ', ')"
    }
    else {
        $runnerParams.Tag = @('Integration')
        Write-Build Gray "Running integration tests (tag: Integration)"
    }

    if ($ExcludeTag) {
        $runnerParams.ExcludeTag = $ExcludeTag
        Write-Build Gray "Excluding tag(s): $($ExcludeTag -join ', ')"
    }

    Write-Build Gray "ThrottleLimit: $ThrottleLimit"
    Write-Build Gray "Output: $($runnerParams.OutputPath)"

    & $runnerPath @runnerParams

    Assert-True ($LASTEXITCODE -eq 0) "Integration tests failed with exit code $LASTEXITCODE"
}

Task Publish SetVersion, SignCode, Package, {
    Assert-True (-not [String]::IsNullOrEmpty($PSGalleryAPIKey)) "No key for the PSGallery"

    Publish-Module -Path "$env:BHBuildOutput/$env:BHProjectName" -NuGetApiKey $PSGalleryAPIKey
}, UpdateHomepage

Task UpdateHomepage {
    # TODO:
}
Task SignCode {
    # TODO: waiting for certificates
}

Task Package {
    $source = "$env:BHBuildOutput\$env:BHProjectName"
    $destination = "$env:BHBuildOutput\$env:BHProjectName.zip"

    Assert-True { Test-Path $source } "Missing files to package"

    Remove-Item $destination -ErrorAction SilentlyContinue
    $null = Compress-Archive -Path $source -DestinationPath $destination
}

Task . Clean, Build, Test
