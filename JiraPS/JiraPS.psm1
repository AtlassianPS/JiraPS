#region Dependencies
if (!("System.Web.HttpUtility" -as [Type])) {
    Add-Type -AssemblyName "System.Web"
}
if (!("System.Net.Http.HttpRequestException" -as [Type])) {
    Add-Type -AssemblyName "System.Net.Http"
}
if (!("System.Net.Http" -as [Type])) {
    Add-Type -Assembly System.Net.Http
}
#endregion Dependencies

#region Configuration
$script:serverConfig = ("{0}/AtlassianPS/JiraPS/server_config" -f [Environment]::GetFolderPath('ApplicationData', 'Create'))

if (-not (Test-Path $script:serverConfig)) {
    try {
        $null = New-Item -Path $script:serverConfig -ItemType File -Force -ErrorAction Stop
    }
    catch {
        if (-not (Test-Path $script:serverConfig)) {
            Write-Verbose "[$($MyInvocation.MyCommand.Name)] Failed to create config file: $_"
        }
    }
}

$script:JiraServerUrl = $null
if (Test-Path $script:serverConfig) {
    try {
        $serverConfigContent = Get-Content $script:serverConfig -Raw -ErrorAction Stop
        if ($serverConfigContent) {
            $firstLine = ($serverConfigContent -split '\r?\n')[0].Trim()
            if ($firstLine) {
                $script:JiraServerUrl = [Uri]$firstLine
            }
        }
    }
    catch {
        Write-Verbose "[$($MyInvocation.MyCommand.Name)] Failed to read config file: $_"
    }
}

$script:DefaultContentType = "application/json; charset=utf-8"
$script:DefaultPageSize = 25
$script:DefaultHeaders = @{
    "Accept-Charset" = "utf-8"
    "Accept"         = "application/json"
}
$script:JiraResponseHeaderLogConfiguration = $null
$script:PagingContainers = @(
    "comments"
    "dashboards"
    "groups"
    "issues"
    "values"
    "worklogs"
)
$script:SessionTransformationMethod = "ConvertTo-JiraSession"
$script:JiraServerInfo = $null
#endregion Configuration

#region LoadFunctions
$PublicFunctions = @( Get-ChildItem -Path "$PSScriptRoot/Public/*.ps1" -ErrorAction SilentlyContinue )
$PrivateFunctions = @( Get-ChildItem -Path "$PSScriptRoot/Private/*.ps1" -ErrorAction SilentlyContinue )

# Dot source the functions
foreach ($file in @($PublicFunctions + $PrivateFunctions)) {
    try {
        . $file.FullName
    }
    catch {
        $exception = ([System.ArgumentException]"Function not found")
        $errorId = "Load.Function"
        $errorCategory = 'ObjectNotFound'
        $errorTarget = $file
        $errorItem = New-Object -TypeName System.Management.Automation.ErrorRecord $exception, $errorId, $errorCategory, $errorTarget
        $errorItem.ErrorDetails = "Failed to import function $($file.BaseName)"
        throw $errorItem
    }
}
#endregion LoadFunctions
