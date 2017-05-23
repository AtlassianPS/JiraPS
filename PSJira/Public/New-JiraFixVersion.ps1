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
            .INPUTS
            This function does not accept pipeline input.
            .OUTPUTS
            [PSJira.FixVersions] The FixVersion field object created
    #>
    [CmdletBinding(DefaultParameterSetName = 'Release')]
    param(
        [Parameter(Mandatory = $true,
        Position = 0)]
        [Alias('FixVersions')]
        [String] $FixVersion,

        [Parameter(Mandatory = $true)]
        [String] $Description,

        [Parameter()]
        [switch] $Archived,

        [Parameter()]
        [switch] $Released,

        [Parameter(ParameterSetName = 'Release')]
        [String] $ReleaseDate,

        [Parameter(ParameterSetName = 'UserRelease')]
        [String] $UserReleaseDate,

        # Project Key
        [Parameter(Mandatory = $true)]
        [String] $Project,

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
}

