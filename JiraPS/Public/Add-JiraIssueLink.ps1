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
        [ValidateScript({
                $propertyNames = $_.PSObject.Properties.Name
                if (
                    ($propertyNames -contains "type") -and
                    (
                        ($propertyNames -contains "outwardIssue") -or
                        ($propertyNames -contains "inwardIssue")
                    )
                ) {
                    return $true
                }
                else {
                    $exception = ([System.ArgumentException]"Invalid Parameter")
                    $errorId = 'ParameterProperties.Incomplete'
                    $errorCategory = 'InvalidArgument'
                    $errorTarget = $_
                    $errorItem = New-Object -TypeName System.Management.Automation.ErrorRecord $exception, $errorId, $errorCategory, $errorTarget
                    $errorItem.ErrorDetails = "The IssueLink provided does not contain the information needed."
                    $PSCmdlet.ThrowTerminatingError($errorItem)
                    <#
                      #ToDo:CustomClass
                      Now that we have custom classes, this polymorphic ValidateScript could be split into a parameter set with [AtlassianPS.JiraPS.<Type>] strong typing
                    #>
                }
            })]
        [Object[]]
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

        foreach ($_issueLink in $IssueLink) {
            if ($_issueLink.inwardIssue) {
                $inwardIssue = @{ key = $_issueLink.inwardIssue.key }
            }
            else {
                $inwardIssue = @{ key = $issueObj.key }
            }

            if ($_issueLink.outwardIssue) {
                $outwardIssue = @{ key = $_issueLink.outwardIssue.key }
            }
            else {
                $outwardIssue = @{ key = $issueObj.key }
            }

            $body = @{
                type         = @{ name = $_issueLink.type.name }
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
