function Get-JiraPermissionScheme {
    <#
    .Synopsis
        Get permission Scheme
    .DESCRIPTION
        Get permission Scheme by name or ID
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
    [CmdletBinding(DefaultParameterSetName = 'All')]
    param(
        # ID of the permission Scheme
        [Parameter(
            Position = 0,
            Mandatory = $true,
            ParameterSetName = 'ByID'
        )]
        [ValidateRange(1, [Int]::MaxValue)]
        [Int[]] $Id,

        # Name of the permission Scheme
        [Parameter(
            Position = 0,
            ParameterSetName = 'All'
        )]
        [String[]] $Name,

        # Switch to expand all properties of the Scheme
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
                If($restResult)
                {
                    $result = ConvertTo-JiraPermissionScheme -InputObject $restResult
                }
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
                    $restResult = Invoke-JiraMethod @parameter
                    If($restResult)
                    {
                        Write-Output (ConvertTo-JiraPermissionScheme -InputObject $result)
                    }
                }
            }
        }
    }

    end {
    }
}
