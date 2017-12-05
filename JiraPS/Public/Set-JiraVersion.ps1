function Set-JiraVersion {
    <#
    .Synopsis
        Modifies an existing Version in JIRA
    .DESCRIPTION
        This function modifies the Version for an existing Project in JIRA.
    .EXAMPLE
        Get-JiraVersion -Project $Project -Name "Old-Name" | Set-JiraVersion -Name 'New-Name'
        This example assigns the modifies the existing version with a new name 'New-Name'.
    .EXAMPLE
        Get-JiraVersion -ID 162401 | Set-JiraVersion -Description 'Descriptive String'
        This example assigns the modifies the existing version with a new name 'New-Name'.
     .INPUTS
        [JiraPS.Version]
     .OUTPUTS
        [JiraPS.Version]
     .NOTES
       This function requires either the -Credential parameter to be passed or a persistent JIRA session. See New-JiraSession for more details.  If neither are supplied, this function will run with anonymous access to JIRA.
    #>
    [CmdletBinding( SupportsShouldProcess )]
    param(
        # Version to be changed
        [Parameter( Mandatory, ValueFromPipeline )]
        [Object[]] $Version,

        # New Name of the Version.
        [String] $Name,

        # New Description of the Version.
        [String] $Description,

        # New value for Archived.
        [Bool] $Archived,

        # New value for Released.
        [Bool] $Released,

        # New Date of the release.
        [DateTime] $ReleaseDate,

        # New Date of the user release.
        [DateTime] $StartDate,

        # The new Project where this version should be in.
        # This can be the ID of the Project, or the Project Object
        [Object] $Project,

        # Credentials to use to connect to JIRA.
        # If not specified, this function will use anonymous access.
        [PSCredential] $Credential
    )

    begin {
        Write-Verbose "[$($MyInvocation.MyCommand.Name)] Function started"

        $server = Get-JiraConfigServer -ConfigFile $ConfigFile -ErrorAction Stop
    }

    process {
        Write-DebugMessage "[$($MyInvocation.MyCommand.Name)] ParameterSetName: $($PsCmdlet.ParameterSetName)"
        Write-DebugMessage "[$($MyInvocation.MyCommand.Name)] PSBoundParameters: $($PSBoundParameters | Out-String)"

        foreach ($_version in $Version) {
            Write-Verbose "[$($MyInvocation.MyCommand.Name)] Processing [$_version]"
            Write-Debug "[$($MyInvocation.MyCommand.Name)] Processing `$_version [$_version]"

            $versionObj = Get-JiraUser -InputObject $_version -Credential $Credential -ErrorAction Stop

            $requestBody = @{}

            if ($PSCmdlet.MyInvocation.BoundParameters.ContainsKey("Name")) {
                $requestBody["name"] = $Name
            }
            if ($PSCmdlet.MyInvocation.BoundParameters.ContainsKey("Description")) {
                $requestBody["description"] = $Description
            }
            if ($PSCmdlet.MyInvocation.BoundParameters.ContainsKey("Archived")) {
                $requestBody["archived"] = $Archived
            }
            if ($PSCmdlet.MyInvocation.BoundParameters.ContainsKey("Released")) {
                $requestBody["released"] = $Released
            }
            if ($PSCmdlet.MyInvocation.BoundParameters.ContainsKey("Project")) {
                $projectObj = Get-JiraProject -Project $Project -Credential $Credential -ErrorAction Stop

                $requestBody["projectId"] = $Project.Id
            }
            if ($PSCmdlet.MyInvocation.BoundParameters.ContainsKey("ReleaseDate")) {
                $requestBody["releaseDate"] = $ReleaseDate.ToString('yyyy-MM-dd')
            }
            if ($PSCmdlet.MyInvocation.BoundParameters.ContainsKey("StartDate")) {
                $requestBody["startDate"] = $StartDate.ToString('yyyy-MM-dd')
            }

            Write-Debug -Message '[Set-JiraVersion] Converting to JSON'
            $json = ConvertTo-Json -InputObject $requestBody

            $parameter = @{
                URI        = $versionObj.RestUrl
                Method     = "PUT"
                Body       = ConvertTo-Json -InputObject $requestBody
                Credential = $Credential
            }
            Write-Debug "[$($MyInvocation.MyCommand.Name)] Invoking JiraMethod with `$parameter"
            if ($PSCmdlet.ShouldProcess($Name, "Updating Version on JIRA")) {
                $result = Invoke-JiraMethod @parameter

                Write-Output (Get-JiraVersion -InputObject $result)
            }
        }
    }

    end {
        Write-Verbose "[$($MyInvocation.MyCommand.Name)] Complete"
    }
}
