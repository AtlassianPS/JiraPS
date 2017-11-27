function Add-JiraIssueAttachment {
    <#
    .Synopsis
       Adds a file attachment to an existing Jira Issue
    .DESCRIPTION
       This function adds an Attachment to an existing issue in JIRA.
    .EXAMPLE
       Add-JiraIssueAttachment -FilePath "Test comment" -Issue "TEST-001"
       This example adds a simple comment to the issue TEST-001.
    .EXAMPLE
       Get-JiraIssue "TEST-002" | Add-JiraIssueAttachment -FilePath "Test comment from PowerShell"
       This example illustrates pipeline use from Get-JiraIssue to Add-JiraIssueAttachment.
    .INPUTS
       This function can accept JiraPS.Issue objects via pipeline.
    .OUTPUTS
       This function outputs the results of the attachment add.
    .NOTES
       This function requires either the -Credential parameter to be passed or a persistent JIRA session. See New-JiraSession for more details.  If neither are supplied, this function will run with anonymous access to JIRA.
    #>
    [CmdletBinding()]
    param(
        # Issue to which to attach the file
        [Parameter(
            Mandatory = $true
        )]
        [ValidateNotNullOrEmpty()]
        [Alias('Key')]
        [Object] $Issue,

        # Path of the file to upload and attach
        [Parameter(
            Mandatory = $true,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true
        )]
        [ValidateScript( { Test-Path $_ })]
        [Alias('InFile', 'FullName')]
        [String[]] $FilePath,

        # Credentials to use to connect to JIRA.
        # If not specified, this function will use anonymous access.
        [PSCredential] $Credential,

        # Whether output should be provided after invoking this function
        [Switch] $PassThru
    )

    begin {
        Write-Verbose "[$($MyInvocation.MyCommand.Name)] Function started"

        $resourceURi = "{0}/attachments"
    }

    process {
        Write-DebugMessage "[$($MyInvocation.MyCommand.Name)] ParameterSetName: $($PsCmdlet.ParameterSetName)"
        Write-DebugMessage "[$($MyInvocation.MyCommand.Name)] PSBoundParameters: $($PSBoundParameters | Out-String)"

        # Validate input object
        if (($Issue.PSObject.TypeNames[0] -ne "JiraPS.Issue") -and (($Issue -isnot [String]))) {
            $errorItem = [System.Management.Automation.ErrorRecord]::new(
                ([System.ArgumentException]"Invalid Type for Parameter"),
                'ParameterType.NotJiraIssue',
                [System.Management.Automation.ErrorCategory]::InvalidArgument,
                $Issue
            )
            $errorItem.ErrorDetails = "Wrong object type provided for Issue. Expected [JiraPS.Issue] or [String], but was $($Issue.GetType().Name)"
            $PSCmdlet.ThrowTerminatingError($errorItem)
        }

        foreach ($file in $FilePath) {
            # Find the porper object for the Issue
            $issueObj = Resolve-JiraIssueObject -InputObject $Issue -Credential $Credential

            $fileName = Split-Path -Path $file -Leaf
            $readFile = [System.IO.File]::ReadAllBytes($file)
            $enc = [System.Text.Encoding]::GetEncoding("iso-8859-1")
            $fileEnc = $enc.GetString($readFile)
            $boundary = [System.Guid]::NewGuid().ToString()
            $mimeType = [System.Web.MimeMapping]::GetMimeMapping($file)
            if ($mimeType) { $ContentType = $mimeType }
            else { $ContentType = "application/octet-stream" }

            $bodyLines = @'
--{0}
Content-Disposition: form-data; name="file"; filename="{1}"
Content-Type: {2}

{3}
--{0}--

'@ -f $boundary, $fileName, $mimeType, $fileEnc

            $headers = @{
                'X-Atlassian-Token' = 'nocheck'
                'Content-Type'      = "multipart/form-data; boundary=`"$boundary`""
            }

            $parameter = @{
                URI        = $resourceURi -f $issueObj.RestURL
                Method     = "POST"
                Body       = $bodyLines
                Headers    = $headers
                RawBody    = $true
                Credential = $Credential
            }
            Write-Debug "[$($MyInvocation.MyCommand.Name)] Invoking JiraMethod with `$parameter"
            $rawResult = Invoke-JiraMethod @parameter

            if ($PassThru) {
                Write-Output (ConvertTo-JiraAttachment -InputObject $rawResult)
            }
        }
    }

    end {
        Write-Verbose "[$($MyInvocation.MyCommand.Name)] Complete"
    }
}
