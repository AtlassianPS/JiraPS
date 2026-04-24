function Add-JiraIssueComment {
    # .ExternalHelp ..\JiraPS-help.xml
    [CmdletBinding( SupportsShouldProcess )]
    param(
        [Parameter( Mandatory )]
        [ValidateNotNullOrEmpty()]
        [String]
        $Comment,

        [Parameter( Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName )]
        [ValidateNotNullOrEmpty()]
        [ValidateScript(
            {
                if (("JiraPS.Issue" -notin $_.PSObject.TypeNames) -and (($_ -isnot [String]))) {
                    $exception = ([System.ArgumentException]"Invalid Type for Parameter") #fix code highlighting]
                    $errorId = 'ParameterType.NotJiraIssue'
                    $errorCategory = 'InvalidArgument'
                    $errorTarget = $_
                    $errorItem = New-Object -TypeName System.Management.Automation.ErrorRecord $exception, $errorId, $errorCategory, $errorTarget
                    $errorItem.ErrorDetails = "Wrong object type provided for Issue. Expected [JiraPS.Issue] or [String], but was $($_.GetType().Name)"
                    $PSCmdlet.ThrowTerminatingError($errorItem)
                    <#
                      #ToDo:CustomClass
                      Once we have custom classes, this check can be done with Type declaration
                    #>
                }
                else {
                    return $true
                }
            }
        )]
        [Alias('Key')]
        [Object]
        $Issue,

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

        $resourceURi = "{0}/comment"

        # Jira wiki-markup table headers (`||header||`) render as literal text on
        # Jira Cloud REST v3 endpoints, which expect ADF. The comment text is bound
        # at parameter time (not pipeline-bound), so it's safe to inspect once in
        # `begin` and emit a single warning per invocation. Pattern requires a
        # non-whitespace first interior char to avoid false-positives such as
        # `a || b || c` (boolean operators in code blocks).
        if ($Comment -match '\|\|\S[^|]*\|\|') {
            try {
                if (Test-JiraCloudServer -Credential $Credential -ErrorAction Stop -WarningAction SilentlyContinue) {
                    Write-Warning "[$($MyInvocation.MyCommand.Name)] The supplied -Comment contains Jira wiki-markup table syntax ('||header||') and you are connected to a Jira Cloud deployment. Cloud REST v3 endpoints expect Atlassian Document Format (ADF) and will render this syntax as literal text. The comment will still post successfully (and will render correctly on Cloud's legacy v2 endpoints), but it will not appear as a table in the Cloud UI. Suppress this warning with -WarningAction SilentlyContinue."
                }
            }
            catch {
                Write-Debug "[$($MyInvocation.MyCommand.Name)] Could not determine deployment type ($($_.Exception.Message)); skipping Cloud-deployment warning."
            }
        }
    }

    process {
        Write-DebugMessage "[$($MyInvocation.MyCommand.Name)] ParameterSetName: $($PsCmdlet.ParameterSetName)"
        Write-DebugMessage "[$($MyInvocation.MyCommand.Name)] PSBoundParameters: $($PSBoundParameters | Out-String)"

        # Find the proper object for the Issue
        $issueObj = Resolve-JiraIssueObject -InputObject $Issue -Credential $Credential

        $requestBody = @{
            'body' = $Comment
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

        $parameter = @{
            URI        = $resourceURi -f $issueObj.RestURL
            Method     = "POST"
            Body       = ConvertTo-Json -InputObject $requestBody
            Credential = $Credential
        }
        Write-Debug "[$($MyInvocation.MyCommand.Name)] Invoking JiraMethod with `$parameter"
        if ($PSCmdlet.ShouldProcess($issueObj.Key)) {
            $rawResult = Invoke-JiraMethod @parameter

            Write-Output (ConvertTo-JiraComment -InputObject $rawResult)
        }
    }

    end {
        Write-Verbose "[$($MyInvocation.MyCommand.Name)] Complete"
    }
}
