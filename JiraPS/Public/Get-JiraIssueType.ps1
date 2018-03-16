function Get-JiraIssueType {
    <#
    .SYNOPSIS
        Returns information about the available issue type in JIRA.
    .DESCRIPTION
        This function retrieves all the available IssueType on the JIRA server an returns them as JiraPS.IssueType.

        This function can restrict the output to a subset of the available IssueTypes if told so.
    .EXAMPLE
        Get-JiraIssueType
        This example returns all the IssueTypes on the JIRA server.
    .EXAMPLE
        Get-JiraIssueType -IssueType "Bug"
        This example returns only the IssueType "Bug".
    .EXAMPLE
        Get-JiraIssueType -IssueType "Bug","Task","4"
        This example return the information about the IssueType named "Bug" and "Task" and with id "4".
    .INPUTS
        This function accepts Strings via the pipeline.
    .OUTPUTS
        This function outputs the JiraPS.IssueType object retrieved.
    .NOTES
        This function requires either the -Credential parameter to be passed or a persistent JIRA session. See New-JiraSession for more details.  If neither are supplied, this function will run with anonymous access to JIRA.
    #>
    [CmdletBinding( DefaultParameterSetName = '_All' )]
    param(
        # The Issue Type name or ID to search.
        [Parameter( Position = 0, Mandatory, ValueFromPipeline, ParameterSetName = '_Search' )]
        [String[]]
        $IssueType,

        # Credentials to use to connect to JIRA.
        # If not specified, this function will use anonymous access.
        [PSCredential]
        $Credential
    )

    begin {
        Write-Verbose "[$($MyInvocation.MyCommand.Name)] Function started"

        $server = Get-JiraConfigServer -ErrorAction Stop

        $resourceURi = "$server/rest/api/latest/issuetype"
    }

    process {
        Write-DebugMessage "[$($MyInvocation.MyCommand.Name)] ParameterSetName: $($PsCmdlet.ParameterSetName)"
        Write-DebugMessage "[$($MyInvocation.MyCommand.Name)] PSBoundParameters: $($PSBoundParameters | Out-String)"

        switch ($PSCmdlet.ParameterSetName) {
            '_All' {
                $parameter = @{
                    URI        = $resourceURi
                    Method     = "GET"
                    Credential = $Credential
                }
                Write-Debug "[$($MyInvocation.MyCommand.Name)] Invoking JiraMethod with `$parameter"
                $result = Invoke-JiraMethod @parameter

                Write-Output (ConvertTo-JiraIssueType -InputObject $result)
            }
            '_Search' {
                foreach ($_issueType in $IssueType) {
                    Write-Verbose "[$($MyInvocation.MyCommand.Name)] Processing [$_issueType]"
                    Write-Debug "[$($MyInvocation.MyCommand.Name)] Processing `$_issueType [$_issueType]"

                    $allIssueTypes = Get-JiraIssueType -Credential $Credential

                    Write-Output ($allIssueTypes | Where-Object -FilterScript {$_.Id -eq $_issueType})
                    Write-Output ($allIssueTypes | Where-Object -FilterScript {$_.Name -like $_issueType})
                }
            }
        }
    }

    end {
        Write-Verbose "[$($MyInvocation.MyCommand.Name)] Complete"
    }
}
