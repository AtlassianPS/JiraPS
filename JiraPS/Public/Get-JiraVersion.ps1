function Get-JiraVersion {
    <#
    .Synopsis
       This function returns information about a JIRA Project's Version
    .DESCRIPTION
       This function provides information about JIRA Version
    .EXAMPLE
       Get-JiraVersion -Project $ProjectKey
       This example returns information about all JIRA Version visible to the current user for the project.
    .EXAMPLE
       Get-JiraVersion -Project $ProjectKey -Name '1.0.0.0'
       This example returns the information of a specific Version.
    .EXAMPLE
       Get-JiraVersion -ID '66596'
       This example returns information about all JIRA Version visible to the current user (or using anonymous access if a JiraPS session has not been defined) for the project.
    .INPUTS
        [JiraPS.Project]
    .OUTPUTS
       [JiraPS.Version]
    .LINK
        New-JiraVersion
    .LINK
        Remove-JiraVersion
    .LINK
        Set-JiraVersion
    .LINK
        Get-JiraProject
    .NOTES
       This function requires either the -Credential parameter to be passed or a persistent JIRA session. See New-JiraSession for more details.  If neither are supplied, this function will run with anonymous access to JIRA.
    #>
    [CmdletBinding( DefaultParameterSetName = 'byId' )]
    param(
        # Project key of a project to search
        [Parameter( Position = 0, Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName, ParameterSetName = 'byProject' )]
        [Alias('Key')]
        [String[]]
        $Project,

        # Jira Version Name
        [Parameter( ParameterSetName = 'byProject' )]
        [Alias('Versions')]
        [String[]]
        $Name,

        # The Version ID
        [Parameter( Mandatory, ValueFromPipelineByPropertyName, ParameterSetName = 'byId' )]
        [Int[]]
        $Id,

        # Credentials to use to connect to JIRA.
        # If not specified, this function will use anonymous access.
        [PSCredential]
        $Credential
    )

    begin {
        Write-Verbose "[$($MyInvocation.MyCommand.Name)] Function started"

        $server = Get-JiraConfigServer -ErrorAction Stop

        $resourceURi = "$server/rest/api/latest/{0}"
    }

    process {
        Write-DebugMessage "[$($MyInvocation.MyCommand.Name)] ParameterSetName: $($PsCmdlet.ParameterSetName)"
        Write-DebugMessage "[$($MyInvocation.MyCommand.Name)] PSBoundParameters: $($PSBoundParameters | Out-String)"

        Switch ($PSCmdlet.ParameterSetName) {
            'byProject' {
                foreach ($_project in $Project) {
                    Write-Verbose "[$($MyInvocation.MyCommand.Name)] Processing [$_project]"
                    Write-Debug "[$($MyInvocation.MyCommand.Name)] Processing `$_project [$_project]"

                    $projectData = Get-JiraProject -Project $_project -Credential $Credential

                    $parameter = @{
                        URI        = $resourceURi -f "project/$($projectData.key)/versions"
                        Method     = "GET"
                        Credential = $Credential
                    }
                    Write-Debug "[$($MyInvocation.MyCommand.Name)] Invoking JiraMethod with `$parameter"
                    $result = Invoke-JiraMethod @parameter

                    if ($Name) {
                        $result = $result | Where-Object {$_.Name -in $Name}
                    }

                    Write-Output (ConvertTo-JiraVersion -InputObject $result)
                }
            }
            'byId' {
                foreach ($_id in $ID) {
                    Write-Verbose "[$($MyInvocation.MyCommand.Name)] Processing [$_id]"
                    Write-Debug "[$($MyInvocation.MyCommand.Name)] Processing `$_id [$_id]"

                    $parameter = @{
                        URI        = $resourceURi -f "version/$_id"
                        Method     = "GET"
                        Credential = $Credential
                    }
                    Write-Debug "[$($MyInvocation.MyCommand.Name)] Invoking JiraMethod with `$parameter"
                    $result = Invoke-JiraMethod @parameter

                    Write-Output (ConvertTo-JiraVersion -InputObject $result)
                }
            }
        }
    }
    end {
        Write-Verbose "[$($MyInvocation.MyCommand.Name)] Complete"
    }
}
