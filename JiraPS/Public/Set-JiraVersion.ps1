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
    [CmdletBinding(SupportsShouldProcess = $true)]
    param(
        # Version to be changed
        [Parameter(
            Position = 0,
            Mandatory = $true,
            ValueFromPipeline = $true
        )]
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

        Write-Debug "[Set-JiraVersion] Completed Begin block."
    }

    process {
        Write-DebugMessage "[$($MyInvocation.MyCommand.Name)] ParameterSetName: $($PsCmdlet.ParameterSetName)"
        Write-DebugMessage "[$($MyInvocation.MyCommand.Name)] PSBoundParameters: $($PSBoundParameters | Out-String)"

        foreach ($_version in $Version) {
            try {
                # Validate InputObject type
                if ($_version.PSObject.TypeNames[0] -ne "JiraPS.Version") {
                    Write-Error "Wrong object type provided for Version. Only JiraPS.Version is accepted"
                }

                $id = [Int]($_version.Id)
                $restUrl = "$server/rest/api/latest/version/$id"

                $props = @{}
                if ($PSCmdlet.MyInvocation.BoundParameters.ContainsKey("Name")) {
                    $props["name"] = $Name
                }
                if ($PSCmdlet.MyInvocation.BoundParameters.ContainsKey("Description")) {
                    $props["description"] = $Description
                }
                if ($PSCmdlet.MyInvocation.BoundParameters.ContainsKey("Archived")) {
                    $props["archived"] = $Archived
                }
                if ($PSCmdlet.MyInvocation.BoundParameters.ContainsKey("Released")) {
                    $props["released"] = $Released
                }
                if ($PSCmdlet.MyInvocation.BoundParameters.ContainsKey("Project")) {
                    if ($Project.PSObject.TypeNames[0] -eq "JiraPS.Project") {
                        if ($Project.Id) {
                            $props["projectId"] = $Project.Id
                        }
                        elseif ($Project.Key) {
                            $props["project"] = $Project.Key
                        }
                    }
                    else {
                        $props["projectId"] = (Get-JiraProject $Project -Credential $Credential).Id
                    }
                }
                if ($PSCmdlet.MyInvocation.BoundParameters.ContainsKey("ReleaseDate")) {
                    $props["releaseDate"] = $ReleaseDate.ToString('yyyy-MM-dd')
                }
                if ($PSCmdlet.MyInvocation.BoundParameters.ContainsKey("StartDate")) {
                    $props["startDate"] = $StartDate.ToString('yyyy-MM-dd')
                }

                Write-Debug -Message '[Set-JiraVersion] Converting to JSON'
                $json = ConvertTo-Json -InputObject $props

                if ($PSCmdlet.ShouldProcess($Name, "Updating Version on JIRA")) {
                    Write-Debug "[$($MyInvocation.MyCommand.Name)] Invoking JiraMethod with `$parameter"
                    Invoke-JiraMethod -Method Put -URI $restUrl -Body $json -Credential $Credential | ConvertTo-JiraVersion -Credential $Credential
                }
            }
            catch {
                Write-Error "Id of the Version was not available or could not be converted to Integer. Value was $($_version.Id)"
            }
        }
    }

    end {
        Write-Verbose "[$($MyInvocation.MyCommand.Name)] Complete"
    }
}
