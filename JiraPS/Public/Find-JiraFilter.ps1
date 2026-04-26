function Find-JiraFilter {
    # .ExternalHelp ..\JiraPS-help.xml
    [CmdletBinding( DefaultParameterSetName = 'ByAccountId', SupportsPaging )]
    param(
        [Parameter(ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [string[]]$Name,

        [Parameter(ParameterSetName = 'ByAccountId', ValueFromPipelineByPropertyName)]
        [string]$AccountId,

        [Parameter(ParameterSetName = 'ByOwner', ValueFromPipelineByPropertyName)]
        [ValidateNotNull()]
        [AtlassianPS.JiraPS.UserTransformation()]
        [Alias('UserName')]
        [AtlassianPS.JiraPS.User]
        $Owner,

        [Parameter(ValueFromPipelineByPropertyName)]
        [string]$GroupName,

        [Parameter(ValueFromPipelineByPropertyName)]
        [ValidateNotNull()]
        [AtlassianPS.JiraPS.ProjectTransformation()]
        [AtlassianPS.JiraPS.Project]
        $Project,

        [Validateset('description', 'favourite', 'favouritedCount', 'jql', 'owner', 'searchUrl', 'sharePermissions', 'subscriptions', 'viewUrl')]
        [String[]]
        $Fields = @('description', 'favourite', 'favouritedCount', 'jql', 'owner', 'searchUrl', 'sharePermissions', 'subscriptions', 'viewUrl'),

        [Validateset('description', 'favourite_count', 'is_favourite', 'id', 'name', 'owner')]
        [string]$Sort,

        [System.Management.Automation.PSCredential]
        [System.Management.Automation.Credential()]
        $Credential = [System.Management.Automation.PSCredential]::Empty
    )

    begin {
        Write-Verbose "[$($MyInvocation.MyCommand.Name)] Function started"

        $searchURi = "/rest/api/2/filter/search"

        [String]$Fields = $Fields -join ','
    }

    process {
        Write-DebugMessage "[$($MyInvocation.MyCommand.Name)] PSBoundParameters: $($PSBoundParameters | Out-String)"
        $parameter = @{
            URI          = $searchURi
            Method       = 'GET'
            GetParameter = @{
                expand = $Fields
            }
            Paging       = $true
            Credential   = $Credential
        }
        if ($PSCmdlet.MyInvocation.BoundParameters.ContainsKey('AccountId')) {
            $parameter['GetParameter']['accountId'] = $AccountId
        }
        elseif ($PSCmdlet.ParameterSetName -eq 'ByOwner') {
            $userObj = Resolve-JiraUser -InputObject $Owner -Exact -Credential $Credential -ErrorAction Stop
            $parameter['GetParameter']['accountId'] = $userObj.AccountId
        }
        if ($PSCmdlet.MyInvocation.BoundParameters.ContainsKey('GroupName')) {
            $parameter['GetParameter']['groupName'] = $GroupName
        }
        if ($PSCmdlet.MyInvocation.BoundParameters.ContainsKey('Project')) {
            if ($Project.Id) {
                # Caller passed a Project that already had its numeric ID
                # (either a real object or a numeric scalar coerced by the
                # transformer); use it directly and skip the lookup.
                $parameter['GetParameter']['projectId'] = $Project.Id
            }
            else {
                $projectObj = Get-JiraProject -Project $Project.Key -Credential $Credential -ErrorAction Stop
                $parameter['GetParameter']['projectId'] = $projectObj.Id
            }
        }
        if ($PSCmdlet.MyInvocation.BoundParameters.ContainsKey('Sort')) {
            $parameter['GetParameter']['orderBy'] = $Sort
        }
        # Paging
        ($PSCmdlet.PagingParameters | Get-Member -MemberType Property).Name | ForEach-Object {
            $parameter[$_] = $PSCmdlet.PagingParameters.$_
        }
        if ($PSCmdlet.MyInvocation.BoundParameters.ContainsKey('Name')) {
            foreach ($_name in $Name) {
                $parameter['GetParameter']['filterName'] = $_name
                Write-Debug "[$($MyInvocation.MyCommand.Name)] Invoking JiraMethod with `$parameter"

                Write-Output (Invoke-JiraMethod @parameter | ConvertTo-JiraFilter)
            }
        }
        else {
            Write-Debug "[$($MyInvocation.MyCommand.Name)] Invoking JiraMethod with `$parameter"

            Write-Output (Invoke-JiraMethod @parameter | ConvertTo-JiraFilter)
        }

    }

    end {
        Write-Verbose "[$($MyInvocation.MyCommand.Name)] Complete"
    }
}
