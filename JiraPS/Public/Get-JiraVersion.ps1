function Get-JiraVersion
{
    <#
    .Synopsis
       This function returns information about a JIRA Project's Version
    .DESCRIPTION
       This function provides information about JIRA Version
    .EXAMPLE
       Get-JiraVersion -Project $ProjectKey -Name '1.0.0.0'
       This example returns information about all JIRA Version visible to the current user (or using anonymous access if a PSJira session has not been defined) for the project.
    .EXAMPLE
       Get-JiraVersion -ID '66596'
       This example returns information about all JIRA Version visible to the current user (or using anonymous access if a PSJira session has not been defined) for the project.
    .INPUTS
        [PSJira.Project]
    .OUTPUTS
       This function outputs a PSobject(s).
    .NOTES
       This function requires either the -Credential parameter to be passed or a persistent JIRA session. See New-JiraSession for more details.  If neither are supplied, this function will run with anonymous access to JIRA.
    #>
    [CmdletBinding(DefaultParameterSetName = 'Key')]
    param(
        # Project key of a project to search
        [Parameter(Mandatory = $true,
                    ParameterSetName = 'Key',
                    Position = 0,
                    ValueFromPipelineByPropertyName=$true)]
        [Alias('Key')]
        [String] $Project,

        # Jira Version Name
        [Parameter(Mandatory = $false,
                    ParameterSetName = 'Key')]
        [Alias('Versions')]
        [string] $Name,

        # The Version ID
        [Parameter(Mandatory = $true,
                    ParameterSetName = 'VersionID')]
        [String] $ID,

        # Credentials to use to connect to Jira
        [Parameter(Mandatory = $false)]
        [System.Management.Automation.PSCredential] $Credential
    )
    begin
    {
        Write-Debug "[Get-JiraVersion] Reading server from config file"
        try
        {
            Write-Debug -Message '[Get-JiraVersion] Reading Jira server from config file'
            $server = Get-JiraConfigServer -ConfigFile $ConfigFile -ErrorAction Stop
        }
        catch
        {
            $err = $_
            Write-Debug -Message '[Get-JiraVersion] Encountered an error reading configuration data.'
            throw $err
        }

        Write-Debug "[Get-JiraVersion] Completed Begin block."
    }
    process
    {
        Switch($PSCmdlet.ParameterSetName)
        {
            'Key'
            {
                Write-Debug "[Get-JiraVersion] Gathering project data for [$Project]."
                $ProjectData = Get-JiraProject -Project $Project
                $restUrl = "$server/rest/api/2/project/$($projectData.key)/versions"
            }
            'VersionID'
            {
                $restUrl = "$server/rest/api/2/version/$ID"
            }
        }
        Write-Debug "[Get-JiraVersion] Rest URL set to $restUrl."

        Write-Debug -Message '[Get-JiraVersion] Preparing for blastoff!'
        $result = Invoke-JiraMethod -Method Get -URI $restUrl -Credential $Credential

        If ($result)
        {
            If ($Name)
            {
                $result = $result | Where-Object {$PSItem.Name -eq $Name}
            }
            Write-Output -InputObject $result
        }Else
        {
            Write-Debug -Message '[Get-JiraVersion] Jira returned no results to output.'
        }
    }
    end
    {
        Write-Debug "[Get-JiraVersion] Complete"
    }
}
