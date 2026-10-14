function New-JiraVersion {
    # .ExternalHelp ..\JiraPS-help.xml
    [CmdletBinding( SupportsShouldProcess, DefaultParameterSetName = 'byObject' )]
    param(
        [Parameter( Position = 0, Mandatory, ValueFromPipeline, ParameterSetName = 'byObject' )]
        [ValidateNotNull()]
        [AtlassianPS.JiraPS.VersionTransformation()]
        [AtlassianPS.JiraPS.Version]
        $InputObject,

        [Parameter( Position = 0, Mandatory, ParameterSetName = 'byParameters' )]
        [String]
        $Name,

        [Parameter( Position = 1, Mandatory, ParameterSetName = 'byParameters' )]
        [ValidateNotNull()]
        [AtlassianPS.JiraPS.ProjectTransformation()]
        [AtlassianPS.JiraPS.Project]
        $Project,

        [Parameter( ParameterSetName = 'byParameters' )]
        [String]
        $Description,

        [Parameter( ParameterSetName = 'byParameters' )]
        [Bool]
        $Archived,

        [Parameter( ParameterSetName = 'byParameters' )]
        [Bool]
        $Released,

        [Parameter( ParameterSetName = 'byParameters' )]
        [DateTime]
        $ReleaseDate,

        [Parameter( ParameterSetName = 'byParameters' )]
        [DateTime]
        $StartDate,

        [Parameter()]
        [System.Management.Automation.PSCredential]
        [System.Management.Automation.Credential()]
        $Credential,

        [Alias('Session')][AtlassianPS.Connection]$Connection,

        [Alias('Server', 'ServerName')]
        [ArgumentCompleter({
                param($commandName, $parameterName, $wordToComplete)
                AtlassianPS.Configuration\Get-AtlassianConnection -Product Jira |
                    Where-Object { $_.Name -like "$wordToComplete*" } |
                    ForEach-Object { $_.Name }
            })][String]$ConnectionName,

        [Uri]$Uri,

        [Alias('Email')][String]$EmailAddress,

        [Object]$ApiToken,

        [Alias('PAT', 'BearerToken')][Object]$PersonalAccessToken,

        [Switch]$Anonymous
    )
    begin {
        try {
            Write-Verbose "[$($MyInvocation.MyCommand.Name)] Function started"

            $RequestContext = Resolve-JiraOperationContext -BoundParameters $PSBoundParameters

            $resourceURi = "/rest/api/2/version"
        }
        catch {
            if ($RequestContext -and $RequestContext.State -eq 'Standalone') { $RequestContext.Dispose() }
            throw
        }
    }

    process {
        try {
            Write-DebugMessage "[$($MyInvocation.MyCommand.Name)] ParameterSetName: $($PsCmdlet.ParameterSetName)"

            $requestBody = @{}
            switch ($PSCmdlet.ParameterSetName) {
                'byObject' {
                    $requestBody["name"] = $InputObject.Name
                    $requestBody["description"] = $InputObject.Description
                    $requestBody["archived"] = [bool]($InputObject.Archived)
                    $requestBody["released"] = [bool]($InputObject.Released)
                    if ($InputObject.ReleaseDate) { $requestBody["releaseDate"] = $InputObject.ReleaseDate.ToString('yyyy-MM-dd') }
                    if ($InputObject.StartDate) { $requestBody["startDate"] = $InputObject.StartDate.ToString('yyyy-MM-dd') }
                    if ($InputObject.Project) { $requestBody["projectId"] = $InputObject.Project }
                }
                'byParameters' {
                    $requestBody["name"] = $Name
                    if ($PSCmdlet.MyInvocation.BoundParameters.ContainsKey("Description")) { $requestBody["description"] = $Description }
                    if ($PSCmdlet.MyInvocation.BoundParameters.ContainsKey("Archived")) { $requestBody["archived"] = $Archived }
                    if ($PSCmdlet.MyInvocation.BoundParameters.ContainsKey("Released")) { $requestBody["released"] = $Released }
                    if ($PSCmdlet.MyInvocation.BoundParameters.ContainsKey("ReleaseDate")) {
                        $requestBody["releaseDate"] = Get-Date $ReleaseDate -Format 'yyyy-MM-dd'
                    }
                    if ($PSCmdlet.MyInvocation.BoundParameters.ContainsKey("StartDate")) {
                        $requestBody["startDate"] = Get-Date $StartDate -Format 'yyyy-MM-dd'
                    }

                    # Prefer the numeric ID when the typed parameter has it (real
                    # Project object or a numeric scalar coerced by the transformer);
                    # otherwise fall back to the project key, which the v2/v3 create
                    # endpoint accepts under the "project" field.
                    if ($Project.Id) { $requestBody["projectId"] = $Project.Id }
                    elseif ($Project.Key) { $requestBody["project"] = $Project.Key }
                }
            }

            $parameter = @{
                URI    = $resourceURi
                Method = "POST"
                Body   = ConvertTo-Json -InputObject $requestBody

            }
            Write-Debug "[$($MyInvocation.MyCommand.Name)] Invoking JiraMethod with `$parameter"
            if ($PSCmdlet.ShouldProcess($Name, "Creating new Version on JIRA")) {
                $result = Invoke-JiraMethod -RequestContext $RequestContext @parameter

                Write-Output (ConvertTo-JiraVersion -InputObject $result)
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
