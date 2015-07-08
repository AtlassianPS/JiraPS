function Get-JiraIssueType
{
    [CmdletBinding()]
    param(
        # The Issue Type name or ID to search
        [Parameter(Mandatory = $false,
                   Position = 0,
                   ValueFromRemainingArguments = $true)]
        [String[]] $IssueType,

        # Credentials to use to connect to Jira
        [Parameter(Mandatory = $false)]
        [System.Management.Automation.PSCredential] $Credential
    )

    begin
    {
        Write-Debug "[Get-JiraIssueType] Reading server from config file"
        try
        {
            $server = Get-JiraConfigServer -ConfigFile $ConfigFile -ErrorAction Stop
        } catch {
            $err = $_
            Write-Debug "[Get-JiraIssueType] Encountered an error reading the Jira server."
            throw $err
        }

        $uri = "$server/rest/api/latest/issuetype"
        Write-Debug "[Get-JiraIssueType] Obtaining all issue types from Jira"
        $allIssueTypes = ConvertTo-JiraIssueType -InputObject (Invoke-JiraMethod -Method Get -URI $uri -Credential $Credential)
    }

    process
    {
        if ($IssueType)
        {
            foreach ($i in $IssueType)
            {
                Write-Debug "[Get-JiraIssueType] Processing issue type [$i]"
                Write-Debug "[Get-JiraIssueType] Searching for issue type (name=[$i])"
                $thisIssueType = $allIssueTypes | Where-Object -FilterScript {$_.Name -eq $i}
                if ($thisIssueType)
                {
                    Write-Debug "[Get-JiraIssueType] Found results; outputting"
                    Write-Output $thisIssueType
                } else {
                    Write-Debug "[Get-JiraIssueType] No results were found for issue type by name. Searching for issue type (id=[$i])"
                    $thisIssueType = $allIssueTypes | Where-Object -FilterScript {$_.Id -eq $i}
                    if ($thisIssueType)
                    {
                        Write-Debug "[Get-JiraIssueType] Found results; outputting"
                        Write-Output $thisIssueType
                    } else {
                        Write-Debug "[Get-JiraIssueType] No results were found for issue type by ID. This issue type appears to be unknown."
                        Write-Verbose "Unable to identify Jira issue type [$i]"
                    }
                }
            }
        } else {
            Write-Debug "[Get-JiraIssueType] No IssueType was supplied. Outputting all issues."
            Write-Output $allIssueTypes
        }
    }

    end
    {
        Write-Debug "Complete"
    }
}