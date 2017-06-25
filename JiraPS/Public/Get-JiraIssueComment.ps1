function Get-JiraIssueComment
{
    <#
    .Synopsis
       Returns comments on an issue in JIRA.
    .DESCRIPTION
       This function obtains comments from existing issues in JIRA.
    .EXAMPLE
       Get-JiraIssueComment -Key TEST-001
       This example returns all comments posted to issue TEST-001.
    .EXAMPLE
       Get-JiraIssue TEST-002 | Get-JiraIssueComment
       This example illustrates use of the pipeline to return all comments on issue TEST-002.
    .INPUTS
       This function can accept JiraPS.Issue objects, Strings, or Objects via the pipeline.  It uses Get-JiraIssue to identify the issue parameter; see its Inputs section for details on how this function handles inputs.
    .OUTPUTS
       This function outputs all JiraPS.Comment issues associated with the provided issue.
    .NOTES
       This function requires either the -Credential parameter to be passed or a persistent JIRA session. See New-JiraSession for more details.  If neither are supplied, this function will run with anonymous access to JIRA.
    #>
    [CmdletBinding()]
    param(
        # JIRA issue to check for comments.
        # Can be a JiraPS.Issue object, issue key, or internal issue ID.
        [Parameter(Mandatory = $true,
            Position = 0,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true)]
        [Alias('Key')]
        [Object] $Issue,

        # Credentials to use to connect to JIRA.
        # If not specified, this function will use anonymous access.
        [Parameter(Mandatory = $false)]
        [System.Management.Automation.PSCredential] $Credential
    )

    begin
    {
        # We can't validate pipeline input here, since pipeline input doesn't exist in the Begin block.
    }

    process
    {
        Write-Debug "Obtaining a reference to Jira issue [$Issue]"
        $issueObj = Get-JiraIssue -InputObject $Issue -Credential $Credential

        $url = "$($issueObj.RestURL)/comment"

        Write-Debug "Preparing for blastoff!"
        $result = Invoke-JiraMethod -Method Get -URI $url -Credential $Credential

        if ($result)
        {
            if ($result.comments)
            {
                Write-Debug "Converting result to Jira comment objects"
                $obj = ConvertTo-JiraComment -InputObject $result.comments

                Write-Debug "Outputting results"
                Write-Output $obj
            }
            else
            {
                Write-Debug "Result appears to be in an unexpected format. Outputting raw result."
                Write-Output $result
            }
        }
        else
        {
            Write-Debug "Invoke-JiraMethod returned no results to output."
        }
    }

    end
    {
        Write-Debug "Completed Get-JiraIssueComment"
    }
}
