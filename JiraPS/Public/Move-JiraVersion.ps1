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
        [String]$Position,

        [Parameter( Mandatory, ParameterSetName = 'ByAfter' )]
        [ValidateNotNull()]
        [AtlassianPS.JiraPS.VersionTransformation()]
        [AtlassianPS.JiraPS.Version]
        $After,

        [Parameter()]
        [System.Management.Automation.PSCredential]
        [System.Management.Automation.Credential()]
        $Credential = [System.Management.Automation.PSCredential]::Empty
    )

    begin {
        Write-Verbose "[$($MyInvocation.MyCommand.Name)] Function started"

        $versionResourceUri = "/rest/api/2/version/{0}/move"
    }

    process {
        Write-DebugMessage "[$($MyInvocation.MyCommand.Name)] ParameterSetName: $($PsCmdlet.ParameterSetName)"
        Write-DebugMessage "[$($MyInvocation.MyCommand.Name)] PSBoundParameters: $($PSBoundParameters | Out-String)"

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
            'ByPosition' {
                $requestBody["position"] = $Position
            }
            'ByAfter' {
                if ($After.RestUrl) {
                    $afterSelfUri = $After.RestUrl
                }
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
                    $versionObj = Get-JiraVersion -Id $After.Id -Credential $Credential -ErrorAction Stop
                    $afterSelfUri = $versionObj.RestUrl
                }

                $requestBody["after"] = $afterSelfUri
            }
        }

        $parameter = @{
            URI        = $versionResourceUri -f $Version.Id
            Method     = "POST"
            Body       = ConvertTo-Json $requestBody
            Credential = $Credential
        }

        Write-Debug "[$($MyInvocation.MyCommand.Name)] Invoking JiraMethod with `$parameter"
        Invoke-JiraMethod @parameter
    }

    end {
        Write-Verbose "[$($MyInvocation.MyCommand.Name)] Complete"
    }
}
