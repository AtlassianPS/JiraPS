function Get-JiraIssueComment {
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
        [Parameter( Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName )]
        [Alias('Key')]
        [Object]
        $Issue,

        # Credentials to use to connect to JIRA.
        # If not specified, this function will use anonymous access.
        [PSCredential]
        $Credential
    )

    begin {
        Write-Verbose "[$($MyInvocation.MyCommand.Name)] Function started"
    }

    process {
        Write-DebugMessage "[$($MyInvocation.MyCommand.Name)] ParameterSetName: $($PsCmdlet.ParameterSetName)"
        Write-DebugMessage "[$($MyInvocation.MyCommand.Name)] PSBoundParameters: $($PSBoundParameters | Out-String)"

        # Find the proper object for the Issue
        $issueObj = Resolve-JiraIssueObject -InputObject $Issue -Credential $Credential

        $parameter = @{
            URI        = "{0}/comment" -f $issueObj.RestURL
            Method     = "GET"
            Credential = $Credential
        }
        Write-Debug "[$($MyInvocation.MyCommand.Name)] Invoking JiraMethod with `$parameter"
        $result = Invoke-JiraMethod @parameter

        Write-Output (ConvertTo-JiraComment -InputObject $result)
    }

    end {
        Write-Verbose "[$($MyInvocation.MyCommand.Name)] Complete"
    }
}
