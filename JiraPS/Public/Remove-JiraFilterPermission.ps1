function Remove-JiraFilterPermission {
    # .ExternalHelp ..\JiraPS-help.xml
    [CmdletBinding( SupportsShouldProcess, DefaultParameterSetName = 'ByFilterId' )]
    param(
        [Parameter( Position = 0, Mandatory, ValueFromPipeline, ParameterSetName = 'ByFilterObject' )]
        [ValidateNotNullOrEmpty()]
        [ValidateScript(
            {
                if (@($Filter).Count -gt 1) {
                    $exception = ([System.ArgumentException]"Invalid Parameter")
                    $errorId = 'ParameterType.TooManyFilters'
                    $errorCategory = 'InvalidArgument'
                    $errorTarget = $_
                    $errorItem = New-Object -TypeName System.Management.Automation.ErrorRecord $exception, $errorId, $errorCategory, $errorTarget
                    $errorItem.ErrorDetails = "Only one Filter can be passed at a time."
                    $PSCmdlet.ThrowTerminatingError($errorItem)
                }
                elseif (@($_.FilterPermissions).Count -lt 1) {
                    $exception = ([System.ArgumentException]"Invalid Type for Parameter")
                    $errorId = 'ParameterType.FilterWithoutPermission'
                    $errorCategory = 'InvalidArgument'
                    $errorTarget = $_
                    $errorItem = New-Object -TypeName System.Management.Automation.ErrorRecord $exception, $errorId, $errorCategory, $errorTarget
                    $errorItem.ErrorDetails = "The Filter provided does not contain any Permission to delete."
                    $PSCmdlet.ThrowTerminatingError($errorItem)
                }
                else {
                    return $true
                }
            }
        )]
        [PSTypeName('JiraPS.Filter')]
        $Filter,

        [Parameter( Position = 0, Mandatory, ParameterSetName = 'ByFilterId' )]
        [ValidateNotNullOrEmpty()]
        [Alias('Id')]
        [UInt32]
        $FilterId,

        # TODO: [Parameter( Position = 1, ParameterSetName = 'ByFilterObject')]
        [Parameter( Position = 1, Mandatory, ParameterSetName = 'ByFilterId')]
        [ValidateNotNullOrEmpty()]
        [UInt32[]]
        $PermissionId,

        [Parameter()]
        [System.Management.Automation.PSCredential]
        [System.Management.Automation.Credential()]
        $Credential = [System.Management.Automation.PSCredential]::Empty
    )

    begin {
        Write-Verbose "[$($MyInvocation.MyCommand.Name)] Function started"
    }

    process {
        Write-DebugMessage "[$($MyInvocation.MyCommand.Name)] ParameterSetName: $($PsCmdlet.ParameterSetName)"
        Write-DebugMessage "[$($MyInvocation.MyCommand.Name)] PSBoundParameters: $($PSBoundParameters | Out-String)"

        switch ($PSCmdlet.ParameterSetName) {
            "ByFilterObject" {
                $PermissionId = $Filter.FilterPermissions.Id
            }
            "ByFilterId" {
                $Filter = Get-JiraFilter -Id $FilterId
            }
        }

        foreach ($_permissionId in $PermissionId) {
            $parameter = @{
                URI        = "{0}/permission/{1}" -f $Filter.RestURL, $_permissionId
                Method     = "DELETE"
                Credential = $Credential
            }
            Write-Debug "[$($MyInvocation.MyCommand.Name)] Invoking JiraMethod with `$parameter"
            if ($PSCmdlet.ShouldProcess($InputObject.Type, "Remove Permission")) {
                Invoke-JiraMethod @parameter
            }
        }
    }

    end {
        Write-Verbose "[$($MyInvocation.MyCommand.Name)] Complete"
    }
}
