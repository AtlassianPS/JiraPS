function Add-JiraIssueComment
{
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true,
                   Position = 0)]
        [String] $Comment,

        [Parameter(Mandatory = $true,
                   Position = 1,
                   ValueFromPipeline = $true,
                   ValueFromPipelineByPropertyName = $true)]
        [Alias('Key')]
        [Object] $Issue,

        [ValidateSet('All Users','Developers','Administrators')]
        [String] $VisibleRole = 'Developers',

        # Credentials to use to connect to Jira
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
#        if ($Issue.PSObject.TypeNames[0] -eq 'PSJira.Issue')
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