function Set-JiraVersion {
    # .ExternalHelp ..\JiraPS-help.xml
    [CmdletBinding( SupportsShouldProcess )]
    param(
        [Parameter( Mandatory, ValueFromPipeline )]
        [ValidateNotNullOrEmpty()]
        [ValidateScript(
            {
                if (("JiraPS.Version" -notin $_.PSObject.TypeNames) -and (($_ -isnot [String]))) {
                    $exception = ([System.ArgumentException]"Invalid Type for Parameter") #fix code highlighting]
                    $errorId = 'ParameterType.NotJiraVersion'
                    $errorCategory = 'InvalidArgument'
                    $errorTarget = $_
                    $errorItem = New-Object -TypeName System.Management.Automation.ErrorRecord $exception, $errorId, $errorCategory, $errorTarget
                    $errorItem.ErrorDetails = "Wrong object type provided for Version. Expected [JiraPS.Version] or [String], but was $($_.GetType().Name)"
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
        $Version,

        [String]
        $Name,

        [String]
        $Description,

        [Bool]
        $Archived,

        [Bool]
        $Released,

        [DateTime]
        $ReleaseDate,

        [DateTime]
        $StartDate,

        [ValidateScript(
            {
                if (("JiraPS.Project" -notin $_.PSObject.TypeNames) -and (($_ -isnot [String]))) {
                    $exception = ([System.ArgumentException]"Invalid Type for Parameter") #fix code highlighting]
                    $errorId = 'ParameterType.NotJiraProject'
                    $errorCategory = 'InvalidArgument'
                    $errorTarget = $_
                    $errorItem = New-Object -TypeName System.Management.Automation.ErrorRecord $exception, $errorId, $errorCategory, $errorTarget
                    $errorItem.ErrorDetails = "Wrong object type provided for Project. Expected [JiraPS.Project] or [String], but was $($_.GetType().Name)"
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
        $Project,

        [Parameter()]
        [System.Management.Automation.PSCredential]
        [System.Management.Automation.Credential()]
        $Credential = [System.Management.Automation.PSCredential]::Empty
    )

    begin {
        Write-Verbose "[$($MyInvocation.MyCommand.Name)] Function started"
    }

    process {
        Write-DebugMessage "[$($MyInvocation.MyCommand.Name)] ParameterSetName: $($PsCmdlet.ParameterSetName)"
        Write-DebugMessage "[$($MyInvocation.MyCommand.Name)] PSBoundParameters: $($PSBoundParameters | Out-String)"

        foreach ($_version in $Version) {
            Write-Verbose "[$($MyInvocation.MyCommand.Name)] Processing [$_version]"
            Write-Debug "[$($MyInvocation.MyCommand.Name)] Processing `$_version [$_version]"

            $versionObj = Get-JiraVersion -Id $_version.Id -Credential $Credential -ErrorAction Stop

            $requestBody = @{}

            if ($PSCmdlet.MyInvocation.BoundParameters.ContainsKey("Name")) {
                $requestBody["name"] = $Name
            }
            if ($PSCmdlet.MyInvocation.BoundParameters.ContainsKey("Description")) {
                $requestBody["description"] = $Description
            }
            if ($PSCmdlet.MyInvocation.BoundParameters.ContainsKey("Archived")) {
                $requestBody["archived"] = $Archived
            }
            if ($PSCmdlet.MyInvocation.BoundParameters.ContainsKey("Released")) {
                $requestBody["released"] = $Released
            }
            if ($PSCmdlet.MyInvocation.BoundParameters.ContainsKey("Project")) {
                $projectObj = Get-JiraProject -Project $Project -Credential $Credential -ErrorAction Stop

                $requestBody["projectId"] = $projectObj.Id
            }
            if ($PSCmdlet.MyInvocation.BoundParameters.ContainsKey("ReleaseDate")) {
                $requestBody["releaseDate"] = $ReleaseDate.ToString('yyyy-MM-dd')
            }
            if ($PSCmdlet.MyInvocation.BoundParameters.ContainsKey("StartDate")) {
                $requestBody["startDate"] = $StartDate.ToString('yyyy-MM-dd')
            }

            $parameter = @{
                URI        = $versionObj.RestUrl
                Method     = "PUT"
                Body       = ConvertTo-Json -InputObject $requestBody
                Credential = $Credential
            }
            Write-Debug "[$($MyInvocation.MyCommand.Name)] Invoking JiraMethod with `$parameter"
            if ($PSCmdlet.ShouldProcess($Name, "Updating Version on JIRA")) {
                $result = Invoke-JiraMethod @parameter

                Write-Output (ConvertTo-JiraVersion -InputObject $result)
            }
        }
    }

    end {
        Write-Verbose "[$($MyInvocation.MyCommand.Name)] Complete"
    }
}
