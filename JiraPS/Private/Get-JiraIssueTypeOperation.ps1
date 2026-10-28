function Get-JiraIssueTypeOperation {
    <#
    .SYNOPSIS
        Retrieve and cache Jira issue types, or match typed issue-type selectors.
    .DESCRIPTION
        Refresh fetches a new response and replaces the connection-scoped cache entry.
    #>
    [CmdletBinding( DefaultParameterSetName = '_All' )]
    param(
        [Parameter( Position = 0, Mandatory, ValueFromPipeline, ParameterSetName = '_Search' )]
        [AtlassianPS.JiraPS.IssueTypeTransformation()]
        [AtlassianPS.JiraPS.IssueType[]]
        $IssueType,

        [Parameter()]
        [Switch]
        $Refresh,

        [Parameter()]
        [AtlassianPS.Connection]
        $RequestContext
    )

    begin {
        Write-Verbose "[$($MyInvocation.MyCommand.Name)] Function started"

        $resourceURi = "/rest/api/2/issuetype"
    }

    process {
        Write-DebugMessage "ParameterSetName: $($PsCmdlet.ParameterSetName)"
        Write-DebugMessage -BoundParameters $PSBoundParameters

        switch ($PSCmdlet.ParameterSetName) {
            '_All' {
                $parameter = @{
                    URI         = $resourceURi
                    Method      = "GET"

                    CacheKey    = 'IssueTypes'
                    CacheExpiry = [TimeSpan]::FromHours(1)
                    BypassCache = $Refresh
                }
                Write-DebugMessage "Invoking JiraMethod with `$parameter"
                $result = Invoke-JiraRequest -RequestContext $RequestContext @parameter

                Write-Output (ConvertTo-JiraIssueType -InputObject $result)
            }
            '_Search' {
                foreach ($_issueType in $IssueType) {
                    Write-Verbose "[$($MyInvocation.MyCommand.Name)] Processing [$_issueType]"
                    Write-DebugMessage "Processing `$_issueType [$_issueType]"

                    $allIssueTypes = Get-JiraIssueTypeOperation -Refresh:$Refresh -RequestContext $RequestContext

                    Write-Output ($allIssueTypes | Where-Object -FilterScript {
                            if ($null -ne $_issueType.Id) { $_.Id -eq $_issueType.Id }
                            else { $_.Name -like $_issueType.Name }
                        })
                }
            }
        }
    }

    end {
        Write-Verbose "[$($MyInvocation.MyCommand.Name)] Complete"
    }
}
