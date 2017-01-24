function Add-JiraIssueWatcher
{
    <#
    .Synopsis
       Adds a watcher to an existing JIRA issue
    .DESCRIPTION
       This function adds a watcher to an existing issue in JIRA.
    .EXAMPLE
       Add-JiraIssueWatcher -Watcher "fred" -Issue "TEST-001"
       This example adds a watcher to the issue TEST-001.
    .EXAMPLE
       Get-JiraIssue "TEST-002" | Add-JiraIssueWatcher "fred"
       This example illustrates pipeline use from Get-JiraIssue to Add-JiraIssueWatcher.
    .EXAMPLE
       Get-JiraIssue -Query 'project = "TEST" AND created >= -5d' | % { Add-JiraIssueWatcher "fred" }
       This example illustrates adding watcher on all projects which match a given JQL query. It would be best to validate the query first to make sure the query returns the expected issues!
    .INPUTS
       This function can accept PSJira.Issue objects via pipeline.
    .OUTPUTS
       This function does not provide output.
    .NOTES
       This function requires either the -Credential parameter to be passed or a persistent JIRA session. See New-JiraSession for more details.  If neither are supplied, this function will run with anonymous access to JIRA.
    #>
    [CmdletBinding()]
    param(
        # Watcher that should be added to JIRA
        [Parameter(Mandatory = $true,
                   Position = 0)]
        [string[]] $Watcher,

        # Issue that should be watched
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
        Write-Debug "[Add-JiraIssueWatcher] Begin"
        # We can't validate pipeline input here, since pipeline input doesn't exist in the Begin block.
    }

    process
    {
#        Write-Debug "[Add-JiraIssueWatcher] Checking Issue parameter"
#        if ($Issue.PSObject.TypeNames[0] -eq 'PSJira.Issue')
#        {
#            Write-Debug "[Add-JiraIssueWatcher] Issue parameter is a PSJira.Issue object"
#            $issueObj = $Issue
#        } else {
#            $issueKey = $Issue.ToString()
#            Write-Debug "[Add-JiraIssueWatcher] Issue key is assumed to be [$issueKey] via ToString()"
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
#            Write-Debug "[Add-JiraIssueWatcher] No Jira issues were found for parameter [$Issue]. An exception will be thrown."
#            throw "Unable to identify Jira issue [$Issue]. Does this issue exist?"
#        }

        Write-Debug "[Add-JiraIssueWatcher] Obtaining a reference to Jira issue [$Issue]"
        $issueObj = Get-JiraIssue -InputObject $Issue -Credential $Credential

        $url = "$($issueObj.RestURL)/watchers"

        foreach ($w in $Watcher) {
            $body = """$w"""

            Write-Debug "[Add-JiraIssueWatcher] Preparing for blastoff!"
            $rawResult = Invoke-JiraMethod -Method Post -URI $url -Body $body -Credential $Credential
        }
    }

    end
    {
        Write-Debug "[Add-JiraIssueWatcher] Complete"
    }
}


