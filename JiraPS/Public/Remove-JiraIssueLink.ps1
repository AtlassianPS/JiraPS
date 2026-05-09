function Remove-JiraIssueLink {
    # .ExternalHelp ..\JiraPS-help.xml
    [CmdletBinding( SupportsShouldProcess, ConfirmImpact = 'Medium' )]
    param(
        [Parameter( Mandatory, ValueFromPipeline )]
        [ValidateNotNullOrEmpty()]
        [ValidateScript(
            {
                $_input = $_
                switch ($true) {
                    { $_input -is [AtlassianPS.JiraPS.Issue] } { return $true }
                    { $_input -is [AtlassianPS.JiraPS.IssueLink] } { return $true }
                    default {
                        $exception = ([System.ArgumentException]"Invalid Type for Parameter") #fix code highlighting]
                        $errorId = 'ParameterType.NotJiraIssue'
                        $errorCategory = 'InvalidArgument'
                        $errorTarget = $_input
                        $errorItem = New-Object -TypeName System.Management.Automation.ErrorRecord $exception, $errorId, $errorCategory, $errorTarget
                        $errorItem.ErrorDetails = "Wrong object type provided for Issue. Expected [AtlassianPS.JiraPS.Issue] or [AtlassianPS.JiraPS.IssueLink], but was $($_input.GetType().Name)"
                        $PSCmdlet.ThrowTerminatingError($errorItem)
                        <#
                          #ToDo:CustomClass
                          Now that we have custom classes, this polymorphic ValidateScript could be split into a parameter set with [AtlassianPS.JiraPS.<Type>] strong typing
                        #>
                    }
                }
            }
        )]
        [Object[]]
        $IssueLink,

        [Parameter()]
        [System.Management.Automation.PSCredential]
        [System.Management.Automation.Credential()]
        $Credential = [System.Management.Automation.PSCredential]::Empty
    )

    begin {
        Write-Verbose "[$($MyInvocation.MyCommand.Name)] Function started"

        $resourceURi = "/rest/api/2/issueLink/{0}"
    }

    process {
        Write-DebugMessage "[$($MyInvocation.MyCommand.Name)] ParameterSetName: $($PsCmdlet.ParameterSetName)"
        Write-DebugMessage "[$($MyInvocation.MyCommand.Name)] PSBoundParameters: $($PSBoundParameters | Out-String)"

        # As we are not able to use proper type casting in the parameters, this is a workaround
        # to extract the data from a AtlassianPS.JiraPS.Issue object
        <#
          #ToDo:CustomClass
          Now that we have custom classes, this Resolve-* shim could be replaced by a parameter set that takes [AtlassianPS.JiraPS.<Type>] directly
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
