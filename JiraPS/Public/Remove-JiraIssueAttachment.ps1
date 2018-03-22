function Remove-JiraIssueAttachment {
    <#
    .SYNOPSIS
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
    [CmdletBinding( ConfirmImpact = 'High', SupportsShouldProcess, DefaultParameterSetName = 'byId' )]
    param(
        # Id of the Attachment to delete
        [Parameter( Position = 0, Mandatory, ValueFromPipelineByPropertyName, ParameterSetName = 'byId' )]
        [ValidateNotNullOrEmpty()]
        [Alias('Id')]
        [Int[]]
        $AttachmentId,

        # Issue from which to delete on or more attachments
        [Parameter( Position = 0, Mandatory, ParameterSetName = 'byIssue' )]
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

        # Name of the File to delete
        [Parameter( ParameterSetName = 'byIssue' )]
        [String[]]
        $FileName,

        # Credentials to use to connect to JIRA.
        # If not specified, this function will use anonymous access.
        [PSCredential]
        $Credential,

        # Suppress user confirmation.
        [Switch]
        $Force
    )

    begin {
        Write-Verbose "[$($MyInvocation.MyCommand.Name)] Function started"

        $server = Get-JiraConfigServer -ErrorAction Stop

        $resourceURi = "$server/rest/api/latest/attachment/{0}"

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

                if (@($Issue).Count -ne 1) {
                    $errorItem = [System.Management.Automation.ErrorRecord]::new(
                        ([System.ArgumentException]"invalid Issue provided"),
                        'ParameterValue.JiraIssue',
                        [System.Management.Automation.ErrorCategory]::InvalidArgument,
                        $_
                    )
                    $errorItem.ErrorDetails = "Only one Issue can be provided at a time."
                    $PSCmdlet.ThrowTerminatingError($errorItem)
                }

                # Find the proper object for the Issue
                $issueObj = Resolve-JiraIssueObject -InputObject $Issue -Credential $Credential
                $attachments = Get-JiraIssueAttachment -Issue $IssueObj -Credential $Credential -ErrorAction Stop

                if ($FileName) {
                    $_attachments = @()
                    foreach ($file in $FileName) {
                        $_attachments += $attachments | Where-Object {$_.FileName -like $file}
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
