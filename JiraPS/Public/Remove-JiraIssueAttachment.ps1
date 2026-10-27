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
        $Credential,

        [Switch]
        $Force,

        [Alias('Session')]
        [AtlassianPS.Connection]
        $Connection,

        [Alias('Server', 'ServerName')]
        [ArgumentCompleter( {
                param($commandName, $parameterName, $wordToComplete)
                AtlassianPS.Configuration\Get-AtlassianConnection -Product Jira |
                    Where-Object { $_.Name -like "$wordToComplete*" } |
                    ForEach-Object { $_.Name }
            }
        )]
        [String]
        $ConnectionName,

        [Uri]
        $Uri,

        [Alias('Email')]
        [String]
        $EmailAddress,

        [Object]
        $ApiToken,

        [Alias('PAT', 'BearerToken')]
        [Object]
        $PersonalAccessToken,

        [Switch]
        $Anonymous
    )

    begin {
        try {
            Write-Verbose "[$($MyInvocation.MyCommand.Name)] Function started"

            $RequestContext = Resolve-JiraOperationContext -BoundParameters $PSBoundParameters

            $resourceURi = "/rest/api/2/attachment/{0}"

            if ($Force) {
                Write-DebugMessage "[Remove-JiraGroupMember] -Force was passed. Backing up current ConfirmPreference [$ConfirmPreference] and setting to None"
                $oldConfirmPreference = $ConfirmPreference
                $ConfirmPreference = 'None'
            }
        }
        catch {
            if ($RequestContext -and $RequestContext.State -eq 'Standalone') { $RequestContext.Dispose() }
            throw
        }
    }

    process {
        try {
            Write-DebugMessage "[$($MyInvocation.MyCommand.Name)] ParameterSetName: $($PsCmdlet.ParameterSetName)"

            switch ($PsCmdlet.ParameterSetName) {
                "byId" {
                    foreach ($_id in $AttachmentId) {
                        Write-Verbose "[$($MyInvocation.MyCommand.Name)] Processing [$_id]"
                        Write-Debug "[$($MyInvocation.MyCommand.Name)] Processing `$_id [$_id]"

                        $parameter = @{
                            URI    = $resourceURi -f $_id
                            Method = "DELETE"
                        }
                        Write-Debug "[$($MyInvocation.MyCommand.Name)] Invoking JiraMethod with `$parameter"
                        if ($PSCmdlet.ShouldProcess($thisUrl, "Removing an attachment")) { Invoke-JiraMethod -RequestContext $RequestContext @parameter }
                    }
                }
                "byIssue" {
                    Write-Verbose "[$($MyInvocation.MyCommand.Name)] Processing [$Issue]"
                    Write-Debug "[$($MyInvocation.MyCommand.Name)] Processing `$Issue [$Issue]"

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
                        Write-Debug "[$($MyInvocation.MyCommand.Name)] Processing `$attachment [$attachment]"

                        $parameter = @{
                            URI    = $resourceURi -f $attachment.Id
                            Method = "DELETE"
                        }
                        Write-Debug "[$($MyInvocation.MyCommand.Name)] Invoking JiraMethod with `$parameter"
                        if ($PSCmdlet.ShouldProcess($Issue.Key, "Removing attachment '$($attachment.FileName)'")) {
                            Invoke-JiraMethod -RequestContext $RequestContext @parameter
                        }
                    }
                }
            }
        }
        catch {
            if ($RequestContext -and $RequestContext.State -eq 'Standalone') { $RequestContext.Dispose() }
            throw
        }
    }

    end {
        try {
            if ($Force) {
                Write-DebugMessage "[Remove-JiraGroupMember] Restoring ConfirmPreference to [$oldConfirmPreference]"
                $ConfirmPreference = $oldConfirmPreference
            }

            Write-Verbose "[$($MyInvocation.MyCommand.Name)] Complete"
        }
        finally {
            if ($RequestContext.State -eq 'Standalone') { $RequestContext.Dispose() }
        }
    }
}
