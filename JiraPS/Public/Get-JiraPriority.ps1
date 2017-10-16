function Get-JiraPriority {
    <#
    .Synopsis
        Returns information about the available priorities in JIRA.
    .DESCRIPTION
        This function retrieves all the available Priorities on the JIRA server an returns them as JiraPS.Priority.

        This function can restrict the output to a subset of the available IssueTypes if told so.
    .EXAMPLE
        Get-JiraPriority
        This example returns all the IssueTypes on the JIRA server.
    .EXAMPLE
        Get-JiraPriority -ID 1
        This example returns only the Priority with ID 1.
    .OUTPUTS
        This function outputs the JiraPS.Priority object retrieved.
    .NOTES
        This function requires either the -Credential parameter to be passed or a persistent JIRA session. See New-JiraSession for more details.  If neither are supplied, this function will run with anonymous access to JIRA.
    #>
    [CmdletBinding()]
    param(
        # ID of the priority to get.
        [Parameter(Mandatory = $false)]
        [Int] $Id,

        # Credentials to use to connect to JIRA.
        # If not specified, this function will use anonymous access.
        [Parameter(Mandatory = $false)]
        [System.Management.Automation.PSCredential] $Credential
    )

    begin {
        Write-Debug "[Get-JiraPriority] Reading server from config file"
        $server = Get-JiraConfigServer -ConfigFile $ConfigFile -ErrorAction Stop
        $priorityUrl = "$($server)/rest/api/latest/priority"

        if ($Id) {
            $priorityUrl = "$priorityUrl/$Id"
        }
    }

    process {
        Write-Debug "[Get-JiraPriority] Preparing for blastoff!"
        $result = Invoke-JiraMethod -Method Get -URI $priorityUrl -Credential $Credential

        if ($result) {
            Write-Debug "[Get-JiraPriority] Converting REST result to JiraPriority object"
            $obj = ConvertTo-JiraPriority -InputObject $result

            Write-Debug "[Get-JiraPriority] Outputting result"
            Write-Output $obj
        }
        else {
            Write-Debug "[Get-JiraPriority] Invoke-JiraMethod returned no results to output."
        }
    }

    end {
        Write-Debug "[Get-JiraPriority] Complete."
    }
}
