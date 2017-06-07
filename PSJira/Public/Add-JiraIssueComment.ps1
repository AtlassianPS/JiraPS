function Add-JiraIssueComment
{
    <#
    .Synopsis
       Adds a comment to an existing JIRA issue
    .DESCRIPTION
       This function adds a comment to an existing issue in JIRA. You can optionally set the visibility of the comment (All Users, Developers, or Administrators).
    .EXAMPLE
       Add-JiraIssueComment -Comment "Test comment" -Issue "TEST-001"
       This example adds a simple comment to the issue TEST-001.
    .EXAMPLE
       Get-JiraIssue "TEST-002" | Add-JiraIssueComment "Test comment from PowerShell"
       This example illustrates pipeline use from Get-JiraIssue to Add-JiraIssueComment.
    .EXAMPLE
       Get-JiraIssue -Query 'project = "TEST" AND created >= -5d' | % { Add-JiraIssueComment "This issue has been cancelled per Vice President's orders." }
       This example illustrates commenting on all projects which match a given JQL query. It would be best to validate the query first to make sure the query returns the expected issues!
    .EXAMPLE
       $comment = Get-Process | Format-Jira
       Add-JiraIssueComment $c -Issue TEST-003
       This example illustrates adding a comment based on other logic to a JIRA issue.  Note the use of Format-Jira to convert the output of Get-Process into a format that is easily read by users.
    .INPUTS
       This function can accept PSJira.Issue objects via pipeline.
    .OUTPUTS
       This function outputs the PSJira.Comment object created.
    .NOTES
       This function requires either the -Credential parameter to be passed or a persistent JIRA session. See New-JiraSession for more details.  If neither are supplied, this function will run with anonymous access to JIRA.
    #>
    [CmdletBinding()]
    param(
        # Comment that should be added to JIRA
        [Parameter(Mandatory = $true,
                   Position = 0)]
        [String] $Comment,

        # Issue that should be commented upon
        [Parameter(Mandatory = $true,
                   Position = 1,
                   ValueFromPipeline = $true,
                   ValueFromPipelineByPropertyName = $true)]
        [Alias('Key')]
        [Object] $Issue,

        # Visibility of the comment - should it be publicly visible, viewable to only developers, or only administrators?
        [ValidateSet('All Users','Developers','Administrators')]
        [String] $VisibleRole = 'Developers',

        # Credentials to use to connect to Jira. If not specified, this function will use
        [Parameter(Mandatory = $false)]
        [System.Management.Automation.PSCredential] $Credential
    )

    begin
    {
        Write-Debug "[Add-JiraIssueComment] Begin"
        # We can't validate pipeline input here, since pipeline input doesn't exist in the Begin block.
    }

    process
    {
#        Write-Debug "[Add-JiraIssueComment] Checking Issue parameter"
#        if ($Issue | Test-HasTypeName 'PSJira.Issue')
#        {
#            Write-Debug "[Add-JiraIssueComment] Issue parameter is a PSJira.Issue object"
#            $issueObj = $Issue
#        } else {
#            $issueKey = $Issue.ToString()
#            Write-Debug "[Add-JiraIssueComment] Issue key is assumed to be [$issueKey] via ToString()"
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
#            Write-Debug "[Add-JiraIssueComment] No Jira issues were found for parameter [$Issue]. An exception will be thrown."
#            throw "Unable to identify Jira issue [$Issue]. Does this issue exist?"
#        }

        Write-Debug "[Add-JiraIssueComment] Obtaining a reference to Jira issue [$Issue]"
        $issueObj = Get-JiraIssue -InputObject $Issue -Credential $Credential

        $url = "$($issueObj.RestURL)/comment"

        Write-Debug "[Add-JiraIssueComment] Creating request body from comment"
        $props = @{
            'body' = $Comment;
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

        Write-Debug "[Add-JiraIssueComment] Converting to JSON"
        $json = ConvertTo-Json -InputObject $props

        Write-Debug "[Add-JiraIssueComment] Preparing for blastoff!"
        $rawResult = Invoke-JiraMethod -Method Post -URI $url -Body $json -Credential $Credential

        Write-Debug "[Add-JiraIssueComment] Converting to custom object"
        $result = ConvertTo-JiraComment -InputObject $rawResult

        Write-Debug "[Add-JiraIssueComment] Outputting result"
        Write-Output $result
    }

    end
    {
        Write-Debug "[Add-JiraIssueComment] Complete"
    }
}


