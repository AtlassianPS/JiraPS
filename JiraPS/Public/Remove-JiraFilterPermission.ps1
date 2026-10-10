function Remove-JiraFilterPermission {
    # .ExternalHelp ..\JiraPS-help.xml
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Position = 0, Mandatory, ValueFromPipeline)]
        [ValidateNotNull()]
        [Alias('FilterId', 'Id')]
        [AtlassianPS.JiraPS.FilterTransformation()]
        [AtlassianPS.JiraPS.Filter]
        $Filter,

        [Parameter(Position = 1)]
        [ValidateNotNullOrEmpty()]
        [AtlassianPS.JiraPS.FilterPermissionTransformation()]
        [ValidateScript({
                if ($null -eq $_.Id -or $_.Id -le 0) { throw 'PermissionId must contain positive numeric permission IDs.' }
                return $true
            })]
        [AtlassianPS.JiraPS.FilterPermission[]]
        $PermissionId,

        [Parameter()]
        [System.Management.Automation.PSCredential]
        [System.Management.Automation.Credential()]
        $Credential = [System.Management.Automation.PSCredential]::Empty
    )

    process {
        $filterObject = if ($Filter.RestUrl) { $Filter } else { Get-JiraFilter -Id $Filter.Id -Credential $Credential -ErrorAction Stop }
        $permissions = if ($PSBoundParameters.ContainsKey('PermissionId')) { $PermissionId } else { $filterObject.FilterPermissions }
        if (-not $permissions) {
            throw 'The Filter has no permissions to remove. Supply PermissionId or retrieve it with Get-JiraFilterPermission first.'
        }
        foreach ($permission in $permissions) {
            if ($null -eq $permission.Id -or $permission.Id -le 0) { throw 'PermissionId must contain positive numeric permission IDs.' }
            $parameter = @{
                URI        = "{0}/permission/{1}" -f $filterObject.RestUrl, $permission.Id
                Method     = 'DELETE'
                Credential = $Credential
            }
            if ($PSCmdlet.ShouldProcess($filterObject.Name, "Remove permission $($permission.Id)")) {
                Invoke-JiraMethod @parameter
            }
        }
    }
}
