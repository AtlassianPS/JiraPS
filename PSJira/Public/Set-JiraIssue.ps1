function Set-JiraIssue
{
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
    .INPUTS
       [PSJira.Issue[]] The JIRA issue that should be modified
    .OUTPUTS
       If the -PassThru parameter is provided, this function will provide a reference
       to the JIRA issue modified.  Otherwise, this function does not provide output.
    #>
    [CmdletBinding(DefaultParameterSetName = 'ByInputObject')]
    param(
        # Issue key or PSJira.Issue object returned from Get-JiraIssue
        [Parameter(Mandatory = $true,
                   Position = 0,
                   ValueFromPipeline = $true,
                   ValueFromPipelineByPropertyName = $true)]
        [Alias('Key')]
        [Object[]] $Issue,

        # New summary of the issue
        [Parameter(Mandatory = $false)]
        [String] $Summary,

        # New description of the issue
        [Parameter(Mandatory = $false)]
        [String] $Description,

        # New assignee of the issue. Enter 'Unassigned' to unassign the issue.
        [Parameter(Mandatory = $false)]
        [Object] $Assignee,

        # Labels to be set on the issue. These wil overwrite any existing
        # labels on the issue. For more granular control over issue labels,
        # use Set-JiraIssueLabel.
        [String[]] $Label,

        # Any additional fields that should be updated
        [System.Collections.Hashtable] $Fields,

        [ValidateScript({Test-Path $_})]
        [String] $ConfigFile,

        # Credentials to use to connect to Jira
        [Parameter(Mandatory = $false)]
        [System.Management.Automation.PSCredential] $Credential,

        [Switch] $PassThru
    )

    begin
    {
        Write-Debug "[Set-JiraIssue] Checking to see if we have any operations to perform"
        $fieldNames = $Fields.Keys
        if (-not ($Summary -or $Description -or $Assignee -or $Label -or $fieldNames))
        {
            Write-Verbose "Nothing to do."
            return
        }

        Write-Debug "[Set-JiraIssue] Reading server from config file"
        $server = Get-JiraConfigServer -ConfigFile $ConfigFile -ErrorAction Stop

        if ($Assignee)
        {
            Write-Debug "[Set-JiraIssue] Testing Assignee type"
            if ($Assignee -eq 'Unassigned')
            {
                Write-Debug "[Set-JiraIssue] 'Unassigned' String passed. Issue will be assigned to no one."
                $assigneeString = ""
                $validAssignee = $true
            } else {
                Write-Debug "[Set-JiraIssue] Attempting to obtain Jira user [$Assignee]"
                $assigneeObj = Get-JiraUser -InputObject $Assignee -Credential $Credential
                if ($assigneeObj)
                {
                    Write-Debug "[Set-JiraIssue] User found (name=[$($assigneeObj.Name)],RestUrl=[$($assigneeObj.RestUrl)])"
                    $assigneeString = $assigneeObj.Name
                    $validAssignee = $true
                } else {
                    Write-Debug "[Set-JiraIssue] Unable to obtain Assignee. Exception will be thrown."
                    throw "Unable to validate Jira user [$Assignee]. Use Get-JiraUser for more details."
                }
            }
        }

        Write-Debug "[Set-JiraIssue] Completed Begin block."
    }

    process
    {
        foreach ($i in $Issue)
        {
            $actOnIssueUri = $false
            $actOnAssigneeUri = $false

            Write-Debug "[Set-JiraIssue] Obtaining reference to issue"
            $issueObj = Get-JiraIssue -InputObject $i -Credential $Credential

            if ($issueObj)
            {
                $issueProps = @{
                    'update' = @{}
                }

                if ($Summary)
                {
                    # Update properties need to be passed to JIRA as arrays
                    $issueProps.update.summary = @()
                    $issueProps.update.summary += @{
                        'set' = $Summary;
                    }
                    $actOnIssueUri = $true
                }

                if ($Description)
                {
                    $issueProps.update.description = @()
                    $issueProps.update.description += @{
                        'set' = $Description;
                    }
                    $actOnIssueUri = $true
                }

                if ($Fields)
                {
                    Write-Debug "[Set-JiraIssue] Validating field names"
                    foreach ($k in $Fields.Keys)
                    {
                        $name = $k
                        $value = $Fields.$k
                        Write-Debug "[Set-JiraIssue] Attempting to identify field (name=[$name], value=[$value])"

                        $f = Get-JiraField -Field $name -Credential $Credential
                        if ($f)
                        {
                            # For some reason, this was coming through as a hashtable instead of a String,
                            # which was causing ConvertTo-Json to crash later.
                            # Not sure why, but this forces $id to be a String and not a hashtable.
                            $id = "$($f.ID)"
                            Write-Debug "[Set-JiraIssue] Field [$name] was identified as ID [$id]"
                            $issueProps.update.$id = @()
                            $issueProps.update.$id += @{
                                'set' = $value;
                            }
                            $actOnIssueUri = $true
                        } else {
                            Write-Debug "[Set-JiraIssue] Field [$name] could not be identified in Jira"
                            throw "Unable to identify field [$name] from -Fields hashtable. Use Get-JiraField for more information."
                        }
                    }
                }

                if ($validAssignee)
                {

                    $assigneeProps =  @{
                        'name' = $assigneeString;
                    }

                    $actOnAssigneeUri = $true
                }

                if ($actOnIssueUri)
                {
                    Write-Debug "[Set-JiraIssue] IssueProps: [$issueProps]"

                    Write-Debug "[Set-JiraIssue] Converting results to JSON"
                    $json = ConvertTo-Json -InputObject $issueProps -Depth 5
                    $issueObjURL = $issueObj.RestUrl

                    Write-Debug "[Set-JiraIssue] Preparing for blastoff!"
                    $issueResult = Invoke-JiraMethod -Method Put -URI $issueObjURL -Body $json -Credential $Credential
                    Write-Debug "[Set-JiraIssue] Results are saved to issueResult variable"
                }

                if ($actOnAssigneeUri)
                {
                    # Jira handles assignee differently; you can't change it from the default "edit issues" screen unless
                    # you customize the "Edit Issue" screen.

                    $assigneeUrl = "{0}/assignee" -f $issueObj.RestUrl
                    $json = ConvertTo-Json -InputObject $assigneeProps

                    Write-Debug "[Set-JiraIssue] Preparing for blastoff!"
                    $assigneeResult = Invoke-JiraMethod -Method Put -URI $assigneeUrl -Body $json -Credential $Credential
                    Write-Debug "[Set-JiraIssue] Results are saved to assigneeResult variable"
                }

                if ($Label)
                {
                    Write-Debug "[Set-JiraIssue] Invoking Set-JiraIssueLabel to set issue labels"
                    Set-JiraIssueLabel -Issue $issueObj -Set $Label -Credential $Credential
                }

                if ($PassThru)
                {
                    Write-Debug "[Set-JiraIssue] PassThru was specified. Obtaining updated reference to issue"
                    Get-JiraIssue -Key $issueObj.Key -Credential $Credential
                }

            } else {
                Write-Debug "[Set-JiraIssue] Unable to identify issue [$i]. Writing error message."
                Write-Error "Unable to identify issue [$i]"
            }
        }
    }

    end
    {
        Write-Debug "[Set-JiraIssue] Complete"
    }
}


