function Get-JiraIssueAttachmentOperation {
    [CmdletBinding()]
    param(
        [Parameter( Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName )]
        [ValidateNotNull()]
        [AtlassianPS.JiraPS.IssueTransformation()]
        [Alias('Key')]
        [AtlassianPS.JiraPS.Issue]
        $Issue,

        [String]
        $FileName,

        [Parameter()]
        [AtlassianPS.Connection]
        $RequestContext
    )

    begin {
        Write-Verbose "[$($MyInvocation.MyCommand.Name)] Function started"
    }

    process {
        Write-DebugMessage "[$($MyInvocation.MyCommand.Name)] ParameterSetName: $($PsCmdlet.ParameterSetName)"

        # Find the proper object for the Issue
        $issueObj = Resolve-JiraIssueObject -InputObject $Issue -RequestContext $RequestContext

        if ($issueObj.Attachment) {
            Write-Debug "[$($MyInvocation.MyCommand.Name)] Found Attachments on the Issue."
            if ($FileName) { $attachments = $issueObj.Attachment | Where-Object { $_.Filename -like $FileName } }
            else { $attachments = $issueObj.Attachment }

            ConvertTo-JiraAttachment -InputObject $attachments
        }
    }

    end {
        Write-Verbose "[$($MyInvocation.MyCommand.Name)] Complete"
    }
}
