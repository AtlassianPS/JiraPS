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
        [AtlassianPS.Connection]
        $Connection
    )

    begin {
        Write-Verbose "[$($MyInvocation.MyCommand.Name)] Function started"

        $RequestContext = Resolve-JiraOperationContext -BoundParameters $PSBoundParameters

        $resourceURi = "{0}/permission"
    }

    process {
        Write-DebugMessage "ParameterSetName: $($PsCmdlet.ParameterSetName)"
        Write-DebugMessage -BoundParameters $PSBoundParameters

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
            Write-DebugMessage "Invoking JiraMethod with `$parameter"
            if ($PSCmdlet.ShouldProcess($_filter.Name, "Add Permission [$Type - $Value]")) {
                $result = Invoke-JiraRequest -RequestContext $RequestContext @parameter

                ConvertTo-JiraFilterPermission -InputObject $result
            }
        }
    }

    end {
        Write-Verbose "[$($MyInvocation.MyCommand.Name)] Complete"
    }
}
