function Add-JiraIssueAttachment {
    # .ExternalHelp ..\JiraPS-help.xml
    [CmdletBinding( SupportsShouldProcess )]
    param(
        [Parameter( Mandatory, Position = 0, ValueFromPipeline, ValueFromPipelineByPropertyName )]
        [ValidateNotNull()]
        [AtlassianPS.JiraPS.IssueTransformation()]
        [Alias('Key')]
        [AtlassianPS.JiraPS.Issue]
        $Issue,

        [Parameter( Mandatory, Position = 1, ValueFromPipeline, ValueFromPipelineByPropertyName )]
        [ValidateScript(
            {
                if (-not (Test-Path $_ -PathType Leaf)) {
                    $exception = ([System.ArgumentException]"File not found") #fix code highlighting]
                    $errorId = 'ParameterValue.FileNotFound'
                    $errorCategory = 'ObjectNotFound'
                    $errorTarget = $_
                    $errorItem = New-Object -TypeName System.Management.Automation.ErrorRecord $exception, $errorId, $errorCategory, $errorTarget
                    $errorItem.ErrorDetails = "No file could be found with the provided path '$_'."
                    $PSCmdlet.ThrowTerminatingError($errorItem)
                }
                else {
                    return $true
                }
            }
        )]
        [Alias('InFile', 'FullName', 'Path')]
        [String[]]
        $FilePath,

        [Parameter()]
        [System.Management.Automation.PSCredential]
        [System.Management.Automation.Credential()]
        $Credential = [System.Management.Automation.PSCredential]::Empty,

        [Switch]
        $PassThru
    )

    begin {
        Write-Verbose "[$($MyInvocation.MyCommand.Name)] Function started"

        $resourceURi = "{0}/attachments"
    }

    process {
        Write-DebugMessage "[$($MyInvocation.MyCommand.Name)] ParameterSetName: $($PsCmdlet.ParameterSetName)"
        Write-DebugMessage "[$($MyInvocation.MyCommand.Name)] PSBoundParameters: $($PSBoundParameters | Out-String)"

        $issueObj = Resolve-JiraIssueObject -InputObject $Issue -Credential $Credential

        foreach ($file in $FilePath) {
            $file = Resolve-FilePath -Path $file

            $fileName = Split-Path -Path $file -Leaf

            $headers = @{
                'X-Atlassian-Token' = 'nocheck'
            }

            $parameter = @{
                URI        = $resourceURi -f $issueObj.RestURL
                Method     = "POST"
                InFile     = $file
                Headers    = $headers
                Credential = $Credential
            }
            Write-Debug "[$($MyInvocation.MyCommand.Name)] Invoking JiraMethod with `$parameter"
            if ($PSCmdlet.ShouldProcess($IssueObj.Key, "Adding attachment '$($fileName)'.")) {
                $rawResult = Invoke-JiraMethod @parameter

                if ($PassThru) {
                    Write-Output (ConvertTo-JiraAttachment -InputObject $rawResult)
                }
            }
        }
    }

    end {
        Write-Verbose "[$($MyInvocation.MyCommand.Name)] Complete"
    }
}
