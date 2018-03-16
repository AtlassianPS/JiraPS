function Remove-JiraVersion {
    <#
    .SYNOPSIS
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
    [CmdletBinding( ConfirmImpact = 'High', SupportsShouldProcess )]
    param(
        # Version Object or ID to delete.
        [Parameter( Mandatory, ValueFromPipeline )]
        [ValidateNotNullOrEmpty()]
        [ValidateScript(
            {
                if (("JiraPS.Version" -notin $_.PSObject.TypeNames) -and (($_ -isnot [Int]))) {
                    $errorItem = [System.Management.Automation.ErrorRecord]::new(
                        ([System.ArgumentException]"Invalid Type for Parameter"),
                        'ParameterType.NotJiraVersion',
                        [System.Management.Automation.ErrorCategory]::InvalidArgument,
                        $_
                    )
                    $errorItem.ErrorDetails = "Wrong object type provided for Version. Expected [JiraPS.Version] or [Int], but was $($_.GetType().Name)"
                    $PSCmdlet.ThrowTerminatingError($errorItem)
                    <#
                      #ToDo:CustomClass
                      Once we have custom classes, this check can be done with Type declaration
                    #>
                }
                else {
                    return $true
                }
            }
        )]
        [Object[]]
        $Version,

        # Credentials to use to connect to JIRA.
        # If not specified, this function will use anonymous access.
        [PSCredential]
        $Credential,

        # Suppress user confirmation.
        [Switch]
        $Force
    )

    begin {
        Write-Verbose "[$($MyInvocation.MyCommand.Name)] Function started"

        if ($Force) {
            Write-DebugMessage "[Remove-JiraVersion] -Force was passed. Backing up current ConfirmPreference [$ConfirmPreference] and setting to None"
            $oldConfirmPreference = $ConfirmPreference
            $ConfirmPreference = 'None'
        }
    }

    process {
        Write-DebugMessage "[$($MyInvocation.MyCommand.Name)] ParameterSetName: $($PsCmdlet.ParameterSetName)"
        Write-DebugMessage "[$($MyInvocation.MyCommand.Name)] PSBoundParameters: $($PSBoundParameters | Out-String)"

        foreach ($_version in $Version) {
            Write-Verbose "[$($MyInvocation.MyCommand.Name)] Processing [$_version]"
            Write-Debug "[$($MyInvocation.MyCommand.Name)] Processing `$_version [$_version]"

            if ($_version.id) {
                $_version = $_version.Id
            }

            $versionObj = Get-JiraVersion -Id $_version -Credential $Credential -ErrorAction Stop

            $parameter = @{
                URI        = $versionObj.RestUrl
                Method     = "DELETE"
                Credential = $Credential
            }
            Write-Debug "[$($MyInvocation.MyCommand.Name)] Invoking JiraMethod with `$parameter"
            if ($PSCmdlet.ShouldProcess($versionObj.Name, "Removing Version")) {
                Invoke-JiraMethod @parameter
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
