function Remove-JiraIssue {
    # .ExternalHelp ..\JiraPS-help.xml
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'High')]
    param(
        [Parameter(Mandatory, Position = 0, ValueFromPipeline)]
        [ValidateNotNull()]
        [Alias('Key', 'Id')]
        [AtlassianPS.JiraPS.IssueTransformation(AllowCollection = $true)]
        [AtlassianPS.JiraPS.Issue[]]$Issue,

        [Alias('deleteSubtasks')]
        [Switch]$IncludeSubTasks,

        [AtlassianPS.Connection]$Connection
    )

    begin { $requestContext = Resolve-JiraOperationContext -BoundParameters $PSBoundParameters }
    process {
        foreach ($item in $Issue) {
            $issueObject = Resolve-JiraIssueObject -InputObject $item -RequestContext $requestContext
            $action = if ($IncludeSubTasks) { 'Remove issue and sub-tasks' } else { 'Remove issue' }
            if ($PSCmdlet.ShouldProcess($issueObject.Key, $action)) {
                $parameters = @{
                    Uri          = "/rest/api/2/issue/$($issueObject.Key)"
                    Method       = 'Delete'
                    GetParameter = @{ deleteSubtasks = $IncludeSubTasks.ToString().ToLowerInvariant() }
                }
                $null = Invoke-JiraRequest -RequestContext $requestContext @parameters
            }
        }
    }
}
