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
       This function can accept PSJira.Issue objects via pipeline.
    .OUTPUTS
       This function outputs the results of the attachment add.
    .NOTES
       This function requires either the -Credential parameter to be passed or a persistent JIRA session. See New-JiraSession for more details.  If neither are supplied, this function will run with anonymous access to JIRA.
    #>
    [CmdletBinding()]
    param(
        # Path of the file to upload and attach
        [Parameter(
            Position = 0,
            Mandatory = $true
        )]
        [ValidateScript( { Test-Path $_ })]
        [String] $FilePath,

        # Issue to which to attach the file
        [Parameter(
            Position = 1,
            Mandatory = $true,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true
        )]
        [Alias('Key')]
        [Object] $Issue,

        # Credentials to use to connect to Jira.
        [Parameter(Mandatory = $false)]
        [System.Management.Automation.PSCredential] $Credential,

        # Whether output should be provided after invoking this function
        [Switch] $PassThru
    )

    begin {
        Write-Debug "[Add-JiraIssueAttachment] Begin"
        # We can't validate pipeline input here, since pipeline input doesn't exist in the Begin block.
    }

    process {
        # Validate input object
        if (
            # from Pipeline
            (($_) -and ($_.PSObject.TypeNames[0] -ne "PSJira.Issue")) -or
            # by parameter
            ($Issue.PSObject.TypeNames[0] -ne "PSJira.Issue") -and (($Issue -isnot [String]))
        ) {
            $message = "Wrong object type provided for Issue. Was $($Issue.Gettype().Name)"
            $exception = New-Object -TypeName System.ArgumentException -ArgumentList $message
            Throw $exception
        }

        # As we are not able to use proper type casting in the parameters, this is a workaround
        # to extract the data from a PSJira.Issue object
        Write-Debug "[Add-JiraIssueAttachment] Obtaining a reference to Jira issue [$Issue]"
        if ($Issue.PSObject.TypeNames[0] -eq "PSJira.Issue" -and $Issue.RestURL) {
            $issueObj = $Issue
        }
        else {
            $issueObj = Get-JiraIssue -InputObject $Issue -Credential $Credential -ErrorAction Stop
        }

        $ID = $issueObj.ID
        $url = "$($issueObj.RestURL)/attachments"

        $LF = "`r`n"
        $fileSize = (Get-Item $FilePath).Length
        $fileName = (Split-Path -Path $FilePath -Leaf)
        $readFile = [System.IO.File]::ReadAllBytes($FilePath)
        $enc = [System.Text.Encoding]::GetEncoding("iso-8859-1")
        $fileEnc = $enc.GetString($readFile)
        $boundary = [System.Guid]::NewGuid().ToString()

        $bodyLines =
        "--$boundary$LF" +
        "Content-Disposition: form-data; name=`"file`"; filename=`"$fileName`"; size=`"$fileSize`"; issueId=`"$ID`"$LF" +
        "Content-Type: 'multipart/form-data'$LF$LF" +
        "$fileEnc$LF" +
        "--$boundary--$LF"

        $headers = @{
            'X-Atlassian-Token' = 'nocheck'
            'Content-Type'      = "multipart/form-data; boundary=`"$boundary`""
        }
        $parameter = @{
            URI        = $url
            Method     = "POST"
            Body       = $bodyLines
            Headers    = $headers
            RawBody    = $true
            Credential = $Credential
        }
        Write-Debug "[Add-JiraIssueAttachment] Preparing for blastoff!"
        $rawResult = Invoke-JiraMethod @parameter

        if ($PassThru) {
            Write-Debug "[Add-JiraIssueAttachment] -PassThru specified."
            Write-Debug "[Add-JiraIssueAttachment] Converting to custom object"
            ConvertTo-JiraAttachment -InputObject $rawResult

            Write-Debug "[Add-JiraIssueAttachment] Outputting result"
            Write-Output $result
        }

    }
    end {
        Write-Debug "[Add-JiraIssueAttachment] Complete"
    }
}
