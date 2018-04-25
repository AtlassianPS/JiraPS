function New-JiraPermissionScheme
{
    <#
    .Synopsis

    .DESCRIPTION
       Create permission Scheme
    .EXAMPLE
       New-JiraPermissionScheme
    .EXAMPLE
    .INPUTS
    .OUTPUTS
    #>
    [CmdletBinding()]
    param(
        # Description of the permission Scheme
        [Parameter(Mandatory = $false)]
        [String]
        $Description,

        # Name of the permission Scheme
        [Parameter(Mandatory = $true)]
        [string]
        $Name,

        # JiraPS.PermissionScheme Object, Use Get-JiraPermissionScheme -ID $ID -Expand
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
        $restUri = "$server/rest/api/2/permissionscheme"
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
            $results = ConvertTo-JiraPermissionScheme -InputObject $results
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
