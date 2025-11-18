# JiraPS Installation with API v3 Support

## Prerequisites

- Windows PowerShell 5.1 or higher OR PowerShell Core 6.0+
- Windows, macOS, or Linux

## Installation Methods

### Method 1: Local Installation from this Repository (Recommended for API v3)

This method installs the updated version with API v3 support directly from this repository.

#### Step 1: Clone or download the repository

```powershell
# Option A: Clone with Git
git clone https://github.com/rpx99/JiraPS.git
cd JiraPS

# Option B: Download as ZIP
# Download the repository from GitHub and extract it
```

#### Step 2: Switch to the API v3 branch

```powershell
git checkout claude/upgrade-jira-api-v3-019fSPSQ2x9F7ivyKTSQrFNq
```

#### Step 3: Install the module

```powershell
# Find the PowerShell Module directory
$modulePath = $env:PSModulePath -split ';' | Select-Object -First 1

# Create JiraPS directory if it doesn't exist
$jiraPSPath = Join-Path $modulePath "JiraPS"
New-Item -ItemType Directory -Path $jiraPSPath -Force

# Copy module files
Copy-Item -Path ".\JiraPS\*" -Destination $jiraPSPath -Recurse -Force

Write-Host "JiraPS has been successfully installed to $jiraPSPath" -ForegroundColor Green
```

#### Step 4: Import and use the module

```powershell
# Import module
Import-Module JiraPS -Force

# Verify version
Get-Module JiraPS

# Create Jira session
New-JiraSession -Server 'https://your-domain.atlassian.net' -Credential (Get-Credential)

# Search issues (now using API v3)
Get-JiraIssue -Query "project = TEST AND status = Open"
```

### Method 2: Installation via PowerShell Gallery (Stable version only)

**NOTE:** The PowerShell Gallery version does NOT yet contain the API v3 updates. Use Method 1 for API v3 support.

```powershell
Install-Module JiraPS -Scope CurrentUser
```

## Important Changes in the API v3 Version

### What has changed?

1. **Search Endpoint**: `/rest/api/2/search` → `/rest/api/3/search/jql`
   - Now uses POST instead of GET
   - JSON body instead of query parameters
   - Token-based pagination (`nextPageToken`) instead of offset (`startAt`)

2. **All other endpoints**: `/rest/api/2/*` → `/rest/api/3/*`

3. **Pagination**: Automatic support for both pagination methods
   - New API v3 `/search/jql`: Token-based
   - Legacy endpoints: Offset-based (if still supported)

### Compatibility

- ✅ All existing commands continue to work
- ✅ No changes to PowerShell syntax required
- ✅ Automatic detection of pagination type
- ✅ Backward compatible with Jira Cloud (from August 2025)

## Examples

### Basic Usage

```powershell
# Create Jira session
$cred = Get-Credential
New-JiraSession -Server 'https://your-domain.atlassian.net' -Credential $cred

# Get single issue
Get-JiraIssue -Key "PROJECT-123"

# Search issues with JQL
Get-JiraIssue -Query "project = MYPROJECT AND assignee = currentUser()"

# With pagination (retrieve all issues)
Get-JiraIssue -Query "project = MYPROJECT" -PageSize 50

# Get only specific fields
Get-JiraIssue -Query "project = MYPROJECT" -Fields "summary,status,assignee"
```

### Advanced Examples

```powershell
# Issues with filter
$filter = Get-JiraFilter -Id 12345
Get-JiraIssue -Filter $filter

# Create issues
$issue = New-JiraIssue -Project "TEST" -IssueType "Task" -Summary "New Task"

# Search users
Get-JiraUser -UserName "john.doe@example.com"

# Project information
Get-JiraProject -Key "MYPROJECT"
```

## Troubleshooting

### Issue: "The requested API has been removed"

**Solution:** Make sure you're using the updated version from this branch, not the old version from PowerShell Gallery.

### Issue: Module cannot be imported

```powershell
# Check installed modules
Get-Module -ListAvailable JiraPS

# Remove old versions
Get-Module JiraPS | Remove-Module -Force

# Uninstall old versions from PowerShell Gallery
Uninstall-Module JiraPS -AllVersions

# Reinstall the updated version (see Method 1)
```

### Issue: Pagination not working correctly

The new API v3 has some known pagination issues. If you encounter problems:

```powershell
# Use a larger PageSize (max 100)
Get-JiraIssue -Query "project = MYPROJECT" -PageSize 100

# Or limit the number of results
Get-JiraIssue -Query "project = MYPROJECT" -First 1000
```

## Uninstallation

```powershell
# Remove module
Remove-Module JiraPS -Force

# Uninstall PowerShell Gallery installed version
Uninstall-Module JiraPS -AllVersions

# Delete manually installed version
$modulePath = (Get-Module JiraPS -ListAvailable).ModuleBase
Remove-Item $modulePath -Recurse -Force
```

## Additional Resources

- [JiraPS Documentation](https://atlassianps.org/docs/JiraPS/)
- [GitHub Issues](https://github.com/AtlassianPS/JiraPS/issues)
- [Atlassian API Documentation](https://developer.atlassian.com/cloud/jira/platform/rest/v3/)
- [API v2 to v3 Migration](https://community.atlassian.com/forums/Jira-articles/Your-Jira-Scripts-and-Automations-May-Break-if-they-use-JQL/ba-p/3001235)
