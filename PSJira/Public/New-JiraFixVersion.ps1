function New-JiraFixVersion
{
    <#
    .Synopsis
        Creates a new FixVersion in JIRA
     .DESCRIPTION
         This function creates a new FixVersion in JIRA.
     .EXAMPLE
        New-JiraFixVersion -FixVersion '1.0.0.0'
        This example creates a new JIRA FixVersion named '1.0.0.0'.
        New-JiraFixVersion -FixVersion '1.0.0.0' -Project TEST
        This example creates a new JIRA FixVersion named '1.0.0.0' in Project TEST.
    .EXAMPLE
        New-JiraFixVersion -FixVersion '1.0.0.0' -Project TEST -ReleaseDate "2000-12-31"
        Create a new Version in Project TEST with a set release date.
     .INPUTS
         This function does not accept pipeline input.
     .OUTPUTS
        [PSJira.FixVersions] The FixVersion field object created
    #>
    [CmdletBinding(DefaultParameterSetName = 'Release')]
    param(
        # Name of the version to create.
        [Parameter(Mandatory = $true,
            Position = 0)]
        [Alias('FixVersions')]
        [String] $FixVersion,

        # Description of the version.
        [Parameter(Mandatory = $false)]
        [String] $Description,

        # Create the version as archived.
        [Parameter()]
        [switch] $Archived,

        # Create the version as released.
        [Parameter()]
        [switch] $Released,

        # Date of the release.
        [Parameter(ParameterSetName = 'Release')]
        [String] $ReleaseDate,

        # Date of the user release.
        [Parameter(ParameterSetName = 'UserRelease')]
        [String] $UserReleaseDate,

        # Key of the Project in which to create the version.
        [Parameter(Mandatory = $true)]
        [String] $Project,

        # Credentials to use to connect to Jira.
        [Parameter(Mandatory = $false)]
        [PSCredential] $Credential
    )

    begin
    {
        Write-Debug -Message '[New-JiraFixVersion] Reading information from config file'
        try
        {
            Write-Debug -Message '[New-JiraFixVersion] Reading Jira server from config file'
            $server = Get-JiraConfigServer -ConfigFile $ConfigFile -ErrorAction Stop
        }
        catch
        {
            $err = $_
            Write-Debug -Message '[New-JiraFixVersion] Encountered an error reading configuration data.'
            throw $err
        }

        $restUrl = "$server/rest/api/latest/version"
        Write-Debug "[New-JiraFixVersion] Rest URL set to [$restUrl]."

        Write-Debug "[New-JiraFixVersion] Completed Begin block."
    }

    process
    {
        $ProjectData = Get-JiraProject -Project $Project
        Write-Debug -Message '[New-JiraFixVersion] Defining properties'
        $props = @{
            description = $Description
            name        = $FixVersion
            archived    = $Archived.IsPresent
            released    = $Released.IsPresent
            project     = $ProjectData.Key
            projectId   = $ProjectData.ID
        }
        If($UserReleaseDate)
        {
            $props.releaseDate = $ReleaseDate
        }
        If($ReleaseDate)
        {
            $props.userReleaseDate = $UserReleaseDate
        }

        Write-Debug -Message '[New-JiraFixVersion] Converting to JSON'
        $json = ConvertTo-Json -InputObject $props

        Write-Debug -Message '[New-JiraFixVersion] Preparing for blastoff!'
        $result = Invoke-JiraMethod -Method Post -URI $restUrl -Body $json -Credential $Credential

        If ($result)
        {
            Write-Output -InputObject $result
        }
        Else
        {
            Write-Debug -Message '[New-JiraFixVersion] Jira returned no results to output.'
        }
    }

    end
    {
        Write-Debug "[New-JiraFixVersion] Complete"
    }
}
