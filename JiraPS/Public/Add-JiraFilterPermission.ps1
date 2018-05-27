function Add-JiraFilterPermission {
    [CmdletBinding( SupportsShouldProcess )]
    param(
        # Filter object to which the permission should be applied
        [Parameter( Mandatory, ValueFromPipeline )]
        [ValidateNotNullOrEmpty()]
        [PSTypeName('JiraPS.Filter')]
        $Filter,

        # Type of the permission to add
        [Parameter( Mandatory )]
        [ValidateNotNullOrEmpty()]
        [ValidateSet('Group', 'Project', 'ProjectRole', 'Authenticated', 'Global')]
        [String]$Type,

        # Value for the Type of the permission
        #
        # The Value differs per Type of the permission.
        # Here is a table to know what Value to provide:
        #
        # |Type         |Value                |Source                                              |
        # |-------------|---------------------|----------------------------------------------------|
        # |Group        |Name of the Group    |Can be retrieved with `(Get-JiraGroup ...).Name`    |
        # |Project      |Id of the Project    |Can be retrieved with `(Get-JiraProject ...).Id`    |
        # |ProjectRole  |Id of the ProjectRole|Can be retrieved with `(Get-JiraProjectRole ...).Id`|
        # |Authenticated| **must be null**    |                                                    |
        # |Global       | **must be null**    |                                                    |
        [String]$Value,

        # Credentials to use to connect to JIRA.
        #
        # If not specified, this function will use anonymous access.
        [PSCredential]
        $Credential
    )

    begin {
        Write-Verbose "[$($MyInvocation.MyCommand.Name)] Function started"

        $resourceURi = "{0}/permission"
    }

    process {
        Write-DebugMessage "[$($MyInvocation.MyCommand.Name)] ParameterSetName: $($PsCmdlet.ParameterSetName)"
        Write-DebugMessage "[$($MyInvocation.MyCommand.Name)] PSBoundParameters: $($PSBoundParameters | Out-String)"

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
