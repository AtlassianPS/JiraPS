function New-JiraIssue {
    # .ExternalHelp ..\JiraPS-help.xml
    [CmdletBinding( SupportsShouldProcess )]
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
        [AllowNull()]
        [AllowEmptyString()]
        [String]
        $Reporter,

        [Parameter( ValueFromPipelineByPropertyName )]
        [String[]]
        $Labels,

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

        [Alias("Credential")]
        [psobject]
        $Session
    )

    begin {
        Write-Verbose "[$($MyInvocation.MyCommand.Name)] Function started"
    }

    process {

        $createmeta = Get-JiraIssueCreateMetadata -Project $Project -IssueType $IssueType -Session $Session -ErrorAction Stop -Debug:$false

        $resourceURi = "rest/api/latest/issue"

        Write-DebugMessage "[$($MyInvocation.MyCommand.Name)] ParameterSetName: $($PsCmdlet.ParameterSetName)"
        Write-DebugMessage "[$($MyInvocation.MyCommand.Name)] PSBoundParameters: $($PSBoundParameters | Out-String)"

        $ProjectObj = Get-JiraProject -Project $Project -Session $Session -ErrorAction Stop -Debug:$false
        $issueTypeObj = $projectObj.IssueTypes | Where-Object -FilterScript {$_.Id -eq $IssueType -or $_.Name -eq $IssueType}

        if ($null -eq $issueTypeObj.Id)
        {
            $errorMessage = @{
                Category         = "InvalidResult"
                CategoryActivity = "Validating parameters"
                Message          = "No issue types were found in the project [$Project] for the given issue type [$IssueType]. Use Get-JiraIssueType for more details."
            }
            Write-Error @errorMessage
        }

        $requestBody = @{
            "project"   = @{"id" = $ProjectObj.Id}
            "issuetype" = @{"id" = [String] $IssueTypeObj.Id}
            "summary"   = $Summary
        }

        if ($Priority) {
            $requestBody["priority"] = @{"id" = [String] $Priority}
        }

        if ($Description) {
            $requestBody["description"] = $Description
        }

        if ($PSCmdlet.MyInvocation.BoundParameters.ContainsKey("Reporter")) {
            $requestBody["reporter"] = @{"name" = "$Reporter"}
        }
        elseif ($ProjectObj.Style -eq "next-gen"){
            Write-DebugMessage "[$($MyInvocation.MyCommand.Name)] Adding reporter as next-gen projects must have reporter set."
            $requestBody["reporter"] = @{"name" = "$((Get-JiraUser -Session $Session).Name)"}
        }

        if ($Parent) {
            $requestBody["parent"] = @{"key" = $Parent}
        }

        if ($Labels) {
            $requestBody["labels"] = [System.Collections.ArrayList]@()
            foreach ($item in $Labels) {
                $null = $requestBody["labels"].Add($item)
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

            if ($field = Get-JiraField -Field $name -Session $Session -Debug:$false) {
                # For some reason, this was coming through as a hashtable instead of a String,
                # which was causing ConvertTo-Json to crash later.
                # Not sure why, but this forces $id to be a String and not a hashtable.
                $id = $field.Id
                $requestBody["$id"] = $value
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
        }

        Write-Verbose "[$($MyInvocation.MyCommand.Name)] Validating fields with metadata"
        foreach ($c in $createmeta) {
            Write-Debug "[$($MyInvocation.MyCommand.Name)] Checking metadata for `$c [$c]"
            if ($c.Required) {
                if ($requestBody.ContainsKey($c.Id)) {
                    Write-DebugMessage "[$($MyInvocation.MyCommand.Name)] Required field (id=[$($c.Id)], name=[$($c.Name)]) was provided (value=[$($requestBody.$($c.Id))])"
                }
                else {
                    $exception = ([System.ArgumentException]"Invalid or missing value Parameter")
                    $errorId = 'ParameterValue.CreateMetaFailure'
                    $errorCategory = 'InvalidArgument'
                    $errorTarget = $Fields
                    $errorItem = New-Object -TypeName System.Management.Automation.ErrorRecord $exception, $errorId, $errorCategory, $errorTarget
                    $errorItem.ErrorDetails = "Jira's metadata for project [$Project] and issue type [$IssueType] specifies that a field is required that was not provided (name=[$($c.Name)], id=[$($c.Id)]). Use Get-JiraIssueCreateMetadata for more information."
                    $PSCmdlet.ThrowTerminatingError($errorItem)
                }
            }
            else {
                Write-DebugMessage "[$($MyInvocation.MyCommand.Name)] Non-required field (id=[$($c.Id)], name=[$($c.Name)])"
            }
        }

        $hashtable = @{
            'fields' = ([PSCustomObject]$requestBody)
        }

        $parameter = @{
            URI        = $resourceURi
            Method     = "POST"
            Body       = (ConvertTo-Json -InputObject ([PSCustomObject]$hashtable) -Depth 7)
            Session    = $Session
        }
        Write-Debug "[$($MyInvocation.MyCommand.Name)] Invoking JiraMethod with `$parameter"
        if ($PSCmdlet.ShouldProcess($Summary, "Creating new Issue on JIRA")) {
            if ($result = Invoke-JiraMethod @parameter) {
                # REST result will look something like this:
                # {"id":"12345","key":"IT-3676","self":"http://jiraserver.example.com/rest/api/latest/issue/12345"}
                # This will fetch the created issue to return it with all it'a properties
                Write-Output (Get-JiraIssue -Key $result.Key -Session $Session)
            }
        }
        Write-Verbose "[$($MyInvocation.MyCommand.Name)] Complete"
    }

    end {
    }
}
