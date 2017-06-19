function Add-JiraAttachment
{
    <#
    .Synopsis
       Adds a file attachment to an existing Jira Issue
    .DESCRIPTION
       This function adds an Attachment to an existing issue in JIRA. 
    .EXAMPLE
       Add-JiraAttachment -FilePath "Test comment" -Issue "TEST-001"
       This example adds a simple comment to the issue TEST-001.
    .EXAMPLE
       Get-JiraIssue "TEST-002" | Add-JiraAttachment -FilePath "Test comment from PowerShell" 
       This example illustrates pipeline use from Get-JiraIssue to Add-JiraAttachment.
    .INPUTS
       This function can accept PSJira.Issue objects via pipeline.
    .OUTPUTS
       This function outputs the results of the attachment add. 
    .NOTES
       This function requires either the -Credential parameter to be passed or a persistent JIRA session. See New-JiraSession for more details.  If neither are supplied, this function will run with anonymous access to JIRA.
    #>
    [CmdletBinding()]
    param(
        # Comment that should be added to JIRA
        [Parameter(Mandatory = $true,
                   Position = 0)]
        [String] $FilePath,

        # Issue that should be commented upon
        [Parameter(Mandatory = $true,
                   Position = 1,
                   ValueFromPipeline = $true,
                   ValueFromPipelineByPropertyName = $true)]
        [Alias('Key')]
        [Object] $Issue,

        # Credentials to use to connect to Jira. If not specified, this function will use
        [Parameter(Mandatory = $false)]
        [System.Management.Automation.PSCredential] $Credential
    )

    begin
    {
        Write-Debug "[Add-JiraAttachment] Begin"
        # We can't validate pipeline input here, since pipeline input doesn't exist in the Begin block.
    }

    process
    {

        Write-Debug "[Add-JiraAttachment] Obtaining a reference to Jira issue [$Issue]"
        $issueObj = Get-JiraIssue -InputObject $Issue -Credential $Credential
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
            $Username = $credential.GetNetworkCredential().username
            $Password = $credential.GetNetworkCredential().password
            $pair = "$($Username):$($Password)"

            $encodedCreds = [System.Convert]::ToBase64String([System.Text.Encoding]::ASCII.GetBytes($pair))
            $basicAuthValue = "Basic $encodedCreds"

            $headers = @{ 
                'X-Atlassian-Token' = 'no check'
                'Authorization' = $basicAuthValue
            }

        try{

            Invoke-RestMethod -Uri $url -Credential $Credential -Method Post -ContentType "multipart/form-data; boundary=`"$boundary`"" -Body $bodyLines -Headers $headers
        }catch{
            $result = $_.Exception.Response | Out-String
            write-error "$result"
            exit 1
        }
    }
    end
    {
        Write-Debug "[Add-JiraAttachment] Complete"
    }
}

