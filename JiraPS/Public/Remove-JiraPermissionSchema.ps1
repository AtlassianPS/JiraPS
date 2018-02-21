function Remove-JiraPermissionSchema {
    <#
    .Synopsis
        Removes a permission Schema
    .DESCRIPTION
       Remove permission Schema from Jira
    .EXAMPLE
       Remove-JiraPermissionSchema -Name 'My New Permission Schema'
    .EXAMPLE
        Remove-JiraPermissionSchema -ID 10101
    .INPUTS

    .OUTPUTS
       This function returns no output.
    #>
    [CmdletBinding(DefaultParameterSetName = 'ByID')]
    param(
        # ID of the permission Schema
        [Parameter(Mandatory = $true,
            ParameterSetName = 'ByID'
        )]
        [int]
        $ID,

        # Name of the permission Schema
        [Parameter(Mandatory = $true,
            ParameterSetName = 'ByName'
        )]
        [string]
        $Name,

        # Credentials to use to connect to JIRA.
        # If not specified, this function will use anonymous access.
        [Parameter(Mandatory = $false)]
        [System.Management.Automation.PSCredential] $Credential
    )

    begin {
        $server = Get-JiraConfigServer -ConfigFile $ConfigFile -ErrorAction Stop
        $restUri = "$server/rest/api/2/permissionSchema"
    }

    process {
        If ($PSCmdlet.ParameterSetName -eq 'ByName') {
            $ID = Get-JiraPermissionSchema | Where-Object {$PSitem.Name } | Select-Object -ExpandProperty ID
        }
        If ($ID) {
            $restUri = '{0}/{1}' -f $restUri, $ID
        }
        $results = Invoke-JiraMethod -Method DELETE -URI $restUri -Credential $Credential
        If ($results) {
            ($results | ConvertTo-JiraPermissionSchema)
        }
        else {
            Write-Verbose "JIRA returned no results."
        }
    }
    end {
    }
}
