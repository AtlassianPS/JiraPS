# This approach shamelessly copied from RamblingCookieMonster. ^.^

# Be SURE to install Pester using appveyor.yml. Chocolatey is available, so the simplest way is to use this:
# cinst -y Pester

#region Variables
# AppVeyor environment variables

# This refers to the root of the project directory - usually C:\Projects\PSJira, but it's not safe to assume that
$ProjectRoot = $env:APPVEYOR_BUILD_FOLDER

# This is the root of the module folder inside the project, where the .psm1 file lives
$ModuleRoot = Join-Path -Path $ProjectRoot -ChildPath 'PSJira'

# This is AppVeyor's internal job ID, used to return results using their REST API
$JobId = $env:APPVEYOR_JOB_ID
#endregion

#region Init
Write-Host
Write-Host "=== Beginning AppVeyor.ps1 ===" -ForegroundColor Green
Write-Host

# AppVeyor environment variable set when running in an AppVeyor environment.
if ($env:CI -ne $true)
{
    throw "This script does not appear to be running in an AppVeyor environment."
}

Write-Host
Write-Host ('Project name:               {0}' -f $env:APPVEYOR_PROJECT_NAME) -ForegroundColor Cyan
Write-Host ('Project root:               {0}' -f $ProjectRoot) -ForegroundColor Cyan
Write-Host ('Repo name:                  {0}' -f $env:APPVEYOR_REPO_NAME) -ForegroundColor Cyan
Write-Host ('Branch:                     {0}' -f $env:APPVEYOR_REPO_BRANCH) -ForegroundColor Cyan
Write-Host ('Commit:                     {0}' -f $env:APPVEYOR_REPO_COMMIT) -ForegroundColor Cyan
Write-Host ('  - Author:                 {0}' -f $env:APPVEYOR_REPO_COMMIT_AUTHOR) -ForegroundColor Cyan
Write-Host ('  - Time:                   {0}' -f $env:APPVEYOR_REPO_COMMIT_TIMESTAMP) -ForegroundColor Cyan
Write-Host ('  - Message:                {0}' -f $env:APPVEYOR_REPO_COMMIT_MESSAGE) -ForegroundColor Cyan
Write-Host ('  - Extended message:       {0}' -f $env:APPVEYOR_REPO_COMMIT_MESSAGE_EXTENDED) -ForegroundColor Cyan
Write-Host ('Pull request number:        {0}' -f $env:APPVEYOR_PULL_REQUEST_NUMBER) -ForegroundColor Cyan
Write-Host ('Pull request title:         {0}' -f $env:APPVEYOR_PULL_REQUEST_TITLE) -ForegroundColor Cyan
Write-Host ('AppVeyor build ID:          {0}' -f $env:APPVEYOR_BUILD_ID) -ForegroundColor Cyan
Write-Host ('AppVeyor build number:      {0}' -f $env:APPVEYOR_BUILD_NUMBER) -ForegroundColor Cyan
Write-Host ('AppVeyor build version:     {0}' -f $env:APPVEYOR_BUILD_VERSION) -ForegroundColor Cyan
Write-Host ('AppVeyor job ID:            {0}' -f $JobID) -ForegroundColor Cyan
Write-Host ('Build triggered from tag?   {0}' -f $env:APPVEYOR_REPO_TAG) -ForegroundColor Cyan
Write-Host ('  - Tag name:               {0}' -f $env:APPVEYOR_REPO_TAG_NAME) -ForegroundColor Cyan
Write-Host ('PowerShell version:         {0}' -f $PSVersionTable.PSVersion.ToString()) -ForegroundColor Cyan
Write-Host

Write-Host "AppVeyor build initialized (Job ID $JobId)" -ForegroundColor Cyan

# Get the NuGet provider
Get-PackageProvider -Name NuGet -ForceBootstrap | Out-Null

# Don't forget -Force!
Install-Module Pester,psake -Force
Write-Host "Attempting to run $env:APPVEYOR_BUILD_FOLDER\Tools\psake.ps1" -ForegroundColor Cyan
Invoke-psake $env:APPVEYOR_BUILD_FOLDER\Tools\psake.ps1

Write-Host
Write-Host "=== Completed AppVeyor.ps1 ===" -ForegroundColor Green
Write-Host

exit ( [int] (-not $psake.build_success) )