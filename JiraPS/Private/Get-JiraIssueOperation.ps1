function Get-JiraIssueOperation {
    [CmdletBinding( SupportsPaging, DefaultParameterSetName = 'ByIssueKey' )]
    param(
        [Parameter( Position = 0, Mandatory, ValueFromPipelineByPropertyName, ParameterSetName = 'ByIssueKey' )]
        [ValidateNotNullOrEmpty()]
        [Alias('Issue')]
        [String[]]
        $Key,

        [Parameter( Position = 0, Mandatory, ValueFromPipeline, ParameterSetName = 'ByInputObject' )]
        [ValidateNotNull()]
        [AtlassianPS.JiraPS.IssueTransformation()]
        [AtlassianPS.JiraPS.Issue]
        $InputObject,
        <#
          #ToDo:Deprecate
          This is not necessary if $Key uses ValueFromPipelineByPropertyName
        #>

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
        Write-DebugMessage "[$($MyInvocation.MyCommand.Name)] ParameterSetName: $($PsCmdlet.ParameterSetName)"

        switch ($PSCmdlet.ParameterSetName) {
            'ByIssueKey' {
                foreach ($_key in $Key) {
                    Write-Verbose "[$($MyInvocation.MyCommand.Name)] Processing [$_key]"
                    Write-Debug "[$($MyInvocation.MyCommand.Name)] Processing `$_key [$_key]"

                    $expandValue = if ($IncludeHistory) { "transitions,changelog" }
                    else { "transitions" }
                    $getParameter = @{ expand = $expandValue }
                    if ($Fields) { $getParameter["fields"] = $Fields }

                    $parameter = @{
                        URI          = $resourceURi -f $_key
                        Method       = "GET"
                        GetParameter = $getParameter
                    }

                    Write-Debug "[$($MyInvocation.MyCommand.Name)] Invoking JiraMethod with `$parameter"
                    $result = Invoke-JiraMethod -RequestContext $RequestContext @parameter

                    Write-Output (ConvertTo-JiraIssue -InputObject $result)
                }
            }
            'ByInputObject' {
                # Write-Warning "[$($MyInvocation.MyCommand.Name)] The parameter '-InputObject' has been marked as deprecated."
                Write-Verbose "[$($MyInvocation.MyCommand.Name)] Processing [$InputObject]"
                Write-Debug "[$($MyInvocation.MyCommand.Name)] Processing `$InputObject [$InputObject]"

                Write-Output (Get-JiraIssueOperation -Key $InputObject.Key -Fields $Fields -RequestContext $RequestContext -IncludeHistory:$IncludeHistory)
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

                Write-Debug "[$($MyInvocation.MyCommand.Name)] Invoking JiraMethod with `$parameter"
                Invoke-JiraMethod -RequestContext $RequestContext @parameter
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

                Write-Debug "[$($MyInvocation.MyCommand.Name)] Invoking JiraMethod with `$parameter"
                Invoke-JiraMethod -RequestContext $RequestContext @parameter
            }
        }
    }

    end {
        Write-Verbose "[$($MyInvocation.MyCommand.Name)] Complete"
    }
}
