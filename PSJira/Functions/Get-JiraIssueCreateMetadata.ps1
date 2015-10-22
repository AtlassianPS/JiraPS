function Get-JiraIssueCreateMetadata
{
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
       This function outputs the PSJira.Field objects that represent JIRA's create metadata.
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
                throw "No projects were found for the given project [$Project]. Use Get-JiraProject for more details."
            } elseif (@($jiraResult.projects).Count -gt 1) {
                Write-Debug "[Get-JiraIssueCreateMetadata] Multiple project results were found. Throwing exception."
                throw "Multiple projects were found for the given project [$Project]. Refine the parameters to return only one project."
            }

            $projectId = $jiraResult.projects.id
            $projectKey = $jiraResult.projects.key

            Write-Debug "[Get-JiraIssueCreateMetadata] Identified project key: [$Project]"

            if (@($jiraResult.projects.issuetypes) -eq 0)
            {
                Write-Debug "[Get-JiraIssueCreateMetadata] No issue type results were found. Throwing exception."
                throw "No issue types were found for the given issue type [$IssueType]. Use Get-JiraIssueType for more details."
            } elseif (@($jiraResult.projects.issuetypes).Count -gt 1) {
                Write-Debug "[Get-JiraIssueCreateMetadata] Multiple issue type results were found. Throwing exception."
                throw "Multiple issue types were found for the given issue type [$IssueType]. Refine the parameters to return only one issue type."
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


