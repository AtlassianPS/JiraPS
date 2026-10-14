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
        $Fields = @('description',
            'favourite',
            'favouritedCount',
            'jql',
            'owner',
            'searchUrl',
            'sharePermissions',
            'subscriptions',
            'viewUrl'),

        [Validateset('description', 'favourite_count', 'is_favourite', 'id', 'name', 'owner')]
        [string]$Sort,

        [System.Management.Automation.PSCredential]
        [System.Management.Automation.Credential()]
        $Credential,

        [Alias('Session')]
        [AtlassianPS.Connection]$Connection,

        [Alias('Server', 'ServerName')]
        [ArgumentCompleter({
                param($commandName, $parameterName, $wordToComplete)
                AtlassianPS.Configuration\Get-AtlassianConnection -Product Jira |
                    Where-Object { $_.Name -like "$wordToComplete*" } |
                    ForEach-Object { $_.Name }
            })]
        [String]$ConnectionName,

        [Uri]$Uri,

        [Alias('Email')]
        [String]$EmailAddress,

        [Object]$ApiToken,

        [Alias('PAT', 'BearerToken')]
        [Object]$PersonalAccessToken,

        [Switch]$Anonymous
    )

    begin {
        try {
            Write-Verbose "[$($MyInvocation.MyCommand.Name)] Function started"

            $RequestContext = Resolve-JiraOperationContext -BoundParameters $PSBoundParameters

            $searchURi = "/rest/api/2/filter/search"

            [String]$Fields = $Fields -join ','
        }
        catch {
            if ($RequestContext -and $RequestContext.State -eq 'Standalone') { $RequestContext.Dispose() }
            throw
        }
    }

    process {
        try {
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
                $userObj = Resolve-JiraUser -InputObject $Owner -Exact -RequestContext $RequestContext -ErrorAction Stop
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
                    $projectObj = Get-JiraProjectOperation -Project $Project.Key -RequestContext $RequestContext -ErrorAction Stop
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
                    Write-Debug "[$($MyInvocation.MyCommand.Name)] Invoking JiraMethod with `$parameter"

                    Write-Output (Invoke-JiraMethod -RequestContext $RequestContext @parameter | ConvertTo-JiraFilter)
                }
            }
            else {
                Write-Debug "[$($MyInvocation.MyCommand.Name)] Invoking JiraMethod with `$parameter"

                Write-Output (Invoke-JiraMethod -RequestContext $RequestContext @parameter | ConvertTo-JiraFilter)
            }

        }
        catch {
            if ($RequestContext -and $RequestContext.State -eq 'Standalone') { $RequestContext.Dispose() }
            throw
        }
    }

    end {
        try {
            Write-Verbose "[$($MyInvocation.MyCommand.Name)] Complete"
        }
        finally {
            if ($RequestContext.State -eq 'Standalone') { $RequestContext.Dispose() }
        }
    }
}
