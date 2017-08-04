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
    [CmdletBinding(DefaultParameterSetName = 'byId')]
    param(
        # Project key of a project to search
        [Parameter(
            Position = 0,
            Mandatory = $true,
            ParameterSetName = 'byProject',
            ValueFromPipelineByPropertyName = $true
        )]
        [Alias('Key')]
        [String[]] $Project,

        # Jira Version Name
        [Parameter(
            Mandatory = $false,
            ParameterSetName = 'byProject'
        )]
        [Alias('Versions')]
        [String[]] $Name,

        # The Version ID
        [Parameter(
            Mandatory = $true,
            ParameterSetName = 'byId',
            ValueFromPipelineByPropertyName = $true
        )]
        [Int[]] $Id,

        # Credentials to use to connect to Jira
        [Parameter(Mandatory = $false)]
        [System.Management.Automation.PSCredential] $Credential
    )
    begin {
        Write-Debug "[Get-JiraVersion] Reading server from config file"
        $server = Get-JiraConfigServer -ConfigFile $ConfigFile -ErrorAction Stop

        Write-Debug "[Get-JiraVersion] Completed Begin block."
    }
    process {
        Switch ($PSCmdlet.ParameterSetName) {
            'byProject' {
                foreach ($_project in $Project) {
                    Write-Debug "[Get-JiraVersion] Gathering project data for [$_project]."
                    $projectData = Get-JiraProject -Project $_project
                    $restUrl = "$server/rest/api/latest/project/$($projectData.key)/versions"

                    Write-Debug -Message '[Get-JiraVersion] Preparing for blastoff!'
                    $result = Invoke-JiraMethod -Method Get -URI $restUrl -Credential $Credential

                    If ($Name) {
                        $result = $result | Where-Object {$_.Name -in $Name}
                    }
                    $result | ConvertTo-JiraVersion
                }
            }
            'byId' {
                foreach ($_id in $ID) {
                    $restUrl = "$server/rest/api/latest/version/$_id"

                    Write-Debug -Message '[Get-JiraVersion] Preparing for blastoff!'
                    Invoke-JiraMethod -Method Get -URI $restUrl -Credential $Credential | ConvertTo-JiraVersion
                }
            }
        }
    }
    end {
        Write-Debug "[Get-JiraVersion] Complete"
    }
}
