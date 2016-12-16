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
        [string]$GlobalId,

        # Credentials to use to connect to Jira
        [Parameter(Mandatory = $false)]
        [System.Management.Automation.PSCredential] $Credential
    )

    Begin
    {
        Write-Debug "[Get-JiraRemoteLink] Reading server from config file"
        $server = Get-JiraConfigServer -ConfigFile $ConfigFile -ErrorAction Stop



        if ($apiURi -notmatch "\/$")
            { $apiURi = $apiURi + "/" }
        $restAPI = "${apiURi}rest/api/2/issue"

        $header = @{
            Authorization = "Basic  $([System.Convert]::ToBase64String(
                [System.Text.Encoding]::UTF8.GetBytes(
                    ($Credential.UserName)+":"+($Credential.getnetworkcredential().password)
                )
            ))"
            "Content-Type" = "application/json"
        }
    }

    Process
    {

        foreach ($k in $key)
        {
            Write-Debug "[Get-JiraIssue] Processing issue key [$k]"
            $issueURL = "$($server)/rest/api/latest/issue/${k}/remotelink"

            $body = "{globalId: `"$GlobalId`"}"

            Write-Debug "[Get-JiraIssue] Preparing for blastoff!"
            $result = Invoke-JiraMethod -Method Delete -URI -Body $body $issueURL -Credential $Credential

            if ($result)
            {
                Write-Debug "[Get-JiraIssue] Converting REST result to Jira object"
                ConvertFrom-Json $result
            }
        }
    }

    End {}
}
