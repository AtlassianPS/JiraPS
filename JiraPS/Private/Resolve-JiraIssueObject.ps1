function Resolve-JiraIssueObject {
    [CmdletBinding()]
    [OutputType( [AtlassianPS.JiraPS.Issue] )]
    param(
        [Parameter( Mandatory, ValueFromPipeline )]
        [AtlassianPS.JiraPS.Issue]
        $InputObject,

        [Parameter()]
        [System.Management.Automation.PSCredential]
        [System.Management.Automation.Credential()]
        $Credential = [System.Management.Automation.PSCredential]::Empty
    )

    process {
        if ($InputObject.RestURL) {
            Write-DebugMessage "[$($MyInvocation.MyCommand.Name)] Using `$InputObject as object"
            return $InputObject
        }

        Write-DebugMessage "[$($MyInvocation.MyCommand.Name)] Resolve Issue '$($InputObject.Key)' to object"
        Get-JiraIssue -Key $InputObject.Key -Credential $Credential -ErrorAction Stop
    }
}
