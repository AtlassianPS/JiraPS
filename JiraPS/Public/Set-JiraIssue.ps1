function Set-JiraIssue {
    # .ExternalHelp ..\JiraPS-help.xml
    [CmdletBinding( SupportsShouldProcess )]
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
        [Object[]]
        $Issue,

        [String]
        $Summary,

        [String]
        $Description,

        [Alias('FixVersions')]
        [String[]]
        $FixVersion,

        [Object]
        $Assignee,

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

        $fieldNames = $Fields.Keys
        if (-not ($Summary -or $Description -or $Assignee -or $Label -or $FixVersion -or $fieldNames -or $AddComment)) {
            $errorMessage = @{
                Category         = "InvalidArgument"
                CategoryActivity = "Validating Arguments"
                Message          = "The parameters provided do not change the Issue. No action will be performed"
            }
            Write-Error @errorMessage
            return
        }

        if ($PSCmdlet.MyInvocation.BoundParameters.ContainsKey("Assignee")) {
            if ($Assignee -eq 'Unassigned') {
                <#
                  #ToDo:Deprecated
                  This behavior should be deprecated
                #>
                Write-DebugMessage "[$($MyInvocation.MyCommand.Name)] 'Unassigned' String passed. Issue will be assigned to no one."
                $assigneeString = $null
                $validAssignee = $true
            }
            elseif ($Assignee -eq "Default") {
                <#
                  #ToDo:Deprecated
                  This behavior should be deprecated
                #>
                Write-DebugMessage "[$($MyInvocation.MyCommand.Name)] 'Default' String passed. Issue will be assigned to the default assignee."
                $assigneeString = "-1"
                $validAssignee = $true
            }
            else {
                if ($assigneeObj = Resolve-JiraUser -InputObject $Assignee -Exact -Credential $Credential) {
                    Write-Debug "[$($MyInvocation.MyCommand.Name)] User found (name=[$($assigneeObj.Name)],RestUrl=[$($assigneeObj.RestUrl)])"
                    $assigneeString = $assigneeObj.Name
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
        }
    }

    process {
        Write-DebugMessage "[$($MyInvocation.MyCommand.Name)] ParameterSetName: $($PsCmdlet.ParameterSetName)"
        Write-DebugMessage "[$($MyInvocation.MyCommand.Name)] PSBoundParameters: $($PSBoundParameters | Out-String)"

        foreach ($_issue in $Issue) {
            Write-Verbose "[$($MyInvocation.MyCommand.Name)] Processing [$_issue]"
            Write-Debug "[$($MyInvocation.MyCommand.Name)] Processing `$_issue [$_issue]"

            # Find the proper object for the Issue
            $issueObj = Resolve-JiraIssueObject -InputObject $_issue -Credential $Credential

            $issueProps = @{
                'update' = @{}
            }

            if ($Summary) {
                # Update properties need to be passed to JIRA as arrays
                $issueProps.update["summary"] = @(@{ 'set' = $Summary })
            }

            if ($Description) {
                $issueProps.update["description"] = @(@{ 'set' = $Description })
            }

            if ($FixVersion) {
                $fixVersionSet = [System.Collections.ArrayList]@()
                foreach ($item in $FixVersion) {
                    $null = $fixVersionSet.Add( @{ 'name' = $item } )
                }
                $issueProps.update["fixVersions"] = @( @{ set = $fixVersionSet } )
            }

            if ($AddComment) {
                $issueProps.update["comment"] = @(
                    @{
                        'add' = @{
                            'body' = $AddComment
                        }
                    }
                )
            }


            if ($Fields) {

                # Fetch all available fields ahead-of-time to avoid repeated API calls in the upcoming loop.
                # Eventually, this may be better to extract from EditMeta.
                $AvailableFields = Get-JiraField -Credential $Credential -ErrorAction Stop

                $AvailableFieldsById = $AvailableFields | Group-Object -Property Id -AsHashTable -AsString
                $AvailableFieldsByName = $AvailableFields | Group-Object -Property Name -AsHashTable -AsString

                Write-Debug "[$($MyInvocation.MyCommand.Name)] Resolving `$Fields"
                foreach ($_key in $Fields.Keys) {

                    # The Fields hashtable supports both name- and ID-based lookup for custom fields, so we have to search both.
                    if ($AvailableFieldsById.ContainsKey($_key)) {
                        $field = $AvailableFieldsById[$_key][0]
                        Write-Debug "[$($MyInvocation.MyCommand.Name)] $_key appears to be a field ID"
                    } elseif ($AvailableFieldsById.ContainsKey("customfield_$_key")) {
                        $field = $AvailableFieldsById["customfield_$_key"][0]
                        Write-Debug "[$($MyInvocation.MyCommand.Name)] $_key appears to be a numerical field ID (customfield_$_key)"
                    } elseif ($AvailableFieldsByName.ContainsKey($_key) -and $AvailableFieldsByName[$_key].Count -eq 1) {
                        $field = $AvailableFieldsByName[$_key][0]
                        Write-Debug "[$($MyInvocation.MyCommand.Name)] $_key appears to be a human-readable field name ($($field.ID))"
                    } elseif ($AvailableFieldsByName.ContainsKey($_key)) {
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
                    } else {
                        $exception = ([System.ArgumentException]"Invalid value for Parameter")
                        $errorId = 'ParameterValue.InvalidFields'
                        $errorCategory = 'InvalidArgument'
                        $errorTarget = $Fields
                        $errorItem = New-Object -TypeName System.Management.Automation.ErrorRecord $exception, $errorId, $errorCategory, $errorTarget
                        $errorItem.ErrorDetails = "Unable to identify field [$name] from -Fields hashtable. Use Get-JiraField for more information."
                        $PSCmdlet.ThrowTerminatingError($errorItem)
                    }

                    $id = [string]$field.Id
                    $issueProps.update[$id] = @(@{ 'set' = $value })
                }
            }

            if ($validAssignee) {
                $assigneeProps = @{
                    'name' = $assigneeString
                }
            }

            $SkipNotificationParams = @{}
            if ($SkipNotification) {
                Write-Verbose "[$($MyInvocation.MyCommand.Name)] Skipping notification for watchers"
                $SkipNotificationParams = @{notifyUsers = "false"}
            }

            if ( @($issueProps.update.Keys).Count -gt 0 ) {
                Write-DebugMessage "[$($MyInvocation.MyCommand.Name)] Updating issue fields"

                $parameter = @{
                    URI          = $issueObj.RestUrl
                    Method       = "PUT"
                    Body         = ConvertTo-Json -InputObject $issueProps -Depth 10
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
                    URI          = "{0}/assignee" -f $issueObj.RestUrl
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
    }

    end {
        Write-Verbose "[$($MyInvocation.MyCommand.Name)] Complete"
    }
}
