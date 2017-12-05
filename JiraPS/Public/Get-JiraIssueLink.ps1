function Get-JiraIssueLink {
    <#
    .Synopsis
       Returns a specific issueLink from Jira
    .DESCRIPTION
       This function returns information regarding a specified issueLink from Jira.
    .EXAMPLE
       Get-JiraIssueLink 10000
       Returns information about the IssueLink with ID 10000
    .EXAMPLE
       Get-JiraIssueLink -IssueLink 10000
       Returns information about the IssueLink with ID 10000
    .EXAMPLE
       (Get-JiraIssue TEST-01).issuelinks | Get-JiraIssueLink
       Returns the information about all IssueLinks in issue TEST-01
    .INPUTS
       [Int[]] issueLink ID
       [PSCredential] Credentials to use to connect to Jira
    .OUTPUTS
       [JiraPS.IssueLink]
    #>
    [CmdletBinding()]
    param(
        # The IssueLink ID to search
        #
        # Accepts input from pipeline when the object is of type JiraPS.IssueLink
        [Parameter( Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName )]
        [Int[]]
        $Id,

        # Credentials to use to connect to JIRA.
        # If not specified, this function will use anonymous access.
        [PSCredential] $Credential
    )

    begin {
        Write-Verbose "[$($MyInvocation.MyCommand.Name)] Function started"

        $server = Get-JiraConfigServer -ErrorAction Stop

        $resourceURi = "$server/rest/api/2/issueLink/{0}"
    }

    process {
        Write-DebugMessage "[$($MyInvocation.MyCommand.Name)] ParameterSetName: $($PsCmdlet.ParameterSetName)"
        Write-DebugMessage "[$($MyInvocation.MyCommand.Name)] PSBoundParameters: $($PSBoundParameters | Out-String)"

        # Validate input object from Pipeline
        if (($_) -and ("JiraPS.IssueLink" -notin $_.PSObject.TypeNames)) {
            $errorItem = [System.Management.Automation.ErrorRecord]::new(
                ([System.ArgumentException]"Invalid Parameter"),
                'ParameterProperties.WrongObjectType',
                [System.Management.Automation.ErrorCategory]::InvalidArgument,
                $Id
            )
            $errorItem.ErrorDetails = "The IssueLink provided did not match the constraints."
            $PSCmdlet.ThrowTerminatingError($errorItem)
        }

        foreach ($_id in $Id) {
            Write-Verbose "[$($MyInvocation.MyCommand.Name)] Processing [$_id]"
            Write-Debug "[$($MyInvocation.MyCommand.Name)] Processing `$_id [$_id]"

            $parameter = @{
                URI        = $resourceURi -f $_id
                Method     = "GET"
                Credential = $Credential
            }
            Write-Debug "[$($MyInvocation.MyCommand.Name)] Invoking JiraMethod with `$parameter"
            $result = Invoke-JiraMethod @parameter

            Write-Output (ConvertTo-JiraIssueLink -InputObject $result)
        }
    }

    end {
        Write-Verbose "[$($MyInvocation.MyCommand.Name)] Complete"
    }
}
