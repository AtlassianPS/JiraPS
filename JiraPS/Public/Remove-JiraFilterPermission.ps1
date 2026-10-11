function Remove-JiraFilterPermission {
    # .ExternalHelp ..\JiraPS-help.xml
    [CmdletBinding( ConfirmImpact = 'Medium', SupportsShouldProcess )]
    param(
        [Parameter( Position = 0, Mandatory, ValueFromPipeline )]
        [ValidateNotNull()]
        [Alias('FilterId', 'Id')]
        [AtlassianPS.JiraPS.FilterTransformation()]
        [AtlassianPS.JiraPS.Filter]
        $Filter,

        [Parameter( Position = 1 )]
        [ValidateNotNullOrEmpty()]
        [Alias('PermissionId')]
        [AtlassianPS.JiraPS.FilterPermissionTransformation()]
        [AtlassianPS.JiraPS.FilterPermission[]]
        $Permission,

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

        $filterObject = if ($Filter.RestUrl) {
            $Filter
        }
        else {
            Get-JiraFilter -Id $Filter.Id -Credential $Credential -ErrorAction Stop
        }

        Write-Verbose "[$($MyInvocation.MyCommand.Name)] Processing [$filterObject]"
        Write-Debug "[$($MyInvocation.MyCommand.Name)] Processing `$filterObject [$filterObject]"

        $permissions = $Permission
        if (-not $PSBoundParameters.ContainsKey('Permission')) {
            $permissions = $filterObject.FilterPermissions
        }

        if (-not $permissions) {
            ThrowError -ExceptionType 'System.ArgumentException' `
                -ErrorId 'ParameterValue.FilterWithoutPermission' `
                -Category InvalidArgument `
                -TargetObject $Filter `
                -Message 'The Filter has no permissions to remove. Supply Permission or retrieve it with Get-JiraFilterPermission first.'
        }

        foreach ($permissionToRemove in $permissions) {
            if ($null -eq $permissionToRemove -or $null -eq $permissionToRemove.Id -or $permissionToRemove.Id -lt 0) {
                ThrowError -ExceptionType 'System.ArgumentException' `
                    -ErrorId 'ParameterValue.InvalidFilterPermissionId' `
                    -Category InvalidArgument `
                    -TargetObject $permissionToRemove `
                    -Message 'Permission must contain non-negative numeric permission IDs.'
            }
        }

        foreach ($permissionToRemove in $permissions) {
            Write-Verbose "[$($MyInvocation.MyCommand.Name)] Processing permission [$($permissionToRemove.Id)]"
            Write-Debug "[$($MyInvocation.MyCommand.Name)] Processing `$permissionToRemove [$permissionToRemove]"

            $parameter = @{
                URI        = "{0}/permission/{1}" -f $filterObject.RestUrl, $permissionToRemove.Id
                Method     = 'DELETE'
                Credential = $Credential
            }

            Write-Debug "[$($MyInvocation.MyCommand.Name)] Invoking JiraMethod with `$parameter"
            if ($PSCmdlet.ShouldProcess($filterObject.Name, "Remove permission $($permissionToRemove.Id)")) {
                Invoke-JiraMethod @parameter
            }
        }
    }

    end {
        Write-Verbose "[$($MyInvocation.MyCommand.Name)] Complete"
    }
}
