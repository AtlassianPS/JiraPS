function Remove-JiraIssueAttachment {
    # .ExternalHelp ..\JiraPS-help.xml
    [CmdletBinding( ConfirmImpact = 'High', SupportsShouldProcess, DefaultParameterSetName = 'byId' )]
    param(
        [Parameter( Position = 0, Mandatory, ValueFromPipeline, ParameterSetName = 'byId' )]
        [ValidateNotNullOrEmpty()]
        [Alias('Id', 'AttachmentId')]
        [AtlassianPS.JiraPS.Attachment[]]
        $Attachment,

        [Parameter( Mandatory, Position = 0, ValueFromPipelineByPropertyName, ParameterSetName = 'byIssue' )]
        [ValidateNotNull()]
        [AtlassianPS.JiraPS.IssueTransformation()]
        [Alias('Key')]
        [AtlassianPS.JiraPS.Issue]
        $Issue,

        [Parameter( ParameterSetName = 'byIssue' )]
        [String[]]
        $FileName,

        [Parameter()]
        [AtlassianPS.Connection]
        $Connection
    )

    begin {
        Write-Verbose "[$($MyInvocation.MyCommand.Name)] Function started"

        $RequestContext = Resolve-JiraOperationContext -BoundParameters $PSBoundParameters

        $resourceURi = "/rest/api/2/attachment/{0}"
    }

    process {
        Write-DebugMessage "ParameterSetName: $($PsCmdlet.ParameterSetName)"
        Write-DebugMessage -BoundParameters $PSBoundParameters

        switch ($PsCmdlet.ParameterSetName) {
            "byId" {
                foreach ($item in $Attachment) {
                    $_id = 0L
                    if (-not [long]::TryParse($item.Id, [ref]$_id) -or $_id -le 0) { throw 'Attachment requires a positive numeric attachment ID.' }
                    Write-Verbose "[$($MyInvocation.MyCommand.Name)] Processing [$_id]"
                    Write-DebugMessage "Processing `$_id [$_id]"

                    $parameter = @{
                        URI    = $resourceURi -f $_id
                        Method = "DELETE"
                    }
                    Write-DebugMessage "Invoking JiraMethod with `$parameter"
                    if ($PSCmdlet.ShouldProcess($_id, "Removing an attachment")) { Invoke-JiraRequest -RequestContext $RequestContext @parameter }
                }
            }
            "byIssue" {
                Write-Verbose "[$($MyInvocation.MyCommand.Name)] Processing [$Issue]"
                Write-DebugMessage "Processing `$Issue [$Issue]"

                # Find the proper object for the Issue
                $issueObj = Resolve-JiraIssueObject -InputObject $Issue -RequestContext $RequestContext
                $attachments = Get-JiraIssueAttachmentOperation -Issue $IssueObj -RequestContext $RequestContext -ErrorAction Stop

                if ($FileName) {
                    $_attachments = @()
                    foreach ($file in $FileName) {
                        $_attachments += $attachments | Where-Object { $_.FileName -like $file }
                    }
                    $attachments = $_attachments
                }

                foreach ($attachment in $attachments) {
                    Write-Verbose "[$($MyInvocation.MyCommand.Name)] Processing [$attachment]"
                    Write-DebugMessage "Processing `$attachment [$attachment]"

                    $parameter = @{
                        URI    = $resourceURi -f $attachment.Id
                        Method = "DELETE"
                    }
                    Write-DebugMessage "Invoking JiraMethod with `$parameter"
                    if ($PSCmdlet.ShouldProcess($Issue.Key, "Removing attachment '$($attachment.FileName)'")) {
                        Invoke-JiraRequest -RequestContext $RequestContext @parameter
                    }
                }
            }
        }
    }

    end {
        Write-Verbose "[$($MyInvocation.MyCommand.Name)] Complete"
    }
}
