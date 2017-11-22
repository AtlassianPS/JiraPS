function Get-JiraPermissionScheme {
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
        # ID of the permission scheme
        [Parameter(
            Mandatory = $true,
            ParameterSetName = 'ByID'
        )]
        [ValidateRange(1, [Int]::MaxValue)]
        [Int[]] $Id,

        # Name of the permission scheme
        [Parameter(
            Mandatory = $true,
            ParameterSetName = 'ByName'
        )]
        [String[]] $Name,

        # Switch to expand all properties of the scheme
        [Switch] $Expand,

        # Credentials to use to connect to JIRA.
        # If not specified, this function will use anonymous access.
        [PSCredential] $Credential
    )

    begin {
        Write-Debug "[Get-JiraPermissionScheme] Reading server from config file"
        $server = Get-JiraConfigServer -ConfigFile $ConfigFile -ErrorAction Stop

        Write-Debug "[Get-JiraPermissionScheme] ParameterSetName=$($PSCmdlet.ParameterSetName)"

        Write-Debug "[Get-JiraPermissionScheme] Building URI for REST call"
        $resourceURi = "$server/rest/api/2/permissionscheme"
    }

    process {
        switch ($PSCmdlet.ParameterSetName) {
            "ByID" {
                foreach ($_id in $Id) {
                    $restUri = '{0}/{1}' -f $resourceURi, $ID

                    if ($Expand) {
                        $restUri = '{0}?expand={1}' -f $restUri, 'all'
                    }

                    $parameter = @{
                        URI        = $restUri
                        Method     = "GET"
                        Credential = $Credential
                    }
                    Write-Debug "[Get-JiraPermissionScheme] Preparing for blastoff!"
                    Write-Output (ConvertTo-JiraPermissionScheme (Invoke-JiraMethod @parameter))
                }
            }
            "ByName" {
                Get-JiraPermissionScheme -Expand:$Expand | Where-Object { $_.Name -in $Name }
            }
        }
    }

    end {
        Write-Debug "[Get-JiraPermissionScheme] Complete"
    }
}
