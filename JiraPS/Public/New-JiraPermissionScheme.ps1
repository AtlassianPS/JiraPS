function New-JiraPermissionScheme
{
    <#
    .Synopsis

    .DESCRIPTION
       Create permission scheme
    .EXAMPLE
       New-JiraPermissionScheme
    .EXAMPLE
    .INPUTS
    .OUTPUTS
    #>
    [CmdletBinding()]
    param(
        # Description of the permission scheme
        [Parameter(Mandatory = $false)]
        [String]
        $Description,

        # Name of the permission scheme
        [Parameter(Mandatory = $true)]
        [string]
        $Name,

        # JiraPS.PermissionScheme Object, Use Get-JiraPermissionScheme
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
        Write-Debug "[New-JiraPermissionScheme] Reading server from config file"
        $server = Get-JiraConfigServer -ConfigFile $ConfigFile -ErrorAction Stop

        Write-Debug "[New-JiraPermissionScheme] ParameterSetName=$($PSCmdlet.ParameterSetName)"

        Write-Debug "[New-JiraPermissionScheme] Building URI for REST call"
        $restUri = "$server/rest/api/2/permissionscheme?expand=all"
    }

    process
    {
        $props = @{
            name        = $Name
            description = $Description
            permissions = $InputObject
        }

        Write-Debug "[New-JiraUser] Converting to JSON"
        $json = ConvertTo-Json -Depth 5 -InputObject $props

        Write-Debug "[New-JiraPermissionScheme] Preparing for blastoff!"
        $results = Invoke-JiraMethod -Method POST -URI $restUri -Body $json -Credential $Credential
        If ($results)
        {
            $results = ConvertTo-JiraPermissionScheme -InputObject $results
        }
        else
        {
            Write-Debug "[New-JiraPermissionScheme] JIRA returned no results."
            Write-Verbose "JIRA returned no results."
        }
    }
    end
    {
        $results
        Write-Debug "[New-JiraPermissionScheme] Complete"
    }
}
