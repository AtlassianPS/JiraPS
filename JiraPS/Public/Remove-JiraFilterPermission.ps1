function Remove-JiraFilterPermission {
    # .ExternalHelp ..\JiraPS-help.xml
    [CmdletBinding( ConfirmImpact = 'Medium', SupportsShouldProcess, DefaultParameterSetName = 'Permission' )]
    param(
        [Parameter( Position = 0, Mandatory, ValueFromPipeline )]
        [ValidateNotNull()]
        [Alias('FilterId', 'Id')]
        [AtlassianPS.JiraPS.FilterTransformation()]
        [AtlassianPS.JiraPS.Filter]
        $Filter,

        [Parameter( Mandatory, Position = 1, ParameterSetName = 'Permission' )]
        [ValidateNotNullOrEmpty()]
        [Alias('PermissionId')]
        [AtlassianPS.JiraPS.FilterPermissionTransformation()]
        [AtlassianPS.JiraPS.FilterPermission[]]
        $Permission,

        [Parameter( Mandatory, ParameterSetName = 'All' )]
        [Switch]
        $All,

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

        $filterObject = if ($Filter.RestUrl) { $Filter }
        else {
            Get-JiraFilter -Id $Filter.Id -Connection $RequestContext -ErrorAction Stop
        }

        Write-Verbose "[$($MyInvocation.MyCommand.Name)] Processing [$filterObject]"
        Write-DebugMessage "Processing `$filterObject [$filterObject]"

        if ($PSCmdlet.ParameterSetName -eq 'All' -and -not $All) { throw 'Supply -All to remove every filter permission.' }
        $permissions = if ($PSCmdlet.ParameterSetName -eq 'Permission') { $Permission }
        else {
            $permissionResponse = Invoke-JiraRequest -RequestContext $RequestContext -Uri "$($filterObject.RestUrl)/permission" -Method Get -ErrorAction Stop
            @(ConvertTo-JiraFilterPermission -InputObject $permissionResponse)
        }

        if (-not $permissions) {
            ThrowError -ExceptionType 'System.ArgumentException' `
                -ErrorId 'ParameterValue.FilterWithoutPermission' `
                -Category InvalidArgument `
                -TargetObject $Filter `
                -Message 'The filter has no permissions to remove.'
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
            Write-DebugMessage "Processing `$permissionToRemove [$permissionToRemove]"

            $parameter = @{
                URI    = "{0}/permission/{1}" -f $filterObject.RestUrl, $permissionToRemove.Id
                Method = 'DELETE'
            }

            Write-DebugMessage "Invoking JiraMethod with `$parameter"
            if ($PSCmdlet.ShouldProcess($filterObject.Name, "Remove permission $($permissionToRemove.Id)")) { Invoke-JiraRequest -RequestContext $RequestContext @parameter }
        }
    }

    end {
        Write-Verbose "[$($MyInvocation.MyCommand.Name)] Complete"
    }
}
