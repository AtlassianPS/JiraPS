function Get-JiraIssueTypeOperation {
    [CmdletBinding( DefaultParameterSetName = '_All' )]
    param(
        [Parameter( Position = 0, Mandatory, ValueFromPipeline, ParameterSetName = '_Search' )]
        [AtlassianPS.JiraPS.IssueTypeTransformation()]
        [AtlassianPS.JiraPS.IssueType[]]
        $IssueType,

        [Parameter()]
        [Switch]
        $Force,

        [Parameter()]
        [AtlassianPS.Connection]
        $RequestContext
    )
    begin {
        Write-Verbose "[$($MyInvocation.MyCommand.Name)] Function started"

        $resourceURi = "/rest/api/2/issuetype"
    }

    process {
        Write-DebugMessage "[$($MyInvocation.MyCommand.Name)] ParameterSetName: $($PsCmdlet.ParameterSetName)"

        switch ($PSCmdlet.ParameterSetName) {
            '_All' {
                $parameter = @{
                    URI         = $resourceURi
                    Method      = "GET"

                    CacheKey    = 'IssueTypes'
                    CacheExpiry = [TimeSpan]::FromHours(1)
                    BypassCache = $Force
                }
                Write-Debug "[$($MyInvocation.MyCommand.Name)] Invoking JiraMethod with `$parameter"
                $result = Invoke-JiraMethod -RequestContext $RequestContext @parameter

                Write-Output (ConvertTo-JiraIssueType -InputObject $result)
            }
            '_Search' {
                foreach ($_issueType in $IssueType) {
                    Write-Verbose "[$($MyInvocation.MyCommand.Name)] Processing [$_issueType]"
                    Write-Debug "[$($MyInvocation.MyCommand.Name)] Processing `$_issueType [$_issueType]"

                    $allIssueTypes = Get-JiraIssueTypeOperation -Force:$Force -RequestContext $RequestContext

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
