function Remove-JiraFilterPermission {
    # .ExternalHelp ..\JiraPS-help.xml
    [CmdletBinding( ConfirmImpact = 'Medium', SupportsShouldProcess )]
    param(
        [Parameter(Position = 0, Mandatory, ValueFromPipeline)]
        [ValidateNotNull()]
        [Alias('FilterId', 'Id')]
        [AtlassianPS.JiraPS.FilterTransformation()]
        [AtlassianPS.JiraPS.Filter]
        $Filter,

        [Parameter(Position = 1)]
        [ValidateNotNullOrEmpty()]
        [Alias('PermissionId')]
        [AtlassianPS.JiraPS.FilterPermissionTransformation()]
        [ValidateScript({
                if ($null -eq $_.Id -or $_.Id -lt 0) { throw 'Permission must contain non-negative numeric permission IDs.' }
                return $true
            })]
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
        Write-Verbose "[$($MyInvocation.MyCommand.Name)] Processing [$Filter]"
        Write-Debug "[$($MyInvocation.MyCommand.Name)] Processing `$Filter [$Filter]"

        $filterObject = if ($Filter.RestUrl) { $Filter } else { Get-JiraFilter -Id $Filter.Id -Credential $Credential -ErrorAction Stop }
        $permissions = $Permission
        if (-not $PSBoundParameters.ContainsKey('Permission')) {
            $permissions = $filterObject.FilterPermissions
        }
        if (-not $permissions) {
            ThrowError -ExceptionType 'System.ArgumentException' -ErrorId 'ParameterValue.FilterWithoutPermission' -Category InvalidArgument -TargetObject $Filter -Message 'The Filter has no permissions to remove. Supply Permission or retrieve it with Get-JiraFilterPermission first.'
        }
        foreach ($permissionToRemove in $permissions) {
            if ($null -eq $permissionToRemove -or $null -eq $permissionToRemove.Id -or $permissionToRemove.Id -lt 0) {
                ThrowError -ExceptionType 'System.ArgumentException' -ErrorId 'ParameterValue.InvalidFilterPermissionId' -Category InvalidArgument -TargetObject $permissionToRemove -Message 'Permission must contain non-negative numeric permission IDs.'
            }
        }

        foreach ($permissionToRemove in $permissions) {
            Write-Verbose "[$($MyInvocation.MyCommand.Name)] Processing permission [$($permissionToRemove.Id)]"
            $parameter = @{
                URI        = "{0}/permission/{1}" -f $filterObject.RestUrl, $permissionToRemove.Id
                Method     = 'DELETE'
                Credential = $Credential
            }
            if ($PSCmdlet.ShouldProcess($filterObject.Name, "Remove permission $($permissionToRemove.Id)")) {
                Write-Debug "[$($MyInvocation.MyCommand.Name)] Invoking JiraMethod with `$parameter"
                Invoke-JiraMethod @parameter
            }
        }
    }

    end {
        Write-Verbose "[$($MyInvocation.MyCommand.Name)] Complete"
    }
}
