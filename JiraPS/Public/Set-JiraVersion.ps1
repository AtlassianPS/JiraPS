function Set-JiraVersion {
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
    [CmdletBinding()]
    param(
        # Issue key or PSJira.Issue object returned from Get-JiraIssue
        [Parameter(Mandatory = $true,
            Position = 0,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true)]
        [Alias('Key')]
        [Object[]] $Issue,

        # Set the FixVersion of the issue, this will overwrite any present FixVersions
        [Parameter(Mandatory = $True)]
        [Alias('FixVersions')]
        [String[]] $Name,

        # Credentials to use to connect to Jira
        [Parameter(Mandatory = $false)]
        [System.Management.Automation.PSCredential] $Credential
    )

    begin {
        Write-Debug -Message '[Set-JiraVersion] Reading information from config file'
        try {
            Write-Debug -Message '[Set-JiraVersion] Reading Jira server from config file'
            $server = Get-JiraConfigServer -ConfigFile $ConfigFile -ErrorAction Stop
        }
        catch {
            $err = $_
            Write-Debug -Message '[Set-JiraVersion] Encountered an error reading configuration data.'
            throw $err
        }

        Write-Debug "[Set-JiraVersion] Completed Begin block."
    }

    process {
        foreach ($i in $Issue) {
            Write-Debug "[Set-JiraVersion] Calling [ Set-JiraIssue -Issue $i -FixVersion $Name ]."
            Set-JiraIssue -Issue $i -FixVersion $Name
        }
    }

    end {
        Write-Debug "[Set-JiraVersion] Complete"
    }
}
