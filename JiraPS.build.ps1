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
            Where-Object { $_.ScriptPath -notlike "*${/}Release${/}*" }
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

# Helper: patch the MAML XmlDocument in place to restore the metadata that
# Microsoft.PowerShell.PlatyPS 1.0's Export-MamlCommandHelp drops or mangles:
#
#   * Every <command:parameter> ends up with aliases="none" and
#     pipelineInput="false", regardless of source.
#   * <dev:defaultValue> is never emitted.
#   * INPUTS/OUTPUTS headings of the form '### [A] / [B]' collapse to a
#     single <dev:name>[</dev:name>` because PlatyPS' heading parser chokes
#     on the '/' separator.
#
# Aliases and pipeline behaviour are read back from the live module via
# reflection so the code is the single source of truth (no markdown drift).
# INPUTS/OUTPUTS and default values come from the parsed CommandHelp objects,
# whose Markdig-based parser strips the brackets correctly.
function Repair-MamlMetadata {
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseSingularNouns', '', Justification = '"Metadata" is grammatically singular (mass noun); the analyzer''s pluralization service incorrectly treats it as plural.')]
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [System.Xml.XmlDocument] $Xml,

        [Parameter(Mandatory)]
        [System.Management.Automation.PSModuleInfo] $Module,

        [Hashtable] $CommandHelpMap = @{}
    )

    $devNs = 'http://schemas.microsoft.com/maml/dev/2004/10'
    $mamlNs = 'http://schemas.microsoft.com/maml/2004/10'
    $cmdNs = 'http://schemas.microsoft.com/maml/dev/command/2004/10'

    $nsmgr = [System.Xml.XmlNamespaceManager]::new($Xml.NameTable)
    $nsmgr.AddNamespace('command', $cmdNs)
    $nsmgr.AddNamespace('maml', $mamlNs)
    $nsmgr.AddNamespace('dev', $devNs)

    # Build a maml:description element from a (possibly multi-paragraph) string.
    $buildDescription = {
        param($descriptionText)
        $descElem = $Xml.CreateElement('maml', 'description', $mamlNs)
        $trimmed = ($descriptionText -as [String]).Trim()
        if ($trimmed) {
            foreach ($paragraph in ($trimmed -split '(?:\r?\n){2,}')) {
                $paraText = $paragraph.Trim()
                if ($paraText) {
                    $paraElem = $Xml.CreateElement('maml', 'para', $mamlNs)
                    $paraElem.InnerText = $paraText
                    $null = $descElem.AppendChild($paraElem)
                }
            }
        }
        else {
            $null = $descElem.AppendChild($Xml.CreateElement('maml', 'para', $mamlNs))
        }
        $descElem
    }

    foreach ($commandNode in $Xml.SelectNodes('//command:command', $nsmgr)) {
        $nameNode = $commandNode.SelectSingleNode('command:details/command:name', $nsmgr)
        if (-not $nameNode) { continue }
        $commandName = $nameNode.InnerText.Trim()

        $cmdInfo = $Module.ExportedCommands[$commandName]
        if (-not $cmdInfo) {
            Write-Warning "Repair-MamlMetadata: command '$commandName' is in the MAML but not exported by module '$($Module.Name)'; skipping."
            continue
        }
        $cmdHelp = $CommandHelpMap[$commandName]

        foreach ($paramNode in $commandNode.SelectNodes('.//command:parameter', $nsmgr)) {
            $paramNameNode = $paramNode.SelectSingleNode('maml:name', $nsmgr)
            if (-not $paramNameNode) { continue }
            $paramName = $paramNameNode.InnerText.Trim()
            $paramInfo = $cmdInfo.Parameters[$paramName]
            if (-not $paramInfo) { continue }

            $aliasList = @($paramInfo.Aliases | Where-Object { $_ })
            $paramNode.SetAttribute('aliases', $(if ($aliasList) { $aliasList -join ', ' } else { 'none' }))

            $byValue = $false
            $byProperty = $false
            foreach ($set in $paramInfo.ParameterSets.Values) {
                if ($set.ValueFromPipeline) { $byValue = $true }
                if ($set.ValueFromPipelineByPropertyName) { $byProperty = $true }
            }
            $pipelineInput = if (-not ($byValue -or $byProperty)) { 'False' }
            elseif ($byValue -and $byProperty) { 'True (ByValue, ByPropertyName)' }
            elseif ($byValue) { 'True (ByValue)' }
            else { 'True (ByPropertyName)' }
            $paramNode.SetAttribute('pipelineInput', $pipelineInput)

            # <dev:defaultValue> only belongs on the full parameter block
            # (parent: command:parameters), not on command:syntaxItem variants.
            if ($paramNode.ParentNode.LocalName -eq 'parameters' -and $cmdHelp) {
                $helpParam = $cmdHelp.Parameters | Where-Object { $_.Name -eq $paramName } | Select-Object -First 1
                $defaultText = ($helpParam.DefaultValue -as [String]).Trim()
                if ($defaultText -and $defaultText -notin @('None', 'none')) {
                    $existing = $paramNode.SelectSingleNode('dev:defaultValue', $nsmgr)
                    if (-not $existing) {
                        $defaultElem = $Xml.CreateElement('dev', 'defaultValue', $devNs)
                        $defaultElem.InnerText = $defaultText
                        $null = $paramNode.AppendChild($defaultElem)
                    }
                }
            }
        }

        if (-not $cmdHelp) { continue }

        # Replace INPUTS / OUTPUTS containers from the parsed CommandHelp object,
        # which captures the typenames correctly even when Export-MamlCommandHelp's
        # heading parser collapses '### [A] / [B]' to a literal '['.
        $inputsContainer = $commandNode.SelectSingleNode('command:inputTypes', $nsmgr)
        if ($inputsContainer -and $cmdHelp.Inputs -and $cmdHelp.Inputs.Count -gt 0) {
            $inputsContainer.RemoveAll()
            foreach ($t in $cmdHelp.Inputs) {
                $inputTypeElem = $Xml.CreateElement('command', 'inputType', $cmdNs)
                $typeElem = $Xml.CreateElement('dev', 'type', $devNs)
                $nameElem = $Xml.CreateElement('dev', 'name', $devNs)
                $nameElem.InnerText = ($t.Typename -as [String]).Trim()
                $null = $typeElem.AppendChild($nameElem)
                $null = $inputTypeElem.AppendChild($typeElem)
                $null = $inputTypeElem.AppendChild((& $buildDescription $t.Description))
                $null = $inputsContainer.AppendChild($inputTypeElem)
            }
        }

        $outputsContainer = $commandNode.SelectSingleNode('command:returnValues', $nsmgr)
        if ($outputsContainer -and $cmdHelp.Outputs -and $cmdHelp.Outputs.Count -gt 0) {
            $outputsContainer.RemoveAll()
            foreach ($t in $cmdHelp.Outputs) {
                $returnValueElem = $Xml.CreateElement('command', 'returnValue', $cmdNs)
                $typeElem = $Xml.CreateElement('dev', 'type', $devNs)
                $nameElem = $Xml.CreateElement('dev', 'name', $devNs)
                $nameElem.InnerText = ($t.Typename -as [String]).Trim()
                $null = $typeElem.AppendChild($nameElem)
                $null = $returnValueElem.AppendChild($typeElem)
                $null = $returnValueElem.AppendChild((& $buildDescription $t.Description))
                $null = $outputsContainer.AppendChild($returnValueElem)
            }
        }
    }
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
                # PlatyPS 1.0's Markdig-based import parser collapses bracketed
                # INPUTS/OUTPUTS headings of the form `### [Type]` to a literal
                # '[' typename, so write each markdown into a temp directory
                # with that heading style normalized to `### Type`. The source
                # files are never modified.
                $tempDocsDir = Join-Path ([System.IO.Path]::GetTempPath()) "JiraPS_help_$([Guid]::NewGuid())"
                $null = New-Item -ItemType Directory -Path $tempDocsDir -Force
                $patchedFiles = foreach ($mdFile in $commandHelpFiles) {
                    $content = [System.IO.File]::ReadAllText($mdFile.FullName)
                    # Iteratively strip a [bracket] occurrence from each `### ` heading
                    # until none are left, so both single (`### [A]`) and compound
                    # (`### [A] / [B]`) forms collapse to bare typenames.
                    $bracketPattern = '(?m)^(###[ \t]+[^\r\n]*?)\[\s*([^\]\r\n]+?)\s*\]'
                    while ([regex]::IsMatch($content, $bracketPattern)) {
                        $content = [regex]::Replace($content, $bracketPattern, '$1$2')
                    }
                    $tmp = Join-Path $tempDocsDir $mdFile.Name
                    [System.IO.File]::WriteAllText($tmp, $content)
                    Get-Item $tmp
                }

                try {
                    $commandHelp = @($patchedFiles | Import-MarkdownCommandHelp)
                    Assert-True ($commandHelp.Count -eq $commandHelpFiles.Count) "Imported $($commandHelp.Count) command help objects but expected $($commandHelpFiles.Count) (one per markdown file)."
                }
                finally {
                    Remove-Item $tempDocsDir -Recurse -Force -ErrorAction SilentlyContinue
                }

                # Index the parsed CommandHelp objects by command name so the
                # MAML repair pass can look up INPUTS/OUTPUTS typenames and
                # documentary default values without re-parsing the markdown.
                $commandHelpMap = @{}
                foreach ($help in $commandHelp) { $commandHelpMap[$help.Title] = $help }

                $commandHelp | Export-MamlCommandHelp -OutputFolder $outputPath -Force

                # Move from nested module folder to output path
                $nestedPath = Join-Path $outputPath $env:BHProjectName
                if (Test-Path $nestedPath) {
                    Get-ChildItem $nestedPath -Filter '*.xml' | Move-Item -Destination $outputPath -Force
                    Remove-Item $nestedPath -Recurse -Force
                }

                $mamlFile = Join-Path $outputPath "$env:BHProjectName-help.xml"
                Assert-True (Test-Path $mamlFile) "Expected MAML help file was not created: $mamlFile"

                $xml = [xml](Get-Content $mamlFile -Raw)
                $nsmgr = [System.Xml.XmlNamespaceManager]::new($xml.NameTable)
                $nsmgr.AddNamespace('command', 'http://schemas.microsoft.com/maml/dev/command/2004/10')
                $nsmgr.AddNamespace('maml', 'http://schemas.microsoft.com/maml/2004/10')
                $nsmgr.AddNamespace('dev', 'http://schemas.microsoft.com/maml/dev/2004/10')

                # Re-inject parameter metadata that PlatyPS 1.0 drops on every
                # Export-MamlCommandHelp call (aliases, pipelineInput, defaults).
                # Reflection against the live source module is the source of truth.
                $sourceModule = Import-Module "$env:BHProjectPath/$env:BHProjectName/$env:BHProjectName.psd1" -Force -PassThru -DisableNameChecking
                try {
                    Repair-MamlMetadata -Xml $xml -Module $sourceModule -CommandHelpMap $commandHelpMap
                }
                finally {
                    Remove-Module $sourceModule -Force -ErrorAction SilentlyContinue
                }

                # Restructure examples: PlatyPS 1.0 emits the original markdown source
                # (fenced code block + prose) inside maml:introduction; split it into
                # dev:code + dev:remarks/maml:para so Get-Help renders correctly.
                $fencePattern = '```([\w-]*)\r?\n([\s\S]*?)```'
                # Strip markdown italics, but only at word boundaries so paths and
                # identifiers like `non_unique_id` or `$_var_` are not mangled.
                $italicPattern = '(?<![\w/\\])_([^_\n]{1,200}?)_(?![\w/\\])'

                foreach ($example in $xml.SelectNodes('//command:example', $nsmgr)) {
                    $intro = $example.SelectSingleNode('maml:introduction', $nsmgr)
                    $code = $example.SelectSingleNode('dev:code', $nsmgr)
                    $remarks = $example.SelectSingleNode('dev:remarks', $nsmgr)
                    if (-not ($intro -and $code -and $remarks)) { continue }

                    $introText = ($intro.ChildNodes | ForEach-Object { $_.InnerText }) -join "`n"
                    $fenceMatches = [regex]::Matches($introText, $fencePattern)
                    if ($fenceMatches.Count -lt 1) { continue }

                    if ($fenceMatches.Count -gt 1) {
                        $owningCommand = $example.SelectSingleNode('ancestor::command:command/command:details/command:name', $nsmgr)
                        $owningName = if ($owningCommand) { $owningCommand.InnerText.Trim() } else { '<unknown>' }
                        Write-Warning "Example for $owningName contains $($fenceMatches.Count) fenced code blocks; only the first is captured as code."
                    }

                    $code.InnerText = $fenceMatches[0].Groups[2].Value.Trim()

                    $remarksContent = ($introText -replace $fencePattern, '').Trim()
                    $remarksContent = $remarksContent -replace $italicPattern, '$1'
                    if ($remarksContent) {
                        $para = $xml.CreateElement('maml', 'para', 'http://schemas.microsoft.com/maml/2004/10')
                        $para.InnerText = $remarksContent
                        $null = $remarks.AppendChild($para)
                    }

                    $intro.RemoveAll()
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
