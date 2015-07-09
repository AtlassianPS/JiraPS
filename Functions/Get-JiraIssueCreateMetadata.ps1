function Get-JiraIssueCreateMetadata
{
    <#
    .Synopsis
       Returns metadata required to create an issue in JIRA
    .DESCRIPTION
       This function returns metadata required to create an issue in JIRA.
       
       This function can be used to directly query JIRA for a specific issue key or internal issue ID. It can also be used to query JIRA for issues matching a specific criteria using JQL (Jira Query Language).

       For more details on JQL syntax, see this articla from Atlassian: https://confluence.atlassian.com/display/JIRA/Advanced+Searching

       Output from this function can be piped to various other functions in this module, including Set-JiraIssue, Add-JiraIssueComment, and Invoke-JiraIssueTransition.
    .EXAMPLE
       Get-JiraIssue -Key TEST-001
       This example returns a reference to JIRA issue TEST-001.
    .EXAMPLE
       Get-JiraIssue "TEST-002" | Add-JiraIssueComment "Test comment from PowerShell"
       This example illustrates pipeline use from Get-JiraIssue to Add-JiraIssueComment.
    .EXAMPLE
       Get-JiraIssue -Query 'project = "TEST" AND created >= -5d'
       This example illustrates using the Query parameter and JQL syntax to query Jira for matching issues.
    .INPUTS
       This function can accept PSJira.Issue objects, Strings, or Objects via the pipeline.
       
       * If a PSJira.Issue object is passed, this function returns a new reference to the same issue.
       * If a String is passed, this function searches for an issue with that issue key or internal ID.
       * If an Object is passed, this function invokes its ToString() method and treats it as a String.
    .OUTPUTS
       This function outputs the PSJira.Issue object retrieved.
    .NOTES
       This function requires either the -Credential parameter to be passed or a persistent JIRA session. See New-JiraSession for more details.  If neither are supplied, this function will run with anonymous access to JIRA.
    #>
    [CmdletBinding()]
    param(
        # Project ID or key
        [Parameter(Mandatory = $true,
                   Position = 0)]
        [String] $Project,

        # Issue type ID or name
        [Parameter(Mandatory = $true,
                   Position = 1)]
        [String] $IssueType,

        [String] $ConfigFile,

        # Credentials to use to connect to Jira
        [Parameter(Mandatory = $false)]
        [System.Management.Automation.PSCredential] $Credential
    )

    begin
    {
        Write-Debug "[Get-JiraIssueCreateMetadata] Reading server from config file"
        try
        {
            $server = Get-JiraConfigServer -ConfigFile $ConfigFile -ErrorAction Stop
        } catch {
            $err = $_
            Write-Debug "[Get-JiraIssueCreateMetadata] Encountered an error reading the Jira server."
            throw $err
        }
        
        Write-Debug "[Get-JiraIssueCreateMetadata] Building URI for REST call based on parameters"
        $uri = "$server/rest/api/latest/issue/createmeta?"
        
        Write-Debug "[Get-JiraIssueCreateMetadata] Obtaining project ID for project [$Project]"
        $projectObj = Get-JiraProject -Project $Project -Credential $Credential
        if ($projectObj)
        {
            $projectId = $projectObj.Id
            $uri = "${uri}projectIds=$projectId&"
        } else {
            throw "No project was found for the given Project [$Project]. Use Get-JiraProject for more information on this issue."
        }

        Write-Debug "[Get-JiraIssueCreateMetadata] Obtaining issue type ID for issue type [$IssueType]"
        $issueTypeObj = Get-JiraIssueType -IssueType $IssueType -Credential $Credential
        if ($issueTypeObj)
        {
#            #$n = [System.Net.WebUtility]::UrlEncode($IssueType)
#            # This escapes URLs in the correct syntax for a Web request.
#            # Need to load the assembly before we use this class.
#            Add-Type -AssemblyName System.Web
#            $n = [System.Web.HttpUtility]::UrlPathEncode($IssueType)
#            $uri = "${uri}issuetypeNames=$n&"
            
            $issueTypeId = $issueTypeObj.Id
            $uri = "${uri}issuetypeIds=$issueTypeId&"
        } else {
            throw "No issue types were found for the given IssueType [$IssueType]. Use Get-JiraIssueType for more information on this issue."
        }

        $uri = "${uri}expand=projects.issuetypes.fields"
    }

    process
    {
        Write-Debug "[Get-JiraIssueCreateMetadata] Preparing for blastoff!"
        $jiraResult = Invoke-JiraMethod -Method Get -URI $uri -Credential $Credential
        
        if ($jiraResult)
        {
            if (@($jiraResult.projects).Count -eq 0)
            {
                Write-Debug "[Get-JiraIssueCreateMetadata] No project results were found. Throwing exception."
                if (-not ($Credential))
                {
                    throw "No projects were found for the given project type (projectKey=[$Project]). If you are certain that the key is correct, try passing credentials to Jira using the -Credential parameter."
                } else {
                    throw "No projects were found for the given project type (projectKey=[$Project])."
                }
            } elseif (@($jiraResult.projects).Count -gt 1) {
                Write-Debug "[Get-JiraIssueCreateMetadata] Multiple project results were found. Throwing exception."
                throw "Multiple projects were found for the given project type (projectKey=[$Project]). Refine the parameters to return only one project."
            }

            $projectId = $jiraResult.projects.id
            $projectKey = $jiraResult.projects.key

            Write-Debug "[Get-JiraIssueCreateMetadata] Identified project key: [$Project]"

            if (@($jiraResult.projects.issuetypes) -eq 0)
            {
                Write-Debug "[Get-JiraIssueCreateMetadata] No issue type results were found. Throwing exception."
                throw "No issue types were found for the given project type (issuetypeName=[$IssueType])."
            } elseif (@($jiraResult.projects.issuetypes).Count -gt 1) {
                Write-Debug "[Get-JiraIssueCreateMetadata] Multiple issue type results were found. Throwing exception."
                throw "Multiple issue types were found for the given issue type (issuetypeName=[$IssueType]). Refine the parameters to return only one issue type."
            }

            $issueTypeId = $jiraResult.projects.issuetypes.id
            $issueTypeName = $jiraResult.projects.issuetypes.name

            Write-Debug "[Get-JiraIssueCreateMetadata] Obtaining reference to fields"
            $fields = $jiraResult.projects.issuetypes.fields
            
            Write-Debug "[Get-JiraIssueCreateMetadata] Obtaining field names"
            $fieldNames = (Get-Member -InputObject $fields -MemberType '*Property').Name
            
            $resultArrayList = New-Object -TypeName System.Collections.ArrayList
            foreach ($name in $fieldNames)
            {
                $thisRaw = $fields.$name
                $obj = [PSCustomObject] @{
                    'Id' = $name;
                    'Name' = $thisRaw.name;
                    'Required' = [bool]::Parse($thisRaw.required);
                    'HasDefaultValue' = [bool]::Parse($thisRaw.hasDefaultValue);
                    'Project' = $projectObj;
                    'IssueType' = $issueTypeObj;
                }

                $obj.PSObject.TypeNames.Insert(0, 'PSJira.CreateMetaField')
                Write-Output $obj
            }
        }
    }
}