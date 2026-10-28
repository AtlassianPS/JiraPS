function Resolve-JiraUser {
    <#
    .SYNOPSIS
        Resolve a typed user by its deployment-specific identity without implicit search.
    #>
    [CmdletBinding()]
    [OutputType([AtlassianPS.JiraPS.User])]
    param(
        [Parameter(Mandatory, ValueFromPipeline)]
        [ValidateNotNull()]
        [AtlassianPS.JiraPS.UserTransformation()]
        [AtlassianPS.JiraPS.User]$InputObject,

        [AtlassianPS.Connection]$RequestContext
    )

    process {
        $isCloud = Test-JiraCloudServer -RequestContext $RequestContext
        $identifier = if ($isCloud) { $InputObject.AccountId } else { $InputObject.Name }
        if ($InputObject.RestUrl -and $identifier) { return $InputObject }
        Get-JiraUserOperation -User $InputObject -RequestContext $RequestContext -ErrorAction Stop
    }
}
