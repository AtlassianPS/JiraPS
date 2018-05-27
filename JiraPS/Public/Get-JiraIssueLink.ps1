function Get-JiraIssueLink {
    [CmdletBinding()]
    param(
        [Parameter( Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName )]
        [Int[]]
        $Id,

        [Parameter()]
        [System.Management.Automation.PSCredential]
        [System.Management.Automation.Credential()]
        $Credential = [System.Management.Automation.PSCredential]::Empty
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
