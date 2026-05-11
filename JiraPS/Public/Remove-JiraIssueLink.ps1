function Remove-JiraIssueLink {
    # .ExternalHelp ..\JiraPS-help.xml
    [CmdletBinding( SupportsShouldProcess, ConfirmImpact = 'Medium', DefaultParameterSetName = 'ByIssueLink' )]
    param(
        [Parameter( Mandatory, ValueFromPipeline, ParameterSetName = 'ByIssueLink' )]
        [ValidateNotNull()]
        [AtlassianPS.JiraPS.IssueLinkTransformation()]
        [AtlassianPS.JiraPS.IssueLink[]]
        $IssueLink,

        [Parameter( Mandatory, ValueFromPipeline, ParameterSetName = 'ByIssue' )]
        [ValidateNotNull()]
        [AtlassianPS.JiraPS.IssueTransformation()]
        [AtlassianPS.JiraPS.Issue[]]
        $Issue,

        [Parameter()]
        [System.Management.Automation.PSCredential]
        [System.Management.Automation.Credential()]
        $Credential = [System.Management.Automation.PSCredential]::Empty
    )

    begin {
        Write-Verbose "[$($MyInvocation.MyCommand.Name)] Function started"

        $resourceURi = "/rest/api/2/issueLink/{0}"
    }

    process {
        Write-DebugMessage "[$($MyInvocation.MyCommand.Name)] ParameterSetName: $($PsCmdlet.ParameterSetName)"
        Write-DebugMessage "[$($MyInvocation.MyCommand.Name)] PSBoundParameters: $($PSBoundParameters | Out-String)"

        $linksToRemove = switch ($PSCmdlet.ParameterSetName) {
            'ByIssue' {
                foreach ($currentIssue in $Issue) {
                    $resolvedIssue = $currentIssue
                    if (-not $resolvedIssue.IssueLinks) {
                        $resolvedIssue = Resolve-JiraIssueObject -InputObject $currentIssue -Credential $Credential -ErrorAction Stop
                    }

                    foreach ($link in @($resolvedIssue.IssueLinks)) {
                        if ($link) {
                            $link
                        }
                    }
                }
            }
            default {
                $IssueLink
            }
        }

        foreach ($link in $linksToRemove) {
            Write-Verbose "[$($MyInvocation.MyCommand.Name)] Processing [$link]"
            Write-Debug "[$($MyInvocation.MyCommand.Name)] Processing `$link [$link]"

            $parameter = @{
                URI        = $resourceURi -f $link.id
                Method     = "DELETE"
                Credential = $Credential
            }
            Write-Debug "[$($MyInvocation.MyCommand.Name)] Invoking JiraMethod with `$parameter"
            if ($PSCmdlet.ShouldProcess($link.id, "Remove IssueLink")) {
                Invoke-JiraMethod @parameter
            }
        }
    }

    end {
        Write-Verbose "[$($MyInvocation.MyCommand.Name)] Complete"
    }
}
