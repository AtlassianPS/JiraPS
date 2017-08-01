﻿function Set-JiraVersion
{
    <#
    .Synopsis
        Modifies an existing issue in JIRA
    .DESCRIPTION
        This function modifies the FixVersion field for an existing issue in JIRA.
    .EXAMPLE
        Set-JiraVersion -Issue TEST-01 -FixVersion '1.0.0.0'
        This example assigns the fixversion 1.0.0.0 to the JIRA issue TEST-01.
    .INPUTS
        [PSJira.Issue[]] The JIRA issue that should be modified
    .OUTPUTS
        No Output on success
    #>
    [CmdletBinding(DefaultParameterSetName = 'ProjectID')]
    param(
        # Name of the version to create.
        [Parameter(Mandatory = $true,
            Position = 0,
            ValueFromPipelineByPropertyName=$true)]
        [Alias('FixVersions')]
        [String] $Name,

        # Description of the version.
        [Parameter(Mandatory = $false,
            ValueFromPipelineByPropertyName=$true)]
        [String] $Description,

        # Create the version as archived.
        [Parameter(,
            ValueFromPipelineByPropertyName=$true)]
        [bool] $Archived,

        # Create the version as released.
        [Parameter(ValueFromPipelineByPropertyName=$true)]
        [bool] $Released,

        # Date of the release.
        [Parameter(ValueFromPipelineByPropertyName=$true)]
        [datetime] $ReleaseDate,

        # Date of the user release.
        [Parameter(ValueFromPipelineByPropertyName=$false)]
        [datetime] $UserReleaseDate,

        # The Version ID
        [Parameter(Mandatory = $true,
                    ValueFromPipelineByPropertyName=$true)]
        [String] $ID,

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

        # The Version URL
        [Parameter(Mandatory = $true,
                    ValueFromPipelineByPropertyName=$true)]
        [Alias('Self')]
        [String] $RestURL,

        # Credentials to use to connect to Jira.
        [Parameter(Mandatory = $false,
            ValueFromPipelineByPropertyName=$true)]
        [PSCredential] $Credential
    )

    begin
    {
        Write-Debug -Message '[Set-JiraVersion] Reading information from config file'
        try
        {
            Write-Debug -Message '[Set-JiraVersion] Reading Jira server from config file'
            $server = Get-JiraConfigServer -ConfigFile $ConfigFile -ErrorAction Stop
        }
        catch
        {
            $err = $_
            Write-Debug -Message '[Set-JiraVersion] Encountered an error reading configuration data.'
            throw $err
        }

        Write-Debug "[Set-JiraVersion] Completed Begin block."
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
        
        $restUrl = "$server/rest/api/2/version/$ID"
        Write-Debug "[Set-JiraVersion] Rest URL set to [$restUrl]."
        
        $props = @{
            id = $ID
            description = $Description
            name        = $Name
            archived    = $Archived
            released    = $Released
            projectId   = $ProjectData.ID
            self = $RestURL
        }
        Write-Debug -Message '[Set-JiraVersion] Defining properties'

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

        Write-Debug -Message '[Set-JiraVersion] Converting to JSON'
        $json = ConvertTo-Json -InputObject $props

        Write-Debug -Message '[Set-JiraVersion] Preparing for blastoff!'
        $result = Invoke-JiraMethod -Method Put -URI $restUrl -Body $json -Credential $Credential

        If ($result)
        {
            Write-Output -InputObject $result
        }
        Else
        {
            Write-Debug -Message '[Set-JiraVersion] Jira returned no results to output.'
        }
    }

    end
    {
        Write-Debug "[Set-JiraVersion] Complete"
    }
}
