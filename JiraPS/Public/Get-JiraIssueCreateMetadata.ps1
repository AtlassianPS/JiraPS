function Get-JiraIssueCreateMetadata {
    <#
    .Synopsis
       Returns metadata required to create an issue in JIRA
    .DESCRIPTION
       This function returns metadata required to create an issue in JIRA - the fields that can be defined in the process of creating an issue.  This can be used to identify custom fields in order to pass them to New-JiraIssue.

       This function is particularly useful when your JIRA instance includes custom fields that are marked as mandatory.  The required fields can be identified from this See the examples for more details on this approach.
    .EXAMPLE
       Get-JiraIssueCreateMetadata -Project 'TEST' -IssueType 'Bug'
       This example returns the fields available when creating an issue of type Bug under project TEST.
    .EXAMPLE
       Get-JiraIssueCreateMetadata -Project 'JIRA' -IssueType 'Bug' | ? {$_.Required -eq $true}
       This example returns fields available when creating an issue of type Bug under the project Jira.  It then uses Where-Object (aliased by the question mark) to filter only the fields that are required.
    .INPUTS
       This function does not accept pipeline input.
    .OUTPUTS
       This function outputs the JiraPS.Field objects that represent JIRA's create metadata.
    .NOTES
       This function requires either the -Credential parameter to be passed or a persistent JIRA session. See New-JiraSession for more details.  If neither are supplied, this function will run with anonymous access to JIRA.
    #>
    [CmdletBinding()]
    param(
        # Project ID or key of the reference issue.
        [Parameter( Mandatory )]
        [String]
        $Project,

        # Issue type ID or name.
        [Parameter( Mandatory )]
        [String]
        $IssueType,

        # Credentials to use to connect to JIRA.
        # If not specified, this function will use anonymous access.
        [PSCredential]
        $Credential
    )

    begin {
        Write-Verbose "[$($MyInvocation.MyCommand.Name)] Function started"

        $server = Get-JiraConfigServer -ErrorAction Stop

        $resourceURi = "$server/rest/api/latest/issue/createmeta?projectIds={0}&issuetypeIds={1}"
    }

    process {
        Write-DebugMessage "[$($MyInvocation.MyCommand.Name)] ParameterSetName: $($PsCmdlet.ParameterSetName)"
        Write-DebugMessage "[$($MyInvocation.MyCommand.Name)] PSBoundParameters: $($PSBoundParameters | Out-String)"

        $projectObj = Get-JiraProject -Project $Project -Credential $Credential -ErrorAction Stop
        $issueTypeObj = Get-JiraIssueType -IssueType $IssueType -Credential $Credential -ErrorAction Stop

        $parameter = @{
            URI        = $resourceURi -f $projectObj.Id, $issueTypeObj.Id
            Method     = "GET"
            Credential = $Credential
        }
        Write-Debug "[$($MyInvocation.MyCommand.Name)] Invoking JiraMethod with `$parameter"
        $result = Invoke-JiraMethod @parameter

        if ($result) {
            if (@($result.projects).Count -eq 0) {
                $errorMessage = @{
                    Category         = "InvalidResult"
                    CategoryActivity = "Validating response"
                    Message          = "No projects were found for the given project [$Project]. Use Get-JiraProject for more details."
                }
                Write-Error @errorMessage
            }
            elseif (@($result.projects).Count -gt 1) {
                $errorMessage = @{
                    Category         = "InvalidResult"
                    CategoryActivity = "Validating response"
                    Message          = "Multiple projects were found for the given project [$Project]. Refine the parameters to return only one project."
                }
                Write-Error @errorMessage
            }

            if (@($result.projects.issuetypes) -eq 0) {
                $errorMessage = @{
                    Category         = "InvalidResult"
                    CategoryActivity = "Validating response"
                    Message          = "No issue types were found for the given issue type [$IssueType]. Use Get-JiraIssueType for more details."
                }
                Write-Error @errorMessage
            }
            elseif (@($result.projects.issuetypes).Count -gt 1) {
                $errorMessage = @{
                    Category         = "InvalidResult"
                    CategoryActivity = "Validating response"
                    Message          = "Multiple issue types were found for the given issue type [$IssueType]. Refine the parameters to return only one issue type."
                }
                Write-Error @errorMessage
            }

            Write-Output (ConvertTo-JiraCreateMetaField -InputObject $result)
        }
        else {
            $errorItem = [System.Management.Automation.ErrorRecord]::new(
                ([System.ArgumentException]"No results"),
                'IssueMetadata.ObjectNotFound',
                [System.Management.Automation.ErrorCategory]::ObjectNotFound,
                $Project
            )
            $errorItem.ErrorDetails = "No metadata found for project $Project and issueType $IssueType."
            Throw $errorItem
        }
    }

    end {
        Write-Verbose "[$($MyInvocation.MyCommand.Name)] Complete"
    }
}
