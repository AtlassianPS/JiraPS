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
        [ValidateNotNull()]
        [AtlassianPS.JiraPS.TransitionTransformation()]
        [AtlassianPS.JiraPS.Transition]
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
        $Credential,

        [Switch]
        $Passthru,

        [Alias('Session')]
        [AtlassianPS.Connection]
        $Connection
    )

    begin {
        try {
            Write-Verbose "[$($MyInvocation.MyCommand.Name)] Function started"

            $RequestContext = Resolve-JiraOperationContext -BoundParameters $PSBoundParameters

            $isCloud = Test-JiraCloudServer -RequestContext $RequestContext

            # Resolve the assignee once; -Assignee / -Unassign do not vary across piped issues.
            if ($Unassign) {
                Write-DebugMessage "[$($MyInvocation.MyCommand.Name)] -Unassign passed. Issue will be unassigned."
                $assigneeString = $null
                $validAssignee = $true
            }
            elseif ($PSCmdlet.MyInvocation.BoundParameters.ContainsKey("Assignee")) {
                if ($assigneeObj = Resolve-JiraUser -InputObject $Assignee -RequestContext $RequestContext -Exact) {
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
        catch {
            if ($RequestContext -and $RequestContext.State -eq 'Standalone') { $RequestContext.Dispose() }
            throw
        }
    }

    process {
        try {
            Write-DebugMessage "[$($MyInvocation.MyCommand.Name)] ParameterSetName: $($PsCmdlet.ParameterSetName)"

            # Find the proper object for the Issue
            $issueObj = Resolve-JiraIssueObject -InputObject $Issue -RequestContext $RequestContext

            $transitionId = $Transition.Id
            if ($null -eq $transitionId -and $Transition.Name) {
                $matchingTransitions = @($issueObj.Transition | Where-Object -FilterScript { $_.Name -eq $Transition.Name })
                if ($matchingTransitions.Count -eq 1) { $transitionId = $matchingTransitions[0].Id }
            }

            Write-DebugMessage "[$($MyInvocation.MyCommand.Name)] Checking that the issue can perform the given transition"
            if ($null -eq $transitionId -or ($issueObj.Transition.Id) -notcontains $transitionId) {
                $errorItem = [System.Management.Automation.ErrorRecord]::new(
                    [System.ArgumentException]::new('Invalid value for Parameter'),
                    'ParameterValue.InvalidTransition',
                    [System.Management.Automation.ErrorCategory]::InvalidArgument,
                    $Issue
                )

                $requestedTransition = if ($null -ne $transitionId) { $transitionId }
                else { $Transition.Name }
                $errorItem.ErrorDetails = "The specified Jira issue cannot perform transition [$requestedTransition]. Check the issue's Transition property and provide a transition valid for its current state."
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
                    }
                    $transitionMeta = (Invoke-JiraMethod -RequestContext $RequestContext @transitionMetaParam -Debug:$false).transitions |
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
                else { @() }

                foreach ($assignment in ConvertTo-JiraFieldAssignment `
                        -Fields $Fields `
                        -ScopedMeta $scopedMeta `
                        -IsCloud $isCloud `
                        -ScopedContext 'transition metadata' `
                        -CallerName $MyInvocation.MyCommand.Name `
                        -FallbackFieldFetcher { Get-JiraFieldOperation -RequestContext $RequestContext -ErrorAction Stop -Debug:$false }) {
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
                        'started'   = $dateStarted.ToString("o") -replace "\.(\d{3})\d*([\+\-]\d{2}):", ".`$1`$2"
                        'timeSpent' = $TimeSpent.TotalMinutes.ToString([System.Globalization.CultureInfo]::InvariantCulture) + 'm'
                    }
                }
            }

            $parameter = @{
                URI    = "{0}/transitions" -f $issueRestUrl
                Method = "POST"
                Body   = ConvertTo-Json -InputObject $requestBody -Depth 20
            }
            Write-Debug "[$($MyInvocation.MyCommand.Name)] Invoking JiraMethod with `$parameter"
            Invoke-JiraMethod -RequestContext $RequestContext @parameter

            if ($Passthru) { Get-JiraIssueOperation -RequestContext $RequestContext $issueObj }
        }
        catch {
            if ($RequestContext -and $RequestContext.State -eq 'Standalone') { $RequestContext.Dispose() }
            throw
        }
    }

    end {
        try {
            Write-Verbose "[$($MyInvocation.MyCommand.Name)] Complete"
        }
        finally {
            if ($RequestContext.State -eq 'Standalone') { $RequestContext.Dispose() }
        }
    }
}
