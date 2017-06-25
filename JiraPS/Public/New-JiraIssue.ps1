function New-JiraIssue
{
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
    [CmdletBinding(SupportsShouldProcess = $true)]
    param(
        # Project in which to create the issue.
        [Parameter(Mandatory = $true)]
        [String] $Project,

        # Type of the issue.
        [Parameter(Mandatory = $true)]
        [String] $IssueType,

        # ID of the Priority the issue shall have.
        [Parameter(Mandatory = $false)]
        [Int] $Priority,

        # Summary of the issue.
        [Parameter(Mandatory = $true)]
        [String] $Summary,

        # Long description of the issue.
        [Parameter(Mandatory = $false)]
        [String] $Description,

        # User that shall be registed as the reporter.
        # If left empty, the currently authenticated user will be used.
        [Parameter(Mandatory = $false)]
        [String] $Reporter,

        # List of labels which will be added to the issue.
        [Parameter(Mandatory = $false)]
        [String[]] $Labels,

        # Parent issue - in case of "Sub-Tasks".
        [Parameter(Mandatory = $false)]
        [String] $Parent,

        # Set the FixVersion of the issue.
        [Parameter(Mandatory = $false)]
        [Alias('FixVersions')]
        [String[]] $FixVersion,

        # Any additional fields.
        [Parameter(Mandatory = $false)]
        [Hashtable] $Fields,

        # Credentials to use to connect to JIRA.
        # If not specified, this function will use anonymous access.
        [Parameter(Mandatory = $false)]
        [PSCredential] $Credential
    )

    begin
    {
        Write-Debug "[New-JiraIssue] Reading information from config file"
        try
        {
            Write-Debug "[New-JiraIssue] Reading Jira server from config file"
            $server = Get-JiraConfigServer -ConfigFile $ConfigFile -ErrorAction Stop

            Write-Debug "[New-JiraIssue] Reading Jira issue create metadata"
            $createmeta = Get-JiraIssueCreateMetadata -Project $Project -IssueType $IssueType -ConfigFile $ConfigFile -Credential $Credential -ErrorAction Stop
        } catch
        {
            $err = $_
            Write-Debug "[New-JiraIssue] Encountered an error reading configuration data."
            throw $err
        }

        $issueURL = "$server/rest/api/latest/issue"

        Write-Debug "[New-JiraIssue] Obtaining a reference to Jira project [$Project]"
        $ProjectObj = Get-JiraProject -Project $Project -Credential $Credential
        if (-not ($ProjectObj))
        {
            throw "Unable to identify Jira project [$Project]. Use Get-JiraProject for more information."
        }

        Write-Debug "[New-JiraIssue] Obtaining a reference to Jira issue type [$IssueType]"
        $IssueTypeObj = Get-JiraIssueType -IssueType $IssueType -Credential $Credential
        if (-not ($IssueTypeObj))
        {
            throw "Unable to identify Jira issue type [$IssueType]. Use Get-JiraIssueType for more information."
        }
    }

    process
    {
        $ProjectParam = New-Object -TypeName PSObject -Property @{"id" = $ProjectObj.Id}
        $IssueTypeParam = New-Object -TypeName PSObject -Property @{"id" = [String] $IssueTypeObj.Id}

        $props = @{
            "project"   = $ProjectParam;
            "summary"   = $Summary;
            "issuetype" = $IssueTypeParam;
        }
        if ($Priority)
        {
            $props.priority = New-Object -TypeName PSObject -Property @{"id" = [String] $Priority}
        }

        if ($Description)
        {
            $props.description = $Description
        }

        if ($Reporter)
        {
            $props.reporter = New-Object -TypeName PSObject -Property @{"name" = $Reporter}
        }

        if ($Parent)
        {
            $props.parent = New-Object -TypeName PSObject -Property @{"key" = $Parent}
        }

        if ($Labels)
        {
            [void] $props.Add('labels', $Labels)
        }

        Write-Debug "[New-JiraIssue] Processing FixVersion parameter"
        If($FixVersion)
        {
            $fixVersionHash = @()
            Foreach($f in $FixVersion)
            {
                $fixVersionHash += @{
                    'name' = $f
                }
            }
            $props.fixVersions = New-Object -TypeName PSObject -Property @{}
            $props.fixVersions = $fixVersionHash
        }

        Write-Debug "[New-JiraIssue] Processing Fields parameter"
        foreach ($k in $Fields.Keys)
        {
            $name = $k
            $value = $Fields.$k
            Write-Debug "[New-JiraIssue] Attempting to identify field (name=[$name], value=[$value])"

            $f = Get-JiraField -Field $name -Credential $Credential

            if ($f)
            {
                $id = $f.ID
                Write-Debug "[New-JiraIssue] Field [$name] was identified as ID [$id]"
                $props.$id = $value
            }
            else
            {
                Write-Debug "[New-JiraIssue] Field [$name] could not be identified in Jira"
                throw "Unable to identify field [$name] from -Fields hashtable. Use Get-JiraField for more information."
            }
        }

        Write-Verbose "Checking Jira createmeta to make sure all required fields are provided"
        Write-Debug "[New-JiraIssue] Testing Jira createmeta"
        foreach ($c in $createmeta)
        {
            if ($c.Required)
            {
                if ($props.ContainsKey($c.Id))
                {
                    Write-Debug "[New-JiraIssue] Required field (id=[$($c.Id)], name=[$($c.Name)]) was provided (value=[$($props.$($c.Id))])"
                }
                else
                {
                    Write-Debug "[New-JiraIssue] Required field (id=[$($c.Id)], name=[$($c.Name)]) was NOT provided. Writing error."
                    if ($c.Id -eq 'Reporter')
                    {
                        throw "Jira's metadata for project [$Project] and issue type [$IssueType] requires a reporter. Provide a value for the -Reporter parameter when creating an issue."
                    }
                    else
                    {
                        throw "Jira's metadata for project [$Project] and issue type [$IssueType] specifies that a field is required that was not provided (name=[$($c.Name)], id=[$($c.Id)]). You must supply this field via the -Fields parameter. Use Get-JiraIssueCreateMetadata for more information."
                    }
                }
            }
            else
            {
                Write-Debug "[New-JiraIssue] Non-required field (id=[$($c.Id)], name=[$($c.Name)])"
            }
        }

        Write-Debug "[New-JiraIssue] Creating hashtable"
        $hashtable = @{
            'fields' = $props
        }

        Write-Debug "[New-JiraIssue] Converting to JSON"
        $json = ConvertTo-Json -InputObject $hashtable -Depth 3

        Write-Debug "[New-JiraIssue] Checking for -WhatIf and Confirm"
        if ($PSCmdlet.ShouldProcess($Summary, "Creating new Issue on JIRA")) {
            Write-Debug "[New-JiraIssue] Preparing for blastoff!"
            $result = Invoke-JiraMethod -Method Post -URI $issueURL -Body $json -Credential $Credential
        }

        if ($result)
        {
            # REST result will look something like this:
            # {"id":"12345","key":"IT-3676","self":"http://jiraserver.example.com/rest/api/latest/issue/12345"}

            Write-Debug "[New-JiraIssue] Obtaining a reference to the issue we just created"

            $getResult = Get-JiraIssue -Key $result.Key -Credential $Credential
            Write-Debug "[New-JiraIssue] Writing output from New-JiraIssue"
            Write-Output $getResult
        }
        else
        {
            Write-Debug "[New-JiraIssue] Jira returned no results to output."
        }
    }

    end
    {
        Write-Debug "[New-JiraIssue] Completing New-JiraIssue"
    }
}
