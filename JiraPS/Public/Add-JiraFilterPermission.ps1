function Add-JiraFilterPermission {
    [CmdletBinding( SupportsShouldProcess, DefaultParameterSetName = 'ByInputObject' )]
    [OutputType( [JiraPS.FilterPermission] )]
    param(
        [Parameter( Position = 0, Mandatory, ValueFromPipeline, ParameterSetName = 'ByInputObject' )]
        [ValidateNotNullOrEmpty()]
        [PSTypeName('JiraPS.Filter')]
        $Filter,

        [Parameter( Position = 0, Mandatory, ValueFromPipeline, ParameterSetName = 'ById')]
        [UInt32[]]
        $Id,

        [Parameter( Position = 1, Mandatory )]
        [ValidateNotNullOrEmpty()]
        [ValidateSet('Group', 'Project', 'ProjectRole', 'Authenticated', 'Global')]
        [String]$Type,

        [String]$Value,

        [Parameter()]
        [System.Management.Automation.PSCredential]
        [System.Management.Automation.Credential()]
        $Credential = [System.Management.Automation.PSCredential]::Empty
    )

    begin {
        Write-Verbose "[$($MyInvocation.MyCommand.Name)] Function started"

        $resourceURi = "{0}/permission"
    }

    process {
        Write-DebugMessage "[$($MyInvocation.MyCommand.Name)] ParameterSetName: $($PsCmdlet.ParameterSetName)"
        Write-DebugMessage "[$($MyInvocation.MyCommand.Name)] PSBoundParameters: $($PSBoundParameters | Out-String)"

        if ($PSCmdlet.ParameterSetName -eq 'ById') {
            $InputObject = foreach ($_id in $Id) {
                Get-JiraFilter -Id $_id
            }
        }

        $body = @{
            type = $Type.ToLower()
        }
        switch ($Type) {
            "Group" {
                $body["groupname"] = $Value
            }
            "Project" {
                $body["projectId"] = $Value
            }
            "ProjectRole" {
                $body["projectRoleId"] = $Value
            }
            "Authenticated" { }
            "Global" { }
        }

        $parameter = @{
            URI        = $resourceURi -f $Filter.RestURL
            Method     = "POST"
            Body       = ConvertTo-Json $body
            Credential = $Credential
        }
        Write-Debug "[$($MyInvocation.MyCommand.Name)] Invoking JiraMethod with `$parameter"
        if ($PSCmdlet.ShouldProcess($Filter.Name, "Add Permission [$Type - $Value]")) {
            $result = Invoke-JiraMethod @parameter

            Write-Output (ConvertTo-JiraFilterPermission -InputObject $result)
        }
    }

    end {
        Write-Verbose "[$($MyInvocation.MyCommand.Name)] Complete"
    }
}
