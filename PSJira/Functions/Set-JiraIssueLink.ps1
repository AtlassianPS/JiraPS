function Set-JiraIssueLink
{
    [CmdletBinding(DefaultParameterSetName = 'ByInputObject')]
    param(
        # Issue key or PSJira.Issue object returned from Get-JiraIssue
        [Parameter(Mandatory = $true, Position = 0, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true )]
        [Alias('Key')]
        [Object[]] $Issue,

        [Parameter(Mandatory = $true)]
        [Object[]] $IssueLink,

        [ValidateScript({Test-Path $_})]
        [String] $ConfigFile,

        # Credentials to use to connect to Jira
        [Parameter(Mandatory = $false)]
        [System.Management.Automation.PSCredential] $Credential #,

        # [Switch] $PassThru
    )

    begin
    {
        Write-Debug "[Set-JiraIssue] Reading server from config file"
        $server = Get-JiraConfigServer -ConfigFile $ConfigFile -ErrorAction Stop

        Write-Debug "[Set-JiraIssue] Completed Begin block."
    }

    process
    {
        foreach ($i in $Issue)
        {
            # $actOnIssueUri = $false
            # $actOnAssigneeUri = $false

            Write-Debug "[Set-JiraIssue] Obtaining reference to issue"
            $issueObj = Get-JiraIssue -InputObject $i -Credential $Credential
            foreach ($link in $IssueLink)
            {
                if ($link.inwardIssue)
                {
                    $inwardIssue = New-Object -type PSObject -Prop @{key = $link.inwardIssue.key}
                } else {
                    $inwardIssue = New-Object -type PSObject -Prop @{key = $issueObj.key}
                }

                if ($link.outwardIssue)
                {
                    $outwardIssue = New-Object -type PSObject -Prop @{key = $link.outwardIssue.key}
                } else {
                    $outwardIssue = New-Object -type PSObject -Prop @{key = $issueObj.key}
                }

                $body = New-Object -type PSObject -Prop @{
                    type = New-Object -type PSObject -Prop @{name = $link.type.name}
                    inwardIssue = $inwardIssue
                    outwardIssue = $outwardIssue
                }
                $json = (ConvertTo-Json $body)

                $issueLinkURL = "$($server)/rest/api/latest/issueLink"
                $issueResult = Invoke-JiraMethod -Method POST -URI $issueLinkURL -Body $json -Credential $Credential
            }



        }
    }

    end
    {
        Write-Debug "[Set-JiraIssue] Complete"
    }
}