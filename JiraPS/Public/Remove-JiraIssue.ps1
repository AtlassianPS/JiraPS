function Remove-JiraIssue {
    # .ExternalHelp ..\JiraPS-help.xml
    [CmdletBinding(
        ConfirmImpact = 'High',
        SupportsShouldProcess,
        DefaultParameterSetName = "ByInputObject"
    )]
    param (
        [Parameter(
            Mandatory,
            ValueFromPipeline,
            Position = 0,
            ParameterSetName = "ByInputObject"
        )]
        [ValidateNotNull()]
        [AtlassianPS.JiraPS.IssueTransformation()]
        [Alias("Issue")]
        [AtlassianPS.JiraPS.Issue]
        $InputObject,

        # The issue's ID number or key.
        [Parameter(
            Mandatory,
            Position = 0,
            ParameterSetName = "ByIssueId"
        )]
        [ValidateNotNullOrEmpty()]
        [Alias(
            "Id",
            "Key",
            "issueIdOrKey"
        )]
        [String[]]
        $IssueId,

        [Switch]
        [Alias("deleteSubtasks")]
        $IncludeSubTasks,

        [System.Management.Automation.CredentialAttribute()]
        [System.Management.Automation.PSCredential]
        $Credential = [System.Management.Automation.PSCredential]::Empty,

        [Switch]
        $Force
    )

    begin {
        Write-Verbose "[$($MyInvocation.MyCommand.Name)] Function started"

        $resourceURi = "/rest/api/2/issue/{0}?deleteSubtasks={1}"

        if ($Force) {
            Write-DebugMessage "[$($MyInvocation.MyCommand.Name)] -Force was passed. Backing up current ConfirmPreference [$ConfirmPreference] and setting to None"
            $oldConfirmPreference = $ConfirmPreference
            $ConfirmPreference = 'None'
        }
    }

    process {

        Write-DebugMessage "[$($MyInvocation.MyCommand.Name)] ParameterSetName: $($PsCmdlet.ParameterSetName)"
        Write-DebugMessage "[$($MyInvocation.MyCommand.Name)] PSBoundParameters: $($PSBoundParameters | Out-String)"

        $issuesToRemove = switch ($PsCmdlet.ParameterSetName) {
            "ByInputObject" { , $InputObject }
            "ByIssueId" { $IssueID | ForEach-Object { Get-JiraIssue -Key $_ -Credential $Credential -ErrorAction Stop } }
        }

        if ($IncludeSubTasks) {
            $ActionText = "Remove issue and sub-tasks"
        }
        else {
            $ActionText = "Remove issue"
        }

        foreach ($_issue in $issuesToRemove) {
            Write-Verbose "[$($MyInvocation.MyCommand.Name)] Processing [$_issue]"
            Write-Debug "[$($MyInvocation.MyCommand.Name)] Processing `$_issue [$_issue]"

            $parameter = @{
                URI        = $resourceURi -f $_issue.Key, $IncludeSubTasks
                Method     = "DELETE"
                Credential = $Credential
                Cmdlet     = $PsCmdlet
            }

            if ($PSCmdlet.ShouldProcess($_issue.ToString(), $ActionText)) {
                Write-Debug "[$($MyInvocation.MyCommand.Name)] Invoking JiraMethod with `$parameter"
                Invoke-JiraMethod @parameter
            }
        }
    }

    end {
        if ($Force) {
            Write-DebugMessage "[$($MyInvocation.MyCommand.Name)] Restoring ConfirmPreference to [$oldConfirmPreference]"
            $ConfirmPreference = $oldConfirmPreference
        }

        Write-Verbose "[$($MyInvocation.MyCommand.Name)] Complete"
    }
}
