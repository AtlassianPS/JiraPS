function Get-JiraIssueType {
    # .ExternalHelp ..\JiraPS-help.xml
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
        $Connection
    )

    begin {
        Write-Verbose "[$($MyInvocation.MyCommand.Name)] Function started"
        Write-DebugMessage -BoundParameters $PSBoundParameters

        $requestContext = Resolve-JiraOperationContext -BoundParameters $PSBoundParameters

        $resourceURi = "/rest/api/2/issuetype"
        $allIssueTypes = $null
    }

    process {
        Write-DebugMessage "ParameterSetName: $($PsCmdlet.ParameterSetName)"
        Write-DebugMessage -BoundParameters $PSBoundParameters

        if ($null -eq $allIssueTypes) {
            $parameter = @{
                URI         = $resourceURi
                Method      = "GET"
                CacheKey    = 'IssueTypes'
                CacheExpiry = [TimeSpan]::FromHours(1)
                BypassCache = $Refresh
            }
            Write-DebugMessage "Invoking JiraMethod with `$parameter"
            $result = Invoke-JiraRequest -RequestContext $RequestContext @parameter
            $allIssueTypes = @(ConvertTo-JiraIssueType -InputObject $result)
        }

        if ($PSCmdlet.ParameterSetName -eq '_All') { Write-Output $allIssueTypes }
        else {
            foreach ($_issueType in $IssueType) {
                Write-Verbose "[$($MyInvocation.MyCommand.Name)] Processing [$_issueType]"
                Write-DebugMessage "Processing `$_issueType [$_issueType]"

                $allIssueTypes | Where-Object -FilterScript {
                    if ($null -ne $_issueType.Id) { $_.Id -eq $_issueType.Id }
                    else { $_.Name -like $_issueType.Name }
                }
            }
        }
    }

    end {
        Write-Verbose "[$($MyInvocation.MyCommand.Name)] Complete"
    }
}
