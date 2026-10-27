function Add-JiraIssueWorklog {
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

        [Parameter( Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName )]
        [TimeSpan]
        $TimeSpent,

        [Parameter( Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName )]
        [DateTime]
        $DateStarted,

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
        [System.Management.Automation.PSCredential]
        [System.Management.Automation.Credential()]
        $Credential,

        [Alias('Session')]
        [AtlassianPS.Connection]
        $Connection
    )

    begin {
        try {
            Write-Verbose "[$($MyInvocation.MyCommand.Name)] Function started"

            $RequestContext = Resolve-JiraOperationContext -BoundParameters $PSBoundParameters

            $resourceURi = "{0}/worklog"
        }
        catch {
            if ($RequestContext -and $RequestContext.State -eq 'Standalone') { $RequestContext.Dispose() }
            throw
        }
    }

    process {
        try {
            Write-DebugMessage "[$($MyInvocation.MyCommand.Name)] ParameterSetName: $($PsCmdlet.ParameterSetName)"

            # Find the proper object for the Issue
            $issueObj = Resolve-JiraIssueObject -InputObject $Issue -RequestContext $RequestContext

            if (-not $issueObj) {
                $errorMessage = @{
                    Category         = "ObjectNotFound"
                    CategoryActivity = "Searching for Issue"
                    Message          = "Invalid Issue provided."
                }
                Write-Error @errorMessage
            }

            # Harmonize DateStarted:
            # `Get-Date -Date "01.01.2000"` does not return the local timezone
            # which is required by the API
            $DateStarted = [DateTime]::new($DateStarted.Ticks, 'Local')

            $isCloud = Test-JiraCloudServer -RequestContext $RequestContext

            $requestBody = @{
                'comment'          = Resolve-JiraTextFieldPayload -Text $Comment -IsCloud $isCloud
                # We need to fix the date with a RegEx replace because the API does not like:
                # * miliseconds with more than 3 digits
                # * `:` in the TimeZone
                'started'          = $DateStarted.ToString("o") -replace "\.(\d{3})\d*([\+\-]\d{2}):", ".`$1`$2"
                'timeSpentSeconds' = $TimeSpent.TotalSeconds.ToString()
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
            Write-Debug "[$($MyInvocation.MyCommand.Name)] Invoking JiraMethod with `$parameter"
            if ($PSCmdlet.ShouldProcess($issueObj.Key)) {
                $result = Invoke-JiraMethod -RequestContext $RequestContext @parameter

                Write-Output (ConvertTo-JiraWorklogitem -InputObject $result)
            }
        }
        catch {
            if ($RequestContext -and $RequestContext.State -eq 'Standalone') { $RequestContext.Dispose() }
            throw
        }
    }

    end {
        try {
            Write-Verbose "[$($MyInvocation.MyCommand.Name)] Complete"
        }
        finally {
            if ($RequestContext.State -eq 'Standalone') { $RequestContext.Dispose() }
        }
    }
}
