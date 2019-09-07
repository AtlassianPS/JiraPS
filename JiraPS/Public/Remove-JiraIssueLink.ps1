function Remove-JiraIssueLink {
    # .ExternalHelp ..\JiraPS-help.xml
    [CmdletBinding( SupportsShouldProcess, ConfirmImpact = 'Medium' )]
    param(
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
                        $exception = ([System.ArgumentException]"Invalid Type for Parameter") #fix code highlighting]
                        $errorId = 'ParameterType.NotJiraIssue'
                        $errorCategory = 'InvalidArgument'
                        $errorTarget = $Input
                        $errorItem = New-Object -TypeName System.Management.Automation.ErrorRecord $exception, $errorId, $errorCategory, $errorTarget
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

        [Parameter()]
        [System.Management.Automation.PSCredential]
        [System.Management.Automation.Credential()]
        $Credential = [System.Management.Automation.PSCredential]::Empty
    )

    begin {
        Write-Verbose "[$($MyInvocation.MyCommand.Name)] Function started"

        $resourceURi = "rest/api/latest/issueLink/{0}"
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
