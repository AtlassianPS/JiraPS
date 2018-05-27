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
    Add-Type -Assembly System.Web
}
if (!("System.Net.Http" -as [Type])) {
    Add-Type -Assembly System.Net.Http
}
#endregion Dependencies

#region Configuration
$script:DefaultContentType = "application/json; charset=utf-8"
$script:DefaultPageSize = 25
$script:DefaultHeaders = @{
    "Accept"         = "application/json"
    "Accept-Charset" = "utf-8"
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
        $errorItem = [System.Management.Automation.ErrorRecord]::new(
            ([System.ArgumentException]"Function not found"),
            'Load.Function',
            [System.Management.Automation.ErrorCategory]::ObjectNotFound,
            $file
        )
        $errorItem.ErrorDetails = "Failed to import function $($file.BaseName)"
        throw $errorItem
    }
}
Export-ModuleMember -Function $PublicFunctions.BaseName
#endregion LoadFunctions
