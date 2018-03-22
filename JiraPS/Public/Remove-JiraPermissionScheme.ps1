function Remove-JiraPermissionScheme {
    <#
    .Synopsis
        Removes a permission scheme
    .DESCRIPTION
       Remove permission scheme from Jira
    .EXAMPLE
       Remove-JiraPermissionScheme -Name 'My New Permission Scheme'
    .EXAMPLE
        Remove-JiraPermissionScheme -ID 0
    .INPUTS

    .OUTPUTS
       This function returns no output.
    #>
    [CmdletBinding(DefaultParameterSetName = 'ByID')]
    param(
        # ID of the permission scheme
        [Parameter(Mandatory = $true,
            ParameterSetName = 'ByID'
        )]
        [int]
        $ID,

        # Name of the permission scheme
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
        Write-Debug "[Remove-JiraPermissionScheme] Reading server from config file"
        $server = Get-JiraConfigServer -ConfigFile $ConfigFile -ErrorAction Stop

        Write-Debug "[Remove-JiraPermissionScheme] ParameterSetName=$($PSCmdlet.ParameterSetName)"

        Write-Debug "[Remove-JiraPermissionScheme] Building URI for REST call"
        $restUri = "$server/rest/api/2/permissionscheme"
    }

    process {
        If ($PSCmdlet.ParameterSetName -eq 'ByName') {
            $ID = Remove-JiraPermissionScheme | Where-Object 'Name' -eq $Name | Select-Object -ExpandProperty ID
        }
        If ($ID) {
            $restUri = '{0}/{1}' -f $restUri, $ID
        }
        Write-Debug "[Remove-JiraPermissionScheme] Preparing for blastoff!"
        $results = Invoke-JiraMethod -Method DELETE -URI $restUri -Credential $Credential
        If ($results) {
            ($results | ConvertTo-JiraPermissionScheme)
        }
        else {
            Write-Debug "[Remove-JiraPermissionScheme] JIRA returned no results."
            Write-Verbose "JIRA returned no results."
        }
    }
    end {
        Write-Debug "[Remove-JiraPermissionScheme] Complete"
    }
}
