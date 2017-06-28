function Get-JiraIssueLinkType {
    <#
    .SYNOPSIS
        Gets available issue link types
    .DESCRIPTION
        This function gets available issue link types from a JIRA server. It can also return specific information about a single issue link type.

        This is a useful function for discovering data about issue link types in order to create and modify issue links on issues.
    .EXAMPLE
        C:\PS> Get-JiraIssueLinkType
        This example returns all available links fron the JIRA server
    .EXAMPLE
        C:\PS> Get-JiraIssueLinkType -LinkType 1
        This example returns information about the link type with ID 1.
    .INPUTS
        This function does not accept pipeline input.
    .OUTPUTS
        This function outputs the JiraPS.IssueLinkType object(s) that represent the JIRA issue link type(s).
    .NOTES
        This function requires either the -Credential parameter to be passed or a persistent JIRA session. See New-JiraSession for more details.  If neither are supplied, this function will run with anonymous access to JIRA.
    #>
    [CmdletBinding()]
    param(
        # The Issue Type name or ID to search
        [Parameter(
            Position = 0,
            Mandatory = $false,
            ValueFromRemainingArguments = $true
        )]
        [Object] $LinkType,

        # Credentials to use to connect to Jira
        [Parameter(Mandatory = $false)]
        [System.Management.Automation.PSCredential] $Credential
    )

    begin {
        Write-Debug "[Get-JiraIssueLinkType] Reading server from config file"
        try {
            $server = Get-JiraConfigServer -ConfigFile $ConfigFile -ErrorAction Stop
        }
        catch {
            $err = $_
            Write-Debug "[Get-JiraIssueLinkType] Encountered an error reading the Jira server."
            throw $err
        }

        $uri = "$server/rest/api/latest/issueLinkType"
    }

    process {
        $searchLinks = $false
        if ($LinkType) {
            # If the link type provided is an int, we can assume it's an ID number.
            # If it's a String, it's probably a name, though, and there isn't an API call to look up a link type by name.
            if ($LinkType -is [int]) {
                Write-Debug "[Get-JiraIssueLinkType] Link type ID was specified; obtaining issue link type $LinkType"
                $uri = "$uri/$LinkType"
            }
            else {
                Write-Debug "[Get-JiraIssueLinkType] Assuming -LinkType parameter $LinkType to be a name; obtaining all link types"
                $searchLinks = $true
            }
        }
        else {
            Write-Debug "[Get-JiraIssueLinkType] Obtaining all issue link types from Jira"
        }

        $jiraResult = Invoke-JiraMethod -Method Get -URI $uri -Credential $Credential

        if ($jiraResult -and $jiraResult.issueLinkTypes) {
            Write-Debug "[Get-JiraIssueLinkType] Converting Jira output to custom object"
            $obj = ConvertTo-JiraIssueLinkType -InputObject $jiraResult.issueLinkTypes

            if ($searchLinks) {
                Write-Debug "[Get-JiraIssueLinkType] Searching for link type with name [$LinkType]"
                $output = $obj | Where-Object {$_.Name -eq $LinkType}
                if ($output) {
                    Write-Debug "[Get-JiraIssueLinkType] Found issue with ID [$($output.ID)]"
                }
                else {
                    Write-Debug "[Get-JiraIssueLinkType] Could not find an issue."
                    Write-Verbose "Unable to identify issue link type $LinkType."
                }
            }
            else {
                $output = $obj
            }

            Write-Debug "[Get-JiraIssueLinkType] Writing output"
            Write-Output $obj
        }
        else {
            Write-Debug "[Get-JiraIssueLinkType] No issue link types were found."
        }
    }
}
