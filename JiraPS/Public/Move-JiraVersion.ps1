function Move-JiraVersion {
    # .ExternalHelp ..\JiraPS-help.xml
    [CmdletBinding( DefaultParameterSetName = 'ByAfter' )]
    param(
        [Parameter( Mandatory, ValueFromPipeline )]
        [ValidateNotNull()]
        [AtlassianPS.JiraPS.VersionTransformation()]
        [AtlassianPS.JiraPS.Version]
        $Version,

        [Parameter( Mandatory, ParameterSetName = 'ByPosition' )]
        [ValidateSet('First', 'Last', 'Earlier', 'Later')]
        [String]
        $Position,

        [Parameter( Mandatory, ParameterSetName = 'ByAfter' )]
        [ValidateNotNull()]
        [AtlassianPS.JiraPS.VersionTransformation()]
        [AtlassianPS.JiraPS.Version]
        $After,

        [Parameter()]
        [System.Management.Automation.PSCredential]
        [System.Management.Automation.Credential()]
        $Credential,

        [Alias('Session')]
        [AtlassianPS.Connection]
        $Connection
    )

    begin {
        try {
            Write-Verbose "[$($MyInvocation.MyCommand.Name)] Function started"

            $RequestContext = Resolve-JiraOperationContext -BoundParameters $PSBoundParameters

            $versionResourceUri = "/rest/api/2/version/{0}/move"
        }
        catch {
            if ($RequestContext -and $RequestContext.State -eq 'Standalone') { $RequestContext.Dispose() }
            throw
        }
    }

    process {
        try {
            Write-DebugMessage "[$($MyInvocation.MyCommand.Name)] ParameterSetName: $($PsCmdlet.ParameterSetName)"

            if (-not $Version.Id) {
                $errorItem = [System.Management.Automation.ErrorRecord]::new(
                    ([System.ArgumentException]"Version ID is required"),
                    'ParameterValue.VersionIdRequired',
                    [System.Management.Automation.ErrorCategory]::InvalidArgument,
                    $Version
                )

                $errorItem.ErrorDetails = "Move-JiraVersion requires a version ID for -Version. Provide a numeric version ID or an AtlassianPS.JiraPS.Version object with an ID."
                ThrowError -ErrorRecord $errorItem
            }

            $requestBody = @{ }
            switch ($PsCmdlet.ParameterSetName) {
                'ByPosition' { $requestBody["position"] = $Position }
                'ByAfter' {
                    if ($After.RestUrl) { $afterSelfUri = $After.RestUrl }
                    else {
                        if (-not $After.Id) {
                            $errorItem = [System.Management.Automation.ErrorRecord]::new(
                                ([System.ArgumentException]"Version ID is required"),
                                'ParameterValue.VersionIdRequired',
                                [System.Management.Automation.ErrorCategory]::InvalidArgument,
                                $After
                            )

                            $errorItem.ErrorDetails = "Move-JiraVersion requires a version ID or RestUrl for -After. Provide a numeric version ID or an AtlassianPS.JiraPS.Version object with an ID or RestUrl."
                            ThrowError -ErrorRecord $errorItem
                        }
                        $versionObj = Get-JiraVersionOperation -Id $After.Id -RequestContext $RequestContext -ErrorAction Stop
                        $afterSelfUri = $versionObj.RestUrl
                    }

                    $requestBody["after"] = $afterSelfUri
                }
            }

            $parameter = @{
                URI    = $versionResourceUri -f $Version.Id
                Method = "POST"
                Body   = ConvertTo-Json $requestBody
            }

            Write-Debug "[$($MyInvocation.MyCommand.Name)] Invoking JiraMethod with `$parameter"
            Invoke-JiraMethod -RequestContext $RequestContext @parameter
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
