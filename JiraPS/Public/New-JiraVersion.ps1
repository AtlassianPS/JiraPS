function New-JiraVersion {
    <#
    .Synopsis
        Creates a new FixVersion in JIRA
    .DESCRIPTION
         This function creates a new FixVersion in JIRA.
    .EXAMPLE
        New-JiraVersion -Name '1.0.0.0' -Project "RD"
        Description
        -----------
        This example creates a new JIRA Version named '1.0.0.0' in project `RD`.
    .EXAMPLE
        $project = Get-JiraProject -Project "RD"
        New-JiraVersion -Name '1.0.0.0' -Project $project -ReleaseDate "2000-12-31"
        Description
        -----------
        Create a new Version in Project `RD` with a set release date.
    .EXAMPLE
        $version = Get-JiraVersion -Name "1.0.0.0" -Project "RD"
        $version = $version.Project.Key "TEST"
        $version | New-JiraVersion
        Description
        -----------
        This example duplicates the Version named '1.0.0.0' in Project `RD` to Project `TEST`.
    .OUTPUTS
        [JiraPS.Version]
    .LINK
        Get-JiraVersion
    .LINK
        Remove-JiraVersion
    .LINK
        Set-JiraVersion
    .LINK
        Get-JiraProject
    .NOTES
        This function requires either the -Credential parameter to be passed or a persistent JIRA session. See New-JiraSession for more details.  If neither are supplied, this function will run with anonymous access to JIRA.
    #>
    [CmdletBinding( SupportsShouldProcess, DefaultParameterSetName = 'byObject' )]
    param(
        # Version object that should be created on the server.
        [Parameter( Position = 0, Mandatory, ValueFromPipeline, ParameterSetName = 'byObject' )]
        [Object]
        $InputObject,

        # Name of the version to create.
        [Parameter( Position = 0, Mandatory, ParameterSetName = 'byParameters' )]
        [String]
        $Name,

        # The Project ID
        [Parameter( Position = 1, Mandatory, ParameterSetName = 'byParameters' )]
        [Object]
        $Project,

        # Description of the version.
        [Parameter( ParameterSetName = 'byParameters' )]
        [String]
        $Description,

        # Create the version as archived.
        [Parameter( ParameterSetName = 'byParameters' )]
        [Bool]
        $Archived,

        # Create the version as released.
        [Parameter( ParameterSetName = 'byParameters' )]
        [Bool]
        $Released,

        # Date of the release.
        [Parameter( ParameterSetName = 'byParameters' )]
        [DateTime]
        $ReleaseDate,

        # Date of the release.
        [Parameter( ParameterSetName = 'byParameters' )]
        [DateTime]
        $StartDate,

        # Credentials to use to connect to JIRA.
        # If not specified, this function will use anonymous access.
        [PSCredential]
        $Credential
    )

    begin {
        Write-Verbose "[$($MyInvocation.MyCommand.Name)] Function started"

        $server = Get-JiraConfigServer -ConfigFile $ConfigFile -ErrorAction Stop

        $resourceURi = "$server/rest/api/latest/version"
    }

    process {
        Write-DebugMessage "[$($MyInvocation.MyCommand.Name)] ParameterSetName: $($PsCmdlet.ParameterSetName)"
        Write-DebugMessage "[$($MyInvocation.MyCommand.Name)] PSBoundParameters: $($PSBoundParameters | Out-String)"

        $requestBody = @{}
        Switch ($PSCmdlet.ParameterSetName) {
            'byObject' {
                # Validate InputObject type
                if ("JiraPS.Version" -notin $InputObject.PSObject.TypeNames) {
                    $errorItem = [System.Management.Automation.ErrorRecord]::new(
                        ([System.ArgumentException]"Invalid Parameter"),
                        'ParameterType.NotJiraVersion',
                        [System.Management.Automation.ErrorCategory]::InvalidArgument,
                        $InputObject
                    )
                    $errorItem.ErrorDetails = "Wrong object type provided for Version. Only JiraPS.Version is accepted."
                    $PSCmdlet.ThrowTerminatingError($errorItem)
                }

                # Validate mandatory properties
                if (-not ($InputObject.Project -and $InputObject.Name)) {
                    $errorItem = [System.Management.Automation.ErrorRecord]::new(
                        ([System.ArgumentException]"Invalid Parameter"),
                        'ParameterMissing',
                        [System.Management.Automation.ErrorCategory]::InvalidArgument,
                        $InputObject
                    )
                    $errorItem.ErrorDetails = "The Version provided does not contain all necessary information. Mandatory properties: 'Project', 'Name'."
                    $PSCmdlet.ThrowTerminatingError($errorItem)
                }

                $requestBody["name"] = $InputObject.Name
                $requestBody["description"] = $InputObject.Description
                $requestBody["archived"] = [bool]($InputObject.Archived)
                $requestBody["released"] = [bool]($InputObject.Released)
                $requestBody["releaseDate"] = $InputObject.ReleaseDate.ToString('yyyy-MM-dd')
                $requestBody["startDate"] = $InputObject.StartDate.ToString('yyyy-MM-dd')
                if ($InputObject.Project.Key) {
                    $requestBody["project"] = $InputObject.Project.Key
                }
                elseif ($InputObject.Project.Id) {
                    $requestBody["projectId"] = $InputObject.Project.Id
                }
            }
            'byParameters' {
                # Validate Project parameter
                if (-not(("JiraPS.Project" -notin $Project.PSObject.TypeNames) -or ($Project -isnot [String]))) {
                    $errorItem = [System.Management.Automation.ErrorRecord]::new(
                        ([System.ArgumentException]"Invalid Parameter"),
                        'ParameterType.NotJiraProject',
                        [System.Management.Automation.ErrorCategory]::InvalidArgument,
                        $Project
                    )
                    $errorItem.ErrorDetails = "The Project provided is invalid."
                    $PSCmdlet.ThrowTerminatingError($errorItem)
                }

                $requestBody["name"] = $Name
                if ($PSCmdlet.MyInvocation.BoundParameters.ContainsKey("Description")) {
                    $requestBody["description"] = $Description
                }
                if ($PSCmdlet.MyInvocation.BoundParameters.ContainsKey("Archived")) {
                    $requestBody["archived"] = $Archived
                }
                if ($PSCmdlet.MyInvocation.BoundParameters.ContainsKey("Released")) {
                    $requestBody["released"] = $Released
                }
                if ($PSCmdlet.MyInvocation.BoundParameters.ContainsKey("ReleaseDate")) {
                    $requestBody["releaseDate"] = Get-Date $ReleaseDate -Format 'yyyy-MM-dd'
                }
                if ($PSCmdlet.MyInvocation.BoundParameters.ContainsKey("StartDate")) {
                    $requestBody["startDate"] = Get-Date $StartDate -Format 'yyyy-MM-dd'
                }

                if ("JiraPS.Project" -in $Project.PSObject.TypeNames) {
                    if ($Project.Id) {
                        $requestBody["projectId"] = $Project.Id
                    }
                    elseif ($Project.Key) {
                        $requestBody["project"] = $Project.Key
                    }
                }
                else {
                    $requestBody["projectId"] = (Get-JiraProject $Project -Credential $Credential).Id
                }
            }
        }

        $parameter = @{
            URI        = $resourceURi
            Method     = "POST"
            Body       = ConvertTo-Json -InputObject $requestBody
            Credential = $Credential
        }
        Write-Debug "[$($MyInvocation.MyCommand.Name)] Invoking JiraMethod with `$parameter"
        if ($PSCmdlet.ShouldProcess($Name, "Creating new Version on JIRA")) {
            $result = Invoke-JiraMethod @parameter

            Write-Output (ConvertTo-JiraVersion -InputObject $result)
        }
    }

    end {
        Write-Verbose "[$($MyInvocation.MyCommand.Name)] Complete"
    }
}
