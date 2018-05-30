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
#endregion Dependencies

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
        # throw $errorItem
        throw $_
    }
}
Export-ModuleMember -Function $PublicFunctions.BaseName -Alias *
#endregion LoadFunctions
