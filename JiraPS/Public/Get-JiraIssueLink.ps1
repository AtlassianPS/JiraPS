function Get-JiraIssueLink {
    # .ExternalHelp ..\JiraPS-help.xml
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

        $resourceURi = "rest/api/2/issueLink/{0}"
    }

    process {
        Write-DebugMessage "[$($MyInvocation.MyCommand.Name)] ParameterSetName: $($PsCmdlet.ParameterSetName)"
        Write-DebugMessage "[$($MyInvocation.MyCommand.Name)] PSBoundParameters: $($PSBoundParameters | Out-String)"

        # Validate input object from Pipeline
        if (($_) -and ("JiraPS.IssueLink" -notin $_.PSObject.TypeNames)) {
            $exception = ([System.ArgumentException]"Invalid Parameter")
            $errorId = 'ParameterProperties.WrongObjectType'
            $errorCategory = [System.Management.Automation.ErrorCategory]::InvalidArgument
            $errorTarget = $Id
            $errorItem = New-Object -TypeName System.Management.Automation.ErrorRecord $exception, $errorId, $errorCategory, $errorTarget
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
