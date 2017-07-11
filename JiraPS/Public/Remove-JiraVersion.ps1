function Remove-JiraVersion {
    <#
    .Synopsis
       This function removes an existing version.
    .DESCRIPTION
       This function removes an existing version in JIRA.
    .EXAMPLE
       Remove-JiraVersion -Name '1.0.0.0' -Project $Project
       This example removes the Version given.
    .EXAMPLE
       Remove-JiraVersion -ID '66596'
       This example removes the Version given.
    .INPUTS
       This function does not accept pipeline input pending class creation.
    .OUTPUTS
       This Function outputs no results
    .NOTES
       This function requires either the -Credential parameter to be passed or a persistent JIRA session. See New-JiraSession for more details.  If neither are supplied, this function will run with anonymous access to JIRA.
    #>
    [CmdletBinding(DefaultParameterSetName = 'Project')]
    param(
        # Jira Version Name
        [Parameter(Mandatory = $true,
            ParameterSetName = 'Project')]
        [Alias('Versions')]
        [string] $Name,

        # The Project ID or project key of a project to search
        [Parameter(Mandatory = $true,
            ParameterSetName = 'Project',
            Position = 0,
            ValueFromRemainingArguments = $true)]
        [String] $Project,

        # The Version ID
        [Parameter(Mandatory = $true,
            ParameterSetName = 'ID')]
        [String] $ID,

        # Credentials to use to connect to Jira
        [Parameter(Mandatory = $false)]
        [System.Management.Automation.PSCredential] $Credential
    )

    begin {
        Write-Debug -Message '[Remove-JiraVersion] Reading information from config file'
        try {
            Write-Debug -Message '[Remove-JiraVersion] Reading Jira server from config file'
            $server = Get-JiraConfigServer -ConfigFile $ConfigFile -ErrorAction Stop
        }
        catch {
            $err = $_
            Write-Debug -Message '[Remove-JiraVersion] Encountered an error reading configuration data.'
            throw $err
        }

        Write-Debug "[Remove-JiraVersion] Completed Begin block."
    }

    process {
        Switch ($PSCmdlet.ParameterSetName) {
            'Project' {
                $existingVersion = Get-JiraVersion -Project $Project | Where-Object {$PSItem.Name -eq $Name}
                $restUrl = $existingVersion.self
            }
            'ID' {
                $restUrl = "$server/rest/api/2/version/$ID"
            }
        }
        Write-Debug "[Get-JiraVersion] Rest URL set to $restUrl."

        Write-Debug -Message '[Remove-JiraVersion] Preparing for blastoff!'
        $result = Invoke-JiraMethod -Method Delete -URI $restUrl -Credential $Credential

        If ($result) {
            Write-Output -InputObject $result
        }
        Else {
            Write-Debug -Message '[Remove-JiraVersion] Jira returned no results to output.'
        }
    }

    end {
        Write-Debug "[Remove-JiraVersion] Complete"
    }
}
