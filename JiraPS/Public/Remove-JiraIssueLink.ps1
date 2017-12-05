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
        [Parameter( Mandatory, ValueFromPipeline )]
        [ValidateNotNullOrEmpty()]
        [ValidateScript(
            {
                $objectProperties = $_ | Get-Member -InputObject $_ -MemberType *Property
                if (
                    ($_ -isnot [String]) -and (
                        ("JiraPS.Issue" -notin $_.PSObject.TypeNames) -or
                        ("JiraPS.IssueLink" -notin $_.PSObject.TypeNames)
                    )
                 ) {
                    $errorItem = [System.Management.Automation.ErrorRecord]::new(
                        ([System.ArgumentException]"Invalid Type for Parameter"),
                        'ParameterType.NotJiraIssue',
                        [System.Management.Automation.ErrorCategory]::InvalidArgument,
                        $_
                    )
                    $errorItem.ErrorDetails = "Wrong object type provided for Issue. Expected [JiraPS.Issue], [JiraPS.IssueLink] or [String], but was $($_.GetType().Name)"
                    $PSCmdlet.ThrowTerminatingError($errorItem)
                    <#
                      #ToDo:CustomClass
                      Once we have custom classes, this check can be done with Type declaration
                    #>
                }
                elseif (-not($objectProperties.Name -contains "id")) {
                    $errorItem = [System.Management.Automation.ErrorRecord]::new(
                        ([System.ArgumentException]"Invalid Parameter"),
                        'ParameterType.MissingProperty',
                        [System.Management.Automation.ErrorCategory]::InvalidArgument,
                        $_
                    )
                    $errorItem.ErrorDetails = "The IssueLink provided does not contain the information needed. $($objectProperties | Out-String)."
                    $PSCmdlet.ThrowTerminatingError($errorItem)
                    <#
                      #ToDo:CustomClass
                      Once we have custom classes, this check can be done with Type declaration
                    #>
                }
                else {
                    return $true
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

        $server = Get-JiraConfigServer -ConfigFile $ConfigFile -ErrorAction Stop

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
        if (($_) -and ("JiraPS.Issue" -in $_.PSObject.TypeNames)) {
            $IssueLink = $_.issueLinks
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
