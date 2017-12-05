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
        [Parameter( Position = 0, Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName )]
        [Alias("Key")]
        [String[]]
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

        $resourceURi = "$server/rest/api/latest/issue/{0}/remotelink{1}"
    }

    process {
        Write-DebugMessage "[$($MyInvocation.MyCommand.Name)] ParameterSetName: $($PsCmdlet.ParameterSetName)"
        Write-DebugMessage "[$($MyInvocation.MyCommand.Name)] PSBoundParameters: $($PSBoundParameters | Out-String)"

        foreach ($_issue in $Issue) {
            Write-Verbose "[$($MyInvocation.MyCommand.Name)] Processing [$_issue]"
            Write-Debug "[$($MyInvocation.MyCommand.Name)] Processing `$_issue [$_issue]"

            $urlAppendix = ""
            if ($LinkId) {
                $urlAppendix = "/$LinkId"
            }

            $parameter = @{
                URI        = $resourceURi -f $_issue, $urlAppendix
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
