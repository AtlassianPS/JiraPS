function Add-JiraIssueLink {
    # .ExternalHelp ..\JiraPS-help.xml
    [CmdletBinding( SupportsShouldProcess )]
    param(
        [Parameter( Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName )]
        [ValidateNotNull()]
        [AtlassianPS.JiraPS.IssueTransformation()]
        [Alias('Key')]
        [AtlassianPS.JiraPS.Issue]
        $Issue,

        [Parameter( Mandatory )]
        [ValidateNotNull()]
        [AtlassianPS.JiraPS.IssueLinkTransformation()]
        [AtlassianPS.JiraPS.IssueLink[]]
        $IssueLink,

        [String]
        $Comment,

        [Parameter()]
        [System.Management.Automation.PSCredential]
        [System.Management.Automation.Credential()]
        $Credential = [System.Management.Automation.PSCredential]::Empty
    )

    begin {
        Write-Verbose "[$($MyInvocation.MyCommand.Name)] Function started"

        $resourceURi = "/rest/api/2/issueLink"
    }

    process {
        Write-DebugMessage "[$($MyInvocation.MyCommand.Name)] ParameterSetName: $($PsCmdlet.ParameterSetName)"
        Write-DebugMessage "[$($MyInvocation.MyCommand.Name)] PSBoundParameters: $($PSBoundParameters | Out-String)"

        # Find the proper object for the Issue
        $issueObj = Resolve-JiraIssueObject -InputObject $Issue -Credential $Credential -ErrorAction Stop

        foreach ($typedIssueLink in $IssueLink) {
            if (-not $typedIssueLink.Type -or (-not $typedIssueLink.InwardIssue -and -not $typedIssueLink.OutwardIssue)) {
                $exception = ([System.ArgumentException]"Invalid Parameter")
                $errorId = 'ParameterProperties.Incomplete'
                $errorCategory = 'InvalidArgument'
                $errorTarget = $typedIssueLink
                $errorItem = New-Object -TypeName System.Management.Automation.ErrorRecord $exception, $errorId, $errorCategory, $errorTarget
                $errorItem.ErrorDetails = "The IssueLink provided does not contain the information needed."
                $PSCmdlet.ThrowTerminatingError($errorItem)
            }

            if ($typedIssueLink.InwardIssue) {
                $inwardIssue = @{ key = $typedIssueLink.InwardIssue.Key }
            }
            else {
                $inwardIssue = @{ key = $issueObj.key }
            }

            if ($typedIssueLink.OutwardIssue) {
                $outwardIssue = @{ key = $typedIssueLink.OutwardIssue.Key }
            }
            else {
                $outwardIssue = @{ key = $issueObj.key }
            }

            $body = @{
                type         = @{ name = $typedIssueLink.Type.Name }
                inwardIssue  = $inwardIssue
                outwardIssue = $outwardIssue
            }

            if ($Comment) {
                $body.comment = @{ body = $Comment }
            }

            $parameter = @{
                URI        = $resourceURi
                Method     = "POST"
                Body       = ConvertTo-Json -InputObject $body
                Credential = $Credential
            }
            Write-Debug "[$($MyInvocation.MyCommand.Name)] Invoking JiraMethod with `$parameter"
            if ($PSCmdlet.ShouldProcess($issueObj.Key)) {
                Invoke-JiraMethod @parameter
            }
        }
    }

    end {
        Write-Verbose "[$($MyInvocation.MyCommand.Name)] Complete"
    }
}
