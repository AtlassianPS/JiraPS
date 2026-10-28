function Resolve-JiraIssueObject {
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
        Get-JiraIssueOperation -Key $InputObject.Key -RequestContext $RequestContext -ErrorAction Stop
    }
}
