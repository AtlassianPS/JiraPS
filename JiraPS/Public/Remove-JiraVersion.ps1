function Remove-JiraVersion {
    <#
    .Synopsis
       This function removes an existing version.
    .DESCRIPTION
       This function removes an existing version in JIRA.
    .EXAMPLE
       Get-JiraVersion -Name '1.0.0.0' -Project $Project | Remove-JiraVersion
       This example removes the Version given.
    .EXAMPLE
       Remove-JiraVersion -Version '66596'
       This example removes the Version given.
     .INPUTS
        [JiraPS.Version]
    .OUTPUTS
       This Function outputs no results
    .LINK
        New-JiraVersion
    .LINK
        Get-JiraVersion
    .LINK
        Set-JiraVersion
    .NOTES
       This function requires either the -Credential parameter to be passed or a persistent JIRA session. See New-JiraSession for more details.  If neither are supplied, this function will run with anonymous access to JIRA.
    #>
    [CmdletBinding(
        ConfirmImpact = 'High',
        SupportsShouldProcess = $true
    )]
    param(
        # Version Object or ID to delete.
        [Parameter(
            Position = 0,
            Mandatory = $true,
            ValueFromPipeline = $true
        )]
        [Object[]] $Version,

        # Credentials to use to connect to JIRA.
        # If not specified, this function will use anonymous access.
        [PSCredential] $Credential,

        # Suppress user confirmation.
        [Switch] $Force
    )

    begin {
        Write-Verbose "[$($MyInvocation.MyCommand.Name)] Function started"

        $server = Get-JiraConfigServer -ConfigFile $ConfigFile -ErrorAction Stop

        if ($Force) {
            Write-Debug "[Remove-JiraVersion] -Force was passed. Backing up current ConfirmPreference [$ConfirmPreference] and setting to None"
            $oldConfirmPreference = $ConfirmPreference
            $ConfirmPreference = 'None'
        }
    }

    process {
        Write-DebugMessage "[$($MyInvocation.MyCommand.Name)] ParameterSetName: $($PsCmdlet.ParameterSetName)"
        Write-DebugMessage "[$($MyInvocation.MyCommand.Name)] PSBoundParameters: $($PSBoundParameters | Out-String)"

        foreach ($_version in $Version) {
            Write-Debug "[Remove-JiraVersion] Obtaining reference to Version [$_version]"
            if ($_version.PSObject.TypeNames[0] -eq "JiraPS.Version") {
                $versionObject = Get-JiraVersion -Id $_version.Id -Credential $Credential
            }
            elseif ($_version -is [Int]) {
                $versionObject = Get-JiraVersion -Id $_version -Credential $Credential
            }
            else {
                $message = "Invalid Version provided."
                $exception = New-Object -TypeName System.ArgumentException -ArgumentList $message
                Throw $exception
            }

            if ($versionObject) {
                $restUrl = "$server/rest/api/latest/version/$($versionObject.Id)"

                if ($PSCmdlet.ShouldProcess($versionObject.Name, "Removing Version on JIRA")) {
                    Write-Debug "[$($MyInvocation.MyCommand.Name)] Invoking JiraMethod with `$parameter"
                    Invoke-JiraMethod -Method Delete -URI $restUrl -Credential $Credential
                }
            }
            else {
                throw "no versionoBjects"
            }
        }
    }

    end {
        if ($Force) {
            Write-Debug "[Remove-JiraVersion] Restoring ConfirmPreference to [$oldConfirmPreference]"
            $ConfirmPreference = $oldConfirmPreference
        }

        Write-Verbose "[$($MyInvocation.MyCommand.Name)] Complete"
    }
}
