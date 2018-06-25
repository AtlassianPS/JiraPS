function New-JiraVersion {
    # .ExternalHelp ..\JiraPS-help.xml
    [CmdletBinding( SupportsShouldProcess, DefaultParameterSetName = 'byObject' )]
    param(
        [Parameter( Position = 0, Mandatory, ValueFromPipeline, ParameterSetName = 'byObject' )]
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
        [Object]
        $InputObject,

        [Parameter( Position = 0, Mandatory, ParameterSetName = 'byParameters' )]
        [String]
        $Name,

        [Parameter( Position = 1, Mandatory, ParameterSetName = 'byParameters' )]
        [ValidateNotNullOrEmpty()]
        [ValidateScript(
            {
                $Input = $_

                switch ($true) {
                    {"JiraPS.Project" -in $Input.PSObject.TypeNames} { return $true }
                    {$Input -is [String]} { return $true}
                    Default {
                        $exception = ([System.ArgumentException]"Invalid Type for Parameter") #fix code highlighting]
                        $errorId = 'ParameterType.NotJiraProject'
                        $errorCategory = 'InvalidArgument'
                        $errorTarget = $Input
                        $errorItem = New-Object -TypeName System.Management.Automation.ErrorRecord $exception, $errorId, $errorCategory, $errorTarget
                        $errorItem.ErrorDetails = "Wrong object type provided for Project. Expected [JiraPS.Project] or [String], but was $($Input.GetType().Name)"
                        $PSCmdlet.ThrowTerminatingError($errorItem)
                        <#
                          #ToDo:CustomClass
                          Once we have custom classes, this check can be done with Type declaration
                        #>
                    }
                }
            }
        )]
        [Object]
        $Project,

        [Parameter( ParameterSetName = 'byParameters' )]
        [String]
        $Description,

        [Parameter( ParameterSetName = 'byParameters' )]
        [Bool]
        $Archived,

        [Parameter( ParameterSetName = 'byParameters' )]
        [Bool]
        $Released,

        [Parameter( ParameterSetName = 'byParameters' )]
        [DateTime]
        $ReleaseDate,

        [Parameter( ParameterSetName = 'byParameters' )]
        [DateTime]
        $StartDate,

        [Parameter()]
        [System.Management.Automation.PSCredential]
        [System.Management.Automation.Credential()]
        $Credential = [System.Management.Automation.PSCredential]::Empty
    )

    begin {
        Write-Verbose "[$($MyInvocation.MyCommand.Name)] Function started"

        $server = Get-JiraConfigServer -ErrorAction Stop

        $resourceURi = "$server/rest/api/latest/version"
    }

    process {
        Write-DebugMessage "[$($MyInvocation.MyCommand.Name)] ParameterSetName: $($PsCmdlet.ParameterSetName)"
        Write-DebugMessage "[$($MyInvocation.MyCommand.Name)] PSBoundParameters: $($PSBoundParameters | Out-String)"

        $requestBody = @{}
        Switch ($PSCmdlet.ParameterSetName) {
            'byObject' {
                $requestBody["name"] = $InputObject.Name
                $requestBody["description"] = $InputObject.Description
                $requestBody["archived"] = [bool]($InputObject.Archived)
                $requestBody["released"] = [bool]($InputObject.Released)
                $requestBody["releaseDate"] = $InputObject.ReleaseDate.ToString('yyyy-MM-dd')
                $requestBody["startDate"] = $InputObject.StartDate.ToString('yyyy-MM-dd')
                if ($InputObject.Project.Key) {
                    $requestBody["project"] = $InputObject.Project.Key
                }
                elseif ($InputObject.Project.Id) {
                    $requestBody["projectId"] = $InputObject.Project.Id
                }
            }
            'byParameters' {
                $requestBody["name"] = $Name
                if ($PSCmdlet.MyInvocation.BoundParameters.ContainsKey("Description")) {
                    $requestBody["description"] = $Description
                }
                if ($PSCmdlet.MyInvocation.BoundParameters.ContainsKey("Archived")) {
                    $requestBody["archived"] = $Archived
                }
                if ($PSCmdlet.MyInvocation.BoundParameters.ContainsKey("Released")) {
                    $requestBody["released"] = $Released
                }
                if ($PSCmdlet.MyInvocation.BoundParameters.ContainsKey("ReleaseDate")) {
                    $requestBody["releaseDate"] = Get-Date $ReleaseDate -Format 'yyyy-MM-dd'
                }
                if ($PSCmdlet.MyInvocation.BoundParameters.ContainsKey("StartDate")) {
                    $requestBody["startDate"] = Get-Date $StartDate -Format 'yyyy-MM-dd'
                }

                if ("JiraPS.Project" -in $Project.PSObject.TypeNames) {
                    if ($Project.Id) {
                        $requestBody["projectId"] = $Project.Id
                    }
                    elseif ($Project.Key) {
                        $requestBody["project"] = $Project.Key
                    }
                }
                else {
                    $requestBody["projectId"] = (Get-JiraProject $Project -Credential $Credential).Id
                }
            }
        }

        $parameter = @{
            URI        = $resourceURi
            Method     = "POST"
            Body       = ConvertTo-Json -InputObject $requestBody
            Credential = $Credential
        }
        Write-Debug "[$($MyInvocation.MyCommand.Name)] Invoking JiraMethod with `$parameter"
        if ($PSCmdlet.ShouldProcess($Name, "Creating new Version on JIRA")) {
            $result = Invoke-JiraMethod @parameter

            Write-Output (ConvertTo-JiraVersion -InputObject $result)
        }
    }

    end {
        Write-Verbose "[$($MyInvocation.MyCommand.Name)] Complete"
    }
}
