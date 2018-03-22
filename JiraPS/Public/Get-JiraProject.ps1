function Get-JiraProject {
    <#
    .SYNOPSIS
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
    [CmdletBinding( DefaultParameterSetName = '_All' )]
    param(
        # The Project ID or project key of a project to search.
        [Parameter( Position = 0, Mandatory, ValueFromPipeline, ParameterSetName = '_Search' )]
        [String[]]
        $Project,

        # Credentials to use to connect to JIRA.
        # If not specified, this function will use anonymous access.
        [PSCredential]
        $Credential
    )

    begin {
        Write-Verbose "[$($MyInvocation.MyCommand.Name)] Function started"

        $server = Get-JiraConfigServer -ErrorAction Stop

        $resourceURi = "$server/rest/api/latest/project{0}?expand=description,lead,issueTypes,url,projectKeys"
    }

    process {
        Write-DebugMessage "[$($MyInvocation.MyCommand.Name)] ParameterSetName: $($PsCmdlet.ParameterSetName)"
        Write-DebugMessage "[$($MyInvocation.MyCommand.Name)] PSBoundParameters: $($PSBoundParameters | Out-String)"

        switch ($PSCmdlet.ParameterSetName) {
            '_All' {
                $parameter = @{
                    URI        = $resourceURi -f ""
                    Method     = "GET"
                    Credential = $Credential
                }
                Write-Debug "[$($MyInvocation.MyCommand.Name)] Invoking JiraMethod with `$parameter"
                $result = Invoke-JiraMethod @parameter

                Write-Output (ConvertTo-JiraProject -InputObject $result)
            }
            '_Search' {
                foreach ($_project in $Project) {
                    Write-Verbose "[$($MyInvocation.MyCommand.Name)] Processing [$_project]"
                    Write-Debug "[$($MyInvocation.MyCommand.Name)] Processing `$_project [$_project]"

                    $parameter = @{
                        URI        = $resourceURi -f "/$($_project)"
                        Method     = "GET"
                        Credential = $Credential
                    }
                    Write-Debug "[$($MyInvocation.MyCommand.Name)] Invoking JiraMethod with `$parameter"
                    $result = Invoke-JiraMethod @parameter

                    Write-Output (ConvertTo-JiraProject -InputObject $result)
                }
            }
        }
    }

    end {
        Write-Verbose "[$($MyInvocation.MyCommand.Name)] Complete"
    }
}
