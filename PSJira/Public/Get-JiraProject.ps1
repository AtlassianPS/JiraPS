function Get-JiraProject
{
    <#
    .Synopsis
       Returns a project from Jira
    .DESCRIPTION
       This function returns information regarding a specified project from Jira. If
       the Project parameter is not supplied, it will return information about all
       projects the given user is authorized to view.

       The -Project parameter will accept either a project ID or a project key.
    .EXAMPLE
       Get-JiraProject -Project TEST -Credential $cred
       Returns information about the project TEST
    .EXAMPLE
       Get-JiraProject 2 -Credential $cred
       Returns information about the project with ID 2
    .EXAMPLE
       Get-JiraProject -Credential $cred
       Returns information about all projects the user is authorized to view
    .INPUTS
       [String[]] Project ID or project key
       [PSCredential] Credentials to use to connect to Jira
    .OUTPUTS
       [PSJira.Project]
    #>
    [CmdletBinding(DefaultParameterSetName = 'AllProjects')]
    param(
        # The Project ID or project key of a project to search.
        [Parameter(Mandatory = $false,
                   Position = 0)]
        [String[]] $Project,

        # Credentials to use to connect to JIRA.
        # If not specified, this function will use anonymous access.
        [Parameter(Mandatory = $false)]
        [System.Management.Automation.PSCredential] $Credential
    )

    begin
    {
        Write-Debug "[Get-JiraProject] Reading server from config file"
        try
        {
            $server = Get-JiraConfigServer -ConfigFile $ConfigFile -ErrorAction Stop
        } catch {
            $err = $_
            Write-Debug "[Get-JiraProject] Encountered an error reading the Jira server."
            throw $err
        }

        $uri = "$server/rest/api/latest/project"
    }

    process
    {
        if ($Project)
        {
            foreach ($p in $Project)
            {
                Write-Debug "[Get-JiraProject] Processing project [$p]"
                $thisUri = "$uri/${p}?expand=projectKeys"

                Write-Debug "[Get-JiraProject] Preparing for blastoff!"

                $result = Invoke-JiraMethod -Method Get -URI $thisUri -Credential $Credential
                if ($result)
                {
                    Write-Debug "[Get-JiraProject] Converting to object"
                    $obj = ConvertTo-JiraProject -InputObject $result

                    Write-Debug "[Get-JiraProject] Outputting result"
                    Write-Output $obj
                } else {
                    Write-Debug "[Get-JiraProject] No results were returned from Jira"
                    Write-Debug "[Get-JiraProject] No results were returned from Jira for project [$p]"
                }
            }
        } else {
            Write-Debug "[Get-JiraProject] Attempting to search for all projects"
            $thisUri = "$uri"

            Write-Debug "[Get-JiraProject] Preparing for blastoff!"
            $result = Invoke-JiraMethod -Method Get -URI $uri -Credential $Credential
            if ($result)
            {
                Write-Debug "[Get-JiraProject] Converting to object"
                $obj = ConvertTo-JiraProject -InputObject $result

                Write-Debug "[Get-JiraProject] Outputting result"
                Write-Output $obj
            } else {
                Write-Debug "[Get-JiraProject] No results were returned from Jira"
                Write-Debug "[Get-JiraProject] No project results were returned from Jira"
            }
        }
    }

    end
    {
        Write-Debug "Complete"
    }
}
