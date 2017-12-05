function Set-JiraIssue {
    <#
    .Synopsis
       Modifies an existing issue in JIRA
    .DESCRIPTION
       This function modifies an existing isue in JIRA.  This can include changing
       the issue's summary or description, or assigning the issue.
    .EXAMPLE
       Set-JiraIssue -Issue TEST-01 -Summary 'Modified issue summary' -Description 'This issue has been modified by PowerShell'
       This example changes the summary and description of the JIRA issue TEST-01.
    .EXAMPLE
       $issue = Get-JiraIssue TEST-01
       $issue | Set-JiraIssue -Description "$($issue.Description)`n`nEdit: Also foo."
       This example appends text to the end of an existing issue description by using
       Get-JiraIssue to obtain a reference to the current issue and description.
    .EXAMPLE
       Set-JiraIssue -Issue TEST-01 -Assignee 'Unassigned'
       This example removes the assignee from JIRA issue TEST-01.
    .EXAMPLE
       Set-JiraIssue -Issue TEST-01 -Assignee 'joe' -AddComment 'Dear [~joe], please review.'
       This example assigns the JIRA Issue TEST-01 to 'joe' and adds a comment at one.
    .INPUTS
       [JiraPS.Issue[]] The JIRA issue that should be modified
    .OUTPUTS
       If the -PassThru parameter is provided, this function will provide a reference
       to the JIRA issue modified.  Otherwise, this function does not provide output.
    #>
    [CmdletBinding( SupportsShouldProcess )]
    param(
        # Issue key or JiraPS.Issue object returned from Get-JiraIssue
        [Parameter( Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName )]
        [ValidateNotNullOrEmpty()]
        [ValidateScript(
            {
                if (("JiraPS.Issue" -notin $_.PSObject.TypeNames) -and (($_ -isnot [String]))) {
                    $errorItem = [System.Management.Automation.ErrorRecord]::new(
                        ([System.ArgumentException]"Invalid Type for Parameter"),
                        'ParameterType.NotJiraIssue',
                        [System.Management.Automation.ErrorCategory]::InvalidArgument,
                        $_
                    )
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

        # New summary of the issue.
        [String]
        $Summary,

        # New description of the issue.
        [String]
        $Description,

        # Set the FixVersion of the issue, this will overwrite any present FixVersions
        [Alias('FixVersions')]
        [String[]]
        $FixVersion,

        # New assignee of the issue. Enter 'Unassigned' to unassign the issue.
        [Object]
        $Assignee,

        # Labels to be set on the issue. These wil overwrite any existing
        # labels on the issue. For more granular control over issue labels,
        # use Set-JiraIssueLabel.
        [String[]]
        $Label,

        # Any additional fields that should be updated.
        [Hashtable]
        $Fields,

        # Add a comment ad once with your changes
        [String]
        $AddComment,

        # Credentials to use to connect to JIRA.
        # If not specified, this function will use anonymous access.
        [PSCredential]
        $Credential,

        # Whether output should be provided after invoking this function.
        [Switch]
        $PassThru
    )

    begin {
        Write-Verbose "[$($MyInvocation.MyCommand.Name)] Function started"

        Write-Debug "[$($MyInvocation.MyCommand.Name)] Checking to see if we have any operations to perform"
        $fieldNames = $Fields.Keys
        if (-not ($Summary -or $Description -or $Assignee -or $Label -or $FixVersion -or $fieldNames)) {
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
                $assigneeString = ""
                $validAssignee = $true
            }
            else {
                if ($assigneeObj = Get-JiraUser -UserName $Assignee -Credential $Credential) {
                    Write-Debug "[$($MyInvocation.MyCommand.Name)] User found (name=[$($assigneeObj.Name)],RestUrl=[$($assigneeObj.RestUrl)])"
                    $assigneeString = $assigneeObj.Name
                    $validAssignee = $true
                }
                else {
                    $errorItem = [System.Management.Automation.ErrorRecord]::new(
                        ([System.ArgumentException]"Invalid value for Parameter"),
                        'ParameterValue.InvalidAssignee',
                        [System.Management.Automation.ErrorCategory]::InvalidArgument,
                        $Assignee
                    )
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
                $issueProps.update.summary = @(@{ 'set' = $Summary })
            }

            if ($Description) {
                $issueProps.update.description = @(@{ 'set' = $Description })
            }

            if ($FixVersion) {
                $fixVersionSet = [System.Collections.ArrayList]@()
                $null = @($FixVersion).foreach( { $fixVersionSet.Add( @{ 'name' = $_ } ) } )
                $issueProps.update["fixVersions"] = @( @{ set = $fixVersionSet } )
            }

            if ($AddComment) {
                $issueProps.update.comment = @(
                    @{
                        'add' = @{
                            'body' = $AddComment
                        }
                    }
                )
            }

            if ($Fields) {
                Write-Debug "[$($MyInvocation.MyCommand.Name)] Resolving `$Fields"
                foreach ($_key in $Fields.Keys) {
                    $name = $_key
                    $value = $Fields.$_key
                    Write-Debug "[$($MyInvocation.MyCommand.Name)] Attempting to identify field (name=[$name], value=[$value])"

                    $field = Get-JiraField -Field $name -Credential $Credential -ErrorAction Stop

                    # For some reason, this was coming through as a hashtable instead of a String,
                    # which was causing ConvertTo-Json to crash later.
                    # Not sure why, but this forces $id to be a String and not a hashtable.
                    $id = $field.Id
                    Write-Debug "[$($MyInvocation.MyCommand.Name)] Field [$name] was identified as ID [$id]"
                    $issueProps.update.$id = @(@{ 'set' = $value })
                }
            }

            if ($validAssignee) {
                $assigneeProps = @{
                    'name' = $assigneeString
                }
            }

            if ( @($issueProps.update.Keys).Count -gt 0 ) {
                Write-DebugMessage "[$($MyInvocation.MyCommand.Name)] Updating issue fields"

                $parameter = @{
                    URI        = $issueObj.RestUrl
                    Method     = "PUT"
                    Body       = ConvertTo-Json -InputObject $issueProps -Depth 5
                    Credential = $Credential
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
                    URI        = "{0}/assignee" -f $issueObj.RestUrl
                    Method     = "PUT"
                    Body       = ConvertTo-Json -InputObject $assigneeProps
                    Credential = $Credential
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
