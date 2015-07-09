function Get-JiraIssue
{
    <#
    .Synopsis
       Returns information about an issue in JIRA.
    .DESCRIPTION
       This function obtains references to issues in JIRA.
       
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
    [CmdletBinding(DefaultParameterSetName = 'ByIssueKey')]
    param(
        [Parameter(ParameterSetName = 'ByIssueKey',
                   Mandatory = $true,
                   Position = 0)]
        [ValidateNotNullOrEmpty()]
        [String[]] $Key,

        [Parameter(ParameterSetName = 'ByInputObject',
                   Mandatory = $true,
                   Position = 0)]
        [Object[]] $InputObject,

        [Parameter(ParameterSetName = 'ByJQL',
                   Mandatory = $true)]
        [Alias('JQL')]
        [String] $Query,

        [Parameter(ParameterSetName = 'ByJQL')]
        [Int] $MaxResults = 50,

        # Credentials to use to connect to Jira
        [Parameter(Mandatory = $false)]
        [System.Management.Automation.PSCredential] $Credential
    )

    begin
    {
        Write-Debug "[Get-JiraIssue] Reading server from config file"
        $server = Get-JiraConfigServer -ConfigFile $ConfigFile -ErrorAction Stop
        
        Write-Debug "[Get-JiraIssue] ParameterSetName=$($PSCmdlet.ParameterSetName)"
    }

    process
    {
        if ($PSCmdlet.ParameterSetName -eq 'ByIssueKey')
        {
            foreach ($k in $Key)
            {
                Write-Debug "[Get-JiraIssue] Processing issue key [$k]"
                $issueURL = "$($server)/rest/api/latest/issue/${k}?expand=transitions"

                Write-Debug "[Get-JiraIssue] Preparing for blastoff!"
                $result = Invoke-JiraMethod -Method Get -URI $issueURL -Credential $Credential
                
                if ($result)
                {
                    Write-Debug "[Get-JiraIssue] Converting REST result to Jira object"
                    $obj = ConvertTo-JiraIssue -InputObject $result

                    Write-Debug "[Get-JiraIssue] Outputting result"
                    Write-Output $obj
                } else {
                    Write-Debug "[Get-JiraIssue] Invoke-JiraMethod returned no results to output."
                }
            }
        } elseif ($PSCmdlet.ParameterSetName -eq 'ByInputObject') {
            foreach ($i in $InputObject)
            {
                Write-Debug "[Get-JiraIssue] Processing InputObject [$i]"
                if ((Get-Member -InputObject $i).TypeName -eq 'PSJira.Issue')
                {
                    Write-Debug "[Get-JiraIssue] Issue parameter is a PSJira.Issue object"
                    $issueKey = $i.Key
                } else {
                    $issueKey = $i.ToString()
                    Write-Debug "[Get-JiraIssue] Issue key is assumed to be [$issueKey] via ToString()"
                }

                Write-Debug "[Get-JiraIssue] Invoking myself with the Key parameter set to search for issue [$issueKey]"
                $issueObj = Get-JiraIssue -Key $issueKey -Credential $Credential
                Write-Debug "[Get-JiraIssue] Returned from invoking myself; outputting results"
                Write-Output $issueObj
            }
        } elseif ($PSCmdlet.ParameterSetName -eq 'ByJQL') {
            
            Write-Debug "[Get-JiraMethod] Escaping query and building URL"
            $escapedQuery = [System.Web.HttpUtility]::UrlPathEncode($Query)
            $issueURL = "$($server)/rest/api/latest/search?jql=$escapedQuery&validateQuery=true&expand=transitions&maxResults=$MaxResults"

            Write-Debug "[Get-JiraMethod] Preparing for blastoff!"
            $result = Invoke-JiraMethod -Method Get -URI $issueURL -Credential $Credential

            if ($result)
            {
                # {"startAt":0,"maxResults":50,"total":0,"issues":[]}

                if ($result.total -gt 0)
                {
                    Write-Debug "[Get-JiraMethod] Converting REST result to Jira issue"
                    $obj = ConvertTo-JiraIssue -InputObject $result.issues

                    Write-Debug "[Get-JiraMethod] Outputting result"
                    Write-Output $obj
                } else {
                    Write-Debug "[Get-JiraMethod] No results were found for the specified query"
                    Write-Verbose "No results were found for the query [$Query]"
                }
            } else {
                Write-Debug "[Get-JiraMethod] Invoke-JiraMethod returned no results"
            }
        }
    }

    end
    {
        Write-Debug "[Get-JiraIssue] Complete"
    }
}