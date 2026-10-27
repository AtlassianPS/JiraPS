function Set-JiraVersion {
    # .ExternalHelp ..\JiraPS-help.xml
    [CmdletBinding( SupportsShouldProcess )]
    param(
        [Parameter( Mandatory, ValueFromPipeline )]
        [ValidateNotNull()]
        [AtlassianPS.JiraPS.VersionTransformation()]
        [AtlassianPS.JiraPS.Version[]]
        $Version,

        [String]
        $Name,

        [String]
        $Description,

        [Bool]
        $Archived,

        [Bool]
        $Released,

        [DateTime]
        $ReleaseDate,

        [DateTime]
        $StartDate,

        [ValidateNotNull()]
        [AtlassianPS.JiraPS.ProjectTransformation()]
        [AtlassianPS.JiraPS.Project]
        $Project,

        [Parameter()]
        [System.Management.Automation.PSCredential]
        [System.Management.Automation.Credential()]
        $Credential,

        [Alias('Session')]
        [AtlassianPS.Connection]
        $Connection,

        [Alias('Server', 'ServerName')]
        [ArgumentCompleter( {
                param($commandName, $parameterName, $wordToComplete)
                AtlassianPS.Configuration\Get-AtlassianConnection -Product Jira |
                    Where-Object { $_.Name -like "$wordToComplete*" } |
                    ForEach-Object { $_.Name }
            }
        )]
        [String]
        $ConnectionName,

        [Uri]
        $Uri,

        [Alias('Email')]
        [String]
        $EmailAddress,

        [Object]
        $ApiToken,

        [Alias('PAT', 'BearerToken')]
        [Object]
        $PersonalAccessToken,

        [Switch]
        $Anonymous
    )

    begin {
        try {
            Write-Verbose "[$($MyInvocation.MyCommand.Name)] Function started"

            $RequestContext = Resolve-JiraOperationContext -BoundParameters $PSBoundParameters
        }
        catch {
            if ($RequestContext -and $RequestContext.State -eq 'Standalone') { $RequestContext.Dispose() }
            throw
        }
    }

    process {
        try {
            Write-DebugMessage "[$($MyInvocation.MyCommand.Name)] ParameterSetName: $($PsCmdlet.ParameterSetName)"

            foreach ($_version in $Version) {
                Write-Verbose "[$($MyInvocation.MyCommand.Name)] Processing [$_version]"
                Write-Debug "[$($MyInvocation.MyCommand.Name)] Processing `$_version [$_version]"

                if (-not $_version.Id) {
                    $errorItem = [System.Management.Automation.ErrorRecord]::new(
                        ([System.ArgumentException]"Version ID is required"),
                        'ParameterValue.VersionIdRequired',
                        [System.Management.Automation.ErrorCategory]::InvalidArgument,
                        $_version
                    )

                    $errorItem.ErrorDetails = "Set-JiraVersion requires a version ID. Provide a numeric version ID or an AtlassianPS.JiraPS.Version object with an ID."
                    ThrowError -ErrorRecord $errorItem
                }

                $versionObj = Get-JiraVersionOperation -Id $_version.Id -RequestContext $RequestContext -ErrorAction Stop

                $requestBody = @{}

                if ($PSCmdlet.MyInvocation.BoundParameters.ContainsKey("Name")) { $requestBody["name"] = $Name }
                if ($PSCmdlet.MyInvocation.BoundParameters.ContainsKey("Description")) { $requestBody["description"] = $Description }
                if ($PSCmdlet.MyInvocation.BoundParameters.ContainsKey("Archived")) { $requestBody["archived"] = $Archived }
                if ($PSCmdlet.MyInvocation.BoundParameters.ContainsKey("Released")) { $requestBody["released"] = $Released }
                if ($PSCmdlet.MyInvocation.BoundParameters.ContainsKey("Project")) {
                    if ($Project.Id) {
                        # Caller passed a Project that already carried its numeric
                        # ID (real object or a numeric scalar coerced by the
                        # transformer); skip the lookup.
                        $requestBody["projectId"] = $Project.Id
                    }
                    else {
                        $projectObj = Get-JiraProjectOperation -Project $Project.Key -RequestContext $RequestContext -ErrorAction Stop
                        $requestBody["projectId"] = $projectObj.Id
                    }
                }
                if ($PSCmdlet.MyInvocation.BoundParameters.ContainsKey("ReleaseDate")) {
                    $requestBody["releaseDate"] = $ReleaseDate.ToString('yyyy-MM-dd')
                }
                if ($PSCmdlet.MyInvocation.BoundParameters.ContainsKey("StartDate")) {
                    $requestBody["startDate"] = $StartDate.ToString('yyyy-MM-dd')
                }

                $parameter = @{
                    URI    = $versionObj.RestUrl
                    Method = "PUT"
                    Body   = ConvertTo-Json -InputObject $requestBody
                }
                Write-Debug "[$($MyInvocation.MyCommand.Name)] Invoking JiraMethod with `$parameter"
                if ($PSCmdlet.ShouldProcess($Name, "Updating Version on JIRA")) {
                    $result = Invoke-JiraMethod -RequestContext $RequestContext @parameter

                    Write-Output (ConvertTo-JiraVersion -InputObject $result)
                }
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
