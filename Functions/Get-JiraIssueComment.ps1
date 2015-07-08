function Get-JiraIssueComment
{
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true,
                   Position = 0,
                   ValueFromPipeline = $true,
                   ValueFromPipelineByPropertyName = $true)]
        [Alias('Key')]
        [Object] $Issue,

        # Credentials to use to connect to Jira
        [Parameter(Mandatory = $false)]
        [System.Management.Automation.PSCredential] $Credential
    )

    begin
    {
        # We can't validate pipeline input here, since pipeline input doesn't exist in the Begin block.
    }

    process
    {
        Write-Debug "Obtaining a reference to Jira issue [$Issue]"
        $issueObj = Get-JiraIssue -InputObject $Issue -Credential $Credential

        $url = "$($issueObj.RestURL)/comment"
        
        Write-Debug "Preparing for blastoff!"
        $result = Invoke-JiraMethod -Method Get -URI $url -Credential $Credential

        if ($result)
        {
            if ($result.comments)
            {
                Write-Debug "Converting result to Jira comment objects"
                $obj = ConvertTo-JiraComment -InputObject $result.comments

                Write-Debug "Outputting results"
                Write-Output $obj
            } else {
                Write-Debug "Result appears to be in an unexpected format. Outputting raw result."
                Write-Output $result
            }
        } else {
            Write-Debug "Invoke-JiraMethod returned no results to output."
        }
    }

    end
    {
        Write-Debug "Completed Get-JiraIssueComment"
    }
}