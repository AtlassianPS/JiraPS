function Get-JiraFilter
{
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