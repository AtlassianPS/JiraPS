function Get-JiraIssueOperation {
    <#
    .SYNOPSIS
        Retrieve exact issues or explicitly search by JQL or saved filter.
    #>
    [CmdletBinding( SupportsPaging, DefaultParameterSetName = 'Issue' )]
    param(
        [Parameter( Position = 0, Mandatory, ValueFromPipeline, ParameterSetName = 'Issue' )]
        [ValidateNotNull()]
        [Alias('Key', 'Id', 'InputObject')]
        [AtlassianPS.JiraPS.IssueTransformation(AllowCollection = $true, AllowPipelineFallthrough = $true)]
        [AtlassianPS.JiraPS.Issue[]]
        $Issue,

        [Parameter( Mandatory, ParameterSetName = 'ByJQL' )]
        [Alias('JQL')]
        [String]
        $Query,

        [Parameter( Mandatory, ParameterSetName = 'ByFilter' )]
        [ValidateNotNull()]
        [AtlassianPS.JiraPS.FilterTransformation()]
        [AtlassianPS.JiraPS.Filter]
        $Filter,

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [String[]]
        $Fields = "*all",

        [Parameter( ParameterSetName = 'ByJQL' )]
        [Parameter( ParameterSetName = 'ByFilter' )]
        [UInt32]
        $PageSize = $script:DefaultPageSize,

        [Parameter()]
        [AtlassianPS.Connection]
        $RequestContext,

        [Parameter()]
        [Alias('GetHistory')]
        [Switch]
        $IncludeHistory
    )

    begin {
        Write-Verbose "[$($MyInvocation.MyCommand.Name)] Function started"

        $isCloud = Test-JiraCloudServer -RequestContext $RequestContext

        $searchURi = "/rest/api/2/search"
        $searchURi_v3 = "/rest/api/3/search/jql"
        $resourceURi = "/rest/api/2/issue/{0}"

        [String]$Fields = $Fields -join ","
    }

    process {
        Write-DebugMessage "ParameterSetName: $($PsCmdlet.ParameterSetName)"
        Write-DebugMessage -BoundParameters $PSBoundParameters

        switch ($PSCmdlet.ParameterSetName) {
            'Issue' {
                foreach ($item in $Issue) {
                    $_key = if ($item.Key) { $item.Key } else { $item.Id }
                    Write-Verbose "[$($MyInvocation.MyCommand.Name)] Processing [$_key]"
                    Write-DebugMessage "Processing `$_key [$_key]"

                    $expandValue = if ($IncludeHistory) { "transitions,changelog" }
                    else { "transitions" }
                    $getParameter = @{ expand = $expandValue }
                    if ($Fields) { $getParameter["fields"] = $Fields }

                    $parameter = @{
                        URI          = $resourceURi -f $_key
                        Method       = "GET"
                        GetParameter = $getParameter
                    }

                    Write-DebugMessage "Invoking JiraMethod with `$parameter"
                    $result = Invoke-JiraRequest -RequestContext $RequestContext @parameter

                    Write-Output (ConvertTo-JiraIssue -InputObject $result)
                }
            }
            'ByJQL' {
                $expandValue = if ($IncludeHistory) { "transitions,changelog" }
                else { "transitions" }
                $parameter = @{
                    URI          = if ($isCloud) { $searchURi_v3 } else { $searchURi }
                    Method       = "GET"
                    GetParameter = @{
                        jql           = $Query
                        validateQuery = $true
                        expand        = $expandValue
                        maxResults    = $PageSize
                    }
                    OutputType   = "JiraIssue"
                    Paging       = $true
                }
                if ($Fields) { $parameter["GetParameter"]["fields"] = $Fields }
                # Paging
                ($PSCmdlet.PagingParameters | Get-Member -MemberType Property).Name | ForEach-Object {
                    $parameter[$_] = $PSCmdlet.PagingParameters.$_
                }

                Write-DebugMessage "Invoking JiraMethod with `$parameter"
                Invoke-JiraRequest -RequestContext $RequestContext @parameter
            }
            'ByFilter' {
                $filterObj = (Get-JiraFilterOperation -Id $Filter.ID -RequestContext $RequestContext -ErrorAction Stop).SearchUrl
                $expandValue = if ($IncludeHistory) { "transitions,changelog" }
                else { "transitions" }
                $parameter = @{
                    URI          = $filterObj
                    Method       = "GET"
                    GetParameter = @{
                        validateQuery = $true
                        expand        = $expandValue
                        maxResults    = $PageSize
                    }
                    OutputType   = "JiraIssue"
                    Paging       = $true
                }
                if ($Fields) { $parameter["GetParameter"]["fields"] = $Fields }
                # Paging
                ($PSCmdlet.PagingParameters | Get-Member -MemberType Property).Name | ForEach-Object {
                    $parameter[$_] = $PSCmdlet.PagingParameters.$_
                }

                Write-DebugMessage "Invoking JiraMethod with `$parameter"
                Invoke-JiraRequest -RequestContext $RequestContext @parameter
            }
        }
    }

    end {
        Write-Verbose "[$($MyInvocation.MyCommand.Name)] Complete"
    }
}
