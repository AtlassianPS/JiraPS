function Set-JiraIssue {
    # .ExternalHelp ..\JiraPS-help.xml
    [CmdletBinding( SupportsShouldProcess, DefaultParameterSetName = 'AssignToUser' )]
    param(
        [Parameter( Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName )]
        [ValidateNotNull()]
        [AtlassianPS.JiraPS.IssueTransformation()]
        [Alias('Key')]
        [AtlassianPS.JiraPS.Issue]
        $Issue,

        [String]
        $Summary,

        [String]
        $Description,

        [Alias('FixVersions')]
        [AllowEmptyCollection()]
        [AtlassianPS.JiraPS.VersionTransformation()]
        [AtlassianPS.JiraPS.Version[]]
        $FixVersion,

        [Parameter( ParameterSetName = 'AssignToUser' )]
        [ValidateNotNull()]
        [AtlassianPS.JiraPS.UserTransformation()]
        [AtlassianPS.JiraPS.User]
        $Assignee,

        [Parameter( ParameterSetName = 'Unassign' )]
        [Switch]
        $Unassign,

        [Parameter( ParameterSetName = 'UseDefaultAssignee' )]
        [Switch]
        $UseDefaultAssignee,

        [Alias("Labels")]
        [String[]]
        $Label,

        [PSCustomObject]
        $Fields,

        [String]
        $AddComment,

        [Parameter()]
        [Switch]
        $PassThru,

        [Switch]
        $SkipNotification,

        [AtlassianPS.Connection]
        $Connection
    )

    begin {
        Write-Verbose "[$($MyInvocation.MyCommand.Name)] Function started"

        $RequestContext = Resolve-JiraOperationContext -BoundParameters $PSBoundParameters

        $isCloud = Test-JiraCloudServer -RequestContext $RequestContext

        $fieldNames = $Fields.Keys
        $assigneeProvided = $PSCmdlet.MyInvocation.BoundParameters.ContainsKey("Assignee")
        $clearableFieldProvided = @('Description', 'Label', 'FixVersion' | Where-Object { $PSBoundParameters.ContainsKey($_) }).Count -gt 0
        if (-not ($Summary -or $clearableFieldProvided -or $assigneeProvided -or $Unassign -or $UseDefaultAssignee -or $fieldNames -or $AddComment)) {
            $errorMessage = @{
                Category         = "InvalidArgument"
                CategoryActivity = "Validating Arguments"
                Message          = "The parameters provided do not change the Issue. No action will be performed"
            }
            Write-Error @errorMessage
            return
        }

        if ($UseDefaultAssignee) {
            Write-DebugMessage "-UseDefaultAssignee passed. Issue will be assigned to the default assignee."
            $assigneeString = "-1"
            $validAssignee = $true
        }
        elseif ($Unassign) {
            Write-DebugMessage "-Unassign passed. Issue will be unassigned."
            $assigneeString = $null
            $validAssignee = $true
        }
        elseif ($assigneeProvided) {
            if ($assigneeObj = Resolve-JiraUser -InputObject $Assignee -RequestContext $RequestContext) {
                Write-DebugMessage "User found (name=[$($assigneeObj.Name)],RestUrl=[$($assigneeObj.RestUrl)])"
                $validAssignee = $true
            }
            else {
                $exception = ([System.ArgumentException]"Invalid value for Parameter")
                $errorId = 'ParameterValue.InvalidAssignee'
                $errorCategory = 'InvalidArgument'
                $errorTarget = $Assignee
                $errorItem = New-Object -TypeName System.Management.Automation.ErrorRecord $exception, $errorId, $errorCategory, $errorTarget
                $errorItem.ErrorDetails = "Unable to validate Jira user [$Assignee]. Use Get-JiraUser for more details."
                $PSCmdlet.ThrowTerminatingError($errorItem)
            }
        }

        # Build the assignee payload once; inputs do not vary across piped issues.
        if ($validAssignee) {
            $assigneeProps = Resolve-JiraUserPayload -UserObject $assigneeObj -UserString $assigneeString -IsCloud $isCloud
        }
    }

    process {
        Write-DebugMessage "ParameterSetName: $($PsCmdlet.ParameterSetName)"
        Write-DebugMessage -BoundParameters $PSBoundParameters

        Write-Verbose "[$($MyInvocation.MyCommand.Name)] Processing [$Issue]"
        Write-DebugMessage "Processing `$Issue [$Issue]"

        # Find the proper object for the Issue
        $issueObj = Resolve-JiraIssueObject -InputObject $Issue -RequestContext $RequestContext

        $issueProps = @{
            'update' = @{}
        }

        if ($Summary) {
            # Update properties need to be passed to JIRA as arrays
            $issueProps.update["summary"] = @(@{ 'set' = $Summary })
        }

        if ($PSBoundParameters.ContainsKey('Description')) {
            $issueProps.update["description"] = @(
                @{
                    'set' = if ($isCloud -and [String]::IsNullOrEmpty($Description)) { $null }
                    else { Resolve-JiraTextFieldPayload -Text $Description -IsCloud $isCloud }
                }
            )
        }

        if ($PSBoundParameters.ContainsKey('FixVersion')) {
            $fixVersionSet = [System.Collections.Generic.List[hashtable]]::new()
            foreach ($version in $FixVersion) {
                $versionValue = if ($version.Id) { @{ id = $version.Id } } else { @{ name = $version.Name } }
                $null = $fixVersionSet.Add($versionValue)
            }
            $issueProps.update["fixVersions"] = @( @{ set = $fixVersionSet } )
        }

        if ($AddComment) {
            $issueProps.update["comment"] = @(
                @{
                    'add' = @{
                        'body' = Resolve-JiraTextFieldPayload -Text $AddComment -IsCloud $isCloud
                    }
                }
            )
        }

        if ($Fields) {

            Write-DebugMessage "Resolving `$Fields against edit metadata"

            # Fetch edit metadata to resolve field names/IDs in the context of this
            # specific issue. Falls back to Get-JiraField when a field is not present
            # in the scoped edit metadata (e.g. the field exists in Jira but is not
            # on this issue's edit screen).
            #
            # Trade-off: this adds one unconditional API call per -Fields use.
            # The benefit is unambiguous name-based resolution (scoped to the
            # edit screen). If every key in -Fields is already a field ID the
            # extra call is wasted; however, scoped metadata is also needed for
            # ADF (rich-text) detection via Test-JiraRichTextField, so a lazy
            # "only when name lookup fails" strategy would still need it for
            # Cloud deployments. The extra call is therefore accepted.
            $scopedMeta = try {
                Get-JiraIssueEditMetadataOperation -Issue $issueObj.Key -RequestContext $RequestContext -ErrorAction Stop -Debug:$false
            }
            catch {
                Write-DebugMessage "Edit metadata unavailable for $($issueObj.Key): $_"
                @()
            }

            foreach ($assignment in ConvertTo-JiraFieldAssignment `
                    -Fields $Fields `
                    -ScopedMeta $scopedMeta `
                    -IsCloud $isCloud `
                    -ScopedContext 'edit metadata' `
                    -CallerName $MyInvocation.MyCommand.Name `
                    -FallbackFieldFetcher { Get-JiraFieldOperation -RequestContext $RequestContext -ErrorAction Stop -Debug:$false }) {
                $issueProps.update[$assignment.Id] = @(@{ 'set' = $assignment.Value })
            }
        }

        if ($PSBoundParameters.ContainsKey('Label')) {
            $issueProps.update['labels'] = @(@{ set = @(if ($null -ne $Label) { $Label }) })
        }
        $updated = $false
        $SkipNotificationParams = @{}
        if ($SkipNotification) {
            Write-Verbose "[$($MyInvocation.MyCommand.Name)] Skipping notification for watchers"
            $SkipNotificationParams = @{ notifyUsers = "false" }
        }

        $issueRestUrl = ConvertTo-JiraRestApiV3Url -Url $issueObj.RestUrl -IsCloud $isCloud

        if ( @($issueProps.update.Keys).Count -gt 0 ) {
            Write-DebugMessage "Updating issue fields"

            $parameter = @{
                URI          = $issueRestUrl
                Method       = "PUT"
                Body         = ConvertTo-Json -InputObject $issueProps -Depth 20

                GetParameter = $SkipNotificationParams
            }
            Write-DebugMessage "Invoking JiraMethod with `$parameter"
            if ($PSCmdlet.ShouldProcess($issueObj.Key, "Updating Issue")) {
                $null = Invoke-JiraRequest -RequestContext $RequestContext @parameter -ErrorAction Stop
                $updated = $true
            }
        }

        if ($assigneeProps) {
            Write-DebugMessage "Updating issue assignee"
            # Jira handles assignee differently; you can't change it from the default "edit issues" screen unless
            # you customize the "Edit Issue" screen.

            $parameter = @{
                URI          = "{0}/assignee" -f $issueRestUrl
                Method       = "PUT"
                Body         = ConvertTo-Json -InputObject $assigneeProps

                GetParameter = $SkipNotificationParams
            }
            Write-DebugMessage "Invoking JiraMethod with `$parameter"
            if ($PSCmdlet.ShouldProcess($issueObj.Key, "Updating Issue [Assignee] from JIRA")) {
                $null = Invoke-JiraRequest -RequestContext $RequestContext @parameter -ErrorAction Stop
                $updated = $true
            }
        }

        if ($PassThru -and $updated) { Get-JiraIssueOperation -Key $issueObj.Key -RequestContext $RequestContext }
    }

    end {
        Write-Verbose "[$($MyInvocation.MyCommand.Name)] Complete"
    }
}
