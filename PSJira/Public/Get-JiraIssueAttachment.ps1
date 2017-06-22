function Get-JiraIssueAttachment
{
    <#
    .Synopsis
       Returns comments on an issue in JIRA.
    .DESCRIPTION
       This function obtains comments from existing issues in JIRA.
    .EXAMPLE
       Get-JiraIssueAttachment -Key TEST-001
       This example returns all comments posted to issue TEST-001.
    .EXAMPLE
       Get-JiraIssue TEST-002 | Get-JiraIssueAttachment
       This example illustrates use of the pipeline to return all comments on issue TEST-002.
    .INPUTS
       This function can accept PSJira.Issue objects, Strings, or Objects via the pipeline.  It uses Get-JiraIssue to identify the issue parameter; see its Inputs section for details on how this function handles inputs.
    .OUTPUTS
       This function outputs all PSJira.Comment issues associated with the provided issue.
    .NOTES
       This function requires either the -Credential parameter to be passed or a persistent JIRA session. See New-JiraSession for more details.  If neither are supplied, this function will run with anonymous access to JIRA.
    #>
    [CmdletBinding()]
    param(
        # JIRA issue to check for comments. Can be a PSJira.Issue object, issue key, or internal issue ID.
        [Parameter(Mandatory = $true,
                   Position = 0,
                   ValueFromPipeline = $true,
                   ValueFromPipelineByPropertyName = $true)]
        [Alias('Key')]
        [Object] $Issue,

        [String] $FileName,
        # Credentials to use to connect to Jira
        [Parameter(Mandatory = $false)]
        [System.Management.Automation.PSCredential] $Credential
    )

    begin
    {
        # We can't validate pipeline input here, since pipeline input doesn't exist in the Begin block.
    }

    process
    {
        # Validate input object
        if (
            # from Pipeline
            (($_) -and ($_.PSObject.TypeNames[0] -ne "PSJira.Issue")) -or
            # by parameter
            ($Issue.PSObject.TypeNames[0] -ne "PSJira.Issue") -and (($Issue -isnot [String]))
        ) {
            $message = "Wrong object type provided for Issue. Only PSJira.Issue and String is allowed"
            $exception = New-Object -TypeName System.ArgumentException -ArgumentList $message
            Throw $exception
        }

        # As we are not able to use proper type casting in the parameters, this is a workaround
        # to extract the data from a PSJira.Issue object
        Write-Debug "[$($MyInvocation.MyCommand.Name)] Obtaining a reference to Jira issue [$Issue]"
        if ($Issue.PSObject.TypeNames[0] -eq "PSJira.Issue" -and $Issue.RestURL) {
            $issueObj = $Issue
        }
        else {
            $issueObj = Get-JiraIssue -InputObject $Issue -Credential $Credential -ErrorAction Stop
        }

        if ($issueObj.Attachment) {
            Write-Debug "[$($MyInvocation.MyCommand.Name)] Found Attachments on the Issue."
            if ($FileName) {
                $attachments = $issueObj.Attachment | Where-Object {$_.FileName -eq $FileName}
            }
            else { $attachments = $issueObj.Attachment }

            Write-Debug "[$($MyInvocation.MyCommand.Name)] Converting result to Jira Attachment objects."
            ConvertTo-JiraAttachment -InputObject $attachments
        }
        else {
            Write-Debug "[$($MyInvocation.MyCommand.Name)] Issue seems to have no Attachments. No output."
        }
    }

    end
    {
        Write-Debug "[$($MyInvocation.MyCommand.Name)] Completed"
    }
}

