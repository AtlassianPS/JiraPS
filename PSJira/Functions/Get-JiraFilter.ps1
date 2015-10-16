function Get-JiraFilter
{
    <#
    .Synopsis
       Returns information about a filter in JIRA
    .DESCRIPTION
       This function returns information about a filter in JIRA, including the JQL syntax of the filter, its owner, and sharing status.

       This function is only capable of returning filters by their Filter ID. This is a limitation of JIRA's REST API.  The easiest way to obtain the ID of a filter is to load the filter in the "regular" Web view of JIRA, then copy the ID from the URL of the page.
    .EXAMPLE
       Get-JiraFilter -Id 12345
       Gets a reference to filter ID 12345 from JIRA
    .INPUTS
       [String[]] ID of the filter(s)
    .OUTPUTS
       [PSJira.Filter[]] Filter objects
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true,
                   Position = 0)]
        [String[]] $Id,

        # Credentials to use to connect to Jira
        [Parameter(Mandatory = $false)]
        [System.Management.Automation.PSCredential] $Credential
    )

    begin
    {
        Write-Debug "[Get-JiraFilter] Reading server from config file"
        try
        {
            $server = Get-JiraConfigServer -ConfigFile $ConfigFile -ErrorAction Stop
        } catch {
            $err = $_
            Write-Debug "[Get-JiraFilter] Encountered an error reading the Jira server."
            throw $err
        }

        $uri = "$server/rest/api/latest/filter/{0}"
    }

    process
    {
        foreach ($i in $Id)
        {
            Write-Debug "[Get-JiraFilter] Processing filter [$i]"
            $thisUri = $uri -f $i
            Write-Debug "[Get-JiraFilter] Filter URI: [$thisUri]"
            Write-Debug "[Get-JiraFilter] Preparing for blast off!"
            $result = Invoke-JiraMethod -Method Get -URI $thisUri -Credential $Credential

            if ($result)
            {
                Write-Debug "[Get-JiraFilter] Converting result to JiraFilter object"
                $obj = ConvertTo-JiraFilter -InputObject $result

                Write-Debug "Outputting result"
                Write-Output $obj
            } else {
                Write-Debug "[Get-JiraFilter] Invoke-JiraFilter returned no results to output."
            }

        }
    }

    end
    {
        Write-Debug "[Get-JiraFilter] Complete"
    }
}