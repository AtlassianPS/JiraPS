function Resolve-JiraUser {
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
                if (("JiraPS.User" -notin $_.PSObject.TypeNames) -and (($_ -isnot [String]))) {
                    $exception = ([System.ArgumentException]"Invalid Type for Parameter") #fix code highlighting]
                    $errorId = 'ParameterType.NotJiraUser'
                    $errorCategory = 'InvalidArgument'
                    $errorTarget = $_
                    $errorItem = New-Object -TypeName System.Management.Automation.ErrorRecord $exception, $errorId, $errorCategory, $errorTarget
                    $errorItem.ErrorDetails = "Wrong object type provided for User. Expected [JiraPS.User] or [String], but was $($_.GetType().Name)"
                    $PSCmdlet.ThrowTerminatingError($errorItem)
                }
                else {
                    return $true
                }
            }
        )]
        [Object]
        $InputObject,

        [Switch]
        $Exact,

        # Authentication credentials
        [Parameter()]
        [System.Management.Automation.PSCredential]
        [System.Management.Automation.Credential()]
        $Credential = [System.Management.Automation.PSCredential]::Empty
    )

    process {
        # As we are not able to use proper type casting in the parameters, this is a workaround
        # to extract the data from a JiraPS.Issue object
        # This shall be removed once we have custom classes for the module
        if ("JiraPS.User" -in $InputObject.PSObject.TypeNames) {
            Write-DebugMessage "[$($MyInvocation.MyCommand.Name)] Using `$InputObject as object"
            return $InputObject
        }
        else {
            Write-DebugMessage "[$($MyInvocation.MyCommand.Name)] Resolve User to object"
            return (Get-JiraUser -UserName $InputObject -Exact:$Exact -Credential $Credential -ErrorAction Stop)
        }
    }
}
