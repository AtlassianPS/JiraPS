function Remove-JiraIssue {
    # .ExternalHelp ..\JiraPS-help.xml
    [CmdletBinding(
        ConfirmImpact = 'High',
        SupportsShouldProcess,
        DefaultParameterSetName = "ByInputObject"
    )]
    param(
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
        $Credential,

        [Switch]
        $Force,

        [Alias('Session')]
        [AtlassianPS.Connection]
        $Connection
    )

    begin {
        Write-Verbose "[$($MyInvocation.MyCommand.Name)] Function started"

        try {
            $RequestContext = Resolve-JiraOperationContext -BoundParameters $PSBoundParameters

            $resourceURi = "/rest/api/2/issue/{0}?deleteSubtasks={1}"

            if ($Force) {
                Write-DebugMessage "-Force was passed. Backing up current ConfirmPreference [$ConfirmPreference] and setting to None"
                $oldConfirmPreference = $ConfirmPreference
                $ConfirmPreference = 'None'
            }
        }
        catch {
            if ($RequestContext -and $RequestContext.State -eq 'Standalone') { $RequestContext.Dispose() }
            throw
        }
    }

    process {
        try {

            Write-DebugMessage "ParameterSetName: $($PsCmdlet.ParameterSetName)"
            Write-DebugMessage -BoundParameters $PSBoundParameters

            $issuesToRemove = switch ($PsCmdlet.ParameterSetName) {
                "ByInputObject" { , $InputObject }
                "ByIssueId" {
                    $IssueID | ForEach-Object { Get-JiraIssueOperation -Key $_ -RequestContext $RequestContext -ErrorAction Stop }
                }
            }

            $ActionText = if ($IncludeSubTasks) { "Remove issue and sub-tasks" }
            else { "Remove issue" }

            foreach ($_issue in $issuesToRemove) {
                Write-Verbose "[$($MyInvocation.MyCommand.Name)] Processing [$_issue]"
                Write-DebugMessage "Processing `$_issue [$_issue]"

                $parameter = @{
                    URI    = $resourceURi -f $_issue.Key, $IncludeSubTasks
                    Method = "DELETE"

                    Cmdlet = $PsCmdlet
                }

                if ($PSCmdlet.ShouldProcess($_issue.ToString(), $ActionText)) {
                    Write-DebugMessage "Invoking JiraMethod with `$parameter"
                    Invoke-JiraRequest -RequestContext $RequestContext @parameter
                }
            }
        }
        catch {
            if ($RequestContext -and $RequestContext.State -eq 'Standalone') { $RequestContext.Dispose() }
            throw
        }
    }

    end {
        try {
            if ($Force) {
                Write-DebugMessage "Restoring ConfirmPreference to [$oldConfirmPreference]"
                $ConfirmPreference = $oldConfirmPreference
            }

            Write-Verbose "[$($MyInvocation.MyCommand.Name)] Complete"
        }
        finally {
            if ($RequestContext.State -eq 'Standalone') { $RequestContext.Dispose() }
        }
    }
}
