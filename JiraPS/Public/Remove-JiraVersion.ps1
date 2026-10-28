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
        [AtlassianPS.Connection]
        $Connection
    )

    begin {
        Write-Verbose "[$($MyInvocation.MyCommand.Name)] Function started"

        $RequestContext = Resolve-JiraOperationContext -BoundParameters $PSBoundParameters
    }

    process {
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

            $versionObj = Get-JiraVersion -Id $_version.Id -Connection $RequestContext -ErrorAction Stop

            $parameter = @{
                URI    = $versionObj.RestUrl
                Method = "DELETE"
            }
            Write-DebugMessage "Invoking JiraMethod with `$parameter"
            if ($PSCmdlet.ShouldProcess($versionObj.Name, "Removing Version")) { Invoke-JiraRequest -RequestContext $RequestContext @parameter }
        }
    }

    end {
        Write-Verbose "[$($MyInvocation.MyCommand.Name)] Complete"
    }
}
