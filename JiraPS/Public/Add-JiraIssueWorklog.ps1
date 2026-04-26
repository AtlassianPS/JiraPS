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

        [ValidateSet('All Users', 'Developers', 'Administrators')]
        [String]
        $VisibleRole = 'All Users',

        [Parameter()]
        [System.Management.Automation.PSCredential]
        [System.Management.Automation.Credential()]
        $Credential = [System.Management.Automation.PSCredential]::Empty
    )

    begin {
        Write-Verbose "[$($MyInvocation.MyCommand.Name)] Function started"

        $resourceURi = "{0}/worklog"
    }

    process {
        Write-DebugMessage "[$($MyInvocation.MyCommand.Name)] ParameterSetName: $($PsCmdlet.ParameterSetName)"
        Write-DebugMessage "[$($MyInvocation.MyCommand.Name)] PSBoundParameters: $($PSBoundParameters | Out-String)"

        # Find the proper object for the Issue
        $issueObj = Resolve-JiraIssueObject -InputObject $Issue -Credential $Credential

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

        $isCloud = Test-JiraCloudServer -Credential $Credential

        $requestBody = @{
            'comment'          = Resolve-JiraTextFieldPayload -Text $Comment -IsCloud $isCloud
            # We need to fix the date with a RegEx replace because the API does not like:
            # * miliseconds with more than 3 digits
            # * `:` in the TimeZone
            'started'          = $DateStarted.ToString("o") -replace "\.(\d{3})\d*([\+\-]\d{2}):", ".`$1`$2"
            'timeSpentSeconds' = $TimeSpent.TotalSeconds.ToString()
        }

        # If the visible role should be all users, the visibility block shouldn't be passed at
        # all. JIRA returns a 500 Internal Server Error if you try to pass this block with a
        # value of "All Users".
        if ($VisibleRole -ne 'All Users') {
            $requestBody.visibility = @{
                'type'  = 'role'
                'value' = $VisibleRole
            }
        }

        $issueRestUrl = ConvertTo-JiraRestApiV3Url -Url $issueObj.RestUrl -IsCloud $isCloud

        $parameter = @{
            URI        = $resourceURi -f $issueRestUrl
            Method     = "POST"
            Body       = ConvertTo-Json -InputObject $requestBody -Depth 20
            Credential = $Credential
        }
        Write-Debug "[$($MyInvocation.MyCommand.Name)] Invoking JiraMethod with `$parameter"
        if ($PSCmdlet.ShouldProcess($issueObj.Key)) {
            $result = Invoke-JiraMethod @parameter

            Write-Output (ConvertTo-JiraWorklogitem -InputObject $result)
        }
    }

    end {
        Write-Verbose "[$($MyInvocation.MyCommand.Name)] Complete"
    }
}
