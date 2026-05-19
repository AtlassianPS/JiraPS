#requires -Modules @{ ModuleName = 'AtlassianPS.Standards'; ModuleVersion = '0.1.6'; MaximumVersion = '0.1.6' }

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
    [Int] $ThrottleLimit = 4,

    # Optional list of test files / directories to scope the TestIntegration task to.
    # Defaults to ./Tests/Integration/ (the whole suite). The Server-track CI workflow
    # uses this to restrict execution to the Server smoke suite while the AMPS standalone
    # image cannot bootstrap a fixture project (see the `server_integration_tests` job
    # in integration_tests.yml for the rationale).
    [Parameter()]
    [String[]] $IntegrationTestPath
)

Import-Module "$PSScriptRoot/Tools/BuildTools.psm1" -Force

$ProjectName = 'JiraPS'
$script:BuildInfo = Initialize-AtlassianPSBuildEnvironment `
    -ProjectName $ProjectName `
    -ProjectPath $PSScriptRoot `
    -VersionToPublish $VersionToPublish `
    -ResetBuildEnvironmentVariables

$builtManifestPath = $script:BuildInfo.BuiltManifestPath

Task ShowDebugInfo {
    Write-AtlassianPSBuildInfo -BuildInfo $script:BuildInfo
}

# Synopsis: Run style checks and PSScriptAnalyzer. Collects both result sets
# before throwing so a single run surfaces every issue. Emits GitHub Actions
# workflow commands when running under CI so violations appear as inline
# annotations on the PR diff.
Task Lint {
    $analyzerPaths = @(
        "$env:BHProjectPath/JiraPS"
        "$env:BHProjectPath/Tests"
        "$env:BHProjectPath/Tools"
        "$env:BHProjectPath/JiraPS.build.ps1"
    )

    $null = Invoke-AtlassianPSLint `
        -ProjectPath $env:BHProjectPath `
        -ModulePath $env:BHModulePath `
        -BuildScriptPath "$env:BHProjectPath/JiraPS.build.ps1" `
        -StyleTestPath "$env:BHProjectPath/Tests/Style.Tests.ps1" `
        -AnalyzerSettingsPath "$env:BHProjectPath/PSScriptAnalyzerSettings.psd1" `
        -AnalyzerPaths $analyzerPaths `
        -PesterVerbosity $PesterVerbosity `
        -Severity @('Error', 'Warning')
}

Task Clean {
    Remove-Item $env:BHBuildOutput -Force -Recurse -ErrorAction SilentlyContinue
    Remove-Item "Test*.xml" -Force -ErrorAction SilentlyContinue
    # `JiraPS/<locale>/` is preserved as the GenerateExternalHelp incremental cache.
}

Task Build Clean, {
    if (-not (Test-Path "$env:BHBuildOutput/$env:BHProjectName")) {
        $null = New-Item -Path "$env:BHBuildOutput", "$env:BHBuildOutput/$env:BHProjectName" -ItemType Directory
    }
}, GenerateExternalHelp, RemoveOrphanedExternalHelp, CopyModuleFiles, CompileModule, UpdateManifest

# Synopsis: Remove generated help artifacts whose source markdown no longer exists.
# Deletions in `docs/` would otherwise survive in `JiraPS/<locale>/` (the
# GenerateExternalHelp cache) and ship via CopyModuleFiles.
Task RemoveOrphanedExternalHelp {
    if (-not (Test-Path $env:BHModulePath)) { return }
    $docsRoot = Join-Path $env:BHProjectPath 'docs'

    # Safety net: only sweep dirs that already look like generated help output.
    # Prevents a missing/renamed `docs/<locale>/` from wiping `Public/` or `Private/`.
    $isHelpOutputDir = {
        param($dir)
        $files = @(Get-ChildItem $dir.FullName -File -ErrorAction SilentlyContinue)
        if ($files.Count -eq 0) { return $false }
        @($files | Where-Object { $_.Name -notlike '*.help.txt' -and $_.Name -notlike '*-help.xml' }).Count -eq 0
    }
    $helpDirs = Get-ChildItem $env:BHModulePath -Directory -ErrorAction SilentlyContinue |
        Where-Object { & $isHelpOutputDir $_ }

    foreach ($localeDir in $helpDirs) {
        $localeDocs = Join-Path $docsRoot $localeDir.Name
        if (-not (Test-Path $localeDocs)) {
            Remove-Item $localeDir.FullName -Recurse -Force
            continue
        }

        $expected = [System.Collections.Generic.HashSet[string]]::new(
            [System.StringComparer]::OrdinalIgnoreCase)

        $hasCommandHelp = Get-ChildItem (Join-Path $localeDocs 'commands/*.md') -File -ErrorAction SilentlyContinue |
            Where-Object { $_.Name -ne 'index.md' } |
            Select-Object -First 1
        if ($hasCommandHelp) {
            $null = $expected.Add("$env:BHProjectName-help.xml")
        }

        Get-ChildItem (Join-Path $localeDocs 'about_*.md') -File -ErrorAction SilentlyContinue |
            ForEach-Object { $null = $expected.Add("$($_.BaseName).help.txt") }

        Get-ChildItem $localeDir.FullName -File -ErrorAction SilentlyContinue |
            Where-Object { -not $expected.Contains($_.Name) } |
            Remove-Item -Force
    }
}

# Synopsis: Generate ./Release structure
Task CopyModuleFiles {
    $additionalFiles = @(
        'CHANGELOG.md'
        'LICENSE'
        'README.md'
    )

    $null = Copy-AtlassianPSModuleArtifacts `
        -ProjectPath $env:BHProjectPath `
        -ModuleName $env:BHProjectName `
        -BuildOutputPath $env:BHBuildOutput `
        -AdditionalFiles $additionalFiles `
        -IncludeTests

    Copy-Item -Path "$env:BHProjectPath/PSScriptAnalyzerSettings.psd1" -Destination $env:BHBuildOutput -Force
}

# Synopsis: Compile all functions into the .psm1 file
Task CompileModule {
    $null = Join-AtlassianPSModuleSource `
        -ReleaseModulePath "$env:BHBuildOutput/$env:BHProjectName" `
        -RegionsToKeep @('Dependencies', 'Configuration')
}

# Synopsis: Use PlatyPS to generate External-Help
Task GenerateExternalHelp -Inputs {
    Get-ChildItem "$env:BHProjectPath/docs" -Recurse -File -Filter '*.md'
} -Outputs {
    foreach ($locale in (Get-ChildItem "$env:BHProjectPath/docs" -Attribute Directory)) {
        $localeOut = Join-Path $env:BHModulePath $locale.BaseName

        $hasCommandHelp = Get-ChildItem "$($locale.FullName)/commands/*.md" -File -ErrorAction SilentlyContinue |
            Where-Object { $_.Name -ne 'index.md' } |
            Select-Object -First 1
        if ($hasCommandHelp) {
            Join-Path $localeOut "$env:BHProjectName-help.xml"
        }

        Get-ChildItem "$($locale.FullName)/about_*.md" -File -ErrorAction SilentlyContinue |
            ForEach-Object { Join-Path $localeOut "$($_.BaseName).help.txt" }
    }
} {
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
                        # One <maml:para> per paragraph; Get-Help inserts a
                        # blank line between sibling para elements.
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
                        # MAML schema places <dev:defaultValue> only on the flat
                        # <command:parameters> entries, not on syntax-item copies.
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
    $null = Update-AtlassianPSModuleManifestExports `
        -SourceModulePath $env:BHModulePath `
        -BuiltManifestPath $builtManifestPath `
        -ModuleName $env:BHProjectName
}

Task SetVersion {
    $versionString = Set-AtlassianPSModuleManifestVersion `
        -BuiltManifestPath $builtManifestPath `
        -ModuleName $env:BHProjectName `
        -VersionToPublish $VersionToPublish
    Write-Build Gray "Resolved release version: $versionString"
}

Task Test {
    # Skip the Integration folder at discovery time so Pester does not run
    # its BeforeDiscovery blocks (which read .env and warn when integration
    # secrets are missing). Use TestIntegration task to run them.
    $integrationPath = Join-Path $env:BHBuildOutput 'Tests/Integration'

    $null = Invoke-AtlassianPSModuleTests `
        -TestPath "$env:BHBuildOutput/Tests" `
        -PesterVerbosity $PesterVerbosity `
        -Tag $Tag `
        -ExcludeTag $ExcludeTag `
        -DefaultExcludeTag @('Integration') `
        -ExcludePath @($integrationPath) `
        -MinimumPesterVersion ([Version]'5.7.0')
}

# Synopsis: Run integration tests against live Jira (Cloud or Data Center; no build required)
Task TestIntegration {
    # Pick the required-env set based on deployment target. CI_JIRA_TYPE is set by the
    # `server_integration_tests` job in integration_tests.yml and by the StartJiraDocker
    # task; it defaults to Cloud so legacy invocations stay unchanged.
    $deploymentType = if ($env:CI_JIRA_TYPE) { $env:CI_JIRA_TYPE } else { 'Cloud' }
    if ($deploymentType -notin @('Cloud', 'Server')) {
        throw "Invalid CI_JIRA_TYPE '$deploymentType'. Must be 'Cloud' or 'Server'."
    }

    $requiredEnvVars = if ($deploymentType -eq 'Server') {
        @(
            'CI_JIRA_URL'
            'CI_JIRA_ADMIN'
            'CI_JIRA_ADMIN_PASSWORD'
            'CI_JIRA_USER'
            'CI_JIRA_USER_PASSWORD'
        )
    }
    else {
        @(
            'JIRA_CLOUD_URL'
            'JIRA_CLOUD_USERNAME'
            'JIRA_CLOUD_PASSWORD'
            'JIRA_TEST_PROJECT'
            'JIRA_TEST_ISSUE'
        )
    }

    $missing = $requiredEnvVars | Where-Object {
        [string]::IsNullOrEmpty([Environment]::GetEnvironmentVariable($_))
    }
    if ($missing) {
        throw @"
Required environment variables for the $deploymentType integration test track are not set: $($missing -join ', ')

For CI: Configure these as repository secrets (Cloud) or workflow env vars (Server) under Settings -> Secrets and variables -> Actions.
For local development: Set these environment variables before running integration tests.
See Tests/Integration/README.md for integration test configuration details.
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
        OutputPath    = "Test-Integration.xml"
    }

    if ($IntegrationTestPath) {
        $runnerParams.Path = $IntegrationTestPath
        Write-Build Gray "Restricting integration tests to: $($IntegrationTestPath -join ', ')"
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

# Synopsis: Start the local Jira Data Center Docker container (for Server-track integration tests)
Task StartJiraDocker {
    if (-not (Get-Command docker -ErrorAction SilentlyContinue)) {
        throw "Docker is required for the Jira Server track. See https://docs.docker.com/get-docker/."
    }
    $composeFile = Join-Path $env:BHProjectPath 'docker-compose.yml'
    Assert-True (Test-Path $composeFile) "docker-compose.yml not found at $composeFile"
    Write-Build Gray "Starting Jira Data Center container via $composeFile (cold start: ~5 min)..."
    Invoke-BuildExec { docker compose -f $composeFile up -d }
    & (Join-Path $env:BHProjectPath 'Tools/Wait-JiraServer.ps1')
}

# Synopsis: Stop the local Jira Data Center Docker container
Task StopJiraDocker {
    if (-not (Get-Command docker -ErrorAction SilentlyContinue)) {
        throw "Docker is required for the Jira Server track. See https://docs.docker.com/get-docker/."
    }
    $composeFile = Join-Path $env:BHProjectPath 'docker-compose.yml'
    Assert-True (Test-Path $composeFile) "docker-compose.yml not found at $composeFile"
    Write-Build Gray "Stopping Jira Data Center container ($composeFile)..."
    Invoke-BuildExec { docker compose -f $composeFile down -v }
}

Task Publish SetVersion, SignCode, Package, {
    Assert-True (-not [String]::IsNullOrEmpty($PSGalleryAPIKey)) "No key for the PSGallery"
    Publish-AtlassianPSModuleRelease -BuildOutputPath $env:BHBuildOutput -ModuleName $env:BHProjectName -ApiKey $PSGalleryAPIKey
}, UpdateHomepage

Task UpdateHomepage {
    # TODO:
}
Task SignCode {
    # TODO: waiting for certificates
}

Task Package {
    $null = New-AtlassianPSModulePackage -BuildOutputPath $env:BHBuildOutput -ModuleName $env:BHProjectName
}

Task . Clean, Build, Test
