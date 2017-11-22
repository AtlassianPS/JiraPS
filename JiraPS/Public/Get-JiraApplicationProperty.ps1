function Get-JiraApplicationProperty {
    <#
    .Synopsis
        Get Jira Application Property
    .DESCRIPTION
       Get Jira Application Property
    .EXAMPLE
       Get-JiraApplicationProperty -key
    .EXAMPLE
    .INPUTS
    .OUTPUTS
    #>
    [CmdletBinding()]
    param(
        # Property key
        [String] $Key,

        # When fetching a list allows the list to be filtered by the property's start of key
        # e.g. "jira.lf.*" whould fetch only those permissions that are editable and whose keys start with "jira.lf.".
        # This is a regex.
        [String] $Filter,

        # When fetching a list specifies the permission level of all items in the list.
        # see https://docs.atlassian.com/jira/7.0.5/com/atlassian/jira/bc/admin/ApplicationPropertiesService.EditPermissionLevel.html
        [String] $PermissionLevel,

        # Credentials to use to connect to JIRA.
        # If not specified, this function will use anonymous access.
        [PSCredential] $Credential
    )

    begin {
        Write-Debug "[Get-JiraApplicationProperty] Reading server from config file"
        $server = Get-JiraConfigServer -ConfigFile $ConfigFile -ErrorAction Stop

        Write-Debug "[Get-JiraApplicationProperty] ParameterSetName=$($PSCmdlet.ParameterSetName)"

        Write-Debug "[Get-JiraApplicationProperty] Building URI for REST call"
        $restUri = "$server/rest/api/2/application-properties/"
    }

    process {
        If ($Key) {
            [uri]$restUri = '{0}?key={1}' -f $restUri, $Key
        }
        If ($Filter) {
            [uri]$restUri = '{0}?Filter={1}' -f $restUri, $Filter
        }
        If ($PermissionLevel) {
            [uri]$restUri = '{0}?permissionLevel={1}' -f $restUri, $PermissionLevel
        }
        $parameter = @{
            URI = $restUri
            Method = "GET"
            Credential = $Credential
        }
        Write-Debug "[Get-JiraApplicationProperty] Preparing for blastoff!"
        Write-Output (Invoke-JiraMethod @parameter)
    }
    end {
        Write-Debug "[Get-JiraApplicationProperty] Complete"
    }
}
