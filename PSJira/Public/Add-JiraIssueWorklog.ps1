function Add-JiraIssueWorklog
{
    <#
    .Synopsis
       Adds a worklog item to an existing JIRA issue
    .DESCRIPTION
       This function adds a worklog item to an existing issue in JIRA. You can optionally set the visibility of the item (All Users, Developers, or Administrators).
    .EXAMPLE
       Add-JiraIssueWorklog -Comment "Test comment" -Issue "TEST-001" -TimeSpent 60 -DateStarted (Get-Date)
       This example adds a simple worklog item to the issue TEST-001.
    .EXAMPLE
       Get-JiraIssue "TEST-002" | Add-JiraIssueWorklog "Test worklog item from PowerShell" -TimeSpent 60 -DateStarted (Get-Date)
       This example illustrates pipeline use from Get-JiraIssue to Add-JiraIssueWorklog.
    .EXAMPLE
       Get-JiraIssue -Query 'project = "TEST" AND created >= -5d' | % { Add-JiraIssueWorklog "This issue has been cancelled per Vice President's orders." -TimeSpent 60 -DateStarted (Get-Date)}
       This example illustrates logging work on all projects which match a given JQL query. It would be best to validate the query first to make sure the query returns the expected issues!
    .EXAMPLE
       $comment = Get-Process | Format-Jira
       Add-JiraIssueWorklog $c -Issue TEST-003 -TimeSpent 60 -DateStarted (Get-Date)
       This example illustrates adding a comment based on other logic to a JIRA issue.  Note the use of Format-Jira to convert the output of Get-Process into a format that is easily read by users.
    .INPUTS
       This function can accept PSJira.Issue objects via pipeline.
    .OUTPUTS
       This function outputs the PSJira.Worklogitem object created.
    .NOTES
       This function requires either the -Credential parameter to be passed or a persistent JIRA session. See New-JiraSession for more details.  If neither are supplied, this function will run with anonymous access to JIRA.
    #>
    [CmdletBinding()]
    param(
        # Worklog item that should be added to JIRA
        [Parameter(Mandatory = $true,
                   Position = 0)]
        [String] $Comment,

        # Issue to receive the new worklog item
        [Parameter(Mandatory = $true,
                   Position = 1,
                   ValueFromPipeline = $true,
                   ValueFromPipelineByPropertyName = $true)]
        [Alias('Key')]
        [Object] $Issue,

        # Time spent to be logged
        [Parameter(Mandatory = $true,
                   Position = 2,
                   ValueFromPipeline = $true,
                   ValueFromPipelineByPropertyName = $true)]
        [TimeSpan] $TimeSpent,

        # Date/time started to be logged
        [Parameter(Mandatory = $true,
                   Position = 3,
                   ValueFromPipeline = $true,
                   ValueFromPipelineByPropertyName = $true)]
        [DateTime] $DateStarted,

        # Visibility of the comment - should it be publicly visible, viewable to only developers, or only administrators?
        [ValidateSet('All Users','Developers','Administrators')]
        [String] $VisibleRole = 'Developers',

        # Credentials to use to connect to Jira. If not specified, this function will use
        [Parameter(Mandatory = $false)]
        [System.Management.Automation.PSCredential] $Credential
    )

    begin
    {
        Write-Debug "[Add-JiraIssueWorklog] Begin"
        # We can't validate pipeline input here, since pipeline input doesn't exist in the Begin block.
    }

    process
    {
        Write-Debug "[Add-JiraIssueWorklog] Checking Issue parameter"
        if ($Issue.PSObject.TypeNames[0] -eq 'PSJira.Issue')
        {
            Write-Debug "[Add-JiraIssueWorklog] Issue parameter is a PSJira.Issue object"
            $issueObj = $Issue
        } else {
            $issueKey = $Issue.ToString()
            Write-Debug "[Add-JiraIssueWorklog] Issue key is assumed to be [$issueKey] via ToString()"
            Write-Verbose "Searching for issue [$issueKey]"
            try
            {
                $issueObj = Get-JiraIssue -Key $issueKey -Credential $Credential
            } catch {
                $err = $_
                Write-Debug 'Encountered an error searching for Jira issue. An exception will be thrown.'
                throw $err
            }
        }

        if (-not $issueObj)
        {
            Write-Debug "[Add-JiraIssueWorklog] No Jira issues were found for parameter [$Issue]. An exception will be thrown."
            throw "Unable to identify Jira issue [$Issue]. Does this issue exist?"
        }

        #Write-Debug "[Add-JiraIssueWorklog] Obtaining a reference to Jira issue [$Issue]"
        #$issueObj = Get-JiraIssue -InputObject $Issue -Credential $Credential

        $url = "$($issueObj.RestURL)/worklog"

        Write-Debug "[Add-JiraIssueWorklog] Creating request body from comment"
        $props = @{
            'comment' = $Comment;
            'started' = $DateStarted.ToString();
            'timeSpent' = $TimeSpent.TotalSeconds.ToString();
        }



        # If the visible role should be all users, the visibility block shouldn't be passed at
        # all. JIRA returns a 500 Internal Server Error if you try to pass this block with a
        # value of "All Users".
        if ($VisibleRole -ne 'All Users')
        {
            $props.visibility = @{
                'type' = 'role';
                'value' = $VisibleRole;
            }
        }

        Write-Debug "[Add-JiraIssueWorklog] Converting to JSON"
        $json = ConvertTo-Json -InputObject $props

        Write-Debug "[Add-JiraIssueWorklog] Preparing for blastoff!! $json"
        $rawResult = Invoke-JiraMethod -Method Post -URI $url -Body $json -Credential $Credential

        Write-Debug "[Add-JiraIssueWorklog] Converting to custom object"
        $result = ConvertTo-JiraWorklogitem -InputObject $rawResult

        Write-Debug "[Add-JiraIssueWorklog] Outputting result"
        Write-Output $result
    }

    end
    {
        Write-Debug "[Add-JiraIssueWorklog] Complete"
    }
}


