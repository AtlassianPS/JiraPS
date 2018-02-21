function Remove-JiraPermissionScheme {
    <#
    .Synopsis
        Removes a permission scheme
    .DESCRIPTION
       Remove permission scheme from Jira
    .EXAMPLE
       Remove-JiraPermissionScheme -Name 'My New Permission Scheme'
    .EXAMPLE
        Remove-JiraPermissionScheme -ID 10101
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
        $server = Get-JiraConfigServer -ConfigFile $ConfigFile -ErrorAction Stop
        $restUri = "$server/rest/api/2/permissionscheme"
    }

    process {
        If ($PSCmdlet.ParameterSetName -eq 'ByName') {
            $ID = Get-JiraPermissionScheme | Where-Object {$PSitem.Name } | Select-Object -ExpandProperty ID
        }
        If ($ID) {
            $restUri = '{0}/{1}' -f $restUri, $ID
        }
        $results = Invoke-JiraMethod -Method DELETE -URI $restUri -Credential $Credential
        If ($results) {
            ($results | ConvertTo-JiraPermissionScheme)
        }
        else {
            Write-Verbose "JIRA returned no results."
        }
    }
    end {
    }
}
