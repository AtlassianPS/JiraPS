function New-JiraIssue {
    # .ExternalHelp ..\JiraPS-help.xml
    [CmdletBinding( SupportsShouldProcess, DefaultParameterSetName = 'AssignToUser' )]
    param(
        [Parameter( Mandatory, ValueFromPipelineByPropertyName )]
        [AtlassianPS.JiraPS.ProjectTransformation()]
        [AtlassianPS.JiraPS.Project]
        $Project,

        [Parameter( Mandatory, ValueFromPipelineByPropertyName )]
        [AtlassianPS.JiraPS.IssueTypeTransformation()]
        [AtlassianPS.JiraPS.IssueType]
        $IssueType,

        [Parameter( Mandatory, ValueFromPipelineByPropertyName )]
        [String]
        $Summary,

        [Parameter( ValueFromPipelineByPropertyName )]
        [AtlassianPS.JiraPS.PriorityTransformation()]
        [AtlassianPS.JiraPS.Priority]
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
        [AtlassianPS.JiraPS.VersionTransformation()]
        [AtlassianPS.JiraPS.Version[]]
        $FixVersion,

        [Parameter( ValueFromPipelineByPropertyName )]
        [PSCustomObject]
        $Fields,

        [Parameter( ValueFromPipelineByPropertyName )]
        [AllowNull()]
        [AtlassianPS.JiraPS.ComponentTransformation()]
        [AtlassianPS.JiraPS.Component[]]
        $Components,

        [Parameter()]
        [System.Management.Automation.PSCredential]
        [System.Management.Automation.Credential()]
        $Credential,

        [Alias('Session')][AtlassianPS.Connection]$Connection,

        [Alias('Server', 'ServerName')]
        [ArgumentCompleter({
                param($commandName, $parameterName, $wordToComplete)
                AtlassianPS.Configuration\Get-AtlassianConnection -Product Jira |
                    Where-Object { $_.Name -like "$wordToComplete*" } |
                    ForEach-Object { $_.Name }
            })][String]$ConnectionName,

        [Uri]$Uri,

        [Alias('Email')][String]$EmailAddress,

        [Object]$ApiToken,

        [Alias('PAT', 'BearerToken')][Object]$PersonalAccessToken,

        [Switch]$Anonymous
    )
    begin {
        try {
            Write-Verbose "[$($MyInvocation.MyCommand.Name)] Function started"

            $RequestContext = Resolve-JiraOperationContext -BoundParameters $PSBoundParameters

            $isCloud = Test-JiraCloudServer -RequestContext $RequestContext
        }
        catch {
            if ($RequestContext -and $RequestContext.State -eq 'Standalone') { $RequestContext.Dispose() }
            throw
        }
    }

    process {
        try {
            $resourceURi = ConvertTo-JiraRestApiV3Url -Url "/rest/api/2/issue" -IsCloud $isCloud

            Write-DebugMessage "[$($MyInvocation.MyCommand.Name)] ParameterSetName: $($PsCmdlet.ParameterSetName)"

            $ProjectObj = Get-JiraProjectOperation -Project $Project -RequestContext $RequestContext -ErrorAction Stop -Debug:$false
            $issueTypeObj = $projectObj.IssueTypes | Where-Object -FilterScript {
                if ($null -ne $IssueType.Id) { $_.Id -eq $IssueType.Id } else { $_.Name -eq $IssueType.Name }
            }

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
                $priorityId = $Priority.Id
                if ($null -eq $priorityId) {
                    $matchingPriorities = @(Get-JiraPriorityOperation -RequestContext $RequestContext -ErrorAction Stop |
                            Where-Object -FilterScript { $_.Name -eq $Priority.Name })

                    if ($matchingPriorities.Count -ne 1) {
                        ThrowError -ExceptionType 'System.ArgumentException' `
                            -ErrorId 'ParameterValue.InvalidPriority' `
                            -Category InvalidArgument `
                            -TargetObject $Priority `
                            -Message "Priority '$($Priority.Name)' must identify exactly one priority. Use Get-JiraPriority to find a valid priority ID."
                    }
                    $priorityId = $matchingPriorities[0].Id
                }
                $requestBody["priority"] = @{"id" = [String] $priorityId }
            }

            if ($Description) { $requestBody["description"] = Resolve-JiraTextFieldPayload -Text $Description -IsCloud $isCloud }

            if ($PSCmdlet.MyInvocation.BoundParameters.ContainsKey("Reporter")) {
                if ($reporterUser = Resolve-JiraUser -InputObject $Reporter -Exact -RequestContext $RequestContext) {
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
                if ($assigneeUser = Resolve-JiraUser -InputObject $Assignee -Exact -RequestContext $RequestContext) {
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

            if ($Parent) { $requestBody["parent"] = @{"key" = $Parent } }

            if ($Label) {
                $requestBody["labels"] = [System.Collections.Generic.List[string]]::new()
                $Label.ForEach({ $null = $requestBody["labels"].Add($_) })
            }

            if ($Components) {
                $requestBody["components"] = [System.Collections.Generic.List[hashtable]]::new()
                $Components.ForEach({
                        $componentValue = if ($_.Id) { @{ id = $_.Id } } else { @{ name = $_.Name } }
                        $null = $requestBody["components"].Add($componentValue)
                    })
            }

            if ($FixVersion) {
                $requestBody['fixVersions'] = [System.Collections.Generic.List[hashtable]]::new()
                $FixVersion.ForEach({
                        $versionValue = if ($_.Id) { @{ id = $_.Id } } else { @{ name = $_.Name } }
                        $null = $requestBody["fixVersions"].Add($versionValue)
                    })
            }

            if ($Fields) {

                Write-Debug "[$($MyInvocation.MyCommand.Name)] Resolving `$Fields against create metadata"

                # Fetch create metadata lazily so `-Fields` can resolve names against
                # the current project/issue-type create screen without restoring the
                # removed client-side required-field validation behavior.
                $createmeta = Get-JiraIssueCreateMetadataOperation `
                    -Project $Project `
                    -IssueType $IssueType `
                    -RequestContext $RequestContext `
                    -ErrorAction Stop `
                    -Debug:$false

                # This gives context-aware, unambiguous resolution for fields on this
                # project/issue-type create screen and avoids a global Get-JiraField
                # round-trip for the common case. Get-JiraField is only fetched as a
                # fallback for fields not present in the scoped metadata.
                foreach ($assignment in ConvertTo-JiraFieldAssignment `
                        -Fields $Fields `
                        -ScopedMeta $createmeta `
                        -IsCloud $isCloud `
                        -ScopedContext 'create metadata' `
                        -CallerName $MyInvocation.MyCommand.Name `
                        -FallbackFieldFetcher { Get-JiraFieldOperation -RequestContext $RequestContext -ErrorAction Stop -Debug:$false }) {
                    $requestBody[$assignment.Id] = $assignment.Value
                }
            }


            $hashtable = @{
                'fields' = ([PSCustomObject]$requestBody)
            }

            $parameter = @{
                URI    = $resourceURi
                Method = "POST"
                Body   = (ConvertTo-Json -InputObject ([PSCustomObject]$hashtable) -Depth 20)

            }
            Write-Debug "[$($MyInvocation.MyCommand.Name)] Invoking JiraMethod with `$parameter"
            if ($PSCmdlet.ShouldProcess($Summary, "Creating new Issue on JIRA")) {
                if ($result = Invoke-JiraMethod -RequestContext $RequestContext @parameter) {
                    # REST result will look something like this:
                    # {"id":"12345","key":"IT-3676","self":"http://jiraserver.example.com/rest/api/2/issue/12345"}
                    # This will fetch the created issue to return it with all it'a properties
                    Write-Output (Get-JiraIssueOperation -Key $result.Key -RequestContext $RequestContext)
                }
            }
            Write-Verbose "[$($MyInvocation.MyCommand.Name)] Complete"
        }
        catch {
            if ($RequestContext -and $RequestContext.State -eq 'Standalone') { $RequestContext.Dispose() }
            throw
        }
    }

    end {
        try {
        }
        finally {
            if ($RequestContext.State -eq 'Standalone') { $RequestContext.Dispose() }
        }
    }
}
