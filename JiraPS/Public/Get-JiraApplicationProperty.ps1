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
        [Parameter(Mandatory = $false)]
        [string] $Key,

        # When fetching a list allows the list to be filtered by the property's start of key e.g. "jira.lf.*" whould fetch only those permissions that are editable and whose keys start with "jira.lf.". This is a regex.
        [Parameter(Mandatory = $false)]
        [string] $KeyFilter,

        # When fetching a list specifies the permission level of all items in the list see {@link com.atlassian.jira.bc.admin.ApplicationPropertiesService.EditPermissionLevel}
        [Parameter(Mandatory = $false)]
        [string] $PermissionLevel,

        # Credentials to use to connect to JIRA.
        # If not specified, this function will use anonymous access.
        [Parameter(Mandatory = $false)]
        [System.Management.Automation.PSCredential] $Credential
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
        If ($KeyFilter) {
            [uri]$restUri = '{0}?keyFilter={1}' -f $restUri, $KeyFilter
        }
        If ($KeyFilter) {
            [uri]$restUri = '{0}?permissionLevel={1}' -f $restUri, $PermissionLevel
        }
        Write-Verbose "rest URI: [$restUri]"
        Write-Debug "[Get-JiraApplicationProperty] Preparing for blastoff!"
        $results = Invoke-JiraMethod -Method GET -URI $restUri -Credential $Credential
        If ($results) {
            Write-Output $results
        }
        else {
            Write-Debug "[Get-JiraApplicationProperty] JIRA returned no results."
            Write-Verbose "JIRA returned no results."
        }
    }
    end {
        Write-Debug "[Get-JiraApplicationProperty] Complete"
    }
}
