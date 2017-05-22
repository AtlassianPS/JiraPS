###############################################################################
# Customize these properties and tasks for your module.
###############################################################################

Properties {
    # ----------------------- Basic properties --------------------------------

    Write-Host "build.settings.ps1 - Properties" -ForegroundColor Green
    Write-Host "* PSScriptRoot: $PSScriptRoot" -ForegroundColor Green

    # Root directory for the project
    $ProjectRoot = Split-Path "$PSScriptRoot" -Parent
    Write-Host "* ProjectRoot: $ProjectRoot" -ForegroundColor Green

    # The root directories for the module's docs, src and test.
    [System.Diagnostics.CodeAnalysis.SuppressMessage('PSUseDeclaredVarsMoreThanAssigments', '')]
    $DocsRootDir = "$ProjectRoot\docs"
    $SrcRootDir  = "$ProjectRoot\PSJira"
    [System.Diagnostics.CodeAnalysis.SuppressMessage('PSUseDeclaredVarsMoreThanAssigments', '')]
    $TestRootDir = "$ProjectRoot\Tests"

    # The name of your module should match the basename of the PSD1 file.
    [System.Diagnostics.CodeAnalysis.SuppressMessage('PSUseDeclaredVarsMoreThanAssigments', '')]
    $ModuleName = Get-Item $SrcRootDir/*.psd1 |
                      Where-Object { $null -ne (Test-ModuleManifest -Path $_ -ErrorAction SilentlyContinue) } |
                      Select-Object -First 1 | Foreach-Object BaseName
    Write-Host "* ModuleName: $ModuleName" -ForegroundColor Green

    # The $OutDir is where module files and updatable help files are staged for signing, install and publishing.
    [System.Diagnostics.CodeAnalysis.SuppressMessage('PSUseDeclaredVarsMoreThanAssigments', '')]
    $OutDir = "$ProjectRoot\Release"
    Write-Host "* OutDir: $OutDir" -ForegroundColor Green

    # The local installation directory for the install task. Defaults to your home Modules location.
    if ($profile.CurrentUserAllHosts) {
        [System.Diagnostics.CodeAnalysis.SuppressMessage('PSUseDeclaredVarsMoreThanAssigments', '')]
        $InstallPath = Join-Path (Split-Path $profile.CurrentUserAllHosts -Parent) `
            "Modules\$ModuleName\$((Test-ModuleManifest -Path $SrcRootDir\$ModuleName.psd1).Version.ToString())"
    }
    else {
        [System.Diagnostics.CodeAnalysis.SuppressMessage('PSUseDeclaredVarsMoreThanAssigments', '')]
        $InstallPath = Join-Path $env:USERPROFILE `
            "Documents\WindowsPowerShell\Modules\$ModuleName\$((Test-ModuleManifest -Path $SrcRootDir\$ModuleName.psd1).Version.ToString())"
    }
    Write-Host "* InstallPath: $InstallPath" -ForegroundColor Green

    # Default Locale used for help generation, defaults to en-US.
    [System.Diagnostics.CodeAnalysis.SuppressMessage('PSUseDeclaredVarsMoreThanAssigments', '')]
    $DefaultLocale = 'en-US'

    # Items in the $Exclude array will not be copied to the $OutDir e.g. $Exclude = @('.gitattributes')
    # Typically you wouldn't put any file under the src dir unless the file was going to ship with
    # the module. However, if there are such files, add their $SrcRootDir relative paths to the exclude list.
    [System.Diagnostics.CodeAnalysis.SuppressMessage('PSUseDeclaredVarsMoreThanAssigments', '')]
    $Exclude = @()

    # ------------------ Script analysis properties ---------------------------

    # Enable/disable use of PSScriptAnalyzer to perform script analysis.
    [System.Diagnostics.CodeAnalysis.SuppressMessage('PSUseDeclaredVarsMoreThanAssigments', '')]
    $ScriptAnalysisEnabled = $true

    # When PSScriptAnalyzer is enabled, control which severity level will generate a build failure.
    # Valid values are Error, Warning, Information and None.  "None" will report errors but will not
    # cause a build failure.  "Error" will fail the build only on diagnostic records that are of
    # severity error.  "Warning" will fail the build on Warning and Error diagnostic records.
    # "Any" will fail the build on any diagnostic record, regardless of severity.
    [System.Diagnostics.CodeAnalysis.SuppressMessage('PSUseDeclaredVarsMoreThanAssigments', '')]
    [ValidateSet('Error', 'Warning', 'Any', 'None')]
    $ScriptAnalysisFailBuildOnSeverityLevel = 'Error'

    # Path to the PSScriptAnalyzer settings file.
    [System.Diagnostics.CodeAnalysis.SuppressMessage('PSUseDeclaredVarsMoreThanAssigments', '')]
    $ScriptAnalyzerSettingsPath = "$ProjectRoot\ScriptAnalyzerSettings.psd1"

    # ------------------- Script signing properties ---------------------------

    # Set to $true if you want to sign your scripts. You will need to have a code-signing certificate.
    # You can specify the certificate's subject name below. If not specified, you will be prompted to
    # provide either a subject name or path to a PFX file.  After this one time prompt, the value will
    # saved for future use and you will no longer be prompted.
    [System.Diagnostics.CodeAnalysis.SuppressMessage('PSUseDeclaredVarsMoreThanAssigments', '')]
    $ScriptSigningEnabled = $false

    # Specify the Subject Name of the certificate used to sign your scripts.  Leave it as $null and the
    # first time you build, you will be prompted to enter your code-signing certificate's Subject Name.
    # This variable is used only if $SignScripts is set to $true.
    #
    # This does require the code-signing certificate to be installed to your certificate store.  If you
    # have a code-signing certificate in a PFX file, install the certificate to your certificate store
    # with the command below. You may be prompted for the certificate's password.
    #
    # Import-PfxCertificate -FilePath .\myCodeSigingCert.pfx -CertStoreLocation Cert:\CurrentUser\My
    #
    [System.Diagnostics.CodeAnalysis.SuppressMessage('PSUseDeclaredVarsMoreThanAssigments', '')]
    $CertSubjectName = $null

    # Certificate store path.
    [System.Diagnostics.CodeAnalysis.SuppressMessage('PSUseDeclaredVarsMoreThanAssigments', '')]
    $CertPath = "Cert:\"

    # -------------------- File catalog properties ----------------------------

    # Enable/disable generation of a catalog (.cat) file for the module.
    [System.Diagnostics.CodeAnalysis.SuppressMessage('PSUseDeclaredVarsMoreThanAssigments', '')]
    $CatalogGenerationEnabled = $true

    # Select the hash version to use for the catalog file: 1 for SHA1 (compat with Windows 7 and
    # Windows Server 2008 R2), 2 for SHA2 to support only newer Windows versions.
    [System.Diagnostics.CodeAnalysis.SuppressMessage('PSUseDeclaredVarsMoreThanAssigments', '')]
    $CatalogVersion = 2

    # ---------------------- Testing properties -------------------------------

    # Enable/disable Pester code coverage reporting.
    [System.Diagnostics.CodeAnalysis.SuppressMessage('PSUseDeclaredVarsMoreThanAssigments', '')]
    $CodeCoverageEnabled = $true

    # CodeCoverageFiles specifies the files to perform code coverage analysis on. This property
    # acts as a direct input to the Pester -CodeCoverage parameter, so will support constructions
    # like the ones found here: https://github.com/pester/Pester/wiki/Code-Coverage.
    [System.Diagnostics.CodeAnalysis.SuppressMessage('PSUseDeclaredVarsMoreThanAssigments', '')]
    $CodeCoverageFiles = "$SrcRootDir\*.ps1", "$SrcRootDir\*.psm1"

    # -------------------- Publishing properties ------------------------------

    # Your NuGet API key for the PSGallery.  Leave it as $null and the first time you publish,
    # you will be prompted to enter your API key.  The build will store the key encrypted in the
    # settings file, so that on subsequent publishes you will no longer be prompted for the API key.
    [System.Diagnostics.CodeAnalysis.SuppressMessage('PSUseDeclaredVarsMoreThanAssigments', '')]
    $NuGetApiKey = $null

    # Name of the repository you wish to publish to. If $null is specified the default repo (PowerShellGallery) is used.
    [System.Diagnostics.CodeAnalysis.SuppressMessage('PSUseDeclaredVarsMoreThanAssigments', '')]
    $PublishRepository = $null

    # Path to the release notes file.  Set to $null if the release notes reside in the manifest file.
    # The contents of this file are used during publishing for the ReleaseNotes parameter.
    [System.Diagnostics.CodeAnalysis.SuppressMessage('PSUseDeclaredVarsMoreThanAssigments', '')]
    $ReleaseNotesPath = "$ProjectRoot\ReleaseNotes.md"

    # ----------------------- Misc properties ---------------------------------

    # In addition, PFX certificates are supported in an interactive scenario only,
    # as a way to import a certificate into the user personal store for later use.
    # This can be provided using the CertPfxPath parameter. PFX passwords will not be stored.
    [System.Diagnostics.CodeAnalysis.SuppressMessage('PSUseDeclaredVarsMoreThanAssigments', '')]
    $SettingsPath = "$env:LOCALAPPDATA\Plaster\NewModuleTemplate\SecuredBuildSettings.clixml"

    # Specifies an output file path to send to Invoke-Pester's -OutputFile parameter.
    # This is typically used to write out test results so that they can be sent to a CI
    # system like AppVeyor.
    [System.Diagnostics.CodeAnalysis.SuppressMessage('PSUseDeclaredVarsMoreThanAssigments', '')]
    $TestOutputFile = "$env:TEMP\TestResults_PS$PSVersion`_$TimeStamp.xml"

    # Specifies the test output format to use when the TestOutputFile property is given
    # a path.  This parameter is passed through to Invoke-Pester's -OutputFormat parameter.
    [System.Diagnostics.CodeAnalysis.SuppressMessage('PSUseDeclaredVarsMoreThanAssigments', '')]
    $TestOutputFormat = "NUnitXml"

    Write-Host "build.settings.ps1 - Propertes completed" -ForegroundColor Green
    Set-BuildEnvironment -Path $ProjectRoot
}

###############################################################################
# Customize these tasks for performing operations before and/or after file staging.
###############################################################################

# Executes before the StageFiles task.
Task BeforeStageFiles -requiredVariables ProjectRoot {
    Write-Host "build.settings.ps1 - BeforeStageFiles" -ForegroundColor Green
    Write-Host "BuildHelpers environment:`n$(Get-Item env:bh* | Out-String)" -ForegroundColor Green
}

# Executes after the StageFiles task.
Task AfterStageFiles {
}

###############################################################################
# Customize these tasks for performing operations before and/or after Build.
###############################################################################

# Executes before the BeforeStageFiles phase of the Build task.
Task BeforeBuild {
    Write-Host "build.settings.ps1 - BeforeBuild" -ForegroundColor Green
}

# Executes after the Build task.
Task AfterBuild -requiredVariables ProjectRoot,OutDir {
    $outputManifestFile = Join-Path -Path $OutDir -ChildPath 'PSJira\PSJira.psd1'
    Write-Host "Patching module manifest file $outputManifestFile" -ForegroundColor Green
    if ($env:BHBuildSystem -eq 'AppVeyor') {
        # If we're in AppVeyor, add the build number to the manifest
        Write-Host "* Updating build number" -ForegroundColor Green

        $manifestContent = Get-Content -Path $outputManifestFile -Raw
        if ($manifestContent -notmatch '(?<=ModuleVersion\s+=\s+'')(?<ModuleVersion>.*)(?='')') {
            throw "Module version was not found in manifest file $outputManifestFile"
        }

        $currentVersion = [Version] $Matches.ModuleVersion
        if ($env:BHBuildNumber) {
            $newRevision = $env:BHBuildNumber
        }
        else {
            $newRevision = $currentVersion.Revision
        }

        $newVersion = New-Object -TypeName System.Version -ArgumentList $currentVersion.Major,
            $currentVersion.Minor,
            $currentVersion.Build,
            $newRevision

        Update-Metadata -Path $outputManifestFile -PropertyName ModuleVersion -Value $newVersion
    }

    Write-Host "Defining module functions" -ForegroundColor Green
    Set-ModuleFunctions -Name (Join-Path $OutDir -ChildPath 'PSJira\PSJira.psd1')
}

###############################################################################
# Customize these tasks for performing operations before and/or after Test.
###############################################################################

# Executes before the Test task.
Task BeforeTest {
}

# Executes after the Test task.
Task AfterTest -requiredVariables TestOutputFile {
    if ($env:BHBuildSystem -eq 'AppVeyor') {
        # Upload test results to AppVeyor

        if (-not (Test-Path $TestOutputFile)) {
            throw "Pester test file was not created at path $TestOutputFile. Build cannot continue."
        }

        $url = "https://ci.appveyor.com/api/testresults/nunit/$env:APPVEYOR_JOB_ID"
        Write-Host "Uploading test results back to AppVeyor, url=[$url]"
        $wc = New-Object -TypeName System.Net.WebClient
        $wc.UploadFile($url, $TestOutputFile)
        $wc.Dispose()
    }
}

###############################################################################
# Customize these tasks for performing operations before and/or after BuildHelp.
###############################################################################

# Executes before the BuildHelp task.
Task BeforeBuildHelp {
}

# Executes after the BuildHelp task.
Task AfterBuildHelp {
}

###############################################################################
# Customize these tasks for performing operations before and/or after BuildUpdatableHelp.
###############################################################################

# Executes before the BuildUpdatableHelp task.
Task BeforeBuildUpdatableHelp {
}

# Executes after the BuildUpdatableHelp task.
Task AfterBuildUpdatableHelp {
}

###############################################################################
# Customize these tasks for performing operations before and/or after GenerateFileCatalog.
###############################################################################

# Executes before the GenerateFileCatalog task.
Task BeforeGenerateFileCatalog {
}

# Executes after the GenerateFileCatalog task.
Task AfterGenerateFileCatalog {
}

###############################################################################
# Customize these tasks for performing operations before and/or after Install.
###############################################################################

# Executes before the Install task.
Task BeforeInstall {
}

# Executes after the Install task.
Task AfterInstall {
}

###############################################################################
# Customize these tasks for performing operations before and/or after Publish.
###############################################################################

# Executes before the Publish task.
Task BeforePublish -requiredVariables NuGetApiKey {
    if ($env:BHBranchName -ne 'master') {
        Write-Host "This build is from branch [$env:BHBranchName]. It will not be published." -ForegroundColor Yellow
        throw "Terminating build."
    }

    if ($env:BHBuildSystem -eq 'AppVeyor') {
        if ($env:APPVEYOR_PULL_REQUEST_NUMBER) {
            Write-Host "This build is from a pull request. It will not be published." -ForegroundColor Yellow
            throw "Terminating build."
        }

        # This build script saves credentials to a CliXML file in $APPDATA.
        # While that's useful on a single dev machine, AppVeyor uses
        # encrypted credentials in the appveyor.yml file, so we need to
        # load those instead.
        Write-Host "AppVeyor detected; setting NuGetApiKey to encrypted environment value"
        [System.Diagnostics.CodeAnalysis.SuppressMessage('PSUseDeclaredVarsMoreThanAssigments', '')]
        $NuGetApiKey = $env:PSGalleryAPIKey
    }
}

# Executes after the Publish task.
Task AfterPublish {
}
