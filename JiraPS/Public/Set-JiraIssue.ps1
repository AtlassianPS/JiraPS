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
                if ($assigneeObj = Get-JiraUser -UserName $Assignee -Credential $Credential) {
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
                Write-Debug "[$($MyInvocation.MyCommand.Name)] Resolving `$Fields"
                foreach ($_key in $Fields.Keys) {
                    $name = $_key
                    $value = $Fields.$_key

                    $field = Get-JiraField -Field $name -Credential $Credential -ErrorAction Stop

                    # For some reason, this was coming through as a hashtable instead of a String,
                    # which was causing ConvertTo-Json to crash later.
                    # Not sure why, but this forces $id to be a String and not a hashtable.
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
                $SkipNotificationParams = @{notifyUsers = $false}
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
