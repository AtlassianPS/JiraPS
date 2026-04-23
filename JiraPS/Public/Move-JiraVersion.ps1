function Move-JiraVersion {
    # .ExternalHelp ..\JiraPS-help.xml
    [CmdletBinding( DefaultParameterSetName = 'ByAfter' )]
    param(
        [Parameter( Mandatory, ValueFromPipeline )]
        [ValidateNotNullOrEmpty()]
        [ValidateScript(
            {
                if (("AtlassianPS.JiraPS.Version" -notin $_.PSObject.TypeNames) -and (($_ -isnot [Int]))) {
                    $exception = ([System.ArgumentException]"Invalid Type for Parameter") #fix code highlighting]
                    $errorId = 'ParameterType.NotJiraVersion'
                    $errorCategory = 'InvalidArgument'
                    $errorTarget = $_
                    $errorItem = New-Object -TypeName System.Management.Automation.ErrorRecord $exception, $errorId, $errorCategory, $errorTarget
                    $errorItem.ErrorDetails = "Wrong object type provided for Version. Expected [AtlassianPS.JiraPS.Version] or [Int], but was $($_.GetType().Name)"
                    $PSCmdlet.ThrowTerminatingError($errorItem)
                    <#
                      #ToDo:CustomClass
                      Now that we have custom classes, this polymorphic ValidateScript could be split into a parameter set with [AtlassianPS.JiraPS.<Type>] strong typing
                    #>
                }
                else {
                    return $true
                }
            }
        )]
        [Object]
        $Version,

        [Parameter( Mandatory, ParameterSetName = 'ByPosition' )]
        [ValidateSet('First', 'Last', 'Earlier', 'Later')]
        [String]$Position,

        [Parameter( Mandatory, ParameterSetName = 'ByAfter' )]
        [ValidateNotNullOrEmpty()]
        [ValidateScript(
            {
                if (("AtlassianPS.JiraPS.Version" -notin $_.PSObject.TypeNames) -and (($_ -isnot [Int]))) {
                    $exception = ([System.ArgumentException]"Invalid Type for Parameter") #fix code highlighting]
                    $errorId = 'ParameterType.NotJiraVersion'
                    $errorCategory = 'InvalidArgument'
                    $errorTarget = $_
                    $errorItem = New-Object -TypeName System.Management.Automation.ErrorRecord $exception, $errorId, $errorCategory, $errorTarget
                    $errorItem.ErrorDetails = "Wrong object type provided for Version. Expected [AtlassianPS.JiraPS.Version] or [Int], but was $($_.GetType().Name)"
                    $PSCmdlet.ThrowTerminatingError($errorItem)
                    <#
                      #ToDo:CustomClass
                      Now that we have custom classes, this polymorphic ValidateScript could be split into a parameter set with [AtlassianPS.JiraPS.<Type>] strong typing
                    #>
                }
                else {
                    return $true
                }
            }
        )]
        [Object]
        $After,

        [Parameter()]
        [System.Management.Automation.PSCredential]
        [System.Management.Automation.Credential()]
        $Credential = [System.Management.Automation.PSCredential]::Empty
    )

    begin {
        Write-Verbose "[$($MyInvocation.MyCommand.Name)] Function started"

        $versionResourceUri = "/rest/api/2/version/{0}/move"
    }

    process {
        Write-DebugMessage "[$($MyInvocation.MyCommand.Name)] ParameterSetName: $($PsCmdlet.ParameterSetName)"
        Write-DebugMessage "[$($MyInvocation.MyCommand.Name)] PSBoundParameters: $($PSBoundParameters | Out-String)"

        $requestBody = @{ }
        switch ($PsCmdlet.ParameterSetName) {
            'ByPosition' {
                $requestBody["position"] = $Position
            }
            'ByAfter' {
                $afterSelfUri = ''
                if ($After -is [Int]) {
                    $versionObj = Get-JiraVersion -Id $After -Credential $Credential -ErrorAction Stop
                    $afterSelfUri = $versionObj.RestUrl
                }
                else {
                    $afterSelfUri = $After.RestUrl
                }

                $requestBody["after"] = $afterSelfUri
            }
        }

        if ($Version.Id) {
            $versionId = $Version.Id
        }
        else {
            $versionId = $Version
        }

        $parameter = @{
            URI        = $versionResourceUri -f $versionId
            Method     = "POST"
            Body       = ConvertTo-Json $requestBody
            Credential = $Credential
        }

        Write-Debug "[$($MyInvocation.MyCommand.Name)] Invoking JiraMethod with `$parameter"
        Invoke-JiraMethod @parameter
    }

    end {
        Write-Verbose "[$($MyInvocation.MyCommand.Name)] Complete"
    }
}
