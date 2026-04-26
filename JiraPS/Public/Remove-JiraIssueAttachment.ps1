function Remove-JiraIssueAttachment {
    # .ExternalHelp ..\JiraPS-help.xml
    [CmdletBinding( ConfirmImpact = 'High', SupportsShouldProcess, DefaultParameterSetName = 'byId' )]
    param(
        [Parameter( Position = 0, Mandatory, ValueFromPipelineByPropertyName, ParameterSetName = 'byId' )]
        [ValidateNotNullOrEmpty()]
        [Alias('Id')]
        [Int[]]
        $AttachmentId,

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
        [System.Management.Automation.PSCredential]
        [System.Management.Automation.Credential()]
        $Credential = [System.Management.Automation.PSCredential]::Empty,

        [Switch]
        $Force
    )

    begin {
        Write-Verbose "[$($MyInvocation.MyCommand.Name)] Function started"

        $resourceURi = "/rest/api/2/attachment/{0}"

        if ($Force) {
            Write-DebugMessage "[Remove-JiraGroupMember] -Force was passed. Backing up current ConfirmPreference [$ConfirmPreference] and setting to None"
            $oldConfirmPreference = $ConfirmPreference
            $ConfirmPreference = 'None'
        }
    }

    process {
        Write-DebugMessage "[$($MyInvocation.MyCommand.Name)] ParameterSetName: $($PsCmdlet.ParameterSetName)"
        Write-DebugMessage "[$($MyInvocation.MyCommand.Name)] PSBoundParameters: $($PSBoundParameters | Out-String)"

        switch ($PsCmdlet.ParameterSetName) {
            "byId" {
                foreach ($_id in $AttachmentId) {
                    Write-Verbose "[$($MyInvocation.MyCommand.Name)] Processing [$_id]"
                    Write-Debug "[$($MyInvocation.MyCommand.Name)] Processing `$_id [$_id]"

                    $parameter = @{
                        URI        = $resourceURi -f $_id
                        Method     = "DELETE"
                        Credential = $Credential
                    }
                    Write-Debug "[$($MyInvocation.MyCommand.Name)] Invoking JiraMethod with `$parameter"
                    if ($PSCmdlet.ShouldProcess($thisUrl, "Removing an attachment")) {
                        Invoke-JiraMethod @parameter
                    }
                }
            }
            "byIssue" {
                Write-Verbose "[$($MyInvocation.MyCommand.Name)] Processing [$Issue]"
                Write-Debug "[$($MyInvocation.MyCommand.Name)] Processing `$Issue [$Issue]"

                # Find the proper object for the Issue
                $issueObj = Resolve-JiraIssueObject -InputObject $Issue -Credential $Credential
                $attachments = Get-JiraIssueAttachment -Issue $IssueObj -Credential $Credential -ErrorAction Stop

                if ($FileName) {
                    $_attachments = @()
                    foreach ($file in $FileName) {
                        $_attachments += $attachments | Where-Object { $_.FileName -like $file }
                    }
                    $attachments = $_attachments
                }

                foreach ($attachment in $attachments) {
                    Write-Verbose "[$($MyInvocation.MyCommand.Name)] Processing [$attachment]"
                    Write-Debug "[$($MyInvocation.MyCommand.Name)] Processing `$attachment [$attachment]"

                    $parameter = @{
                        URI        = $resourceURi -f $attachment.Id
                        Method     = "DELETE"
                        Credential = $Credential
                    }
                    Write-Debug "[$($MyInvocation.MyCommand.Name)] Invoking JiraMethod with `$parameter"
                    if ($PSCmdlet.ShouldProcess($Issue.Key, "Removing attachment '$($attachment.FileName)'")) {
                        Invoke-JiraMethod @parameter
                    }
                }
            }
        }
    }

    end {
        if ($Force) {
            Write-DebugMessage "[Remove-JiraGroupMember] Restoring ConfirmPreference to [$oldConfirmPreference]"
            $ConfirmPreference = $oldConfirmPreference
        }

        Write-Verbose "[$($MyInvocation.MyCommand.Name)] Complete"
    }
}
