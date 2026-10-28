function Get-JiraIssueWorklog {
    # .ExternalHelp ..\JiraPS-help.xml
    [CmdletBinding(SupportsPaging)]
    param(
        [Parameter( Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName )]
        [ValidateNotNull()]
        [AtlassianPS.JiraPS.IssueTransformation()]
        [Alias('Key')]
        [AtlassianPS.JiraPS.Issue]
        $Issue,

        [ValidateRange(1, [int]::MaxValue)]
        [Int]
        $PageSize = $script:DefaultPageSize,

        [Parameter()]
        [AtlassianPS.Connection]
        $Connection
    )

    begin {
        Write-Verbose "[$($MyInvocation.MyCommand.Name)] Function started"

        $RequestContext = Resolve-JiraOperationContext -BoundParameters $PSBoundParameters
    }

    process {
        Write-DebugMessage "ParameterSetName: $($PsCmdlet.ParameterSetName)"
        Write-DebugMessage -BoundParameters $PSBoundParameters

        # Find the proper object for the Issue
        $issueObj = Resolve-JiraIssueObject -InputObject $Issue -RequestContext $RequestContext

        $parameter = @{
            URI               = "{0}/worklog" -f $issueObj.RestURL
            Method            = "GET"
            GetParameter      = @{
                maxResults = $PageSize
            }
            OutputType        = "JiraWorklogItem"
            Paging            = $true
            PageSize          = $PageSize
            First             = $PSCmdlet.PagingParameters.First
            Skip              = $PSCmdlet.PagingParameters.Skip
            IncludeTotalCount = $PSCmdlet.PagingParameters.IncludeTotalCount
        }

        Write-DebugMessage "Invoking JiraMethod with `$parameter"
        Invoke-JiraRequest -RequestContext $RequestContext @parameter
    }

    end {
        Write-Verbose "[$($MyInvocation.MyCommand.Name)] Complete"
    }
}
