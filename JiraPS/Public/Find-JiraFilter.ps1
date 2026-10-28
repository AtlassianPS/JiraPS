function Find-JiraFilter {
    # .ExternalHelp ..\JiraPS-help.xml
    [CmdletBinding( DefaultParameterSetName = 'ByAccountId', SupportsPaging )]
    param(
        [Parameter( ValueFromPipeline, ValueFromPipelineByPropertyName )]
        [string[]]
        $Name,

        [Parameter( ParameterSetName = 'ByAccountId', ValueFromPipelineByPropertyName )]
        [string]
        $AccountId,

        [Parameter( ParameterSetName = 'ByOwner', ValueFromPipelineByPropertyName )]
        [ValidateNotNull()]
        [AtlassianPS.JiraPS.UserTransformation()]
        [Alias('UserName')]
        [AtlassianPS.JiraPS.User]
        $Owner,

        [Parameter( ValueFromPipelineByPropertyName )]
        [string]
        $GroupName,

        [Parameter( ValueFromPipelineByPropertyName )]
        [ValidateNotNull()]
        [AtlassianPS.JiraPS.ProjectTransformation()]
        [AtlassianPS.JiraPS.Project]
        $Project,

        [Validateset('description', 'favourite', 'favouritedCount', 'jql', 'owner', 'searchUrl', 'sharePermissions', 'subscriptions', 'viewUrl')]
        [String[]]
        $Fields = @(
            'description',
            'favourite',
            'favouritedCount',
            'jql',
            'owner',
            'searchUrl',
            'sharePermissions',
            'subscriptions',
            'viewUrl'
        ),

        [Validateset('description', 'favourite_count', 'is_favourite', 'id', 'name', 'owner')]
        [string]
        $Sort,

        [AtlassianPS.Connection]
        $Connection
    )

    begin {
        Write-Verbose "[$($MyInvocation.MyCommand.Name)] Function started"
        Write-DebugMessage -BoundParameters $PSBoundParameters

        $RequestContext = Resolve-JiraOperationContext -BoundParameters $PSBoundParameters
        if (-not (Test-JiraCloudServer -RequestContext $RequestContext)) {
            throw 'Jira Data Center does not expose the filter search API. Use Get-JiraFilter -Filter or -Favorite.'
        }

        $searchURi = "/rest/api/2/filter/search"

        [String]$Fields = $Fields -join ','
    }

    process {
        $parameter = @{
            URI          = $searchURi
            Method       = 'GET'
            GetParameter = @{
                expand = $Fields
            }
            Paging       = $true
        }
        if ($PSCmdlet.MyInvocation.BoundParameters.ContainsKey('AccountId')) { $parameter['GetParameter']['accountId'] = $AccountId }
        elseif ($PSCmdlet.ParameterSetName -eq 'ByOwner') {
            $userObj = Resolve-JiraUser -InputObject $Owner -RequestContext $RequestContext -ErrorAction Stop
            if (-not $userObj.AccountId) { throw 'Filter Owner requires a Jira Cloud accountId.' }
            $parameter['GetParameter']['accountId'] = $userObj.AccountId
        }
        if ($PSCmdlet.MyInvocation.BoundParameters.ContainsKey('GroupName')) { $parameter['GetParameter']['groupName'] = $GroupName }
        if ($PSCmdlet.MyInvocation.BoundParameters.ContainsKey('Project')) {
            if ($Project.Id) {
                # Caller passed a Project that already had its numeric ID
                # (either a real object or a numeric scalar coerced by the
                # transformer); use it directly and skip the lookup.
                $parameter['GetParameter']['projectId'] = $Project.Id
            }
            else {
                $projectObj = Get-JiraProject -Project $Project.Key -Connection $RequestContext -ErrorAction Stop
                $parameter['GetParameter']['projectId'] = $projectObj.Id
            }
        }
        if ($PSCmdlet.MyInvocation.BoundParameters.ContainsKey('Sort')) { $parameter['GetParameter']['orderBy'] = $Sort }
        # Paging
        ($PSCmdlet.PagingParameters | Get-Member -MemberType Property).Name | ForEach-Object {
            $parameter[$_] = $PSCmdlet.PagingParameters.$_
        }
        if ($PSCmdlet.MyInvocation.BoundParameters.ContainsKey('Name')) {
            foreach ($_name in $Name) {
                $parameter['GetParameter']['filterName'] = $_name
                Write-DebugMessage "Invoking JiraMethod with `$parameter"

                Write-Output (Invoke-JiraRequest -RequestContext $RequestContext @parameter | ConvertTo-JiraFilter)
            }
        }
        else {
            Write-DebugMessage "Invoking JiraMethod with `$parameter"

            Write-Output (Invoke-JiraRequest -RequestContext $RequestContext @parameter | ConvertTo-JiraFilter)
        }
    }

    end {
        Write-Verbose "[$($MyInvocation.MyCommand.Name)] Complete"
    }
}
