function Remove-JiraIssueAttachment {
    <#
    .Synopsis
       Removes an attachment from a JIRA issue
    .DESCRIPTION
       This function removes an attachment from a JIRA issue.
    .EXAMPLE
       Remove-JiraIssueAttachment -AttachmentId 10039
       Removes attachment with id of 10039
    .EXAMPLE
       Get-JiraIssueAttachment -Issue FOO-1234 | Remove-JiraIssueAttachment
       Removes all attachments from issue FOO-1234
    .EXAMPLE
       Remove-JiraIssueAttachment -Issue FOO-1234 -FileName '*.png' -force
       Removes all *.png attachments from Issue FOO-1234 without prompting for confirmation
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
        [ValidateNotNullOrEmpty()]
        [Alias('Id')]
        [Int[]] $AttachmentId,

        # Issue from which to delete on or more attachments
        [Parameter(
            Position = 0,
            Mandatory = $true,
            ParameterSetName = 'byIssue'
        )]
        [ValidateNotNullOrEmpty()]
        [Alias('Key')]
        [Object] $Issue,

        # Name of the File to delete
        [Parameter(
            ParameterSetName = 'byIssue'
        )]
        [String[]] $FileName,

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

        switch ($PsCmdlet.ParameterSetName) {
            "byId" {
                foreach ($_id in $AttachmentId) {
                    Write-Verbose "Deleting Attachment by ID: $_id"
                    $thisUrl = $restUrl -f $_id

                    if ($PSCmdlet.ShouldProcess($thisUrl, "Removing an attachment")) {
                        Write-Debug "[Remove-JiraIssueAttachment] Preparing for blastoff!"
                        Invoke-JiraMethod -Method Delete -URI $thisUrl -Credential $Credential
                    }
                }
            }
            "byIssue" {
                # Validate input object
                if (
                    ($Issue) -and
                    (!(
                            ("JiraPS.Issue" -in $Issue.PSObject.TypeNames) -or
                            ($Issue -is [String])
                        ))
                ) {
                    $message = "Wrong object type provided for Issue. Was $($Issue.GetType().Name)"
                    $exception = New-Object -TypeName System.ArgumentException -ArgumentList $message
                    Throw $exception
                }

                Write-Verbose "Deleting Attachment from Issue: $Issue"

                $attachments = Get-JiraIssueAttachment -Issue $Issue

                if ("JiraPS.Issue" -in $Issue.PSObject.TypeNames) {
                    $Issue = $Issue.Key
                }

                if ($FileName) {
                    $_attachments = @()
                    foreach ($file in $FileName) {
                        $_attachments += $attachments | Where-Object {$_.FileName -like $file}
                    }
                    $attachments = $_attachments
                }

                foreach ($attachment in $attachments) {
                    $thisUrl = $restUrl -f $attachment.Id

                    if ($PSCmdlet.ShouldProcess($attachment.FileName, "Removing an attachment from Issue $($Issue)")) {
                        Write-Debug "[Remove-JiraIssueAttachment] Preparing for blastoff!"
                        Invoke-JiraMethod -Method Delete -URI $thisUrl -Credential $Credential
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
