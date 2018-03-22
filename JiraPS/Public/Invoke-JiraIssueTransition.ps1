function Invoke-JiraIssueTransition {
    <#
    .SYNOPSIS
       Performs an issue transition on a JIRA issue, changing its status
    .DESCRIPTION
       This function performs an issue transition on a JIRA issue.  Transitions are
       defined in JIRA through workflows, and allow the issue to move from one status
       to the next.  For example, the "Start Progress" transition typically moves
       an issue from an Open status to an "In Progress" status.

       To identify the transitions that an issue can perform, use Get-JiraIssue and
       check the Transition property of the issue obj ect returned.  Attempting to
       perform a transition that does not apply to the issue (for example, trying
       to "start progress" on an issue in progress) will result in an exception.
    .EXAMPLE
       Invoke-JiraIssueTransition -Issue TEST-01 -Transition 11
       Invokes transition ID 11 on issue TEST-01.
    .EXAMPLE
       Invoke-JiraIssueTransition -Issue TEST-01 -Transition 11 -Comment 'Transition comment'
       Invokes transition ID 11 on issue TEST-01 with a comment. Requires the comment field to be configured visible for transition.
    .EXAMPLE
       Invoke-JiraIssueTransition -Issue TEST-01 -Transition 11 -Assignee 'joe.bloggs'
       Invokes transition ID 11 on issue TEST-01 and assigns to user 'Joe Blogs'. Requires the assignee field to be configured as visible for transition.
    .EXAMPLE
       $transitionFields = @{'customfield_12345' = 'example'}
       Invoke-JiraIssueTransition -Issue TEST-01 -Transition 11 -Fields $transitionFields
       Invokes transition ID 11 on issue TEST-01 and configures a custom field value. Requires fields to be configured as visible for transition.
    .EXAMPLE
       $transition = Get-JiraIssue -Issue TEST-01 | Select-Object -ExpandProperty Transition | ? {$_.ResultStatus.Name -eq 'In Progress'}
       Invoke-JiraIssueTransition -Issue TEST-01 -Transition $transition
       This example identifies the correct transition based on the result status of
       "In Progress," and invokes that transition on issue TEST-01.
    .INPUTS
       [JiraPS.Issue] Issue (can also be provided as a String)
       [JiraPS.Transition] Transition to perform (can also be provided as an int ID)
    .OUTPUTS
       This function does not provide output.
    #>
    [CmdletBinding()]
    param(
        # The Issue Object or ID to transition.
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
        [Object]
        $Issue,

        # The Transition Object or ID.
        [Parameter( Mandatory )]
        [Object]
        $Transition,

        # Any additional fields that should be updated.
        #
        # Fields must be configured to appear on the transition screen to use this parameter.
        [System.Collections.Hashtable]
        $Fields,

        # New assignee of the issue
        #
        # Enter 'Unassigned' to unassign the issue.
        # Assignee field must be configured to appear on the transition screen to use this parameter.
        [Object]
        $Assignee,

        # Comment that should be added to JIRA.
        #
        # Comment field must be configured to appear on the transition screen to use this parameter.
        [String]
        $Comment,

        # Credentials to use to connect to JIRA.
        # If not specified, this function will use anonymous access.
        [PSCredential]
        $Credential
    )

    begin {
        Write-Verbose "[$($MyInvocation.MyCommand.Name)] Function started"
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
                $errorItem = [System.Management.Automation.ErrorRecord]::new(
                    ([System.ArgumentException]"Invalid Type for Parameter"),
                    'ParameterType.NotJiraTransition',
                    [System.Management.Automation.ErrorCategory]::InvalidArgument,
                    $Transition
                )
                $errorItem.ErrorDetails = "Wrong object type provided for Transition. Expected [JiraPS.Transition] or [Int], but was $($Transition.GetType().Name)"
                $PSCmdlet.ThrowTerminatingError($errorItem)
            }
        }

        Write-DebugMessage "[$($MyInvocation.MyCommand.Name)] Checking that the issue can perform the given transition"
        if (($issueObj.Transition.Id) -notcontains $transitionId) {
            $errorItem = [System.Management.Automation.ErrorRecord]::new(
                ([System.ArgumentException]"Invalid value for Parameter"),
                'ParameterValue.InvalidTransition',
                [System.Management.Automation.ErrorCategory]::InvalidArgument,
                $Issue
            )
            $errorItem.ErrorDetails = "The specified Jira issue cannot perform transition [$transitionId]. Check the issue's Transition property and provide a transition valid for its current state."
            $PSCmdlet.ThrowTerminatingError($errorItem)
        }

        $requestBody = @{
            'transition' = @{
                'id' = $transitionId
            }
        }

        if ($Assignee) {
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
                if ($assigneeObj = Get-JiraUser -InputObject $Assignee -Credential $Credential) {
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

        if ($validAssignee) {
            Write-DebugMessage "[$($MyInvocation.MyCommand.Name)] Updating Assignee"
            $requestBody += @{
                'fields' = @{
                    'assignee' = @{
                        'name' = $assigneeString
                    }
                }
            }
        }

        $requestBody += @{
            'update' = @{}
        }

        if ($Fields) {
            Write-Debug "[$($MyInvocation.MyCommand.Name)] Resolving `$Fields"
            foreach ($key in $Fields.Keys) {
                $name = $key
                $value = $Fields.$key
                Write-DebugMessage "[$($MyInvocation.MyCommand.Name)] Attempting to identify field (name=[$name], value=[$value])"

                if ($field = Get-JiraField -Field $name -Credential $Credential) {
                    # For some reason, this was coming through as a hashtable instead of a String,
                    # which was causing ConvertTo-Json to crash later.
                    # Not sure why, but this forces $id to be a String and not a hashtable.
                    $id = "$($field.ID)"
                    Write-DebugMessage "[$($MyInvocation.MyCommand.Name)] Field [$name] was identified as ID [$id]"
                    $requestBody.update.$id = @( @{
                            'set' = $value
                        })
                }
                else {
                    $errorItem = [System.Management.Automation.ErrorRecord]::new(
                        ([System.ArgumentException]"Invalid value for Parameter"),
                        'ParameterValue.InvalidFields',
                        [System.Management.Automation.ErrorCategory]::InvalidArgument,
                        $Fields
                    )
                    $errorItem.ErrorDetails = "Unable to identify field [$name] from -Fields hashtable. Use Get-JiraField for more information."
                    $PSCmdlet.ThrowTerminatingError($errorItem)
                }
            }
        }

        if ($Comment) {
            Write-DebugMessage "[$($MyInvocation.MyCommand.Name)] Adding comment"
            $requestBody.update.comment += , @{
                'add' = @{
                    'body' = $Comment
                }
            }
        }

        $parameter = @{
            URI        = "{0}/transitions" -f $issueObj.RestURL
            Method     = "POST"
            Body       = ConvertTo-Json -InputObject $requestBody -Depth 4
            Credential = $Credential
        }
        Write-Debug "[$($MyInvocation.MyCommand.Name)] Invoking JiraMethod with `$parameter"
        $result = Invoke-JiraMethod @parameter

        if ($result) {
            # JIRA doesn't typically return results here unless they contain errors, which are handled within Invoke-JiraMethod.
            # If something does come out, let us know.
            Write-Warning "JIRA returned unexpected results, which are provided below."
            Write-Warning "Please report this at $($MyInvocation.MyCommand.Module.PrivateData.PSData.ProjectUri)"
            Write-Output $result
        }
    }

    end {
        Write-Verbose "[$($MyInvocation.MyCommand.Name)] Complete"
    }
}
