function Get-JiraIssueLinkType {
    # .ExternalHelp ..\JiraPS-help.xml
    [CmdletBinding(DefaultParameterSetName = '_All')]
    param(
        [Parameter( Position = 0, Mandatory, ParameterSetName = '_Search' )]
        [ValidateNotNullOrEmpty()]
        [ValidateScript(
            {
                if (("JiraPS.IssueLinkType" -notin $_.PSObject.TypeNames) -and (($_ -isnot [String])) -and (($_ -isnot [Int]))) {
                    $exception = ([System.ArgumentException]"Invalid Type for Parameter") #fix code highlighting]
                    $errorId = 'ParameterType.NotJiraIssueLinkType'
                    $errorCategory = 'InvalidArgument'
                    $errorTarget = $_
                    $errorItem = New-Object -TypeName System.Management.Automation.ErrorRecord $exception, $errorId, $errorCategory, $errorTarget
                    $errorItem.ErrorDetails = "Wrong object type provided for IssueLinkType. Expected [JiraPS.IssueLinkType], [String] or [Int], but was $($_.GetType().Name)"
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
        [Object]
        $LinkType,

        [Parameter()]
        [System.Management.Automation.PSCredential]
        [System.Management.Automation.Credential()]
        $Credential = [System.Management.Automation.PSCredential]::Empty
    )

    begin {
        Write-Verbose "[$($MyInvocation.MyCommand.Name)] Function started"

        $server = Get-JiraConfigServer -ErrorAction Stop

        $resourceURi = "$server/rest/api/2/issueLinkType{0}"
    }

    process {
        Write-DebugMessage "[$($MyInvocation.MyCommand.Name)] ParameterSetName: $($PsCmdlet.ParameterSetName)"
        Write-DebugMessage "[$($MyInvocation.MyCommand.Name)] PSBoundParameters: $($PSBoundParameters | Out-String)"

        if ($LinkType -is [Int]) {
            # If the link type provided is an int, we can assume it's an ID number.
            $parameter = @{
                URI        = $resourceURi -f "/$LinkType"
                Method     = "GET"
                Credential = $Credential
            }
            Write-Debug "[$($MyInvocation.MyCommand.Name)] Invoking JiraMethod with `$parameter"
            $result = Invoke-JiraMethod @parameter

            Write-Output (ConvertTo-JiraIssueLinkType -InputObject $result)
        } else {
            # If it's a String, it's probably a name, though, and there isn't an API call to look up a link type by name.
            $parameter = @{
                URI        = $resourceURi -f ""
                Method     = "GET"
                Credential = $Credential
            }
            Write-Debug "[$($MyInvocation.MyCommand.Name)] Invoking JiraMethod with `$parameter"
            $result = Invoke-JiraMethod @parameter
            $allLinkTypes = ConvertTo-JiraIssueLinkType -InputObject $result.issueLinkTypes

            if ($LinkType) {
                Write-Output ($allLinkTypes | Where-Object { $_.Name -like $LinkType })
            } else {
                Write-Output $allLinkTypes
            }
        }
    }

    end {
        Write-Verbose "[$($MyInvocation.MyCommand.Name)] Complete"
    }
}
