function Get-JiraPermissionSchema {
    <#
    .Synopsis
        Get permission Schema
    .DESCRIPTION
        Get permission Schema by name or ID
    .EXAMPLE
        Get-JiraPermissionSchema
    .EXAMPLE
        Get-JiraPermissionSchema -Expand
    .EXAMPLE
        Get-JiraPermissionSchema -ID 0
    .EXAMPLE
        Get-JiraPermissionSchema -ID 0 -Expand
    .EXAMPLE
        Get-JiraPermissionSchema -Name 'Default Permission Schema'
    .EXAMPLE
        Get-JiraPermissionSchema -Name 'Default Permission Schema' -Expand
    .OUTPUTS
        [JiraPS.PermissionsSchema]
    #>
    [CmdletBinding(DefaultParameterSetName = 'All')]
    param(
        # ID of the permission Schema
        [Parameter(
            Position = 0,
            Mandatory = $true,
            ParameterSetName = 'ByID'
        )]
        [ValidateRange(1, [Int]::MaxValue)]
        [Int[]] $Id,

        # Name of the permission Schema
        [Parameter(
            Position = 0,
            ParameterSetName = 'All'
        )]
        [String[]] $Name,

        # Switch to expand all properties of the Schema
        [Switch] $Expand,

        # Credentials to use to connect to JIRA.
        # If not specified, this function will use anonymous access.
        [PSCredential] $Credential
    )

    begin {
        Write-Debug "[Get-JiraPermissionSchema] Reading server from config file"
        $server = Get-JiraConfigServer -ConfigFile $ConfigFile -ErrorAction Stop

        Write-Debug "[Get-JiraPermissionSchema] ParameterSetName=$($PSCmdlet.ParameterSetName)"

        Write-Debug "[Get-JiraPermissionSchema] Building URI for REST call"
        $resourceURi = "$server/rest/api/2/permissionSchema"
    }

    process {
        switch ($PSCmdlet.ParameterSetName) {
            "All" {
                if ($Expand) {
                    $resourceURi = '{0}?expand={1}' -f $resourceURi, 'all'
                }
                $parameter = @{
                    URI        = $resourceURi
                    Method     = "GET"
                    Credential = $Credential
                }
                $restResult = Invoke-JiraMethod @parameter
                $result = ConvertTo-JiraPermissionSchema -InputObject $restResult
                if ($Name) {
                    foreach ($_name in $Name) {
                        Write-Verbose "Filtering $_name"
                        Write-Output ($result | Where-Object {$_.Name -like $_name})
                    }
                } else {
                    Write-Output $result
                }
            }
            "ByID" {
                foreach ($i in $Id) {
                    $restUri = '{0}/{1}' -f $resourceURi, $i
                    if ($Expand) {
                        $restUri = '{0}?expand={1}' -f $restUri, 'all'
                    }
                    $parameter = @{
                        URI        = $restUri
                        Method     = "GET"
                        Credential = $Credential
                    }
                    $result = Invoke-JiraMethod @parameter
                    Write-Output (ConvertTo-JiraPermissionSchema -InputObject $result)
                }
            }
        }
    }

    end {
    }
}
