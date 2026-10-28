function Get-JiraIssueEditMetadataOperation {
    [System.Diagnostics.CodeAnalysis.SuppressMessage('PSUseSingularNouns', '')]
    [CmdletBinding()]
    param(
        [Parameter( Mandatory )]
        [String]
        $Issue,
        <#
          #ToDo:CustomClass
          Now that we have custom classes, this could be typed as [AtlassianPS.JiraPS.Issue]
        #>

        [Parameter()]
        [AtlassianPS.Connection]
        $RequestContext
    )

    begin {
        Write-Verbose "[$($MyInvocation.MyCommand.Name)] Function started"

        $resourceURi = "/rest/api/2/issue/{0}/editmeta"
    }

    process {
        Write-DebugMessage "ParameterSetName: $($PsCmdlet.ParameterSetName)"
        Write-DebugMessage -BoundParameters $PSBoundParameters

        $parameter = @{
            URI    = $resourceURi -f $Issue
            <#
              #ToDo:CustomClass
              When the Input is typecasted to a AtlassianPS.JiraPS.Issue, the `self` of the issue can be used
            #>
            Method = "GET"
        }
        Write-DebugMessage "Invoking JiraMethod with `$parameter"
        $result = Invoke-JiraMethod -RequestContext $RequestContext @parameter

        Write-DebugMessage ($result | Out-String)

        if ($result) { Write-Output (ConvertTo-JiraEditMetaField -InputObject $result) }
        else {
            $exception = ([System.ArgumentException]"No results")
            $errorId = 'IssueMetadata.ObjectNotFound'
            $errorCategory = 'ObjectNotFound'
            $errorTarget = $Issue
            $errorItem = New-Object -TypeName System.Management.Automation.ErrorRecord $exception, $errorId, $errorCategory, $errorTarget
            $errorItem.ErrorDetails = "No edit metadata found for issue [$Issue]."
            $PSCmdlet.ThrowTerminatingError($errorItem)
        }
    }

    end {
        Write-Verbose "[$($MyInvocation.MyCommand.Name)] Complete"
    }
}
