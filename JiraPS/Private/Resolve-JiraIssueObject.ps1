function Resolve-JiraIssueObject {
    <#
    .SYNOPSIS
        Use a complete typed issue or retrieve its exact key or numeric ID.
    #>
    [CmdletBinding()]
    [OutputType( [AtlassianPS.JiraPS.Issue] )]
    param(
        [Parameter( Mandatory, ValueFromPipeline )]
        [AtlassianPS.JiraPS.Issue]
        $InputObject,

        [Parameter()]
        [AtlassianPS.Connection]
        $RequestContext
    )

    process {
        if ($InputObject.RestURL) {
            Write-DebugMessage "Using `$InputObject as object"
            return $InputObject
        }

        Write-DebugMessage "Resolve Issue '$($InputObject.Key)' to object"
        Get-JiraIssue -Issue $InputObject -Connection $RequestContext -ErrorAction Stop
    }
}
