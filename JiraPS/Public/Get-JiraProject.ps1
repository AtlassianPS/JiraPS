function Get-JiraProject {
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
       [JiraPS.Project]
    #>
    [CmdletBinding()]
    param(
        # The Project ID or project key of a project to search.
        [Parameter(
            Position = 0,
            Mandatory = $false
        )]
        [String[]] $Project,

        # Credentials to use to connect to JIRA.
        # If not specified, this function will use anonymous access.
        [PSCredential] $Credential
    )

    begin {
        Write-Verbose "[$($MyInvocation.MyCommand.Name)] Function started"

        $server = Get-JiraConfigServer -ConfigFile $ConfigFile -ErrorAction Stop

        $uri = "$server/rest/api/latest/project"
    }

    process {
        Write-DebugMessage "[$($MyInvocation.MyCommand.Name)] ParameterSetName: $($PsCmdlet.ParameterSetName)"
        Write-DebugMessage "[$($MyInvocation.MyCommand.Name)] PSBoundParameters: $($PSBoundParameters | Out-String)"

        if ($Project) {
            foreach ($p in $Project) {
                Write-Debug "[Get-JiraProject] Processing project [$p]"
                $thisUri = "$uri/$p?expand=projectKeys"

                Write-Debug "[$($MyInvocation.MyCommand.Name)] Invoking JiraMethod with `$parameter"
                $result = Invoke-JiraMethod -Method Get -URI $thisUri -Credential $Credential

                if ($result) {
                    Write-Debug "[Get-JiraProject] Converting to object"
                    $obj = ConvertTo-JiraProject -InputObject $result

                    Write-Debug "[Get-JiraProject] Outputting result"
                    Write-Output $obj
                }
                else {
                    Write-Debug "[Get-JiraProject] No results were returned from Jira"
                    Write-Debug "[Get-JiraProject] No results were returned from Jira for project [$p]"
                }
            }
        }
        else {
            Write-Debug "[Get-JiraProject] Attempting to search for all projects"
            $thisUri = "$uri"

            Write-Debug "[$($MyInvocation.MyCommand.Name)] Invoking JiraMethod with `$parameter"
            $result = Invoke-JiraMethod -Method Get -URI $uri -Credential $Credential

            if ($result) {
                Write-Debug "[Get-JiraProject] Converting to object"
                $obj = ConvertTo-JiraProject -InputObject $result

                Write-Debug "[Get-JiraProject] Outputting result"
                Write-Output $obj
            }
            else {
                Write-Debug "[Get-JiraProject] No results were returned from Jira"
                Write-Debug "[Get-JiraProject] No project results were returned from Jira"
            }
        }
    }

    end {
        Write-Verbose "[$($MyInvocation.MyCommand.Name)] Complete"
    }
}
