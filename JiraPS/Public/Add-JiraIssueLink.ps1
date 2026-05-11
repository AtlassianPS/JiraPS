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
        [AtlassianPS.JiraPS.IssueLinkCreateRequestTransformation()]
        [AtlassianPS.JiraPS.IssueLinkCreateRequest[]]
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
                ThrowError `
                    -ExceptionType "System.ArgumentException" `
                    -Message "The IssueLink provided does not contain the information needed." `
                    -ErrorId 'ParameterProperties.Incomplete' `
                    -Category InvalidArgument `
                    -TargetObject $typedIssueLink `
                    -Cmdlet $PSCmdlet
            }

            if (-not $typedIssueLink.Type.Name -and -not $typedIssueLink.Type.Id) {
                ThrowError `
                    -ExceptionType "System.ArgumentException" `
                    -Message "The IssueLink type must include either a Name or an Id." `
                    -ErrorId 'ParameterProperties.Incomplete' `
                    -Category InvalidArgument `
                    -TargetObject $typedIssueLink `
                    -Cmdlet $PSCmdlet
            }

            if ($typedIssueLink.InwardIssue -and (-not $typedIssueLink.InwardIssue.Key -and -not $typedIssueLink.InwardIssue.Id)) {
                ThrowError `
                    -ExceptionType "System.ArgumentException" `
                    -Message "The inwardIssue reference must include either a Key or an Id." `
                    -ErrorId 'ParameterProperties.Incomplete' `
                    -Category InvalidArgument `
                    -TargetObject $typedIssueLink `
                    -Cmdlet $PSCmdlet
            }

            if ($typedIssueLink.OutwardIssue -and (-not $typedIssueLink.OutwardIssue.Key -and -not $typedIssueLink.OutwardIssue.Id)) {
                ThrowError `
                    -ExceptionType "System.ArgumentException" `
                    -Message "The outwardIssue reference must include either a Key or an Id." `
                    -ErrorId 'ParameterProperties.Incomplete' `
                    -Category InvalidArgument `
                    -TargetObject $typedIssueLink `
                    -Cmdlet $PSCmdlet
            }

            if ($typedIssueLink.InwardIssue) {
                if ($typedIssueLink.InwardIssue.Key) {
                    $inwardIssue = @{ key = $typedIssueLink.InwardIssue.Key }
                }
                else {
                    $inwardIssue = @{ id = $typedIssueLink.InwardIssue.Id }
                }
            }
            else {
                $inwardIssue = @{ key = $issueObj.key }
            }

            if ($typedIssueLink.OutwardIssue) {
                if ($typedIssueLink.OutwardIssue.Key) {
                    $outwardIssue = @{ key = $typedIssueLink.OutwardIssue.Key }
                }
                else {
                    $outwardIssue = @{ id = $typedIssueLink.OutwardIssue.Id }
                }
            }
            else {
                $outwardIssue = @{ key = $issueObj.key }
            }

            $typePayload = @{}
            if ($typedIssueLink.Type.Name) {
                $typePayload.name = $typedIssueLink.Type.Name
            }
            if ($typedIssueLink.Type.Id) {
                $typePayload.id = $typedIssueLink.Type.Id
            }

            $body = @{
                type         = $typePayload
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
