function Get-JiraIssueAttachmentFile {
    # .ExternalHelp ..\JiraPS-help.xml
    [CmdletBinding()]
    [OutputType([Bool])]
    param (
        [Parameter( Mandatory, ValueFromPipeline )]
        [ValidateScript(
            {
                if (($_ -is [AtlassianPS.JiraPS.Attachment]) -or ('AtlassianPS.JiraPS.Attachment' -in $_.PSObject.TypeNames) -or ('JiraPS.Attachment' -in $_.PSObject.TypeNames)) {
                    return $true
                }

                $errorItem = [System.Management.Automation.ErrorRecord]::new(
                    ([System.ArgumentException]"Invalid Type for Parameter 'Attachment'"),
                    'ParameterType.NotJiraAttachment',
                    [System.Management.Automation.ErrorCategory]::InvalidArgument,
                    $_
                )
                $errorItem.ErrorDetails = "Wrong object type provided for Attachment. Expected [AtlassianPS.JiraPS.Attachment], [JiraPS.Attachment], or an object with a matching PSTypeName."
                $PSCmdlet.ThrowTerminatingError($errorItem)
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
