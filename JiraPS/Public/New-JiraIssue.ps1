function New-JiraIssue {
    # .ExternalHelp ..\JiraPS-help.xml
    [CmdletBinding( SupportsShouldProcess, DefaultParameterSetName = 'AssignToUser' )]
    param(
        [Parameter( Mandatory, ValueFromPipelineByPropertyName )]
        [String]
        $Project,

        [Parameter( Mandatory, ValueFromPipelineByPropertyName )]
        [String]
        $IssueType,

        [Parameter( Mandatory, ValueFromPipelineByPropertyName )]
        [String]
        $Summary,

        [Parameter( ValueFromPipelineByPropertyName )]
        [Int]
        $Priority,

        [Parameter( ValueFromPipelineByPropertyName )]
        [String]
        $Description,

        [Parameter( ValueFromPipelineByPropertyName )]
        [ValidateNotNull()]
        [AtlassianPS.JiraPS.UserTransformation()]
        [AtlassianPS.JiraPS.User]
        $Reporter,

        [Parameter( ParameterSetName = 'AssignToUser', ValueFromPipelineByPropertyName )]
        [ValidateNotNull()]
        [AtlassianPS.JiraPS.UserTransformation()]
        [AtlassianPS.JiraPS.User]
        $Assignee,

        [Parameter( ParameterSetName = 'Unassign' )]
        [Switch]
        $Unassign,

        [Parameter( ValueFromPipelineByPropertyName )]
        [Alias("Labels")]
        [String[]]
        $Label,

        [Parameter( ValueFromPipelineByPropertyName )]
        [String]
        $Parent,

        [Parameter( ValueFromPipelineByPropertyName )]
        [Alias('FixVersions')]
        [String[]]
        $FixVersion,

        [Parameter( ValueFromPipelineByPropertyName )]
        [PSCustomObject]
        $Fields,

        [Parameter( ValueFromPipelineByPropertyName )]
        [AllowNull()]
        [String[]]
        $Components,

        [Parameter()]
        [System.Management.Automation.PSCredential]
        [System.Management.Automation.Credential()]
        $Credential = [System.Management.Automation.PSCredential]::Empty
    )

    begin {
        Write-Verbose "[$($MyInvocation.MyCommand.Name)] Function started"

        $isCloud = Test-JiraCloudServer -Credential $Credential
    }

    process {
        $resourceURi = ConvertTo-JiraRestApiV3Url -Url "/rest/api/2/issue" -IsCloud $isCloud

        Write-DebugMessage "[$($MyInvocation.MyCommand.Name)] ParameterSetName: $($PsCmdlet.ParameterSetName)"
        Write-DebugMessage "[$($MyInvocation.MyCommand.Name)] PSBoundParameters: $($PSBoundParameters | Out-String)"

        $ProjectObj = Get-JiraProject -Project $Project -Credential $Credential -ErrorAction Stop -Debug:$false
        $issueTypeObj = $projectObj.IssueTypes | Where-Object -FilterScript { $_.Id -eq $IssueType -or $_.Name -eq $IssueType }

        if ($null -eq $issueTypeObj.Id) {
            $errorMessage = @{
                Category         = "InvalidResult"
                CategoryActivity = "Validating parameters"
                Message          = "No issue types were found in the project [$Project] for the given issue type [$IssueType]. Use Get-JiraIssueType for more details."
            }
            Write-Error @errorMessage
        }

        $requestBody = @{
            "project"   = @{"id" = $ProjectObj.Id }
            "issuetype" = @{"id" = [String] $IssueTypeObj.Id }
            "summary"   = $Summary
        }

        if ($Priority) {
            $requestBody["priority"] = @{"id" = [String] $Priority }
        }

        if ($Description) {
            $requestBody["description"] = Resolve-JiraTextFieldPayload -Text $Description -IsCloud $isCloud
        }

        if ($PSCmdlet.MyInvocation.BoundParameters.ContainsKey("Reporter")) {
            if ($reporterUser = Resolve-JiraUser -InputObject $Reporter -Exact -Credential $Credential) {
                Write-Debug "[$($MyInvocation.MyCommand.Name)] Reporter resolved (name=[$($reporterUser.Name)])"
            }
            else {
                $exception = ([System.ArgumentException]"Invalid value for Parameter")
                $errorId = 'ParameterValue.InvalidReporter'
                $errorCategory = 'InvalidArgument'
                $errorTarget = $Reporter
                $errorItem = New-Object -TypeName System.Management.Automation.ErrorRecord $exception, $errorId, $errorCategory, $errorTarget
                $errorItem.ErrorDetails = "Unable to validate Jira user [$Reporter]. Use Get-JiraUser for more details."
                $PSCmdlet.ThrowTerminatingError($errorItem)
            }

            $requestBody["reporter"] = Resolve-JiraUserPayload -UserObject $reporterUser -IsCloud $isCloud
        }

        if ($Unassign) {
            # When `assignee` is required by the project's createmeta, Jira
            # will reject the unassign payload server-side. We deliberately
            # defer to Jira's response rather than attempting to duplicate
            # create-screen validation in the client.
            $requestBody["assignee"] = Resolve-JiraUserPayload -UserObject $null -IsCloud $isCloud
        }
        elseif ($PSCmdlet.MyInvocation.BoundParameters.ContainsKey("Assignee")) {
            if ($assigneeUser = Resolve-JiraUser -InputObject $Assignee -Exact -Credential $Credential) {
                Write-Debug "[$($MyInvocation.MyCommand.Name)] Assignee resolved (name=[$($assigneeUser.Name)])"
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

            $requestBody["assignee"] = Resolve-JiraUserPayload -UserObject $assigneeUser -IsCloud $isCloud
        }

        if ($Parent) {
            $requestBody["parent"] = @{"key" = $Parent }
        }

        if ($Label) {
            $requestBody["labels"] = [System.Collections.Generic.List[string]]::new()
            $Label.ForEach({ $null = $requestBody["labels"].Add($_) })
        }

        if ($Components) {
            $requestBody["components"] = [System.Collections.Generic.List[hashtable]]::new()
            $Components.ForEach({ $null = $requestBody["components"].Add(@{ id = "$_" }) })
        }

        if ($FixVersion) {
            $requestBody['fixVersions'] = [System.Collections.Generic.List[hashtable]]::new()
            $FixVersion.ForEach({ $null = $requestBody["fixVersions"].Add(@{ name = "$_" }) })
        }

        if ($Fields) {

            Write-Debug "[$($MyInvocation.MyCommand.Name)] Resolving `$Fields against create metadata"

            # Use the create metadata already fetched for required-field validation.
            # This gives context-aware, unambiguous resolution for fields on this
            # project/issue-type create screen and avoids a global Get-JiraField
            # round-trip for the common case. Get-JiraField is only fetched as a
            # fallback for fields not present in the scoped metadata.
            $ScopedFieldsById = if ($createmeta) {
                $createmeta | Group-Object -Property Id -AsHashTable -AsString
            }
            else {
                @{}
            }
            $ScopedFieldsByName = if ($createmeta) {
                $createmeta | Group-Object -Property Name -AsHashTable -AsString
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
                    Write-Debug "[$($MyInvocation.MyCommand.Name)] [$name] not in create metadata; fetching global field list as fallback"
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

                $id = "$($field.Id)"

                # `-Fields` values hit a raw assignment; wrap rich-text strings here
                # for parity with the named-parameter paths.
                if ($isCloud -and ($value -is [string]) -and (Test-JiraRichTextField -Field $field)) {
                    $value = Resolve-JiraTextFieldPayload -Text $value -IsCloud $true
                }

                $requestBody["$id"] = $value
            }
        }


        $hashtable = @{
            'fields' = ([PSCustomObject]$requestBody)
        }

        $parameter = @{
            URI        = $resourceURi
            Method     = "POST"
            Body       = (ConvertTo-Json -InputObject ([PSCustomObject]$hashtable) -Depth 20)
            Credential = $Credential
        }
        Write-Debug "[$($MyInvocation.MyCommand.Name)] Invoking JiraMethod with `$parameter"
        if ($PSCmdlet.ShouldProcess($Summary, "Creating new Issue on JIRA")) {
            if ($result = Invoke-JiraMethod @parameter) {
                # REST result will look something like this:
                # {"id":"12345","key":"IT-3676","self":"http://jiraserver.example.com/rest/api/2/issue/12345"}
                # This will fetch the created issue to return it with all it'a properties
                Write-Output (Get-JiraIssue -Key $result.Key -Credential $Credential)
            }
        }
        Write-Verbose "[$($MyInvocation.MyCommand.Name)] Complete"
    }

    end {
    }
}
