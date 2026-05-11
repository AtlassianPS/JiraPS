function Add-JiraIssueLink {
    # .ExternalHelp ..\JiraPS-help.xml
    [CmdletBinding( SupportsShouldProcess )]
    param(
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

        foreach ($typedIssueLink in $IssueLink) {
            if (-not $typedIssueLink.Type -or -not $typedIssueLink.InwardIssue -or -not $typedIssueLink.OutwardIssue) {
                ThrowError `
                    -ExceptionType "System.ArgumentException" `
                    -Message "The IssueLink provided does not contain the information needed. Type, InwardIssue, and OutwardIssue are all required." `
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

            if (-not $typedIssueLink.InwardIssue.Key -and -not $typedIssueLink.InwardIssue.Id) {
                ThrowError `
                    -ExceptionType "System.ArgumentException" `
                    -Message "The inwardIssue reference must include either a Key or an Id." `
                    -ErrorId 'ParameterProperties.Incomplete' `
                    -Category InvalidArgument `
                    -TargetObject $typedIssueLink `
                    -Cmdlet $PSCmdlet
            }

            if (-not $typedIssueLink.OutwardIssue.Key -and -not $typedIssueLink.OutwardIssue.Id) {
                ThrowError `
                    -ExceptionType "System.ArgumentException" `
                    -Message "The outwardIssue reference must include either a Key or an Id." `
                    -ErrorId 'ParameterProperties.Incomplete' `
                    -Category InvalidArgument `
                    -TargetObject $typedIssueLink `
                    -Cmdlet $PSCmdlet
            }

            $inwardTarget = if ($typedIssueLink.InwardIssue.Key) { $typedIssueLink.InwardIssue.Key } else { $typedIssueLink.InwardIssue.Id }
            $inwardField = if ($typedIssueLink.InwardIssue.Key) { "key" } else { "id" }
            $inwardIssue = @{ $inwardField = $inwardTarget }

            $outwardTarget = if ($typedIssueLink.OutwardIssue.Key) { $typedIssueLink.OutwardIssue.Key } else { $typedIssueLink.OutwardIssue.Id }
            $outwardField = if ($typedIssueLink.OutwardIssue.Key) { "key" } else { "id" }
            $outwardIssue = @{ $outwardField = $outwardTarget }

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
            $typeTarget = if ($typedIssueLink.Type.Name) { $typedIssueLink.Type.Name } else { $typedIssueLink.Type.Id }
            $whatIfTarget = "$inwardTarget -[$typeTarget]-> $outwardTarget"
            if ($PSCmdlet.ShouldProcess($whatIfTarget)) {
                Invoke-JiraMethod @parameter
            }
        }
    }

    end {
        Write-Verbose "[$($MyInvocation.MyCommand.Name)] Complete"
    }
}
