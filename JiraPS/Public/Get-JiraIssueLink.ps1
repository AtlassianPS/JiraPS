function Get-JiraIssueLink {
    # .ExternalHelp ..\JiraPS-help.xml
    [CmdletBinding()]
    param(
        [Parameter( Mandatory, ValueFromPipeline )]
        [ValidateNotNull()]
        [Alias('Id')]
        [AtlassianPS.JiraPS.IssueLinkTransformation()]
        [AtlassianPS.JiraPS.IssueLink[]]
        $IssueLink,

        [Parameter()]
        [AtlassianPS.Connection]
        $Connection
    )

    begin {
        Write-Verbose "[$($MyInvocation.MyCommand.Name)] Function started"

        $RequestContext = Resolve-JiraOperationContext -BoundParameters $PSBoundParameters

        $resourceURi = "/rest/api/2/issueLink/{0}"
    }

    process {
        Write-DebugMessage "ParameterSetName: $($PsCmdlet.ParameterSetName)"
        Write-DebugMessage -BoundParameters $PSBoundParameters

        foreach ($link in $IssueLink) {
            if ($null -eq $link.Id -or $link.Id -le 0) { throw 'IssueLink requires a positive issue-link ID.' }
            $_id = $link.Id
            Write-Verbose "[$($MyInvocation.MyCommand.Name)] Processing [$_id]"
            Write-DebugMessage "Processing `$_id [$_id]"

            $parameter = @{
                URI    = $resourceURi -f $_id
                Method = "GET"
            }
            Write-DebugMessage "Invoking JiraMethod with `$parameter"
            $result = Invoke-JiraRequest -RequestContext $RequestContext @parameter

            Write-Output (ConvertTo-JiraIssueLink -InputObject $result)
        }
    }

    end {
        Write-Verbose "[$($MyInvocation.MyCommand.Name)] Complete"
    }
}
