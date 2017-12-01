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
    [CmdletBinding(
        SupportsShouldProcess = $true,
        DefaultParameterSetName = 'byObject'
    )]
    param(
        # Version object that should be created on the server.
        [Parameter(
            Position = 0,
            Mandatory = $true,
            ValueFromPipeline = $true,
            ParameterSetName = 'byObject'
        )]
        [Object] $InputObject,

        # Name of the version to create.
        [Parameter(
            Position = 0,
            Mandatory = $true,
            ParameterSetName = 'byParameters'
        )]
        [String] $Name,

        # Description of the version.
        [Parameter(
            Mandatory = $false,
            ParameterSetName = 'byParameters'
        )]
        [String] $Description,

        # Create the version as archived.
        [Parameter(
            Mandatory = $false,
            ParameterSetName = 'byParameters'
        )]
        [Bool] $Archived,

        # Create the version as released.
        [Parameter(
            Mandatory = $false,
            ParameterSetName = 'byParameters'
        )]
        [Bool] $Released,

        # Date of the release.
        [Parameter(
            Mandatory = $false,
            ParameterSetName = 'byParameters'
        )]
        [DateTime] $ReleaseDate,

        # Date of the release.
        [Parameter(
            Mandatory = $false,
            ParameterSetName = 'byParameters'
        )]
        [DateTime] $StartDate,

        # The Project ID
        [Parameter(
            Mandatory = $true,
            ParameterSetName = 'byParameters'
        )]
        [Object] $Project,

        # Credentials to use to connect to JIRA.
        # If not specified, this function will use anonymous access.
        [PSCredential] $Credential
    )

    begin {
        Write-Verbose "[$($MyInvocation.MyCommand.Name)] Function started"

        $server = Get-JiraConfigServer -ConfigFile $ConfigFile -ErrorAction Stop

        $restUrl = "$server/rest/api/latest/version"
    }

    process {
        Write-DebugMessage "[$($MyInvocation.MyCommand.Name)] ParameterSetName: $($PsCmdlet.ParameterSetName)"
        Write-DebugMessage "[$($MyInvocation.MyCommand.Name)] PSBoundParameters: $($PSBoundParameters | Out-String)"

        $iwrSplat = @{}
        Switch ($PSCmdlet.ParameterSetName) {
            'byObject' {
                # Validate InputObject type
                if ($InputObject.PSObject.TypeNames[0] -ne "JiraPS.Version") {
                    $message = "Wrong object type provided for Version. Only JiraPS.Version is accepted"
                    $exception = New-Object -TypeName System.ArgumentException -ArgumentList $message
                    Throw $exception
                }

                # Validate mandatory properties
                if (-not ($InputObject.Project -and $InputObject.Name)) {
                    $message = "The Version provided does not contain all necessary information. Mandatory properties: 'Project', 'Name'"
                    $exception = New-Object -TypeName System.ArgumentException -ArgumentList $message
                    Throw $exception
                }

                $iwrSplat["name"] = $InputObject.Name
                $iwrSplat["description"] = $InputObject.Description
                $iwrSplat["archived"] = [bool]($InputObject.Archived)
                $iwrSplat["released"] = [bool]($InputObject.Released)
                $iwrSplat["releaseDate"] = $InputObject.ReleaseDate.ToString('yyyy-MM-dd')
                $iwrSplat["startDate"] = $InputObject.StartDate.ToString('yyyy-MM-dd')
                if ($InputObject.Project.Key) {
                    $iwrSplat["project"] = $InputObject.Project.Key
                }
                elseif ($InputObject.Project.Id) {
                    $iwrSplat["projectId"] = $InputObject.Project.Id
                }
            }
            'byParameters' {
                # Validate Project parameter
                if (-not(($Project.PSObject.TypeNames[0] -ne "JiraPS.Project") -or ($Project -isnot [String]))) {
                    $message = "The Project provided is invalid."
                    $exception = New-Object -TypeName System.ArgumentException -ArgumentList $message
                    Throw $exception
                }

                Write-Debug -Message '[New-JiraVersion] Defining properties'
                $iwrSplat["name"] = $Name
                if ($PSCmdlet.MyInvocation.BoundParameters.ContainsKey("Description")) {
                    $iwrSplat["description"] = $Description
                }
                if ($PSCmdlet.MyInvocation.BoundParameters.ContainsKey("Archived")) {
                    $iwrSplat["archived"] = $Archived
                }
                if ($PSCmdlet.MyInvocation.BoundParameters.ContainsKey("Released")) {
                    $iwrSplat["released"] = $Released
                }
                if ($PSCmdlet.MyInvocation.BoundParameters.ContainsKey("ReleaseDate")) {
                    $iwrSplat["releaseDate"] = Get-Date $ReleaseDate -Format 'yyyy-MM-dd'
                }
                if ($PSCmdlet.MyInvocation.BoundParameters.ContainsKey("StartDate")) {
                    $iwrSplat["startDate"] = Get-Date $StartDate -Format 'yyyy-MM-dd'
                }

                if ($Project.PSObject.TypeNames[0] -eq "JiraPS.Project") {
                    if ($Project.Id) {
                        $iwrSplat["projectId"] = $Project.Id
                    }
                    elseif ($Project.Key) {
                        $iwrSplat["project"] = $Project.Key
                    }
                }
                else {
                    $iwrSplat["projectId"] = (Get-JiraProject $Project -Credential $Credential).Id
                }
            }
        }

        Write-Debug -Message '[New-JiraVersion] Converting to JSON'
        $json = ConvertTo-Json -InputObject $iwrSplat

        if ($PSCmdlet.ShouldProcess($Name, "Creating new Version on JIRA")) {
            Write-Debug "[$($MyInvocation.MyCommand.Name)] Invoking JiraMethod with `$parameter"
            $result = Invoke-JiraMethod -Method Post -URI $restUrl -Body $json -Credential $Credential
        }

        if ($result) {
            $result | ConvertTo-JiraVersion -Credential $Credential
        }
        else {
            Write-Debug -Message '[New-JiraVersion] Jira returned no results to output.'
        }
    }

    end {
        Write-Verbose "[$($MyInvocation.MyCommand.Name)] Complete"
    }
}
