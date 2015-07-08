function Get-JiraPriority
{
    [CmdletBinding()]
    param(
        # ID of the priority to get
        [Parameter(Mandatory = $false)]
        [Int] $Id,

        # Credentials to use to connect to Jira
        [Parameter(Mandatory = $false)]
        [System.Management.Automation.PSCredential] $Credential
    )

    begin
    {
        Write-Debug "[Get-JiraPriority] Reading server from config file"
        $server = Get-JiraConfigServer -ConfigFile $ConfigFile -ErrorAction Stop
        $priorityUrl = "$($server)/rest/api/latest/priority"

        if ($Id)
        {
            $priorityUrl = "$priorityUrl/$Id"
        }
    }

    process
    {
        Write-Debug "[Get-JiraPriority] Preparing for blastoff!"
        $result = Invoke-JiraMethod -Method Get -URI $priorityUrl -Credential $Credential

        if ($result)
        {
            Write-Debug "[Get-JiraPriority] Converting REST result to JiraPriority object"
            $obj = ConvertTo-JiraPriority -InputObject $result

            Write-Debug "[Get-JiraPriority] Outputting result"
            Write-Output $obj
        } else {
            Write-Debug "[Get-JiraPriority] Invoke-JiraMethod returned no results to output."
        }
    }

    end
    {
        Write-Debug "[Get-JiraPriority] Complete."
    }   
}