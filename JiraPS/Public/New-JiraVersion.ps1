function New-JiraVersion
{
    <#
    .Synopsis
        Creates a new FixVersion in JIRA
     .DESCRIPTION
         This function creates a new FixVersion in JIRA.
     .EXAMPLE
        New-JiraVersion -FixVersion '1.0.0.0'
        This example creates a new JIRA FixVersion named '1.0.0.0'.
	.EXAMPLE
        New-JiraVersion -FixVersion '1.0.0.0' -Project TEST
        This example creates a new JIRA FixVersion named '1.0.0.0' in Project TEST.
    .EXAMPLE
        New-JiraVersion -FixVersion '1.0.0.0' -Project TEST -ReleaseDate "2000-12-31"
        Create a new Version in Project TEST with a set release date.
     .OUTPUTS
        [PSJira.Version]
     .NOTES
       This function requires either the -Credential parameter to be passed or a persistent JIRA session. See New-JiraSession for more details.  If neither are supplied, this function will run with anonymous access to JIRA.
    #>
    [CmdletBinding(DefaultParameterSetName = 'ProjectID')]
    param(
        # Name of the version to create.
        [Parameter(Mandatory = $true,
        ValueFromPipelineByPropertyName=$true,
            Position = 0)]
        [Alias('FixVersions','Versions')]
        [String] $Name,

        # Description of the version.
        [Parameter(Mandatory = $false)]
        [String] $Description,

        # Create the version as archived.
        [Parameter(Mandatory = $false,
            ValueFromPipelineByPropertyName=$true)]
        [bool] $Archived,

        # Create the version as released.
        [Parameter(Mandatory = $false,
            ValueFromPipelineByPropertyName=$true)]
        [bool] $Released,

        # Date of the release.
        [Parameter(Mandatory = $false,
            ValueFromPipelineByPropertyName=$true)]
        [DateTime] $ReleaseDate,

        # Date of the user release.
        [Parameter(Mandatory = $false,
            ValueFromPipelineByPropertyName=$true)]
        [DateTime] $UserReleaseDate,

        # The Project ID
        [Parameter(Mandatory = $true,
                    ValueFromPipelineByPropertyName=$true,
                    ParameterSetName = 'ProjectID')]
        [String] $ProjectID,

        # The Project Key
        [Parameter(Mandatory = $true,
                    ValueFromPipelineByPropertyName=$true,
                    ParameterSetName = 'Key')]
        [String] $Project,

        # Credentials to use to connect to Jira.
        [Parameter(Mandatory = $false)]
        [PSCredential] $Credential
    )

    begin
    {
        Write-Debug -Message '[New-JiraVersion] Reading information from config file'
        try
        {
            Write-Debug -Message '[New-JiraVersion] Reading Jira server from config file'
            $server = Get-JiraConfigServer -ConfigFile $ConfigFile -ErrorAction Stop
        }
        catch
        {
            $err = $_
            Write-Debug -Message '[New-JiraVersion] Encountered an error reading configuration data.'
            throw $err
        }

        $restUrl = "$server/rest/api/latest/version"
        Write-Debug "[New-JiraVersion] Rest URL set to [$restUrl]."

        Write-Debug "[New-JiraVersion] Completed Begin block."
    }

    process
    {
        Switch($PSCmdlet.ParameterSetName)
        {
            'Key'
            {
                $ProjectData = Get-JiraProject -Project $Project
            }
            'ProjectID'
            {
                $ProjectData = @{}
                $ProjectData.ID = $ProjectID
            }
        }
        Write-Debug -Message '[New-JiraVersion] Defining properties'
        $props = @{
            description = $Description
            name        = $Name
            archived    = $Archived
            released    = $Released
            project     = $ProjectData.Key
            projectId   = $ProjectData.ID
        }
        If($UserReleaseDate)
        {
            $formatedUserReleaseDate = Get-Date $UserReleaseDate -Format 'd/MMM/yy'
            $props.userReleaseDate = $formatedUserReleaseDate
        }
        If($ReleaseDate)
        {
            $formatedReleaseDate = Get-Date $ReleaseDate -Format 'yyyy-MM-dd'
            $props.releaseDate = $formatedReleaseDate
        }

        Write-Debug -Message '[New-JiraVersion] Converting to JSON'
        $json = ConvertTo-Json -InputObject $props

        Write-Debug -Message '[New-JiraVersion] Preparing for blastoff!'
        $result = Invoke-JiraMethod -Method Post -URI $restUrl -Body $json -Credential $Credential

        If ($result)
        {
            Write-Output -InputObject $result
        }
        Else
        {
            Write-Debug -Message '[New-JiraVersion] Jira returned no results to output.'
        }
    }

    end
    {
        Write-Debug "[New-JiraVersion] Complete"
    }
}
