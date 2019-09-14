#region Dependencies
# Load the ConfluencePS namespace from C#
# if (!("" -as [Type])) {
#     Add-Type -Path (Join-Path $PSScriptRoot JiraPS.Types.cs) -ReferencedAssemblies Microsoft.CSharp, Microsoft.PowerShell.Commands.Utility, System.Management.Automation
# }
# if ($PSVersionTable.PSVersion.Major -lt 5) {
#     Add-Type -Path (Join-Path $PSScriptRoot JiraPS.Attributes.cs) -ReferencedAssemblies Microsoft.CSharp, Microsoft.PowerShell.Commands.Utility, System.Management.Automation
# }

# Load Web assembly when needed
# PowerShell Core has the assembly preloaded
if (!("System.Web.HttpUtility" -as [Type])) {
    Add-Type -AssemblyName "System.Web"
}
# Load System.Net.Http when needed
# PowerShell Core has the assembly preloaded
if (!("System.Net.Http.HttpRequestException" -as [Type])) {
    Add-Type -AssemblyName "System.Net.Http"
}
if (!("System.Net.Http" -as [Type])) {
    Add-Type -Assembly System.Net.Http
}
#endregion Dependencies

#region Configuration
$script:configPath = ("{0}/AtlassianPS/JiraPS" -f [Environment]::GetFolderPath('ApplicationData'))
$script:serversConfig = "$script:configPath\servers.json"

if (-not (Test-Path $script:configPath)) {
    $null = New-Item -Path $script:configPath -ItemType Directory -Force
}

if (Test-Path -Path $script:serversConfig) {
    $script:JiraServerConfigs = Get-Content -Path $script:serversConfig -Raw | ConvertFrom-Json
} elseif (Test-Path -Path "$script:configPath\server_config") {
    $serverUrl = Get-Content -Path "$script:configPath\server_config"

    $script:JiraServerConfigs = @{
        Default = (New-Object psobject -Property @{ Server = $serverUrl })
    }
} else {
    $script:JiraServerConfigs = @{}
}

$script:JiraSessions = @{}

$script:DefaultContentType = "application/json; charset=utf-8"
$script:DefaultPageSize = 25
$script:DefaultHeaders = @{ "Accept-Charset" = "utf-8" }
# Bug in PSv3's .Net API
if ($PSVersionTable.PSVersion.Major -gt 3) {
    $script:DefaultHeaders["Accept"] = "application/json"
}
$script:PagingContainers = @(
    "comments"
    "dashboards"
    "groups"
    "issues"
    "values"
    "worklogs"
)
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
Export-ModuleMember -Function $PublicFunctions.BaseName -Alias *
#endregion LoadFunctions
