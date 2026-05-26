#requires -Modules @{ ModuleName = 'AtlassianPS.Standards'; ModuleVersion = '0.1.9'; MaximumVersion = '0.1.9' }

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

function Import-JiraPSStandard {
    [CmdletBinding()]
    param()

    Import-Module AtlassianPS.Standards -RequiredVersion '0.1.9' -Force -ErrorAction Stop
}

$ProjectName = 'JiraPS'
$script:BuildInfo = Initialize-AtlassianPSBuildEnvironment `
    -ProjectName $ProjectName `
    -ProjectPath $PSScriptRoot `
    -VersionToPublish $VersionToPublish `
    -ResetBuildEnvironmentVariables

$builtManifestPath = $script:BuildInfo.BuiltManifestPath

function Initialize-JiraDockerEnvironment {
    [CmdletBinding()]
    param()

    $env:CI_JIRA_TYPE = 'Server'
    $env:CI_JIRA_URL = if ($env:CI_JIRA_URL) { $env:CI_JIRA_URL } else { 'http://localhost:2990/jira' }
    $env:CI_JIRA_ADMIN = if ($env:CI_JIRA_ADMIN) { $env:CI_JIRA_ADMIN } else { 'admin' }
    $env:CI_JIRA_ADMIN_PASSWORD = if ($env:CI_JIRA_ADMIN_PASSWORD) { $env:CI_JIRA_ADMIN_PASSWORD } else { 'admin' }
    $env:CI_JIRA_USER = if ($env:CI_JIRA_USER) { $env:CI_JIRA_USER } else { 'jira_user' }
    $env:CI_JIRA_USER_PASSWORD = if ($env:CI_JIRA_USER_PASSWORD) { $env:CI_JIRA_USER_PASSWORD } else { 'jira' }
    $env:JIRA_TEST_PROJECT = 'TEST'
    $env:JIRA_TEST_ISSUE = $null
    $env:JIRA_TEST_GROUP = $null
    $env:JIRA_TEST_FILTER = $null
    $env:JIRA_TEST_VERSION = $null
}

Task ShowDebugInfo {
    Write-AtlassianPSBuildInfo -BuildInfo $script:BuildInfo
}

# Synopsis: Run style checks and PSScriptAnalyzer. Collects both result sets
# before throwing so a single run surfaces every issue. Emits GitHub Actions
# workflow commands when running under CI so violations appear as inline
# annotations on the PR diff.
Task Lint {
    Import-JiraPSStandard

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
    Import-JiraPSStandard

    Remove-AtlassianPSOrphanedExternalHelp `
        -ModulePath $env:BHModulePath `
        -DocsPath (Join-Path $env:BHProjectPath 'docs') `
        -ModuleName $env:BHProjectName
}

# Synopsis: Generate ./Release structure
Task CopyModuleFiles {
    Import-JiraPSStandard

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

}

# Synopsis: Compile all functions into the .psm1 file
Task CompileModule {
    Import-JiraPSStandard

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
    Import-JiraPSStandard

    Update-AtlassianPSExternalHelp `
        -DocsPath (Join-Path $env:BHProjectPath 'docs') `
        -ModulePath $env:BHModulePath `
        -ModuleName $env:BHProjectName
}

# Synopsis: Update the manifest of the module
Task UpdateManifest {
    Import-JiraPSStandard

    $null = Update-AtlassianPSModuleManifestExports `
        -SourceModulePath $env:BHModulePath `
        -BuiltManifestPath $builtManifestPath `
        -ModuleName $env:BHProjectName
}

Task SetVersion {
    Import-JiraPSStandard

    $versionString = Set-AtlassianPSModuleManifestVersion `
        -BuiltManifestPath $builtManifestPath `
        -ModuleName $env:BHProjectName `
        -VersionToPublish $VersionToPublish
    Write-Build Gray "Resolved release version: $versionString"
}

Task Test {
    Import-JiraPSStandard

    # Skip the Integration folder at discovery time so Pester does not run
    # its BeforeDiscovery blocks (which read .env and warn when integration
    # secrets are missing). Use TestIntegration task to run them.
    $integrationPath = Join-Path $env:BHBuildOutput 'Tests/Integration'
    $testPaths = Get-ChildItem -LiteralPath "$env:BHBuildOutput/Tests" -Force |
        Where-Object {
            $_.FullName -ne $integrationPath -and
            (
                $_.Name -like '*.Tests.ps1' -or
                ($_.PSIsContainer -and (Get-ChildItem -LiteralPath $_.FullName -Filter '*.Tests.ps1' -Recurse -File -ErrorAction SilentlyContinue))
            )
        } |
        ForEach-Object { $_.FullName }

    foreach ($testPath in $testPaths) {
        $resultName = (Split-Path -Path $testPath -Leaf) -replace '[^A-Za-z0-9._-]', '-'
        Import-Module AtlassianPS.Standards -RequiredVersion '0.1.9' -Force -ErrorAction Stop
        $null = Invoke-AtlassianPSModuleTests `
            -TestPath $testPath `
            -PesterVerbosity $PesterVerbosity `
            -Tag $Tag `
            -ExcludeTag $ExcludeTag `
            -DefaultExcludeTag @('Integration') `
            -MinimumPesterVersion ([Version]'5.7.0') `
            -ResultOutputPath (Join-Path $env:BHProjectPath "Test-$resultName.xml")
    }
}

# Synopsis: Run integration tests against live Jira (Cloud or Data Center; no build required)
Task TestIntegration {
    $helpersPath = Join-Path $env:BHProjectPath 'Tests/Helpers/IntegrationTestTools.ps1'
    if (Test-Path $helpersPath) {
        . $helpersPath
        Read-DotEnvFile -Path (Join-Path $env:BHProjectPath '.env') -ExcludeName (Get-DotEnvExcludedName)
    }

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

# Synopsis: Configure environment variables for the local Jira Data Center Docker track
Task SetJiraDockerEnvironment {
    Initialize-JiraDockerEnvironment
}

# Synopsis: Start the local Jira Data Center Docker container (for Server-track integration tests)
Task StartJiraDocker SetJiraDockerEnvironment, {
    if (-not (Get-Command docker -ErrorAction SilentlyContinue)) {
        throw "Docker is required for the Jira Server track. See https://docs.docker.com/get-docker/."
    }
    $composeFile = Join-Path $env:BHProjectPath 'docker-compose.yml'
    Assert-True (Test-Path $composeFile) "docker-compose.yml not found at $composeFile"
    Write-Build Gray "Starting Jira Data Center container via $composeFile (cold start: ~5 min)..."
    Invoke-BuildExec { docker compose -f $composeFile up -d }
    & (Join-Path $env:BHProjectPath 'Tools/Wait-JiraServer.ps1')
}

# Synopsis: Start local Jira Data Center, run Server-tagged integration tests, then stop the container
Task TestIntegrationServer {
    if (-not (Get-Command docker -ErrorAction SilentlyContinue)) {
        throw "Docker is required for the Jira Server track. See https://docs.docker.com/get-docker/."
    }

    $composeFile = Join-Path $env:BHProjectPath 'docker-compose.yml'
    Assert-True (Test-Path $composeFile) "docker-compose.yml not found at $composeFile"
    $containerLogPath = Join-Path $env:BHProjectPath 'jira-container.log'

    $runnerPath = "$env:BHProjectPath/Tests/Invoke-ParallelPester.ps1"
    Assert-True (Test-Path $runnerPath) "Integration test runner not found: $runnerPath"

    Initialize-JiraDockerEnvironment

    try {
        Write-Build Gray "Starting Jira Data Center container via $composeFile (cold start: ~5 min)..."
        Invoke-BuildExec { docker compose -f $composeFile up -d }
        & (Join-Path $env:BHProjectPath 'Tools/Wait-JiraServer.ps1')

        & $runnerPath `
            -ThrottleLimit 2 `
            -Output $PesterVerbosity `
            -OutputPath 'Test-Integration.xml' `
            -Tag 'Server'

        Assert-True ($LASTEXITCODE -eq 0) "Server integration tests failed with exit code $LASTEXITCODE"
    }
    catch {
        Write-Build Yellow "Capturing Jira Data Center container logs to $containerLogPath before teardown..."
        try {
            docker compose -f $composeFile logs jira > $containerLogPath
        }
        catch {
            Write-Build Yellow "Failed to capture Jira Data Center container logs: $_"
        }
        throw
    }
    finally {
        Write-Build Gray "Stopping Jira Data Center container ($composeFile)..."
        Invoke-BuildExec { docker compose -f $composeFile down -v }
    }
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

Task Publish SetVersion, Package, {
    Assert-True (-not [String]::IsNullOrEmpty($PSGalleryAPIKey)) "No key for the PSGallery"
    Publish-Module -Path (Join-Path $env:BHBuildOutput $env:BHProjectName) -NuGetApiKey $PSGalleryAPIKey
}

Task SignCode {
    throw "Code signing is not configured yet. Add certificate provisioning before wiring this task into Publish."
}

Task Package {
    Import-JiraPSStandard

    $script:PackagePath = New-AtlassianPSModulePackage -BuildOutputPath $env:BHBuildOutput -ModuleName $env:BHProjectName
}

Task TestPublish Build, Package, {
    Import-JiraPSStandard

    $testPackageParameters = @{
        BuildOutputPath = $env:BHBuildOutput
        ModuleName      = $env:BHProjectName
    }
    if ($script:PackagePath) {
        $testPackageParameters.PackagePath = $script:PackagePath
    }

    $package = Test-AtlassianPSModulePackage @testPackageParameters
    Write-Build Green "Publish dry-run passed: $($package.PackagePath)"
}

Task . Clean, Build, Test
