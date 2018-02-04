function Remove-JiraIssueLink {
    <#
    .Synopsis
        Removes a issue link from a JIRA issue
    .DESCRIPTION
        This function removes a issue link from a JIRA issue.
    .EXAMPLE
        Remove-JiraIssueLink 1234,2345
        Removes two issue links with id 1234 and 2345
    .EXAMPLE
        Get-JiraIssue -Query "project = Project1 AND label = lingering" | Remove-JiraIssueLink
        Removes all issue links for all issues in project Project1 and that have a label "lingering"
    .INPUTS
        [JiraPS.IssueLink[]] The JIRA issue link  which to delete
    .OUTPUTS
        This function returns no output.
    #>
    [CmdletBinding( SupportsShouldProcess, ConfirmImpact = 'Medium' )]
    param(
        # IssueLink to delete
        # If an Issue is provided, all issueLinks will be deleted.
        [Parameter( Mandatory, ValueFromPipeline )]
        [ValidateNotNullOrEmpty()]
        [ValidateScript(
            {
                $Input = $_
                $objectProperties = $Input | Get-Member -MemberType *Property
                switch ($true) {
                    {("JiraPS.Issue" -in $Input.PSObject.TypeNames) -and ("issueLinks" -in $objectProperties.Name)} { return $true }
                    {("JiraPS.IssueLink" -in $Input.PSObject.TypeNames) -and ("Id" -in $objectProperties.Name)} { return $true }
                    default {
                        $errorItem = [System.Management.Automation.ErrorRecord]::new(
                            ([System.ArgumentException]"Invalid Type for Parameter"),
                            'ParameterType.NotJiraIssue',
                            [System.Management.Automation.ErrorCategory]::InvalidArgument,
                            $Input
                        )
                        $errorItem.ErrorDetails = "Wrong object type provided for Issue. Expected [JiraPS.Issue], [JiraPS.IssueLink] or [String], but was $($Input.GetType().Name)"
                        $PSCmdlet.ThrowTerminatingError($errorItem)
                        <#
                          #ToDo:CustomClass
                          Once we have custom classes, this check can be done with Type declaration
                        #>
                    }
                }
            }
        )]
        [Object[]]
        $IssueLink,

        # Credentials to use to connect to JIRA.
        # If not specified, this function will use anonymous access.
        [PSCredential]
        $Credential
    )

    begin {
        Write-Verbose "[$($MyInvocation.MyCommand.Name)] Function started"

        $server = Get-JiraConfigServer -ErrorAction Stop

        $resourceURi = "$server/rest/api/latest/issueLink/{0}"
    }

    process {
        Write-DebugMessage "[$($MyInvocation.MyCommand.Name)] ParameterSetName: $($PsCmdlet.ParameterSetName)"
        Write-DebugMessage "[$($MyInvocation.MyCommand.Name)] PSBoundParameters: $($PSBoundParameters | Out-String)"

        # As we are not able to use proper type casting in the parameters, this is a workaround
        # to extract the data from a JiraPS.Issue object
        <#
          #ToDo:CustomClass
          Once we have custom classes, this will no longer be necessary
        #>
        if ($IssueLink.issueLinks) {
            $IssueLink = $IssueLink.issueLinks
        }

        foreach ($link in $IssueLink) {
            Write-Verbose "[$($MyInvocation.MyCommand.Name)] Processing [$link]"
            Write-Debug "[$($MyInvocation.MyCommand.Name)] Processing `$link [$link]"

            $parameter = @{
                URI        = $resourceURi -f $link.id
                Method     = "DELETE"
                Credential = $Credential
            }
            Write-Debug "[$($MyInvocation.MyCommand.Name)] Invoking JiraMethod with `$parameter"
            if ($PSCmdlet.ShouldProcess($link.id, "Remove IssueLink")) {
                Invoke-JiraMethod @parameter
            }
        }
    }

    end {
        Write-Verbose "[$($MyInvocation.MyCommand.Name)] Complete"
    }
}
