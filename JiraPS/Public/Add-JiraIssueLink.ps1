function Add-JiraIssueLink {
# .ExternalHelp ..\JiraPS-help.xml
    [CmdletBinding( SupportsShouldProcess )]
    param(
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
        [Object[]]
        $Issue,

        [Parameter( Mandatory )]
        [ValidateScript(
            {
                $objectProperties = Get-Member -InputObject $_ -MemberType *Property
                if (-not(
                        ($objectProperties.Name -contains "type") -and
                        (($objectProperties.Name -contains "outwardIssue") -or ($objectProperties.Name -contains "inwardIssue"))
                    )) {
                    $exception = ([System.ArgumentException]"Invalid Parameter") #fix code highlighting]
                    $errorId = 'ParameterProperties.Incomplete'
                    $errorCategory = 'InvalidArgument'
                    $errorTarget = $_
                    $errorItem = New-Object -TypeName System.Management.Automation.ErrorRecord $exception, $errorId, $errorCategory, $errorTarget
                    $errorItem.ErrorDetails = "The IssueLink provided does not contain the information needed."
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

        $server = Get-JiraConfigServer -ErrorAction Stop

        $resourceURi = "$server/rest/api/3/issueLink"
    }

    process {
        Write-DebugMessage "[$($MyInvocation.MyCommand.Name)] ParameterSetName: $($PsCmdlet.ParameterSetName)"
        Write-DebugMessage "[$($MyInvocation.MyCommand.Name)] PSBoundParameters: $($PSBoundParameters | Out-String)"

        foreach ($_issue in $Issue) {
            # Find the proper object for the Issue
            $issueObj = Resolve-JiraIssueObject -InputObject $_issue -Credential $Credential

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
                    # API v3 requires comment body in Atlassian Document Format (ADF)
                    $body.comment = @{ body = ConvertTo-AtlassianDocumentFormat -PlainText $Comment }
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
    }

    end {
        Write-Verbose "[$($MyInvocation.MyCommand.Name)] Complete"
    }
}
