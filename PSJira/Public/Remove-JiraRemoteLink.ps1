function Remove-JiraRemoteLink
{
    #https://docs.atlassian.com/jira/REST/latest/#d2e928
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

        [Parameter(Mandatory = $true)]
        [string]$LinkId,

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
            Write-Debug "[Remove-JiraRemoteLink] Processing issue key [$k]"
            $issueURL = "$($server)/rest/api/latest/issue/${k}/remotelink/${linkId}"

            Write-Debug "[Remove-JiraRemoteLink] Preparing for blastoff!"
            Invoke-JiraMethod -Method Delete -URI $issueURL -Credential $Credential
        }
    }

    End
    {
        Write-Debug "[Remove-JiraRemoteLink] Complete"
    }
}
