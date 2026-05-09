function Invoke-JiraIssueTransition {
    # .ExternalHelp ..\JiraPS-help.xml
    [CmdletBinding( DefaultParameterSetName = 'AssignToUser' )]
    param(
        [Parameter( Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName )]
        [ValidateNotNull()]
        [AtlassianPS.JiraPS.IssueTransformation()]
        [Alias('Key')]
        [AtlassianPS.JiraPS.Issue]
        $Issue,

        [Parameter( Mandatory )]
        $Transition,

        [PSCustomObject]
        $Fields,

        [Parameter( ParameterSetName = 'AssignToUser' )]
        [ValidateNotNull()]
        [AtlassianPS.JiraPS.UserTransformation()]
        [AtlassianPS.JiraPS.User]
        $Assignee,

        [Parameter( ParameterSetName = 'Unassign' )]
        [Switch]
        $Unassign,

        [String]
        $Comment,

        [TimeSpan]
        $TimeSpent,

        [Parameter()]
        [System.Management.Automation.PSCredential]
        [System.Management.Automation.Credential()]
        $Credential = [System.Management.Automation.PSCredential]::Empty,

        [Switch]
        $Passthru
    )

    begin {
        Write-Verbose "[$($MyInvocation.MyCommand.Name)] Function started"

        $isCloud = Test-JiraCloudServer -Credential $Credential

        # Resolve the assignee once; -Assignee / -Unassign do not vary across piped issues.
        if ($Unassign) {
            Write-DebugMessage "[$($MyInvocation.MyCommand.Name)] -Unassign passed. Issue will be unassigned."
            $assigneeString = $null
            $validAssignee = $true
        }
        elseif ($PSCmdlet.MyInvocation.BoundParameters.ContainsKey("Assignee")) {
            if ($assigneeObj = Resolve-JiraUser -InputObject $Assignee -Credential $Credential -Exact) {
                Write-Debug "[$($MyInvocation.MyCommand.Name)] User found (name=[$($assigneeObj.Name)],RestUrl=[$($assigneeObj.RestUrl)])"
                $validAssignee = $true
            }
            else {
                $exception = ([System.ArgumentException]"Invalid value for Parameter")
                $errorId = 'ParameterValue.InvalidAssignee'
                $errorCategory = 'InvalidArgument'
                $errorTarget = $Assignee
                $errorItem = New-Object -TypeName System.Management.Automation.ErrorRecord $exception, $errorId, $errorCategory, $errorTarget
                $errorItem.ErrorDetails = "Unable to validate Jira user [$Assignee]. Use Get-JiraUser for more details."
                ThrowError -ErrorRecord $errorItem
            }
        }

        if ($validAssignee) {
            $assigneeBody = Resolve-JiraUserPayload -UserObject $assigneeObj -UserString $assigneeString -IsCloud $isCloud
        }
    }

    process {
        Write-DebugMessage "[$($MyInvocation.MyCommand.Name)] ParameterSetName: $($PsCmdlet.ParameterSetName)"
        Write-DebugMessage "[$($MyInvocation.MyCommand.Name)] PSBoundParameters: $($PSBoundParameters | Out-String)"

        # Find the proper object for the Issue
        $issueObj = Resolve-JiraIssueObject -InputObject $Issue -Credential $Credential

        if ($Transition -is [AtlassianPS.JiraPS.Transition]) {
            Write-DebugMessage "[$($MyInvocation.MyCommand.Name)] Transition parameter is an AtlassianPS.JiraPS.Transition object"
            $transitionId = $Transition.Id
        }
        else {
            Write-DebugMessage "[$($MyInvocation.MyCommand.Name)] Attempting to cast Transition parameter [$Transition] as int for transition ID"
            try {
                $transitionId = [Int]"$Transition"
            }
            catch {
                $exception = ([System.ArgumentException]"Invalid Type for Parameter")
                $errorId = 'ParameterType.NotJiraTransition'
                $errorCategory = 'InvalidArgument'
                $errorTarget = $Transition
                $errorItem = New-Object -TypeName System.Management.Automation.ErrorRecord $exception, $errorId, $errorCategory, $errorTarget
                $errorItem.ErrorDetails = "Wrong object type provided for Transition. Expected [AtlassianPS.JiraPS.Transition] or [Int], but was $($Transition.GetType().Name)"
                ThrowError -ErrorRecord $errorItem
            }
        }

        Write-DebugMessage "[$($MyInvocation.MyCommand.Name)] Checking that the issue can perform the given transition"
        if (($issueObj.Transition.Id) -notcontains $transitionId) {
            $exception = ([System.ArgumentException]"Invalid value for Parameter")
            $errorId = 'ParameterValue.InvalidTransition'
            $errorCategory = 'InvalidArgument'
            $errorTarget = $Issue
            $errorItem = New-Object -TypeName System.Management.Automation.ErrorRecord $exception, $errorId, $errorCategory, $errorTarget
            $errorItem.ErrorDetails = "The specified Jira issue cannot perform transition [$transitionId]. Check the issue's Transition property and provide a transition valid for its current state."
            ThrowError -ErrorRecord $errorItem
        }

        $issueRestUrl = ConvertTo-JiraRestApiV3Url -Url $issueObj.RestUrl -IsCloud $isCloud

        $requestBody = @{
            'transition' = @{
                'id' = $transitionId
            }
        }

        if ($validAssignee) {
            Write-DebugMessage "[$($MyInvocation.MyCommand.Name)] Updating Assignee"
            $requestBody += @{
                'fields' = @{
                    'assignee' = $assigneeBody
                }
            }
        }

        $requestBody += @{
            'update' = @{}
        }

        if ($Fields) {

            Write-Debug "[$($MyInvocation.MyCommand.Name)] Resolving `$Fields against transition screen metadata"

            # Fetch this transition's screen fields: the authoritative source for which
            # fields appear on a given transition screen. Falls back to the global field
            # list for fields absent from the transition metadata (e.g. when the
            # transition has no screen, or the transition metadata fetch fails).
            $transitionMeta = $null
            try {
                $transitionMetaParam = @{
                    URI          = "{0}/transitions" -f $issueRestUrl
                    Method       = "GET"
                    GetParameter = @{ expand = "transitions.fields"; transitionId = "$transitionId" }
                    Credential   = $Credential
                }
                $transitionMeta = (Invoke-JiraMethod @transitionMetaParam -Debug:$false).transitions |
                    Where-Object { "$($_.id)" -eq "$transitionId" } |
                    Select-Object -First 1
            }
            catch {
                Write-Debug "[$($MyInvocation.MyCommand.Name)] Transition metadata unavailable for transition [$transitionId]: $_"
            }

            $scopedMeta = if (
                $transitionMeta -and
                $transitionMeta.fields -and
                $transitionMeta.fields.PSObject.Properties.Name.Count -gt 0
            ) {
                ConvertTo-JiraEditMetaField -InputObject $transitionMeta
            }
            else {
                @()
            }

            foreach ($assignment in ConvertTo-JiraFieldAssignment `
                    -Fields $Fields `
                    -ScopedMeta $scopedMeta `
                    -IsCloud $isCloud `
                    -ScopedContext 'transition metadata' `
                    -CallerName $MyInvocation.MyCommand.Name `
                    -FallbackFieldFetcher { Get-JiraField -Credential $Credential -ErrorAction Stop -Debug:$false }) {
                $requestBody.update.$($assignment.Id) = @( @{
                        'set' = $assignment.Value
                    })
            }
        }

        if ($Comment) {
            Write-DebugMessage "[$($MyInvocation.MyCommand.Name)] Adding comment"
            $requestBody.update.comment += , @{
                'add' = @{
                    'body' = Resolve-JiraTextFieldPayload -Text $Comment -IsCloud $isCloud
                }
            }
        }

        if ($PSBoundParameters.ContainsKey('TimeSpent')) {
            Write-DebugMessage "[$($MyInvocation.MyCommand.Name)] Adding worklog"
            $dateStarted = [DateTime]::new((Get-Date).Ticks, 'Local')
            $requestBody.update.worklog += , @{
                'add' = @{
                    'started'          = $dateStarted.ToString("o") -replace "\.(\d{3})\d*([\+\-]\d{2}):", ".`$1`$2"
                    'timeSpentSeconds' = $TimeSpent.TotalSeconds.ToString()
                }
            }
        }

        $parameter = @{
            URI        = "{0}/transitions" -f $issueRestUrl
            Method     = "POST"
            Body       = ConvertTo-Json -InputObject $requestBody -Depth 20
            Credential = $Credential
        }
        Write-Debug "[$($MyInvocation.MyCommand.Name)] Invoking JiraMethod with `$parameter"
        Invoke-JiraMethod @parameter

        if ($Passthru) {
            Get-JiraIssue $issueObj
        }
    }

    end {
        Write-Verbose "[$($MyInvocation.MyCommand.Name)] Complete"
    }
}
