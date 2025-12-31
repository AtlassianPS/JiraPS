function Get-JiraIssueAttachmentFile {
    # .ExternalHelp ..\JiraPS-help.xml
    [CmdletBinding()]
    [OutputType([Bool])]
    param (
        [Parameter( Mandatory, ValueFromPipeline )]
        [PSTypeName('JiraPS.Attachment')]
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
                Headers    = @{"Accept" = $_Attachment.MimeType }
                OutFile    = $filename
                Credential = $Credential
            }

            $result = Invoke-JiraMethod @iwParameters
            (-not $result)
        }
    }

    end {
        Write-Verbose "[$($MyInvocation.MyCommand.Name)] Function ended"
    }
}
