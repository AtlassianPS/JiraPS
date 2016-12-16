function Get-JiraRemoteLink
{
    #https://docs.atlassian.com/jira/REST/latest/#d2e928
    #Get-JiraRemoteLink -apiURi $JiraRestURi -cred $cred -issueID "HCF-966"
    #Get-JiraRemoteLink -apiURi $JiraRestURi -cred $cred -issueID "HCF-120"
    [CmdletBinding()]
    param(
        [Parameter(ValueFromPipelineByPropertyName = $true,
                   ParameterSetName = 'ByIssueKey',
                   ValueFromPipeline = $true,
                   Mandatory = $true,
                   Position = 0
        )]
        [ValidateNotNullOrEmpty()]
        [String[]]$Key,

        # Get a single link by it's id
        [int]$linkId,

        # Credentials to use to connect to Jira
        [Parameter(Mandatory = $false)]
        [System.Management.Automation.PSCredential] $Credential
    )

    Begin
    {
        Write-Debug "[Get-JiraRemoteLink] Reading server from config file"
        $server = Get-JiraConfigServer -ConfigFile $ConfigFile -ErrorAction Stop
    }

    Process
    {
        foreach ($k in $key)
        {
            Write-Debug "[Get-JiraIssue] Processing issue key [$k]"
            $issueURL = "$($server)/rest/api/latest/issue/${k}/remotelink"
            if ($linkId)
                { $issueURL += "/$linkId" }

            Write-Debug "[Get-JiraIssue] Preparing for blastoff!"
            $result = Invoke-JiraMethod -Method Get -URI $issueURL -Credential $Credential

            if ($result)
            {
                $result
            }
        }
    }

    End
    {
        Write-Debug "[Get-JiraIssue] Complete"
    }
}
