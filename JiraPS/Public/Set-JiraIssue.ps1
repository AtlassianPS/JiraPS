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
        [String[]]
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
        [System.Management.Automation.PSCredential]
        [System.Management.Automation.Credential()]
        $Credential = [System.Management.Automation.PSCredential]::Empty,

        [Switch]
        $PassThru,

        [Switch]
        $SkipNotification
    )

    begin {
        Write-Verbose "[$($MyInvocation.MyCommand.Name)] Function started"

        $isCloud = Test-JiraCloudServer -Credential $Credential

        $fieldNames = $Fields.Keys
        $assigneeProvided = $PSCmdlet.MyInvocation.BoundParameters.ContainsKey("Assignee")
        if (-not ($Summary -or $Description -or $assigneeProvided -or $Unassign -or $UseDefaultAssignee -or $Label -or $FixVersion -or $fieldNames -or $AddComment)) {
            $errorMessage = @{
                Category         = "InvalidArgument"
                CategoryActivity = "Validating Arguments"
                Message          = "The parameters provided do not change the Issue. No action will be performed"
            }
            Write-Error @errorMessage
            return
        }

        if ($UseDefaultAssignee) {
            Write-DebugMessage "[$($MyInvocation.MyCommand.Name)] -UseDefaultAssignee passed. Issue will be assigned to the default assignee."
            $assigneeString = "-1"
            $validAssignee = $true
        }
        elseif ($Unassign) {
            Write-DebugMessage "[$($MyInvocation.MyCommand.Name)] -Unassign passed. Issue will be unassigned."
            $assigneeString = $null
            $validAssignee = $true
        }
        elseif ($assigneeProvided) {
            if ($assigneeObj = Resolve-JiraUser -InputObject $Assignee -Exact -Credential $Credential) {
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
                $PSCmdlet.ThrowTerminatingError($errorItem)
            }
        }

        # Build the assignee payload once; inputs do not vary across piped issues.
        if ($validAssignee) {
            $assigneeProps = Resolve-JiraUserPayload -UserObject $assigneeObj -UserString $assigneeString -IsCloud $isCloud
        }
    }

    process {
        Write-DebugMessage "[$($MyInvocation.MyCommand.Name)] ParameterSetName: $($PsCmdlet.ParameterSetName)"
        Write-DebugMessage "[$($MyInvocation.MyCommand.Name)] PSBoundParameters: $($PSBoundParameters | Out-String)"

        Write-Verbose "[$($MyInvocation.MyCommand.Name)] Processing [$Issue]"
        Write-Debug "[$($MyInvocation.MyCommand.Name)] Processing `$Issue [$Issue]"

        # Find the proper object for the Issue
        $issueObj = Resolve-JiraIssueObject -InputObject $Issue -Credential $Credential

        $issueProps = @{
            'update' = @{}
        }

        if ($Summary) {
            # Update properties need to be passed to JIRA as arrays
            $issueProps.update["summary"] = @(@{ 'set' = $Summary })
        }

        if ($Description) {
            $issueProps.update["description"] = @(
                @{
                    'set' = Resolve-JiraTextFieldPayload -Text $Description -IsCloud $isCloud
                }
            )
        }

        if ($FixVersion) {
            $fixVersionSet = [System.Collections.Generic.List[hashtable]]::new()
            $FixVersion.ForEach({ $null = $fixVersionSet.Add(@{ 'name' = $_ }) })
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

            Write-Debug "[$($MyInvocation.MyCommand.Name)] Resolving `$Fields against edit metadata"

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
                Get-JiraIssueEditMetadata -Issue $issueObj.Key -Credential $Credential -ErrorAction Stop -Debug:$false
            }
            catch {
                Write-Debug "[$($MyInvocation.MyCommand.Name)] Edit metadata unavailable for $($issueObj.Key): $_"
                @()
            }

            $ScopedFieldsById = if ($scopedMeta) {
                $scopedMeta | Group-Object -Property Id -AsHashTable -AsString
            }
            else {
                @{}
            }
            $ScopedFieldsByName = if ($scopedMeta) {
                $scopedMeta | Group-Object -Property Name -AsHashTable -AsString
            }
            else {
                @{}
            }

            $FallbackFieldsById = $null
            $FallbackFieldsByName = $null

            Write-Debug "[$($MyInvocation.MyCommand.Name)] Resolving `$Fields"
            foreach ($_key in $Fields.Keys) {

                $name = $_key
                $value = $Fields.$_key
                Write-DebugMessage "[$($MyInvocation.MyCommand.Name)] Attempting to identify field (name=[$name], value=[$value])"

                if (
                    -not $ScopedFieldsById.ContainsKey($name) -and
                    -not $ScopedFieldsById.ContainsKey("customfield_$name") -and
                    -not $ScopedFieldsByName.ContainsKey($name) -and
                    $null -eq $FallbackFieldsById
                ) {
                    Write-Debug "[$($MyInvocation.MyCommand.Name)] [$name] not in edit metadata; fetching global field list as fallback"
                    $fb = Get-JiraField -Credential $Credential -ErrorAction Stop -Debug:$false
                    $FallbackFieldsById = if ($fb) { $fb | Group-Object -Property Id -AsHashTable -AsString } else { @{} }
                    $FallbackFieldsByName = if ($fb) { $fb | Group-Object -Property Name -AsHashTable -AsString } else { @{} }
                }

                $FallbackByIdForResolve = @{}
                $FallbackByNameForResolve = @{}
                if ($null -ne $FallbackFieldsById) {
                    $FallbackByIdForResolve = $FallbackFieldsById
                    $FallbackByNameForResolve = $FallbackFieldsByName
                }

                $field = Resolve-JiraField `
                    -Name          $name `
                    -ScopedById    $ScopedFieldsById `
                    -ScopedByName  $ScopedFieldsByName `
                    -FallbackById  $FallbackByIdForResolve `
                    -FallbackByName $FallbackByNameForResolve `
                    -CallerName    $MyInvocation.MyCommand.Name

                $id = [string]$field.Id

                # `-Fields` values hit a raw assignment; wrap rich-text strings here
                # for parity with the named-parameter paths.
                if ($isCloud -and ($value -is [string]) -and (Test-JiraRichTextField -Field $field)) {
                    $value = Resolve-JiraTextFieldPayload -Text $value -IsCloud $true
                }

                $issueProps.update[$id] = @(@{ 'set' = $value })
            }
        }

        $SkipNotificationParams = @{}
        if ($SkipNotification) {
            Write-Verbose "[$($MyInvocation.MyCommand.Name)] Skipping notification for watchers"
            $SkipNotificationParams = @{ notifyUsers = "false" }
        }

        $issueRestUrl = ConvertTo-JiraRestApiV3Url -Url $issueObj.RestUrl -IsCloud $isCloud

        if ( @($issueProps.update.Keys).Count -gt 0 ) {
            Write-DebugMessage "[$($MyInvocation.MyCommand.Name)] Updating issue fields"

            $parameter = @{
                URI          = $issueRestUrl
                Method       = "PUT"
                Body         = ConvertTo-Json -InputObject $issueProps -Depth 20
                Credential   = $Credential
                GetParameter = $SkipNotificationParams
            }
            Write-Debug "[$($MyInvocation.MyCommand.Name)] Invoking JiraMethod with `$parameter"
            if ($PSCmdlet.ShouldProcess($issueObj.Key, "Updating Issue")) {
                Invoke-JiraMethod @parameter
            }
        }

        if ($assigneeProps) {
            Write-DebugMessage "[$($MyInvocation.MyCommand.Name)] Updating issue assignee"
            # Jira handles assignee differently; you can't change it from the default "edit issues" screen unless
            # you customize the "Edit Issue" screen.

            $parameter = @{
                URI          = "{0}/assignee" -f $issueRestUrl
                Method       = "PUT"
                Body         = ConvertTo-Json -InputObject $assigneeProps
                Credential   = $Credential
                GetParameter = $SkipNotificationParams
            }
            Write-Debug "[$($MyInvocation.MyCommand.Name)] Invoking JiraMethod with `$parameter"
            if ($PSCmdlet.ShouldProcess($issueObj.Key, "Updating Issue [Assignee] from JIRA")) {
                Invoke-JiraMethod @parameter
            }
        }

        if ($Label) {
            Set-JiraIssueLabel -Issue $issueObj -Set $Label -Credential $Credential
        }

        if ($PassThru) {
            Get-JiraIssue -Key $issueObj.Key -Credential $Credential
        }
    }

    end {
        Write-Verbose "[$($MyInvocation.MyCommand.Name)] Complete"
    }
}
