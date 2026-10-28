function Get-JiraGroupMemberOperation {
    [CmdletBinding( SupportsPaging )]
    param(
        [Parameter( Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName )]
        [ValidateNotNull()]
        [AtlassianPS.JiraPS.GroupTransformation()]
        [AtlassianPS.JiraPS.Group[]]
        $Group,

        [Switch]
        $IncludeInactive,

        [UInt32]
        $PageSize = $script:DefaultPageSize,

        [Parameter()]
        [AtlassianPS.Connection]
        $RequestContext
    )

    begin {
        Write-Verbose "[$($MyInvocation.MyCommand.Name)] Function started"

        $isCloud = Test-JiraCloudServer -RequestContext $RequestContext

        $resourceURi = "/rest/api/2/group/member"

        if ($PageSize -gt 50) {
            Write-Warning "JIRA's API may not properly support MaxResults values higher than 50 for this method. If you receive inconsistent results, do not pass the MaxResults parameter to this function to return all results."
        }
    }

    process {
        Write-DebugMessage "ParameterSetName: $($PsCmdlet.ParameterSetName)"
        Write-DebugMessage -BoundParameters $PSBoundParameters

        foreach ($_group in $Group) {
            Write-Verbose "[$($MyInvocation.MyCommand.Name)] Processing [$_group]"
            Write-DebugMessage "Processing `$_group [$_group]"

            $getParameter = @{ maxResults = $PageSize }
            if ($isCloud -and $_group.Id) { $getParameter['groupId'] = $_group.Id }
            else { $getParameter['groupname'] = $_group.Name }

            if ($IncludeInactive) { $getParameter['includeInactiveUsers'] = $true }

            $parameter = @{
                URI          = $resourceURi
                Method       = "GET"
                GetParameter = $getParameter
                OutputType   = "JiraUser"
                Paging       = $true
            }

            # Paging
            ($PSCmdlet.PagingParameters | Get-Member -MemberType Property).Name | ForEach-Object {
                $parameter[$_] = $PSCmdlet.PagingParameters.$_
            }

            Write-DebugMessage "Invoking JiraMethod with `$parameter"
            Invoke-JiraRequest -RequestContext $RequestContext @parameter
        }
    }

    end {
        Write-Verbose "[$($MyInvocation.MyCommand.Name)] Complete"
    }
}
