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
        [ValidateNotNullOrEmpty()]
        [ValidateScript(
            {
                if ($_ -is [string] -and [string]::IsNullOrWhiteSpace($_)) {
                    throw "The -Reporter value cannot be a whitespace-only string. Omit the parameter to let Jira apply the default reporter."
                }
                $true
            }
        )]
        [String]
        $Reporter,

        [Parameter( ParameterSetName = 'AssignToUser', ValueFromPipelineByPropertyName )]
        [ValidateNotNullOrEmpty()]
        [ValidateScript(
            {
                if ($_ -is [string] -and [string]::IsNullOrWhiteSpace($_)) {
                    throw "The -Assignee value cannot be a whitespace-only string. Use -Unassign to create the issue with no assignee, or omit -Assignee to let Jira apply the project default."
                }
                $true
            }
        )]
        [Object]
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
        $createmeta = Get-JiraIssueCreateMetadata -Project $Project -IssueType $IssueType -Credential $Credential -ErrorAction Stop -Debug:$false

        $resourceURi = "/rest/api/2/issue"

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
            $requestBody["description"] = $Description
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
            # do not short-circuit here: the required-field check above
            # already runs first, and the resulting Jira error is the
            # source of truth for "is unassign permitted on this project".
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

            Write-Debug "[$($MyInvocation.MyCommand.Name)] Enumerating fields for server"

            # Fetch all available fields ahead-of-time to avoid repeated API calls in the upcoming loop.
            # Eventually, this may be better to extract from CreateMeta.
            $AvailableFields = Get-JiraField -Credential $Credential -ErrorAction Stop -Debug:$false

            $AvailableFieldsById = $AvailableFields | Group-Object -Property Id -AsHashTable -AsString
            $AvailableFieldsByName = $AvailableFields | Group-Object -Property Name -AsHashTable -AsString


            Write-Debug "[$($MyInvocation.MyCommand.Name)] Resolving `$Fields"

            foreach ($_key in $Fields.Keys) {

                $name = $_key
                $value = $Fields.$_key
                # The Fields hashtable supports both name- and ID-based lookup for custom fields, so we have to search both.
                if ($AvailableFieldsById.ContainsKey($name)) {
                    $field = $AvailableFieldsById[$name][0]
                    Write-Debug "[$($MyInvocation.MyCommand.Name)] [$name] appears to be a field ID"
                }
                elseif ($AvailableFieldsById.ContainsKey("customfield_$name")) {
                    $field = $AvailableFieldsById["customfield_$name"][0]
                    Write-Debug "[$($MyInvocation.MyCommand.Name)] [$name] appears to be a numerical field ID (customfield_$name)"
                }
                elseif ($AvailableFieldsByName.ContainsKey($name) -and $AvailableFieldsByName[$name].Count -eq 1) {
                    $field = $AvailableFieldsByName[$name][0]
                    Write-Debug "[$($MyInvocation.MyCommand.Name)] [$name] appears to be a human-readable field name ($($field.ID))"
                }
                elseif ($AvailableFieldsByName.ContainsKey($name)) {
                    # Jira does not prevent multiple custom fields with the same name, so we have to ensure
                    # any name references are unambiguous.

                    # More than one value in $AvailableFieldsByName (i.e. .Count -gt 1) indicates two duplicate custom fields.
                    $exception = ([System.ArgumentException]"Ambiguously Referenced Parameter")
                    $errorId = 'ParameterValue.AmbiguousParameter'
                    $errorCategory = 'InvalidArgument'
                    $errorTarget = $Fields
                    $errorItem = New-Object -TypeName System.Management.Automation.ErrorRecord $exception, $errorId, $errorCategory, $errorTarget
                    $errorItem.ErrorDetails = "Field name [$name] in -Fields hashtable ambiguously refers to more than one field. Use Get-JiraField for more information, or specify the custom field by its ID."
                    $PSCmdlet.ThrowTerminatingError($errorItem)
                }
                else {
                    $exception = ([System.ArgumentException]"Invalid value for Parameter")
                    $errorId = 'ParameterValue.InvalidFields'
                    $errorCategory = 'InvalidArgument'
                    $errorTarget = $Fields
                    $errorItem = New-Object -TypeName System.Management.Automation.ErrorRecord $exception, $errorId, $errorCategory, $errorTarget
                    $errorItem.ErrorDetails = "Unable to identify field [$name] from -Fields hashtable. Use Get-JiraField for more information."
                    $PSCmdlet.ThrowTerminatingError($errorItem)
                }

                $id = $field.Id
                $requestBody["$id"] = $value
            }
        }


        Write-Verbose "[$($MyInvocation.MyCommand.Name)] Validating fields with metadata"
        foreach ($c in $createmeta) {
            Write-Debug "[$($MyInvocation.MyCommand.Name)] Checking metadata for `$c [$c]"
            if (-not $c.Required) {
                Write-DebugMessage "[$($MyInvocation.MyCommand.Name)] Non-required field (id=[$($c.Id)], name=[$($c.Name)])"
                continue
            }

            if ($requestBody.ContainsKey($c.Id)) {
                Write-DebugMessage "[$($MyInvocation.MyCommand.Name)] Required field (id=[$($c.Id)], name=[$($c.Name)]) was provided (value=[$($requestBody.$($c.Id))])"
                continue
            }

            # Jira marks a field as `required: true` whenever the project's
            # field configuration says it must be present on issue create.
            # However, when the same field also has `hasDefaultValue: true`
            # the server applies the configured default at create time when
            # the caller omits the value (this is what the Atlassian REST
            # docs guarantee, and what the Jira UI relies on for fields like
            # Reporter -> acting user, Priority -> project default, etc.).
            # Treating "Required + HasDefaultValue" as a hard client-side
            # requirement rejects perfectly valid create payloads. Mirror the
            # server semantics: only error out for fields that are required
            # AND have no default value the server can fall back on.
            if ($c.HasDefaultValue) {
                Write-DebugMessage "[$($MyInvocation.MyCommand.Name)] Required field (id=[$($c.Id)], name=[$($c.Name)]) was not provided but has a server-side default; relying on Jira to populate it"
                continue
            }

            $exception = ([System.ArgumentException]"Invalid or missing value Parameter")
            $errorId = 'ParameterValue.CreateMetaFailure'
            $errorCategory = 'InvalidArgument'
            $errorTarget = $Fields
            $errorItem = New-Object -TypeName System.Management.Automation.ErrorRecord $exception, $errorId, $errorCategory, $errorTarget
            $errorItem.ErrorDetails = "Jira's metadata for project [$Project] and issue type [$IssueType] specifies that a field is required that was not provided and has no server-side default (name=[$($c.Name)], id=[$($c.Id)]). Use Get-JiraIssueCreateMetadata for more information."
            $PSCmdlet.ThrowTerminatingError($errorItem)
        }

        $hashtable = @{
            'fields' = ([PSCustomObject]$requestBody)
        }

        $parameter = @{
            URI        = $resourceURi
            Method     = "POST"
            Body       = (ConvertTo-Json -InputObject ([PSCustomObject]$hashtable) -Depth 7)
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
