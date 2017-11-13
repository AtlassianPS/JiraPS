function Remove-JiraRemoteLink {
    <#
    .Synopsis
       Removes a remote link from a JIRA issue
    .DESCRIPTION
       This function removes a remote link from a JIRA issue.
    .EXAMPLE
       Remove-JiraRemoteLink Project1-1001 10000,20000
       Removes two remote link from issue "Project1-1001"
    .EXAMPLE
       Get-JiraIssue -Query "project = Project1" | Remove-JiraRemoteLink 10000
       Removes a specific remote link from all issues in project "Project1"
    .INPUTS
       [JiraPS.Issue[]] The JIRA issue from which to delete a link
    .OUTPUTS
       This function returns no output.
    #>
    [CmdletBinding(
        ConfirmImpact = 'High',
        SupportsShouldProcess = $true
    )]
    param(
        # Issue from which to delete a remote link.
        [Parameter(
            Position = 0,
            Mandatory = $true,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true
        )]
        [Alias("Key")]
        [Object[]] $Issue,

        # Id of the remote link to delete.
        [Parameter(Mandatory = $true)]
        [Int[]] $LinkId,

        # Credentials to use to connect to JIRA.
        # If not specified, this function will use anonymous access.
        [PSCredential] $Credential,

        # Suppress user confirmation.
        [Switch] $Force
    )

    begin {
        Write-Verbose "[$($MyInvocation.MyCommand.Name)] Function started"

        $server = Get-JiraConfigServer -ConfigFile $ConfigFile -ErrorAction Stop

        $restUrl = "$server/rest/api/latest/issue/{0}/remotelink/{1}"

        if ($Force) {
            Write-Debug "[Remove-JiraRemoteLink] -Force was passed. Backing up current ConfirmPreference [$ConfirmPreference] and setting to None"
            $oldConfirmPreference = $ConfirmPreference
            $ConfirmPreference = 'None'
        }
    }

    process {
        Write-DebugMessage "[$($MyInvocation.MyCommand.Name)] ParameterSetName: $($PsCmdlet.ParameterSetName)"
        Write-DebugMessage "[$($MyInvocation.MyCommand.Name)] PSBoundParameters: $($PSBoundParameters | Out-String)"

        foreach ($k in $Issue) {
            Write-Debug "[Remove-JiraRemoteLink] Processing issue key [$k]"
            $issueObj = Get-JiraIssue $k -Credential $Credential

            foreach ($l in $LinkId) {
                $thisUrl = $restUrl -f $k, $l
                Write-Debug "[Remove-JiraRemoteLink] RemoteLink URL: [$thisUrl]"

                Write-Debug "[Remove-JiraRemoteLink] Checking for -WhatIf and Confirm"
                if ($PSCmdlet.ShouldProcess($issueObj.Key, "Remove RemoteLink from [$issueObj] from JIRA")) {
                    Write-Debug "[$($MyInvocation.MyCommand.Name)] Invoking JiraMethod with `$parameter"
                    Invoke-JiraMethod -Method Delete -URI $thisUrl -Credential $Credential
                }
                else {
                    Write-Debug "[Remove-JiraRemoteLink] Runnning in WhatIf mode or user denied the Confirm prompt; no operation will be performed"
                }
            }
        }
    }

    end {
        if ($Force) {
            Write-Debug "[Remove-JiraGroupMember] Restoring ConfirmPreference to [$oldConfirmPreference]"
            $ConfirmPreference = $oldConfirmPreference
        }

        Write-Verbose "[$($MyInvocation.MyCommand.Name)] Complete"
    }
}
