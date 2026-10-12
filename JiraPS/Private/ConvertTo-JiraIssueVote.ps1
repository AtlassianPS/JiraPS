function ConvertTo-JiraIssueVote {
    [CmdletBinding()]
    [OutputType([AtlassianPS.JiraPS.IssueVotes])]
    param(
        [Parameter( ValueFromPipeline )]
        [PSObject[]]
        $InputObject
    )

    process {
        foreach ($i in $InputObject) {
            if ($null -eq $i) { continue }
            Write-Debug "[$($MyInvocation.MyCommand.Name)] Converting `$InputObject to AtlassianPS.JiraPS.IssueVotes"

            [AtlassianPS.JiraPS.IssueVotes]@{
                Self     = [uri]$i.self
                Votes    = ConvertTo-JiraNullableInt64 $i.votes
                HasVoted = $i.hasVoted
                Voters   = [AtlassianPS.JiraPS.User[]]@(ConvertTo-JiraUser $i.voters)
            }
        }
    }
}
