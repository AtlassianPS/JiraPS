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
            Write-DebugMessage "[$($MyInvocation.MyCommand.Name)] Using `$InputObject as object"
            return $InputObject
        }

        Write-DebugMessage "[$($MyInvocation.MyCommand.Name)] Resolve Issue '$($InputObject.Key)' to object"
        Get-JiraIssueOperation -Key $InputObject.Key -RequestContext $RequestContext -ErrorAction Stop
    }
}
