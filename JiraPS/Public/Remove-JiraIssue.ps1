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
        [AtlassianPS.Connection]$Connection,

        [Alias('Server', 'ServerName')]
        [ArgumentCompleter({
                param($commandName, $parameterName, $wordToComplete)
                AtlassianPS.Configuration\Get-AtlassianConnection -Product Jira |
                    Where-Object { $_.Name -like "$wordToComplete*" } |
                    ForEach-Object { $_.Name }
            })]
        [String]$ConnectionName,

        [Uri]$Uri,

        [Alias('Email')]
        [String]$EmailAddress,

        [Object]$ApiToken,

        [Alias('PAT', 'BearerToken')]
        [Object]$PersonalAccessToken,

        [Switch]$Anonymous
    )

    begin {
        try {
            Write-Verbose "[$($MyInvocation.MyCommand.Name)] Function started"

            $RequestContext = Resolve-JiraOperationContext -BoundParameters $PSBoundParameters

            $resourceURi = "/rest/api/2/issue/{0}?deleteSubtasks={1}"

            if ($Force) {
                Write-DebugMessage "[$($MyInvocation.MyCommand.Name)] -Force was passed. Backing up current ConfirmPreference [$ConfirmPreference] and setting to None"
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

            Write-DebugMessage "[$($MyInvocation.MyCommand.Name)] ParameterSetName: $($PsCmdlet.ParameterSetName)"

            $issuesToRemove = switch ($PsCmdlet.ParameterSetName) {
                "ByInputObject" { , $InputObject }
                "ByIssueId" {
                    $IssueID | ForEach-Object { Get-JiraIssueOperation -Key $_ -RequestContext $RequestContext -ErrorAction Stop }
                }
            }

            $ActionText = if ($IncludeSubTasks) { "Remove issue and sub-tasks" } else { "Remove issue" }

            foreach ($_issue in $issuesToRemove) {
                Write-Verbose "[$($MyInvocation.MyCommand.Name)] Processing [$_issue]"
                Write-Debug "[$($MyInvocation.MyCommand.Name)] Processing `$_issue [$_issue]"

                $parameter = @{
                    URI    = $resourceURi -f $_issue.Key, $IncludeSubTasks
                    Method = "DELETE"

                    Cmdlet = $PsCmdlet
                }

                if ($PSCmdlet.ShouldProcess($_issue.ToString(), $ActionText)) {
                    Write-Debug "[$($MyInvocation.MyCommand.Name)] Invoking JiraMethod with `$parameter"
                    Invoke-JiraMethod -RequestContext $RequestContext @parameter
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
                Write-DebugMessage "[$($MyInvocation.MyCommand.Name)] Restoring ConfirmPreference to [$oldConfirmPreference]"
                $ConfirmPreference = $oldConfirmPreference
            }

            Write-Verbose "[$($MyInvocation.MyCommand.Name)] Complete"
        }
        finally {
            if ($RequestContext.State -eq 'Standalone') { $RequestContext.Dispose() }
        }
    }
}
