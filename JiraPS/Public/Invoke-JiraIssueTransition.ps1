function Invoke-JiraIssueTransition {
    <#
    .Synopsis
       Performs an issue transition on a JIRA issue, changing its status
    .DESCRIPTION
       This function performs an issue transition on a JIRA issue.  Transitions are
       defined in JIRA through workflows, and allow the issue to move from one status
       to the next.  For example, the "Start Progress" transition typically moves
       an issue from an Open status to an "In Progress" status.

       To identify the transitions that an issue can perform, use Get-JiraIssue and
       check the Transition property of the issue object returned.  Attempting to
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
        [Parameter(
            Position = 0,
            Mandatory = $true,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true
        )]
        [Alias('Key')]
        [Object] $Issue,

        # The Transition Object or ID.
        [Parameter(Mandatory = $true,
            Position = 1)]
        [Object] $Transition,

        # Any additional fields that should be updated. Fields must be configured to appear on the transition screen to use this parameter.
        [System.Collections.Hashtable] $Fields,

        # New assignee of the issue. Enter 'Unassigned' to unassign the issue. Assignee field must be configured to appear on the transition screen to use this parameter.
        [Parameter(Mandatory = $false)]
        [Object] $Assignee,

        # Comment that should be added to JIRA. Comment field must be configured to appear on the transition screen to use this parameter.
        [Parameter(Mandatory = $false)]
        [String] $Comment,

        # Credentials to use to connect to Jira
        [Parameter(Mandatory = $false)]
        [System.Management.Automation.PSCredential] $Credential
    )

    begin {
        # We can't validate pipeline input here, since pipeline input doesn't exist in the Begin block.
    }

    process {
        Write-Debug "[Invoke-JiraIssueTransition] Obtaining a reference to Jira issue [$Issue]"
        $issueObj = Get-JiraIssue -InputObject $Issue -Credential $Credential

        if (-not $issueObj) {
            Write-Debug "[Invoke-JiraIssueTransition] No Jira issues were found for parameter [$Issue]. An exception will be thrown."
            throw "Unable to identify Jira issue [$Issue]. Use Get-JiraIssue for more information."
        }

        Write-Debug "[Invoke-JiraIssueTransition] Checking Transition parameter"
        if ($Transition.PSObject.TypeNames[0] -eq 'JiraPS.Transition') {
            Write-Debug "[Invoke-JiraIssueTransition] Transition parameter is a JiraPS.Transition object"
            $transitionId = $Transition.ID
        }
        else {
            Write-Debug "[Invoke-JiraIssueTransition] Attempting to cast Transition parameter [$Transition] as int for transition ID"
            try {
                $transitionId = [int] "$Transition"
            }
            catch {
                $err = $_
                Write-Debug "[Invoke-JiraIssueTransition] Encountered an error converting transition to Int. An exception will be thrown."
                throw $err
            }
        }

        Write-Debug "[Invoke-JiraIssueTransition] Checking that the issue can perform the given transition"
        if (($issueObj.Transition | Select-Object -ExpandProperty ID) -contains $transitionId) {
            Write-Debug "[Invoke-JiraIssueTransition] Transition [$transitionId] is valid for issue [$issueObj]"
        }
        else {
            Write-Debug "[Invoke-JiraIssueTransition] Transition [$transitionId] is not valid for issue [$issueObj]. An exception will be thrown."
            throw "The specified Jira issue cannot perform transition [$transitionId]. Check the issue's Transition property and provide a transition valid for its current state."
        }

        $transitionUrl = "$($issueObj.RestURL)/transitions"

        Write-Debug "[Invoke-JiraIssueTransition] Creating properties"
        $props = @{
            'transition' = @{
                'id' = $transitionId;
            }
        }

        if ($Assignee) {
            Write-Debug "[Invoke-JiraIssueTransition] Testing Assignee type"
            if ($Assignee -eq 'Unassigned') {
                Write-Debug "[Invoke-JiraIssueTransition] 'Unassigned' String passed. Issue will be assigned to no one."
                $assigneeString = ""
                $validAssignee = $true
            }
            else {
                Write-Debug "[Invoke-JiraIssueTransition] Attempting to obtain Jira user [$Assignee]"
                $assigneeObj = Get-JiraUser -InputObject $Assignee -Credential $Credential
                if ($assigneeObj) {
                    Write-Debug "[Invoke-JiraIssueTransition] User found (name=[$($assigneeObj.Name)],RestUrl=[$($assigneeObj.RestUrl)])"
                    $assigneeString = $assigneeObj.Name
                    $validAssignee = $true
                }
                else {
                    Write-Debug "[Invoke-JiraIssueTransition] Unable to obtain Assignee. Exception will be thrown."
                    throw "Unable to validate Jira user [$Assignee]. Use Get-JiraUser for more details."
                }
            }
        }


        if ($validAssignee) {
            Write-Debug "[Invoke-JiraIssueTransition] Updating Assignee"
            $props += @{
                'fields' = @{
                    'assignee' = @{
                        'name' = $assigneeString;
                    }
                }
            }
        }


        if ($Fields) {
            Write-Debug "[Invoke-JiraIssueTransition] Validating field names"
            $props += @{
                'update' = @{}
            }

            foreach ($k in $Fields.Keys) {
                $name = $k
                $value = $Fields.$k
                Write-Debug "[Invoke-JiraIssueTransition] Attempting to identify field (name=[$name], value=[$value])"

                $f = Get-JiraField -Field $name -Credential $Credential
                if ($f) {
                    # For some reason, this was coming through as a hashtable instead of a String,
                    # which was causing ConvertTo-Json to crash later.
                    # Not sure why, but this forces $id to be a String and not a hashtable.
                    $id = "$($f.ID)"
                    Write-Debug "[Invoke-JiraIssueTransition] Field [$name] was identified as ID [$id]"
                    $props.update.$id = @()
                    $props.update.$id += @{
                        'set' = $value;
                    }
                }
                else {
                    Write-Debug "[Invoke-JiraIssueTransition] Field [$name] could not be identified in Jira"
                    throw "Unable to identify field [$name] from -Fields hashtable. Use Get-JiraField for more information."
                }
            }
        }


        if ($Comment) {
            Write-Debug "[Invoke-JiraIssueTransition] Adding comment"
            if (-not $Fields) {
                Write-Debug "[Invoke-JiraIssueTransition] Create 'update' hashtable since not already created"
                $props += @{
                    'update' = @{}
                }
            }

            $props.update.comment += , @{
                'add' = @{
                    'body' = $Comment
                }
            }
        }

        $json = ConvertTo-Json -InputObject $props -Depth 4
        Write-Debug "[Invoke-JiraIssueTransition] Converted properties to JSON"

        Write-Debug "[Invoke-JiraIssueTransition] Preparing for blastoff!"
        $result = Invoke-JiraMethod -Method Post -URI $transitionUrl -Body $json -Credential $Credential

        if ($result) {
            # JIRA doesn't typically return results here unless they contain errors, which are handled within Invoke-JiraMethod.
            # If something does come out, let us know.
            Write-Debug "[Invoke-JiraIssueTransition] Outputting raw results from JIRA."
            Write-Warning "JIRA returned unexpected results, which are provided below."
            Write-Output $result
        }
        else {
            Write-Debug "[Invoke-JiraIssueTransition] No results were returned from JIRA."
        }
    }

    end {
        Write-Debug "Complete"
    }
}
