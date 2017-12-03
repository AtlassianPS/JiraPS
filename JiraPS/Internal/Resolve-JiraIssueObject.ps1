function Resolve-JiraIssueObject {
    <#
      #ToDo:CustomClass
      Once we have custom classes, this will no longer be necessary
    #>
    [CmdletBinding()]
    param(
        [Parameter( ValueFromPipeline )]
        [Object]
        $InputObject,

        # Authentication credentials
        [PSCredential]
        $Credential
    )

    # As we are not able to use proper type casting in the parameters, this is a workaround
    # to extract the data from a JiraPS.Issue object
    # This shall be removed once we have custom classes for the module
    if ($InputObject.PSObject.TypeNames[0] -eq "JiraPS.Issue" -and $InputObject.RestURL) {
        Write-DebugMessage "[$($MyInvocation.MyCommand.Name)] Using `$Issue as object"
        return $Issue
    }
    elseif ($InputObject.PSObject.TypeNames[0] -eq "JiraPS.Issue" -and $InputObject.Key) {
        Write-DebugMessage "[$($MyInvocation.MyCommand.Name)] Resolve Issue to object"
        return Get-JiraIssue -InputObject $InputObject.Key -Credential $Credential -ErrorAction Stop
    }
    else {
        Write-DebugMessage "[$($MyInvocation.MyCommand.Name)] Resolve Issue to object"
        return Get-JiraIssue -InputObject $InputObject -Credential $Credential -ErrorAction Stop
    }
}
