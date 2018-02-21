function New-JiraPermissionSchema
{
    <#
    .Synopsis

    .DESCRIPTION
       Create permission Schema
    .EXAMPLE
       New-JiraPermissionSchema
    .EXAMPLE
    .INPUTS
    .OUTPUTS
    #>
    [CmdletBinding()]
    param(
        # Description of the permission Schema
        [Parameter(Mandatory = $false)]
        [String]
        $Description,

        # Name of the permission Schema
        [Parameter(Mandatory = $true)]
        [string]
        $Name,

        # JiraPS.PermissionSchema Object, Use Get-JiraPermissionSchema -ID $ID -Expand
        [Parameter(Mandatory = $true)]
        [Array]
        $InputObject,

        # Credentials to use to connect to JIRA.
        # If not specified, this function will use anonymous access.
        [Parameter(Mandatory = $false)]
        [System.Management.Automation.PSCredential] $Credential
    )

    begin
    {
        $server = Get-JiraConfigServer -ConfigFile $ConfigFile -ErrorAction Stop
        $restUri = "$server/rest/api/2/permissionSchema"
    }

    process
    {
        $props = @{
            name        = $Name
            description = $Description
            permissions = $InputObject
        }
        $json = ConvertTo-Json -Depth 5 -InputObject $props
        $results = Invoke-JiraMethod -Method POST -URI $restUri -Body $json -Credential $Credential
        If ($results)
        {
            $results = ConvertTo-JiraPermissionSchema -InputObject $results
        }
        else
        {
            Write-Verbose "JIRA returned no results."
        }
    }
    end
    {
        $results
    }
}
