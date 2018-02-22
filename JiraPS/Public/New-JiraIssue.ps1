function New-JiraIssue {
    <#
    .Synopsis
       Creates an issue in JIRA
    .DESCRIPTION
       This function creates a new issue in JIRA.

       Creating an issue requires a lot of data, and the exact data may be
       different from one instance of JIRA to the next.  To identify what data
       is required for a given issue type and project, use the
       Get-JiraIssueCreateMetadata function provided in this module.

       Some JIRA instances may require additional custom fields specific to that
       instance of JIRA.  In addition to the parameterized fields provided in
       this function, the Fields parameter accepts a hashtable of field names /
       IDs and values.  This allows users to provide custom field data when
       creating an issue.
    .EXAMPLE
       Get-JiraIssueCreateMetadata -Project TEST -IssueType Bug | ? {$_.Required -eq $true}
       New-JiraIssue -Project TEST -IssueType Bug -Priority 1 -Summary 'Test issue from PowerShell' -Description 'This is a test issue created from the JiraPS module in PowerShell.' -Fields {'Custom Field Name 1'='foo';'customfield_10001'='bar';}
       This example uses Get-JiraIssueCreateMetadata to identify fields required
       to create an issue in JIRA.  It then creates an issue with the Fields parameter
       providing a field name and a field ID.
    .INPUTS
       This function does not accept pipeline input.
    .OUTPUTS
       [JiraPS.Issue] The issue created in JIRA.
    #>
    [CmdletBinding( SupportsShouldProcess )]
    param(
        # Project in which to create the issue.
        [Parameter( Mandatory )]
        [String]
        $Project,

        # Type of the issue.
        [Parameter( Mandatory )]
        [String]
        $IssueType,

        # Summary of the issue.
        [Parameter( Mandatory )]
        [String]
        $Summary,

        # ID of the Priority the issue shall have.
        [Int]
        $Priority,

        # Long description of the issue.
        [String]
        $Description,

        # User that shall be registed as the reporter.
        # If left empty, the currently authenticated user will be used.
        [AllowNull()]
        [AllowEmptyString()]
        [String]
        $Reporter,

        # List of labels which will be added to the issue.
        [String[]]
        $Labels,

        # Parent issue - in case of "Sub-Tasks".
        [String]
        $Parent,

        # Set the FixVersion of the issue.
        [Alias('FixVersions')]
        [String[]]
        $FixVersion,

        # Any additional fields.
        [Hashtable]
        $Fields,

        # Credentials to use to connect to JIRA.
        # If not specified, this function will use anonymous access.
        [PSCredential]
        $Credential
    )

    begin {
        Write-Verbose "[$($MyInvocation.MyCommand.Name)] Function started"

        $server = Get-JiraConfigServer -ErrorAction Stop

        $createmeta = Get-JiraIssueCreateMetadata -Project $Project -IssueType $IssueType -Credential $Credential -ErrorAction Stop

        $resourceURi = "$server/rest/api/latest/issue"
    }

    process {
        Write-DebugMessage "[$($MyInvocation.MyCommand.Name)] ParameterSetName: $($PsCmdlet.ParameterSetName)"
        Write-DebugMessage "[$($MyInvocation.MyCommand.Name)] PSBoundParameters: $($PSBoundParameters | Out-String)"

        $ProjectObj = Get-JiraProject -Project $Project -Credential $Credential -ErrorAction Stop
        $IssueTypeObj = Get-JiraIssueType -IssueType $IssueType -Credential $Credential -ErrorAction Stop

        $requestBody = @{
            "project"   = @{"id" = $ProjectObj.Id}
            "issuetype" = @{"id" = [String] $IssueTypeObj.Id}
            "summary"   = $Summary
        }

        if ($Priority) {
            $requestBody.priority = @{"id" = [String] $Priority}
        }

        if ($Description) {
            $requestBody.description = $Description
        }

        if ($PSCmdlet.MyInvocation.BoundParameters.ContainsKey("Reporter")) {
            $requestBody.reporter = @{"name" = "$Reporter"}
        }

        if ($Parent) {
            $requestBody.parent = @{"key" = $Parent}
        }

        if ($Labels) {
            $requestBody["labels"] = [System.Collections.ArrayList]@()
            foreach ($item in $Labels) {
                $null = $requestBody["labels"].Add($_item)
            }
        }

        if ($FixVersion) {
            $requestBody['fixVersions'] = [System.Collections.ArrayList]@()
            foreach ($item in $FixVersion) {
                $null = $requestBody["fixVersions"].Add( @{ name = "$item" } )
            }
        }

        Write-Debug "[$($MyInvocation.MyCommand.Name)] Resolving `$Fields"
        foreach ($_key in $Fields.Keys) {
            $name = $_key
            $value = $Fields.$_key

            if ($field = Get-JiraField -Field $name -Credential $Credential) {
                # For some reason, this was coming through as a hashtable instead of a String,
                # which was causing ConvertTo-Json to crash later.
                # Not sure why, but this forces $id to be a String and not a hashtable.
                $id = $field.Id
                $requestBody.$id = $value
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

        Write-Verbose "[$($MyInvocation.MyCommand.Name)] Validating fields with metadata"
        foreach ($c in $createmeta) {
            Write-Debug "[$($MyInvocation.MyCommand.Name)] Checking metadata for `$c [$c]"
            if ($c.Required) {
                if ($requestBody.ContainsKey($c.Id)) {
                    Write-DebugMessage "[$($MyInvocation.MyCommand.Name)] Required field (id=[$($c.Id)], name=[$($c.Name)]) was provided (value=[$($requestBody.$($c.Id))])"
                }
                else {
                    $errorItem = [System.Management.Automation.ErrorRecord]::new(
                        ([System.ArgumentException]"Invalid or missing value Parameter"),
                        'ParameterValue.CreateMetaFailure',
                        [System.Management.Automation.ErrorCategory]::InvalidArgument,
                        $Fields
                    )
                    $errorItem.ErrorDetails = "Jira's metadata for project [$Project] and issue type [$IssueType] specifies that a field is required that was not provided (name=[$($c.Name)], id=[$($c.Id)]). Use Get-JiraIssueCreateMetadata for more information."
                    $PSCmdlet.ThrowTerminatingError($errorItem)
                }
            }
            else {
                Write-DebugMessage "[$($MyInvocation.MyCommand.Name)] Non-required field (id=[$($c.Id)], name=[$($c.Name)])"
            }
        }

        $hashtable = @{
            'fields' = $requestBody
        }

        $parameter = @{
            URI        = $resourceURi
            Method     = "POST"
            Body       = (ConvertTo-Json -InputObject $hashtable -Depth 7)
            Credential = $Credential
        }
        Write-Debug "[$($MyInvocation.MyCommand.Name)] Invoking JiraMethod with `$parameter"
        if ($PSCmdlet.ShouldProcess($Summary, "Creating new Issue on JIRA")) {
            $result = Invoke-JiraMethod @parameter

            # REST result will look something like this:
            # {"id":"12345","key":"IT-3676","self":"http://jiraserver.example.com/rest/api/latest/issue/12345"}
            # This will fetch the created issue to return it with all it'a properties
            Write-Output (Get-JiraIssue -Key $result.Key -Credential $Credential)
        }
    }

    end {
        Write-Verbose "[$($MyInvocation.MyCommand.Name)] Complete"
    }
}
