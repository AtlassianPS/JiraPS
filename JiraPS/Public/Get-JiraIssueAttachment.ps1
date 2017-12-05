function Get-JiraIssueAttachment {
    <#
    .Synopsis
       Returns attachments of an issue in JIRA.
    .DESCRIPTION
       This function obtains attachments from existing issues in JIRA.
    .EXAMPLE
       Get-JiraIssueAttachment -Issue TEST-001
       This example returns all attachments from issue TEST-001.
    .EXAMPLE
       Get-JiraIssue TEST-002 | Get-JiraIssueAttachment
       This example illustrates use of the pipeline to return all attachments from issue TEST-002.
    .EXAMPLE
       Get-JiraIssue TEST-002 | Get-JiraIssueAttachment -FileName "*.png"
       Returns all attachments of issue TEST-002 where the filename ends in .png
    .INPUTS
       This function can accept JiraPS.Issue objects, Strings, or Objects via the pipeline.  It uses Get-JiraIssue to identify the issue parameter; see its Inputs section for details on how this function handles inputs.
    .OUTPUTS
       JiraPS.Attachment
    .NOTES
       This function requires either the -Credential parameter to be passed or a persistent JIRA session. See New-JiraSession for more details.  If neither are supplied, this function will run with anonymous access to JIRA.
    #>
    [CmdletBinding()]
    param(
        # JIRA issue to check for attachments. Can be a JiraPS.Issue object, issue key, or internal issue ID.
        [Parameter( Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName )]
        [ValidateNotNullOrEmpty()]
        [ValidateScript(
            {
                if (("JiraPS.Issue" -notin $_.PSObject.TypeNames) -and (($_ -isnot [String]))) {
                    $errorItem = [System.Management.Automation.ErrorRecord]::new(
                        ([System.ArgumentException]"Invalid Type for Parameter"),
                        'ParameterType.NotJiraIssue',
                        [System.Management.Automation.ErrorCategory]::InvalidArgument,
                        $_
                    )
                    $errorItem.ErrorDetails = "Wrong object type provided for Issue. Expected [JiraPS.Issue] or [String], but was $($_.GetType().Name)"
                    $PSCmdlet.ThrowTerminatingError($errorItem)
                    <#
                      #ToDo:CustomClass
                      Once we have custom classes, this check can be done with Type declaration
                    #>
                }
                else {
                    return $true
                }
            }
        )]
        [Alias('Key')]
        [Object]
        $Issue,

        # Name of the file(s) to filter.
        # This parameter supports wildchards.
        [String]
        $FileName,

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

        if ($issueObj.Attachment) {
            Write-Debug "[$($MyInvocation.MyCommand.Name)] Found Attachments on the Issue."
            if ($FileName) {
                $attachments = $issueObj.Attachment | Where-Object {$_.Filename -like $FileName}
            }
            else {
                $attachments = $issueObj.Attachment
            }

            ConvertTo-JiraAttachment -InputObject $attachments
        }
        else {
            $errorMessage = @{
                Category         = "ObjectNotFound"
                CategoryActivity = "Searching for resource"
                Message          = "This issue does not have any attachments"
            }
            Write-Error @errorMessage
        }
    }

    end {
        Write-Verbose "[$($MyInvocation.MyCommand.Name)] Complete"
    }
}

