function Get-JiraIssueAttachmentOperation {
    <#
    .SYNOPSIS
        Retrieve typed attachment metadata for an issue, optionally matching file names.
    #>
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
        Write-DebugMessage "ParameterSetName: $($PsCmdlet.ParameterSetName)"
        Write-DebugMessage -BoundParameters $PSBoundParameters

        # Find the proper object for the Issue
        $issueObj = Resolve-JiraIssueObject -InputObject $Issue -RequestContext $RequestContext

        if ($issueObj.Attachment) {
            Write-DebugMessage "Found Attachments on the Issue."
            if ($FileName) { $attachments = $issueObj.Attachment | Where-Object { $_.Filename -like $FileName } }
            else { $attachments = $issueObj.Attachment }

            ConvertTo-JiraAttachment -InputObject $attachments
        }
    }

    end {
        Write-Verbose "[$($MyInvocation.MyCommand.Name)] Complete"
    }
}
