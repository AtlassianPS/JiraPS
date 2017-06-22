function Remove-JiraIssueAttachment {
    <#
    .Synopsis
       Removes an attachment from a JIRA issue
    .DESCRIPTION
       This function removes an attachment from a JIRA issue.
    .EXAMPLE
       Remove-JiraIssueAttachment -AttachmentId 10039
       Removes attachment with id of 10039

    .OUTPUTS
       This function returns no output.
    #>
    [CmdletBinding(
        ConfirmImpact = 'High',
        SupportsShouldProcess = $true,
        DefaultParameterSetName = 'byId'
    )]
    param(
        # Id of the Attachment to delete
        [Parameter(
            Position = 0,
            Mandatory = $true,
            ParameterSetName = 'byId',
            ValueFromPipelineByPropertyName = $true
        )]
        [Int[]] $Id,

        # Issue from which to delete on or more attachments
        [Parameter(
            Mandatory = $true,
            ValueFromPipeline = $true,
            ParameterSetName = 'byIssue'
        )]
        [Object[]] $Issue,

        # Name of the File to delete
        [Parameter(
            ParameterSetName = 'byIssue'
        )]
        [ValidateScript( { Test-Path $_ } )]
        [String] $File,

        # Credentials to use to connect to Jira
        [Parameter(Mandatory = $false)]
        [PSCredential] $Credential,

        # Suppress user confirmation.
        [Switch] $Force
    )

    Begin {
        Write-Debug "[Remove-JiraGroupMember] Reading server from config file"
        $server = Get-JiraConfigServer -ConfigFile $ConfigFile -ErrorAction Stop

        Write-Debug "[Remove-JiraGroupMember] Building URI for REST call"
        $restUrl = "$server/rest/api/latest/attachment/{0}"

        if ($Force) {
            Write-Debug "[Remove-JiraGroupMember] -Force was passed. Backing up current ConfirmPreference [$ConfirmPreference] and setting to None"
            $oldConfirmPreference = $ConfirmPreference
            $ConfirmPreference = 'None'
        }
    }

    Process {
        Write-Debug "[$($MyInvocation.MyCommand.Name)] ParameterSetName: $($PsCmdlet.ParameterSetName)"
        Write-Debug "[$($MyInvocation.MyCommand.Name)] PSBoundParameters: $($PSBoundParameters | Out-String)"

        # Validate pipeline
        if ($_) {
            if (($Id) -and ($_.PSObject.TypeNames[0] -ne "PSJira.Attachment")) {
                $message = "Wrong object type provided for ID. Only PSJira.Attachment is accepted"
                $exception = New-Object -TypeName System.ArgumentException -ArgumentList $message
                Throw $exception
            }
            if (($Issue) -and ($_.PSObject.TypeNames[0] -ne "PSJira.Issue")) {
                $message = "Wrong object type provided for Issue. Only PSJira.Issue is accepted"
                $exception = New-Object -TypeName System.ArgumentException -ArgumentList $message
                Throw $exception
            }
        }

        switch ($PsCmdlet.ParameterSetName) {
            "byId" {
                foreach ($_id in $Id) {
                    Write-Verbose "Deleting Attachment by ID: $_id"
                    $thisUrl = $restUrl -f $_id

                    if ($PSCmdlet.ShouldProcess($attachment.FileName, "Removing an attachment")) {
                        Write-Debug "[Remove-JiraIssueAttachment] Preparing for blastoff!"
                        Invoke-JiraMethod -Method Delete -URI $thisUrl -Credential $Credential
                    }
                }
            }
            "byIssue" {
                foreach ($_issue in $Issue) {
                    Write-Verbose "Deleting Attachment from Issue: $_issue"

                    # ensure the Issue is not missing attachments by accident
                    if (-not($_issue.Attachment)) {
                        $_issue = Get-JiraIssueAttachment -Issue $_issue
                    }

                    if ($File) {
                        $attachments = $_issue.Attachment | Where-Object {$_.FileName -eq $File}
                    } else { $attachments = $_issue.Attachment }

                    foreach ($attachment in $attachments) {
                        $thisUrl = $restUrl -f $attachment.Id

                        if ($PSCmdlet.ShouldProcess($attachment.FileName, "Removing an attachment from Issue $($_issue.Key)")) {
                            Write-Debug "[Remove-JiraIssueAttachment] Preparing for blastoff!"
                            Invoke-JiraMethod -Method Delete -URI $thisUrl -Credential $Credential
                        }
                    }
                }
            }
        }
    }

    End {
        if ($Force) {
            Write-Debug "[Remove-JiraGroupMember] Restoring ConfirmPreference to [$oldConfirmPreference]"
            $ConfirmPreference = $oldConfirmPreference
        }

        Write-Debug "[Remove-JiraIssueAttachment] Complete"
    }
}
