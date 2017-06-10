function Get-JiraFixVersion
{
    <#
    .Synopsis
       This function returns information about a JIRA Projects FixVersions
    .DESCRIPTION
       This function provides information about JIRA FixVersions
    .EXAMPLE
       Get-JiraFixVersion -Project $ProjectKey
       This example returns information about all JIRA FixVersions visible to the current user (or using anonymous access if a PSJira session has not been defined) for the project.
    .INPUTS
       This function does accept pipeline input.
    .OUTPUTS
       This function outputs the PSJira.Fixversion object(s).
    .NOTES
       This function requires either the -Credential parameter to be passed or a persistent JIRA session. See New-JiraSession for more details.  If neither are supplied, this function will run with anonymous access to JIRA.
    #>
    [CmdletBinding()]
    param(
        # The Project ID or project key of a project to search
        [Parameter(Mandatory = $false,
                    Position = 0,
                    ValueFromRemainingArguments = $true)]
        [String] $Project,

        # Credentials to use to connect to Jira
        [Parameter(Mandatory = $false)]
        [System.Management.Automation.PSCredential] $Credential
    )

    begin
    {
        Write-Debug "[Get-JiraFixVersion] Reading server from config file"
        try
        {
            Write-Debug -Message '[Get-JiraFixVersion] Reading Jira server from config file'
            $server = Get-JiraConfigServer -ConfigFile $ConfigFile -ErrorAction Stop
        }
        catch
        {
            $err = $_
            Write-Debug -Message '[Get-JiraFixVersion] Encountered an error reading configuration data.'
            throw $err
        }

        Write-Debug "[Get-JiraFixVersion] Completed Begin block."
    }

    process
    {    
        Write-Debug "[Get-JiraFixVersion] Gathering project data for [$Project]."    
        $ProjectData = Get-JiraProject -Project $Project
                
        $restUrl = "$server/rest/api/2/project/$($projectData.key)/versions"
        Write-Debug "[Get-JiraFixVersion] Rest URL set to $restUrl."
        
        Write-Debug -Message '[Get-JiraFixVersion] Preparing for blastoff!'
        $result = Invoke-JiraMethod -Method Get -URI $restUrl -Credential $Credential

        If ($result)
        {
            Write-Output -InputObject $result
        }
        Else
        {
            Write-Debug -Message '[Get-JiraFixVersion] Jira returned no results to output.'
        }

    }

    end
    {
        Write-Debug "[Get-JiraFixVersion] Complete"
    }
}
