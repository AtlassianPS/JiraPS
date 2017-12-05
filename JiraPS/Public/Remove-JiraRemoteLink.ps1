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
    [CmdletBinding( ConfirmImpact = 'High', SupportsShouldProcess )]
    param(
        # Issue from which to delete a remote link.
        [Parameter( Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName )]
        [Alias("Key")]
        [Object[]]
        $Issue,

        # Id of the remote link to delete.
        [Parameter( Mandatory )]
        [Int[]]
        $LinkId,

        # Credentials to use to connect to JIRA.
        # If not specified, this function will use anonymous access.
        [PSCredential]
        $Credential,

        # Suppress user confirmation.
        [Switch]
        $Force
    )

    begin {
        Write-Verbose "[$($MyInvocation.MyCommand.Name)] Function started"

        $server = Get-JiraConfigServer -ConfigFile $ConfigFile -ErrorAction Stop

        $resourceURi = "$server/rest/api/latest/issue/{0}/remotelink/{1}"

        if ($Force) {
            Write-DebugMessage "[$($MyInvocation.MyCommand.Name)] -Force was passed. Backing up current ConfirmPreference [$ConfirmPreference] and setting to None"
            $oldConfirmPreference = $ConfirmPreference
            $ConfirmPreference = 'None'
        }
    }

    process {
        Write-DebugMessage "[$($MyInvocation.MyCommand.Name)] ParameterSetName: $($PsCmdlet.ParameterSetName)"
        Write-DebugMessage "[$($MyInvocation.MyCommand.Name)] PSBoundParameters: $($PSBoundParameters | Out-String)"

        foreach ($_issue in $Issue) {
            Write-Verbose "[$($MyInvocation.MyCommand.Name)] Processing [$Issue]"
            Write-Debug "[$($MyInvocation.MyCommand.Name)] Processing `$Issue [$Issue]"

            # Find the proper object for the Issue
            $issueObj = Resolve-JiraIssueObject -InputObject $_issue -Credential $Credential

            foreach ($_link in $LinkId) {
                Write-Verbose "[$($MyInvocation.MyCommand.Name)] Processing [$_link]"
                Write-Debug "[$($MyInvocation.MyCommand.Name)] Processing `$_link [$_link]"

                $parameter = @{
                    URI        = $resourceURi -f $issueObj.Key, $_link
                    Method     = "DELETE"
                    Credential = $Credential
                }
                Write-Debug "[$($MyInvocation.MyCommand.Name)] Invoking JiraMethod with `$parameter"
                if ($PSCmdlet.ShouldProcess($issueObj.Key, "Remove RemoteLink '$_link'")) {
                    Invoke-JiraMethod @parameter
                }
            }
        }
    }

    end {
        if ($Force) {
            Write-DebugMessage "[Remove-JiraGroupMember] Restoring ConfirmPreference to [$oldConfirmPreference]"
            $ConfirmPreference = $oldConfirmPreference
        }

        Write-Verbose "[$($MyInvocation.MyCommand.Name)] Complete"
    }
}
