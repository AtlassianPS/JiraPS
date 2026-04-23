function Resolve-JiraUser {
    <#
      #ToDo:CustomClass
      Now that we have custom classes, this Resolve-* shim could be replaced by a parameter set that takes [AtlassianPS.JiraPS.<Type>] directly
    #>
    [CmdletBinding()]
    param(
        [Parameter( ValueFromPipeline )]
        [ValidateNotNullOrEmpty()]
        [ValidateScript(
            {
                if (("AtlassianPS.JiraPS.User" -notin $_.PSObject.TypeNames) -and (($_ -isnot [String]))) {
                    $exception = ([System.ArgumentException]"Invalid Type for Parameter") #fix code highlighting]
                    $errorId = 'ParameterType.NotJiraUser'
                    $errorCategory = 'InvalidArgument'
                    $errorTarget = $_
                    $errorItem = New-Object -TypeName System.Management.Automation.ErrorRecord $exception, $errorId, $errorCategory, $errorTarget
                    $errorItem.ErrorDetails = "Wrong object type provided for User. Expected [AtlassianPS.JiraPS.User] or [String], but was $($_.GetType().Name)"
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

    begin {
        $isCloud = Test-JiraCloudServer -Credential $Credential
    }

    process {
        # As we are not able to use proper type casting in the parameters, this is a workaround
        # to extract the data from a AtlassianPS.JiraPS.Issue object
        # This shall be removed once we have custom classes for the module
        if ("AtlassianPS.JiraPS.User" -in $InputObject.PSObject.TypeNames) {
            Write-DebugMessage "[$($MyInvocation.MyCommand.Name)] Using `$InputObject as object"
            return $InputObject
        }
        else {
            Write-DebugMessage "[$($MyInvocation.MyCommand.Name)] Resolve User to object"

            if (($isCloud) -and ($InputObject -match '^[0-9a-f]{24}$')) {
                return (Get-JiraUser -AccountId $InputObject -Exact:$Exact -Credential $Credential -ErrorAction Stop)
            }
            else {
                return (Get-JiraUser -UserName $InputObject -Exact:$Exact -Credential $Credential -ErrorAction Stop)
            }
        }
    }
}
