function Get-JiraIssueAttachmentFile {
    # .ExternalHelp ..\JiraPS-help.xml
    [CmdletBinding()]
    [OutputType( [Bool] )]
    param(
        [Parameter( Mandatory, ValueFromPipeline )]
        [AtlassianPS.JiraPS.Attachment[]]
        [ValidateScript(
            {
                foreach ($item in @($_)) {
                    if (($null -eq $item) -or [string]::IsNullOrWhiteSpace($item.FileName) -or ($null -eq $item.Content)) {
                        $errorItem = [System.Management.Automation.ErrorRecord]::new(
                            ([System.ArgumentException]"Invalid 'Attachment' value"),
                            'ParameterValue.InvalidJiraAttachment',
                            [System.Management.Automation.ErrorCategory]::InvalidArgument,
                            $item
                        )

                        $errorItem.ErrorDetails = "Attachment values must be [AtlassianPS.JiraPS.Attachment] objects with FileName and Content populated."
                        $PSCmdlet.ThrowTerminatingError($errorItem)
                    }
                }

                return $true
            }
        )]
        $Attachment,

        [ValidateScript(
            {
                if (-not (Test-Path $_)) {
                    $errorItem = [System.Management.Automation.ErrorRecord]::new(
                        ([System.ArgumentException]"Path not found"),
                        'ParameterValue.FileNotFound',
                        [System.Management.Automation.ErrorCategory]::ObjectNotFound,
                        $_
                    )

                    $errorItem.ErrorDetails = "Invalid path '$_'."
                    $PSCmdlet.ThrowTerminatingError($errorItem)
                }
                else { return $true }
            }
        )]
        [String]
        $Path,

        [Parameter()]
        [System.Management.Automation.PSCredential]
        [System.Management.Automation.Credential()]
        $Credential,

        [Alias('Session')]
        [AtlassianPS.Connection]
        $Connection
    )

    begin {
        Write-Verbose "[$($MyInvocation.MyCommand.Name)] Function started"

        try {
            $RequestContext = Resolve-JiraOperationContext -BoundParameters $PSBoundParameters
        }
        catch {
            if ($RequestContext -and $RequestContext.State -eq 'Standalone') { $RequestContext.Dispose() }
            throw
        }
    }

    process {
        try {
            Write-DebugMessage "ParameterSetName: $($PsCmdlet.ParameterSetName)"
            Write-DebugMessage -BoundParameters $PSBoundParameters

            foreach ($_Attachment in $Attachment) {
                $filename = if ($Path) { Join-Path $Path $_Attachment.Filename }
                else { $_Attachment.Filename }

                $contentUri = $_Attachment.Content
                if ($RequestContext.DeploymentType -eq 'Cloud') {
                    if ([string]::IsNullOrWhiteSpace($_Attachment.ID)) { throw 'Cloud attachment download requires an attachment ID.' }
                    $attachmentId = [Uri]::EscapeDataString($_Attachment.ID)
                    $contentUri = [Uri]::new("/rest/api/3/attachment/content/$($attachmentId)?redirect=false", [UriKind]::Relative)
                }
                $iwParameters = @{
                    Uri     = $contentUri
                    Method  = 'Get'
                    OutFile = $filename
                }

                $null = Invoke-JiraMethod -RequestContext $RequestContext @iwParameters
                Test-Path -LiteralPath $filename
            }
        }
        catch {
            if ($RequestContext -and $RequestContext.State -eq 'Standalone') { $RequestContext.Dispose() }
            throw
        }
    }

    end {
        try {
            Write-Verbose "[$($MyInvocation.MyCommand.Name)] Function ended"
        }
        finally {
            if ($RequestContext.State -eq 'Standalone') { $RequestContext.Dispose() }
        }
    }
}
