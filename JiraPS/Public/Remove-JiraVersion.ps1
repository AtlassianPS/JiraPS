function Remove-JiraVersion {
    # .ExternalHelp ..\JiraPS-help.xml
    [CmdletBinding( ConfirmImpact = 'High', SupportsShouldProcess )]
    param(
        [Parameter( Mandatory, ValueFromPipeline )]
        [ValidateNotNull()]
        [AtlassianPS.JiraPS.VersionTransformation()]
        [AtlassianPS.JiraPS.Version[]]
        $Version,

        [Parameter()]
        [System.Management.Automation.PSCredential]
        [System.Management.Automation.Credential()]
        $Credential,

        [Switch]
        $Force,

        [Alias('Session')]
        [AtlassianPS.Connection]
        $Connection
    )

    begin {
        Write-Verbose "[$($MyInvocation.MyCommand.Name)] Function started"

        try {
            $RequestContext = Resolve-JiraOperationContext -BoundParameters $PSBoundParameters

            if ($Force) {
                Write-DebugMessage "[Remove-JiraVersion] -Force was passed. Backing up current ConfirmPreference [$ConfirmPreference] and setting to None"
                $oldConfirmPreference = $ConfirmPreference
                $ConfirmPreference = 'None'
            }
        }
        catch {
            if ($RequestContext -and $RequestContext.State -eq 'Standalone') { $RequestContext.Dispose() }
            throw
        }
    }

    process {
        try {
            Write-DebugMessage "ParameterSetName: $($PsCmdlet.ParameterSetName)"
            Write-DebugMessage -BoundParameters $PSBoundParameters

            foreach ($_version in $Version) {
                Write-Verbose "[$($MyInvocation.MyCommand.Name)] Processing [$_version]"
                Write-DebugMessage "Processing `$_version [$_version]"

                if (-not $_version.Id) {
                    $errorItem = [System.Management.Automation.ErrorRecord]::new(
                        ([System.ArgumentException]"Version ID is required"),
                        'ParameterValue.VersionIdRequired',
                        [System.Management.Automation.ErrorCategory]::InvalidArgument,
                        $_version
                    )

                    $errorItem.ErrorDetails = "Remove-JiraVersion requires a version ID. Provide a numeric version ID or an AtlassianPS.JiraPS.Version object with an ID."
                    ThrowError -ErrorRecord $errorItem
                }

                $versionObj = Get-JiraVersionOperation -Id $_version.Id -RequestContext $RequestContext -ErrorAction Stop

                $parameter = @{
                    URI    = $versionObj.RestUrl
                    Method = "DELETE"
                }
                Write-DebugMessage "Invoking JiraMethod with `$parameter"
                if ($PSCmdlet.ShouldProcess($versionObj.Name, "Removing Version")) { Invoke-JiraRequest -RequestContext $RequestContext @parameter }
            }
        }
        catch {
            if ($RequestContext -and $RequestContext.State -eq 'Standalone') { $RequestContext.Dispose() }
            throw
        }
    }

    end {
        try {
            if ($Force) {
                Write-DebugMessage "[Remove-JiraVersion] Restoring ConfirmPreference to [$oldConfirmPreference]"
                $ConfirmPreference = $oldConfirmPreference
            }

            Write-Verbose "[$($MyInvocation.MyCommand.Name)] Complete"
        }
        finally {
            if ($RequestContext.State -eq 'Standalone') { $RequestContext.Dispose() }
        }
    }
}
