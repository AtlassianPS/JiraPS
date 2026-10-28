function Add-JiraIssueComment {
    # .ExternalHelp ..\JiraPS-help.xml
    [CmdletBinding( SupportsShouldProcess )]
    param(
        [Parameter( Mandatory )]
        [ValidateNotNullOrEmpty()]
        [String]
        $Comment,

        [Parameter( Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName )]
        [ValidateNotNull()]
        [AtlassianPS.JiraPS.IssueTransformation()]
        [Alias('Key')]
        [AtlassianPS.JiraPS.Issue]
        $Issue,

        [Alias('VisibleRole')]
        [AtlassianPS.JiraPS.VisibilityTransformation()]
        [ValidateScript({
                if ($null -eq $_.Type -and $null -eq $_.Value -and $null -eq $_.Identifier) { return $true }
                if ($_.Type -notin 'role', 'group') { throw "Visibility.Type must be 'role' or 'group'." }
                if ([String]::IsNullOrWhiteSpace($_.Value) -and [String]::IsNullOrWhiteSpace($_.Identifier)) {
                    throw 'Visibility requires a non-empty Value or Identifier.'
                }
                return $true
            }
        )]
        [AtlassianPS.JiraPS.Visibility]
        $Visibility,

        [Parameter()]
        [AtlassianPS.Connection]
        $Connection
    )

    begin {
        Write-Verbose "[$($MyInvocation.MyCommand.Name)] Function started"

        $RequestContext = Resolve-JiraOperationContext -BoundParameters $PSBoundParameters

        $resourceURi = "{0}/comment"
    }

    process {
        Write-DebugMessage "ParameterSetName: $($PsCmdlet.ParameterSetName)"
        Write-DebugMessage -BoundParameters $PSBoundParameters

        # Find the proper object for the Issue
        $issueObj = Resolve-JiraIssueObject -InputObject $Issue -RequestContext $RequestContext

        $isCloud = Test-JiraCloudServer -RequestContext $RequestContext

        $requestBody = @{
            'body' = Resolve-JiraTextFieldPayload -Text $Comment -IsCloud $isCloud
        }

        # Unrestricted access omits visibility; older Jira versions reject an "All Users" role.
        if ($Visibility -and $Visibility.Type -and -not (
                $Visibility.Type -eq 'role' -and $Visibility.Value -eq 'All Users' -and -not $Visibility.Identifier
            )
        ) {
            $requestBody.visibility = @{ type = $Visibility.Type }
            if ($Visibility.Value) { $requestBody.visibility.value = $Visibility.Value }
            if ($Visibility.Identifier) { $requestBody.visibility.identifier = $Visibility.Identifier }
        }

        $issueRestUrl = ConvertTo-JiraRestApiV3Url -Url $issueObj.RestUrl -IsCloud $isCloud

        $parameter = @{
            URI    = $resourceURi -f $issueRestUrl
            Method = "POST"
            Body   = ConvertTo-Json -InputObject $requestBody -Depth 20
        }
        Write-DebugMessage "Invoking JiraMethod with `$parameter"
        if ($PSCmdlet.ShouldProcess($issueObj.Key)) {
            $rawResult = Invoke-JiraRequest -RequestContext $RequestContext @parameter

            Write-Output (ConvertTo-JiraComment -InputObject $rawResult)
        }
    }

    end {
        Write-Verbose "[$($MyInvocation.MyCommand.Name)] Complete"
    }
}
