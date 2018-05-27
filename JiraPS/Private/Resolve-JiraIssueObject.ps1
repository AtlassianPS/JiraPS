function Resolve-JiraIssueObject {
    <#
      #ToDo:CustomClass
      Once we have custom classes, this will no longer be necessary
    #>
    [CmdletBinding()]
    param(
        [Parameter( ValueFromPipeline )]
        [ValidateNotNullOrEmpty()]
        [ValidateScript(
            {
                if (("JiraPS.Issue" -notin $_.PSObject.TypeNames) -and (($_ -isnot [String]))) {
                    $errorItem = [System.Management.Automation.ErrorRecord]::new(
                        ([System.ArgumentException]"Invalid Type for Parameter"),
                        'ParameterType.NotJiraIssue',
                        [System.Management.Automation.ErrorCategory]::InvalidArgument,
                        $_
                    )
                    $errorItem.ErrorDetails = "Wrong object type provided for Issue. Expected [JiraPS.Issue] or [String], but was $($_.GetType().Name)"
                    $PSCmdlet.ThrowTerminatingError($errorItem)
                }
                else {
                    return $true
                }
            }
        )]
        [Object]
        $InputObject,

        # Authentication credentials
        [PSCredential]
        $Credential
    )

    # As we are not able to use proper type casting in the parameters, this is a workaround
    # to extract the data from a JiraPS.Issue object
    # This shall be removed once we have custom classes for the module
    if ("JiraPS.Issue" -in $InputObject.PSObject.TypeNames -and $InputObject.RestURL) {
        Write-DebugMessage "[$($MyInvocation.MyCommand.Name)] Using `$Issue as object"
        return $Issue
    }
    elseif ("JiraPS.Issue" -in $InputObject.PSObject.TypeNames -and $InputObject.Key) {
        Write-DebugMessage "[$($MyInvocation.MyCommand.Name)] Resolve Issue to object"
        return Get-JiraIssue -Key $InputObject.Key -Credential $Credential -ErrorAction Stop
    }
    else {
        Write-DebugMessage "[$($MyInvocation.MyCommand.Name)] Resolve Issue to object"
        return Get-JiraIssue -Key $InputObject.ToString() -Credential $Credential -ErrorAction Stop
    }
}
