function Invoke-JiraIssueTransition {
    # .ExternalHelp ..\JiraPS-help.xml
    [CmdletBinding( DefaultParameterSetName = 'AssignToUser' )]
    param(
        [Parameter( Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName )]
        [ValidateNotNullOrEmpty()]
        [ValidateScript(
            {
                if (("JiraPS.Issue" -notin $_.PSObject.TypeNames) -and (($_ -isnot [String]))) {
                    $exception = ([System.ArgumentException]"Invalid Type for Parameter") #fix code highlighting]
                    $errorId = 'ParameterType.NotJiraIssue'
                    $errorCategory = 'InvalidArgument'
                    $errorTarget = $_
                    $errorItem = New-Object -TypeName System.Management.Automation.ErrorRecord $exception, $errorId, $errorCategory, $errorTarget
                    $errorItem.ErrorDetails = "Wrong object type provided for Issue. Expected [JiraPS.Issue] or [String], but was $($_.GetType().Name)"
                    $PSCmdlet.ThrowTerminatingError($errorItem)
                    <#
                      #ToDo:CustomClass
                      Once we have custom classes, this check can be done with Type declaration
                    #>
                }
                else {
                    return $true
                }
            }
        )]
        [Alias('Key')]
        [Object]
        $Issue,

        [Parameter( Mandatory )]
        $Transition,

        [PSCustomObject]
        $Fields,

        [Parameter( ParameterSetName = 'AssignToUser' )]
        [ValidateNotNullOrEmpty()]
        [ValidateScript(
            {
                if ($_ -is [string] -and [string]::IsNullOrWhiteSpace($_)) {
                    throw "The -Assignee value cannot be a whitespace-only string. Use -Unassign to remove the assignee."
                }
                $true
            }
        )]
        [Object]
        $Assignee,

        [Parameter( ParameterSetName = 'Unassign' )]
        [Switch]
        $Unassign,

        [String]
        $Comment,

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
                $PSCmdlet.ThrowTerminatingError($errorItem)
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

        if ("JiraPS.Transition" -in $Transition.PSObject.TypeNames) {
            Write-DebugMessage "[$($MyInvocation.MyCommand.Name)] Transition parameter is a JiraPS.Transition object"
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
                $errorItem.ErrorDetails = "Wrong object type provided for Transition. Expected [JiraPS.Transition] or [Int], but was $($Transition.GetType().Name)"
                $PSCmdlet.ThrowTerminatingError($errorItem)
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
            $PSCmdlet.ThrowTerminatingError($errorItem)
        }

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

            Write-Debug "[$($MyInvocation.MyCommand.Name)] Enumerating fields defined on the server"

            # Fetch all available fields ahead-of-time to avoid one
            # Get-JiraField round-trip per supplied key. Mirrors the
            # pattern already used by New-JiraIssue and Set-JiraIssue.
            $AvailableFields = Get-JiraField -Credential $Credential -ErrorAction Stop -Debug:$false

            $AvailableFieldsById = $AvailableFields | Group-Object -Property Id -AsHashTable -AsString
            $AvailableFieldsByName = $AvailableFields | Group-Object -Property Name -AsHashTable -AsString

            Write-Debug "[$($MyInvocation.MyCommand.Name)] Resolving `$Fields"
            foreach ($_key in $Fields.Keys) {

                $name = $_key
                $value = $Fields.$_key
                Write-DebugMessage "[$($MyInvocation.MyCommand.Name)] Attempting to identify field (name=[$name], value=[$value])"

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

                # Force the id to a string — Get-JiraField historically
                # surfaced numeric ids as hashtables in some metadata
                # shapes, which crashed ConvertTo-Json downstream.
                $id = "$($field.Id)"

                # `-Fields` values hit a raw assignment; wrap rich-text strings here
                # for parity with the named-parameter paths.
                if ($isCloud -and ($value -is [string]) -and (Test-JiraRichTextField -Field $field)) {
                    $value = Resolve-JiraTextFieldPayload -Text $value -IsCloud $true
                }

                $requestBody.update.$id = @( @{
                        'set' = $value
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

        $issueRestUrl = ConvertTo-JiraRestApiV3Url -Url $issueObj.RestUrl -IsCloud $isCloud

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
