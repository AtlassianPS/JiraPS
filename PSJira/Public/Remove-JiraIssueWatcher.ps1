function Remove-JiraIssueWatcher
{
    <#
    .Synopsis
       Removes a watcher from an existing JIRA issue
    .DESCRIPTION
       This function removes a watcher from an existing issue in JIRA.
    .EXAMPLE
       Remove-JiraIssueWatcher -Watcher "fred" -Issue "TEST-001"
       This example removes a watcher from the issue TEST-001.
    .EXAMPLE
       Get-JiraIssue "TEST-002" | Remove-JiraIssueWatcher "fred"
       This example illustrates pipeline use from Get-JiraIssue to Remove-JiraIssueWatcher.
    .EXAMPLE
       Get-JiraIssue -Query 'project = "TEST" AND created >= -5d' | % { Remove-JiraIssueWatcher "fred" }
       This example illustrates removing watcher on all projects which match a given JQL query. It would be best to validate the query first to make sure the query returns the expected issues!
    .INPUTS
       This function can accept PSJira.Issue objects via pipeline.
    .OUTPUTS
       This function does not provide output.
    .NOTES
       This function requires either the -Credential parameter to be passed or a persistent JIRA session. See New-JiraSession for more details.  If neither are supplied, this function will run with anonymous access to JIRA.
    #>
    [CmdletBinding()]
    param(
        # Watcher that should be removed from JIRA
        [Parameter(Mandatory = $true,
                   Position = 0)]
        [string[]] $Watcher,

        # Issue that should be updated
        [Parameter(Mandatory = $true,
                   Position = 1,
                   ValueFromPipeline = $true,
                   ValueFromPipelineByPropertyName = $true)]
        [Alias('Key')]
        [Object] $Issue,

        # Credentials to use to connect to Jira. If not specified, this function will use
        [Parameter(Mandatory = $false)]
        [System.Management.Automation.PSCredential] $Credential
    )

    begin
    {
        Write-Debug "[Remove-JiraIssueWatcher] Begin"
        # We can't validate pipeline input here, since pipeline input doesn't exist in the Begin block.
    }

    process
    {
#        Write-Debug "[Remove-JiraIssueWatcher] Checking Issue parameter"
#        if ($Issue.PSObject.TypeNames[0] -eq 'PSJira.Issue')
#        {
#            Write-Debug "[Remove-JiraIssueWatcher] Issue parameter is a PSJira.Issue object"
#            $issueObj = $Issue
#        } else {
#            $issueKey = $Issue.ToString()
#            Write-Debug "[Remove-JiraIssueWatcher] Issue key is assumed to be [$issueKey] via ToString()"
#            Write-Verbose "Searching for issue [$issueKey]"
#            try
#            {
#                $issueObj = Get-JiraIssue -Key $issueKey -Credential $Credential
#            } catch {
#                $err = $_
#                Write-Debug 'Encountered an error searching for Jira issue. An exception will be thrown.'
#                throw $err
#            }
#        }
#
#        if (-not $issueObj)
#        {
#            Write-Debug "[Remove-JiraIssueWatcher] No Jira issues were found for parameter [$Issue]. An exception will be thrown."
#            throw "Unable to identify Jira issue [$Issue]. Does this issue exist?"
#        }

        Write-Debug "[Remove-JiraIssueWatcher] Obtaining a reference to Jira issue [$Issue]"
        $issueObj = Get-JiraIssue -InputObject $Issue -Credential $Credential

        foreach ($w in $Watcher) {
            $url = "$($issueObj.RestURL)/watchers?username=$w"

            Write-Debug "[Remove-JiraIssueWatcher] Preparing for blastoff!"
            $rawResult = Invoke-JiraMethod -Method Delete -URI $url -Credential $Credential
        }
    }

    end
    {
        Write-Debug "[Remove-JiraIssueWatcher] Complete"
    }
}


