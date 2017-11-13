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
    [CmdletBinding(
        SupportsShouldProcess = $true,
        ConfirmImpact = 'Medium'
    )]
    param(
        # IssueLink to delete
        [Parameter(
            Position = 0,
            Mandatory = $true,
            ValueFromPipeline = $true
        )]
        [Object[]] $IssueLink,

        # Credentials to use to connect to JIRA.
        # If not specified, this function will use anonymous access.
        [PSCredential] $Credential
    )

    begin {
        Write-Verbose "[$($MyInvocation.MyCommand.Name)] Function started"

        $server = Get-JiraConfigServer -ConfigFile $ConfigFile -ErrorAction Stop

        $restUrl = "$server/rest/api/latest/issueLink/{0}"
    }

    process {
        Write-DebugMessage "[$($MyInvocation.MyCommand.Name)] ParameterSetName: $($PsCmdlet.ParameterSetName)"
        Write-DebugMessage "[$($MyInvocation.MyCommand.Name)] PSBoundParameters: $($PSBoundParameters | Out-String)"


        # As we are not able to use proper type casting in the parameters, this is a workaround
        # to extract the data from a JiraPS.Issue object
        if (($_) -and ($_.PSObject.TypeNames[0] -eq "JiraPS.Issue")) {
            $IssueLink = $_.issueLinks
        }

        # Validate IssueLink object
        $objectProperties = $IssueLink | Get-Member -MemberType *Property
        if (-not($objectProperties.Name -contains "id")) {
            $message = "The IssueLink provided does not contain the information needed. $($objectProperties | Out-String)"
            $exception = New-Object -TypeName System.ArgumentException -ArgumentList $message
            Throw $exception
        }

        # Validate input object from Pipeline
        if (($_) -and ($_.PSObject.TypeNames[0] -notin @("JiraPS.IssueLink", "JiraPS.Issue"))) {
            $message = "Wrong object type provided for Issue. Only JiraPS.IssueLink is accepted"
            $exception = New-Object -TypeName System.ArgumentException -ArgumentList $message
            Throw $exception
        }

        foreach ($link in $IssueLink) {
            Write-Debug "[Remove-JiraIssueLink] Processing issue key [$k]"
            $thisUrl = $restUrl -f $link.id
            if ($PSCmdlet.ShouldProcess($link.id, "Remove IssueLink")) {
                Write-Debug "[$($MyInvocation.MyCommand.Name)] Invoking JiraMethod with `$parameter"
                Invoke-JiraMethod -Method Delete -URI $thisUrl -Credential $Credential
            }
        }
    }

    end {
        Write-Verbose "[$($MyInvocation.MyCommand.Name)] Complete"
    }
}
