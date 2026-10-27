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
        $Credential,

        [Alias('Session')]
        [AtlassianPS.Connection]
        $Connection,

        [Alias('Server', 'ServerName')]
        [ArgumentCompleter( {
                param($commandName, $parameterName, $wordToComplete)
                AtlassianPS.Configuration\Get-AtlassianConnection -Product Jira |
                    Where-Object { $_.Name -like "$wordToComplete*" } |
                    ForEach-Object { $_.Name }
            }
        )]
        [String]
        $ConnectionName,

        [Uri]
        $Uri,

        [Alias('Email')]
        [String]
        $EmailAddress,

        [Object]
        $ApiToken,

        [Alias('PAT', 'BearerToken')]
        [Object]
        $PersonalAccessToken,

        [Switch]
        $Anonymous
    )

    begin {
        try {
            Write-Verbose "[$($MyInvocation.MyCommand.Name)] Function started"

            $RequestContext = Resolve-JiraOperationContext -BoundParameters $PSBoundParameters
        }
        catch {
            if ($RequestContext -and $RequestContext.State -eq 'Standalone') { $RequestContext.Dispose() }
            throw
        }
    }

    process {
        try {
            Write-DebugMessage "[$($MyInvocation.MyCommand.Name)] ParameterSetName: $($PsCmdlet.ParameterSetName)"

            $filterObject = if ($Filter.RestUrl) { $Filter }
            else {
                Get-JiraFilterOperation -Id $Filter.Id -RequestContext $RequestContext -ErrorAction Stop
            }

            Write-Verbose "[$($MyInvocation.MyCommand.Name)] Processing [$filterObject]"
            Write-Debug "[$($MyInvocation.MyCommand.Name)] Processing `$filterObject [$filterObject]"

            $permissions = if ($PSBoundParameters.ContainsKey('Permission')) { $Permission }
            else { $filterObject.FilterPermissions }

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
                    URI    = "{0}/permission/{1}" -f $filterObject.RestUrl, $permissionToRemove.Id
                    Method = 'DELETE'
                }

                Write-Debug "[$($MyInvocation.MyCommand.Name)] Invoking JiraMethod with `$parameter"
                if ($PSCmdlet.ShouldProcess($filterObject.Name, "Remove permission $($permissionToRemove.Id)")) { Invoke-JiraMethod -RequestContext $RequestContext @parameter }
            }
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
