function Remove-JiraFixVersion
{
    <#
    .Synopsis
       This function modifies an existing issue in JIRA.
    .DESCRIPTION
       This function removes a fixVersion from an existing issue in JIRA.
    .EXAMPLE
       Remove-JiraFixVersion -Issue $IssueKey -FixVersion 1.0.0.0
       This example removes the fixversion given, if the version does not exisist no errors will be thrown.
    .INPUTS
       This function does accept pipeline input.
    .OUTPUTS
       This Function outputs no results
    .NOTES
       This function requires either the -Credential parameter to be passed or a persistent JIRA session. See New-JiraSession for more details.  If neither are supplied, this function will run with anonymous access to JIRA.
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
        [String[]] $FixVersion,

        # Credentials to use to connect to Jira
        [Parameter(Mandatory = $false)]
        [System.Management.Automation.PSCredential] $Credential
    )

    begin
    {
        Write-Debug -Message '[Remove-JiraFixVersion] Reading information from config file'
        try
        {
            Write-Debug -Message '[Remove-JiraFixVersion] Reading Jira server from config file'
            $server = Get-JiraConfigServer -ConfigFile $ConfigFile -ErrorAction Stop
        }
        catch
        {
            $err = $_
            Write-Debug -Message '[Remove-JiraFixVersion] Encountered an error reading configuration data.'
            throw $err
        }

        Write-Debug "[Remove-JiraFixVersion] Completed Begin block."
    }


    process
    {
        foreach ($i in $Issue)
        {
            $issue = Get-JiraIssue -Key $i
            $RemainingFixVersions = $Issue.fixVersions | Where-Object {$PSItem.Name -NE $FixVersion}
            Write-Debug "[Set-JiraFixVersion] Calling [ Set-JiraIssue -Issue $i -FixVersion $FixVersion ]."
            Set-JiraIssue -Issue $i -FixVersion $RemainingFixVersions.name
        }
    }

    end
    {
        Write-Debug "[Remove-JiraFixVersion] Complete"
    }
}
