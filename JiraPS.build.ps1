[CmdletBinding()]
param(
    [ValidateSet('None', 'Normal' , 'Detailed', 'Diagnostic')]
    [String] $PesterVerbosity = 'Normal',

    [Parameter()]
    [String] $VersionToPublish,

    [Parameter()]
    [String] $PSGalleryAPIKey
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

    foreach ($locale in (Get-ChildItem "$env:BHProjectPath/docs" -Attribute Directory)) {
        $outputPath = "$env:BHModulePath/$($locale.Basename)"
        $null = New-Item -ItemType Directory -Path $outputPath -Force

        # Import command help markdown and export to MAML
        $commandHelpFiles = Get-ChildItem "$($locale.FullName)/commands/*.md" -File |
            Where-Object { $_.Name -ne 'index.md' }

        if ($commandHelpFiles) {
            $commandHelp = $commandHelpFiles | Import-MarkdownCommandHelp -ErrorAction SilentlyContinue
            if ($commandHelp) {
                $commandHelp | Export-MamlCommandHelp -OutputFolder $outputPath -Force
                # Move from nested module folder to output path
                $nestedPath = Join-Path $outputPath $env:BHProjectName
                if (Test-Path $nestedPath) {
                    Get-ChildItem $nestedPath -Filter '*.xml' | Move-Item -Destination $outputPath -Force
                    Remove-Item $nestedPath -Recurse -Force
                }

                # Post-process MAML to fix example structure (PlatyPS 1.0 compatibility)
                $mamlFile = Join-Path $outputPath "$env:BHProjectName-help.xml"
                if (Test-Path $mamlFile) {
                    $xml = [xml](Get-Content $mamlFile -Raw)
                    $nsmgr = [System.Xml.XmlNamespaceManager]::new($xml.NameTable)
                    $nsmgr.AddNamespace("command", "http://schemas.microsoft.com/maml/dev/command/2004/10")
                    $nsmgr.AddNamespace("maml", "http://schemas.microsoft.com/maml/2004/10")
                    $nsmgr.AddNamespace("dev", "http://schemas.microsoft.com/maml/dev/2004/10")

                    foreach ($example in $xml.SelectNodes("//command:example", $nsmgr)) {
                        $intro = $example.SelectSingleNode("maml:introduction", $nsmgr)
                        $code = $example.SelectSingleNode("dev:code", $nsmgr)
                        $remarks = $example.SelectSingleNode("dev:remarks", $nsmgr)

                        if ($intro -and $code -and $remarks) {
                            $introText = ($intro.ChildNodes | ForEach-Object { $_.InnerText }) -join "`n"
                            # Extract code from markdown fences
                            if ($introText -match '```(?:powershell)?\r?\n([\s\S]*?)```') {
                                $codeContent = $Matches[1].Trim()
                                $code.InnerText = $codeContent

                                # Extract remarks (everything after the code block)
                                $remarksContent = ($introText -replace '```(?:powershell)?\r?\n[\s\S]*?```\r?\n?', '').Trim()
                                $remarksContent = $remarksContent -replace '_([^_]+)_', '$1'  # Remove markdown italic
                                if ($remarksContent) {
                                    $para = $xml.CreateElement("maml", "para", "http://schemas.microsoft.com/maml/2004/10")
                                    $para.InnerText = $remarksContent
                                    $remarks.AppendChild($para) | Out-Null
                                }

                                # Clear introduction
                                $intro.RemoveAll()
                            }
                        }
                    }

                    $xml.Save($mamlFile)
                }
            }
        }

        # Copy about topics as help text files
        Get-ChildItem "$($locale.FullName)/about_*.md" -File | ForEach-Object {
            $helpTxtName = $_.BaseName + '.help.txt'
            $content = Get-Content $_.FullName -Raw
            # Remove YAML frontmatter if present
            $content = $content -replace '^---[\s\S]*?---\r?\n', ''
            Set-Content -Path (Join-Path $outputPath $helpTxtName) -Value $content -Encoding UTF8
        }
    }

    Remove-Module Microsoft.PowerShell.PlatyPS
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
    $pesterConfig = New-PesterConfiguration -Hashtable @{
        Run        = @{
            PassThru = $true
            Path     = "$env:BHBuildOutput/Tests"
        }
        TestResult = @{
            Enabled      = $true
            OutputFormat = 'NUnitXml'
            OutputPath   = "Test-$OS-$($PSVersionTable.PSVersion.ToString()).xml"
        }
        Output     = @{
            Verbosity = $PesterVerbosity
        }
        <# CodeCoverage = @{
            Path = $codeCoverageFiles
        } #>
    }

    $testResults = Invoke-Pester -Configuration $pesterConfig
    Assert-True ($testResults.FailedCount -eq 0) "$($testResults.FailedCount) Pester test(s) failed."
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
