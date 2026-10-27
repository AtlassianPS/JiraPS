function Add-JiraFilterPermission {
    # .ExternalHelp ..\JiraPS-help.xml
    [CmdletBinding( SupportsShouldProcess )]
    param(
        [Parameter( Position = 0, Mandatory, ValueFromPipeline )]
        [ValidateNotNullOrEmpty()]
        [Alias('Id')]
        [AtlassianPS.JiraPS.FilterTransformation()]
        [AtlassianPS.JiraPS.Filter[]]
        $Filter,

        [Parameter( Mandatory )]
        [ValidateNotNullOrEmpty()]
        [ValidateSet('Group', 'Project', 'ProjectRole', 'Authenticated', 'Global')]
        [String]
        $Type,

        [Parameter()]
        [String]
        $Value,

        [Parameter()]
        [System.Management.Automation.PSCredential]
        [System.Management.Automation.Credential()]
        $Credential,

        [Alias('Session')]
        [AtlassianPS.Connection]
        $Connection
    )

    begin {
        Write-Verbose "[$($MyInvocation.MyCommand.Name)] Function started"

        try {
            $RequestContext = Resolve-JiraOperationContext -BoundParameters $PSBoundParameters

            $resourceURi = "{0}/permission"
        }
        catch {
            if ($RequestContext -and $RequestContext.State -eq 'Standalone') { $RequestContext.Dispose() }
            throw
        }
    }

    process {
        try {
            Write-DebugMessage "[$($MyInvocation.MyCommand.Name)] ParameterSetName: $($PsCmdlet.ParameterSetName)"

            $filters = foreach ($item in $Filter) {
                if ($item.RestUrl) { $item }
                else {
                    Get-JiraFilterOperation -Id $item.Id -RequestContext $RequestContext -ErrorAction Stop
                }
            }

            $body = @{
                type = $Type.ToLower()
            }
            switch ($Type) {
                "Group" { $body["groupname"] = $Value }
                "Project" { $body["projectId"] = $Value }
                "ProjectRole" { $body["projectRoleId"] = $Value }
                "Authenticated" { }
                "Global" { }
            }

            foreach ($_filter in $filters) {
                $parameter = @{
                    URI    = $resourceURi -f $_filter.RestURL
                    Method = "POST"
                    Body   = ConvertTo-Json $body
                }
                Write-Debug "[$($MyInvocation.MyCommand.Name)] Invoking JiraMethod with `$parameter"
                if ($PSCmdlet.ShouldProcess($_filter.Name, "Add Permission [$Type - $Value]")) {
                    $result = Invoke-JiraMethod -RequestContext $RequestContext @parameter

                    Write-Output (ConvertTo-JiraFilter -InputObject $_filter -FilterPermissions $result)
                }
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
