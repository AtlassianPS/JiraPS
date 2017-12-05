function Get-JiraRemoteLink {
    <#
    .Synopsis
       Returns a remote link from a Jira issue
    .DESCRIPTION
       This function returns information on remote links from a  JIRA issue.
    .EXAMPLE
       Get-JiraRemoteLink -Issue Project1-1000 -Credential $cred
       Returns information about all remote links from the issue "Project1-1000"
    .EXAMPLE
       Get-JiraRemoteLink -Issue Project1-1000 -LinkId 100000 -Credential $cred
       Returns information about a specific remote link from the issue "Project1-1000"
    .INPUTS
       [Object[]] The issue to look up in JIRA. This can be a String or a JiraPS.Issue object.
    .OUTPUTS
       [JiraPS.Link]
    #>
    [CmdletBinding()]
    param(
        # The Issue Object or ID to link.
        [Parameter( Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName )]
        [ValidateNotNullOrEmpty()]
        [ValidateScript(
            {
                if (("JiraPS.Issue" -notin $_.PSObject.TypeNames) -and (($_ -isnot [String]))) {
                    $errorItem = [System.Management.Automation.ErrorRecord]::new(
                        ([System.ArgumentException]"Invalid Type for Parameter"),
                        'ParameterType.NotJiraIssue',
                        [System.Management.Automation.ErrorCategory]::InvalidArgument,
                        $_
                    )
                    $errorItem.ErrorDetails = "Wrong object type provided for Issue. Expected [JiraPS.Issue] or [String], but was $($_.GetType().Name)"
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
        [Alias("Key")]
        [Object]
        $Issue,

        # Get a single link by it's id.
        [Int]
        $LinkId,

        # Credentials to use to connect to JIRA.
        # If not specified, this function will use anonymous access.
        [PSCredential]
        $Credential
    )

    begin {
        Write-Verbose "[$($MyInvocation.MyCommand.Name)] Function started"

        $server = Get-JiraConfigServer -ConfigFile $ConfigFile -ErrorAction Stop
    }

    process {
        Write-DebugMessage "[$($MyInvocation.MyCommand.Name)] ParameterSetName: $($PsCmdlet.ParameterSetName)"
        Write-DebugMessage "[$($MyInvocation.MyCommand.Name)] PSBoundParameters: $($PSBoundParameters | Out-String)"

        foreach ($_issue in $Issue) {
            Write-Verbose "[$($MyInvocation.MyCommand.Name)] Processing [$_issue]"
            Write-Debug "[$($MyInvocation.MyCommand.Name)] Processing `$_issue [$_issue]"

            # Find the proper object for the Issue
            $issueObj = Resolve-JiraIssueObject -InputObject $_issue -Credential $Credential

            $urlAppendix = ""
            if ($LinkId) {
                $urlAppendix = "/$LinkId"
            }

            $parameter = @{
                URI        = "{0}/remotelink{1}" -f $issueObj.RestUrl, $urlAppendix
                Method     = "GET"
                Credential = $Credential
            }
            Write-Debug "[$($MyInvocation.MyCommand.Name)] Invoking JiraMethod with `$parameter"
            $result = Invoke-JiraMethod @parameter

            Write-Output (ConvertTo-JiraIssueLinkType -InputObject $result)
        }
    }

    end {
        Write-Verbose "[$($MyInvocation.MyCommand.Name)] Complete"
    }
}
