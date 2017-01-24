function Get-JiraIssueEditMetadata
{
    <#
    .Synopsis
       Returns metadata required to create an issue in JIRA
    .DESCRIPTION
       This function returns metadata required to create an issue in JIRA - the fields that can be defined in the process of creating an issue.  This can be used to identify custom fields in order to pass them to New-JiraIssue.

       This function is particularly useful when your JIRA instance includes custom fields that are marked as mandatory.  The required fields can be identified from this See the examples for more details on this approach.
    .EXAMPLE
       Get-JiraIssueEditMetadata -Project 'TEST' -IssueType 'Bug'
       This example returns the fields available when creating an issue of type Bug under project TEST.
    .EXAMPLE
       Get-JiraIssueEditMetadata -Project 'JIRA' -IssueType 'Bug' | ? {$_.Required -eq $true}
       This example returns fields available when creating an issue of type Bug under the project Jira.  It then uses Where-Object (aliased by the question mark) to filter only the fields that are required.
    .INPUTS
       This function does not accept pipeline input.
    .OUTPUTS
       This function outputs the PSJira.Field objects that represent JIRA's create metadata.
    .NOTES
       This function requires either the -Credential parameter to be passed or a persistent JIRA session. See New-JiraSession for more details.  If neither are supplied, this function will run with anonymous access to JIRA.
    #>
    [CmdletBinding()]
    param(
        # Issue id or key
        [Parameter(Mandatory = $true,
                   Position = 0)]
        [String] $Issue,

        [String] $ConfigFile,

        # Credentials to use to connect to Jira
        [Parameter(Mandatory = $false)]
        [System.Management.Automation.PSCredential] $Credential
    )

    begin
    {
        Write-Debug "[Get-JiraIssueEditMetadata] Reading server from config file"
        try
        {
            $server = Get-JiraConfigServer -ConfigFile $ConfigFile -ErrorAction Stop
        } catch {
            $err = $_
            Write-Debug "[Get-JiraIssueEditMetadata] Encountered an error reading the Jira server."
            throw $err
        }

        Write-Debug "[Get-JiraIssueEditMetadata] Building URI for REST call based on parameters"
        $uri = "$server/rest/api/latest/issue/$Issue/editmeta"
    }

    process
    {
        Write-Debug "[Get-JiraIssueEditMetadata] Preparing for blastoff!"
        $jiraResult = Invoke-JiraMethod -Method Get -URI $uri -Credential $Credential

        if ($jiraResult)
        {
            if (@($jiraResult.projects).Count -eq 0)
            {
                Write-Debug "[Get-JiraIssueEditMetadata] No project results were found. Throwing exception."
                throw "No projects were found for the given project [$Project]. Use Get-JiraProject for more details."
            } elseif (@($jiraResult.projects).Count -gt 1) {
                Write-Debug "[Get-JiraIssueEditMetadata] Multiple project results were found. Throwing exception."
                throw "Multiple projects were found for the given project [$Project]. Refine the parameters to return only one project."
            }

            $projectId = $jiraResult.projects.id
            $projectKey = $jiraResult.projects.key

            Write-Debug "[Get-JiraIssueEditMetadata] Identified project key: [$Project]"

            if (@($jiraResult.projects.issuetypes) -eq 0)
            {
                Write-Debug "[Get-JiraIssueEditMetadata] No issue type results were found. Throwing exception."
                throw "No issue types were found for the given issue type [$IssueType]. Use Get-JiraIssueType for more details."
            } elseif (@($jiraResult.projects.issuetypes).Count -gt 1) {
                Write-Debug "[Get-JiraIssueEditMetadata] Multiple issue type results were found. Throwing exception."
                throw "Multiple issue types were found for the given issue type [$IssueType]. Refine the parameters to return only one issue type."
            }

            Write-Debug "[Get-JiraIssueEditMetadata] Converting results to custom object"
            $obj = ConvertTo-JiraEditMetaField -InputObject $jiraResult

            Write-Debug "Outputting results"
            Write-Output $obj

#            Write-Output $jiraResult
        } else {
            Write-Debug "[Get-JiraIssueEditMetadata] No results were returned from JIRA."
        }
    }
}


