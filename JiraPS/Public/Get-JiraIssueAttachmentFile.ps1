function Get-JiraIssueAttachmentFile {
    # .ExternalHelp ..\JiraPS-help.xml
    [CmdletBinding()]
    [OutputType([Bool])]
    param (
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
                else {
                    return $true
                }
            }
        )]
        [String]
        $Path,

        [Parameter()]
        [System.Management.Automation.PSCredential]
        [System.Management.Automation.Credential()]
        $Credential = [System.Management.Automation.PSCredential]::Empty
    )

    begin {
        Write-Verbose "[$($MyInvocation.MyCommand.Name)] Function started"
    }

    process {
        Write-DebugMessage "[$($MyInvocation.MyCommand.Name)] ParameterSetName: $($PsCmdlet.ParameterSetName)"
        Write-DebugMessage "[$($MyInvocation.MyCommand.Name)] PSBoundParameters: $($PSBoundParameters | Out-String)"

        foreach ($_Attachment in $Attachment) {
            if ($Path) {
                $filename = Join-Path $Path $_Attachment.Filename
            }
            else {
                $filename = $_Attachment.Filename
            }

            $iwParameters = @{
                Uri        = $_Attachment.Content
                Method     = 'Get'
                OutFile    = $filename
                Credential = $Credential
            }

            $null = Invoke-JiraMethod @iwParameters
            Test-Path -LiteralPath $filename
        }
    }

    end {
        Write-Verbose "[$($MyInvocation.MyCommand.Name)] Function ended"
    }
}
