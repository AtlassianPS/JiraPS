function Get-JiraPermissionScheme
{
    <#
    .Synopsis
        Get permission scheme
    .DESCRIPTION
        Get permission scheme by name or ID
    .EXAMPLE
        Get-JiraPermissionScheme
    .EXAMPLE
        Get-JiraPermissionScheme -Expand
    .EXAMPLE
        Get-JiraPermissionScheme -ID 0
    .EXAMPLE
        Get-JiraPermissionScheme -ID 0 -Expand
    .EXAMPLE
        Get-JiraPermissionScheme -Name 'Default Permission Scheme'
    .EXAMPLE
        Get-JiraPermissionScheme -Name 'Default Permission Scheme' -Expand
    .OUTPUTS
        [JiraPS.PermissionsScheme]
    #>
    [CmdletBinding(DefaultParameterSetName = 'ByID')]
    param(
        # Switch to expand all properties of the scheme
        [Parameter(Mandatory = $false)]
        [switch]
        $Expand,

        # ID of the permission scheme
        [Parameter(Mandatory = $false,
            ParameterSetName = 'ByID'
        )]
        [int]
        $ID,

        # Name of the permission scheme
        [Parameter(Mandatory = $false,
            ParameterSetName = 'ByName'
        )]
        [string]
        $Name,

        # Credentials to use to connect to JIRA.
        # If not specified, this function will use anonymous access.
        [Parameter(Mandatory = $false)]
        [System.Management.Automation.PSCredential] $Credential
    )

    begin
    {
        Write-Debug "[Get-JiraPermissionScheme] Reading server from config file"
        $server = Get-JiraConfigServer -ConfigFile $ConfigFile -ErrorAction Stop

        Write-Debug "[Get-JiraPermissionScheme] ParameterSetName=$($PSCmdlet.ParameterSetName)"

        Write-Debug "[Get-JiraPermissionScheme] Building URI for REST call"
        $restUri = "$server/rest/api/2/permissionscheme"
    }

    process
    {
        If ($PSCmdlet.ParameterSetName -eq 'ByName')
        {
            $ID = Get-JiraPermissionScheme | Where-Object 'Name' -eq $Name | Select-Object -ExpandProperty ID
            If ($ID -eq 0)
            {
                Write-Verbose "JIRA returned no results."
                return
            }
            else
            {
                $restUri = '{0}/{1}' -f $restUri, $ID
            }
        }
        If ($PSBoundParameters.ContainsKey('ID'))
        {
            $restUri = '{0}/{1}' -f $restUri, $ID
        }
        if ($Expand)
        {
            $restUri = '{0}?expand={1}' -f $restUri, 'all'
        }
        Write-Debug "[Get-JiraPermissionScheme] Preparing for blastoff!"
        $results = Invoke-JiraMethod -Method GET -URI $restUri -Credential $Credential
        If ($results)
        {
            ($results | ConvertTo-JiraPermissionScheme)
        }
        else
        {
            Write-Debug "[Get-JiraPermissionScheme] JIRA returned no results."
            Write-Verbose "JIRA returned no results."
        }
    }
    end
    {
        Write-Debug "[Get-JiraPermissionScheme] Complete"
    }
}
