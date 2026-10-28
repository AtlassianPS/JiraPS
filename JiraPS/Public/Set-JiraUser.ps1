function Set-JiraUser {
    # .ExternalHelp ..\JiraPS-help.xml
    [CmdletBinding( SupportsShouldProcess, DefaultParameterSetName = 'ByNamedParameters' )]
    param(
        [Parameter( Position = 0, Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName )]
        [ValidateNotNull()]
        [AtlassianPS.JiraPS.UserTransformation()]
        [Alias('UserName')]
        [AtlassianPS.JiraPS.User]
        $User,

        [Parameter( ParameterSetName = 'ByNamedParameters' )]
        [ValidateNotNullOrEmpty()]
        [String]
        $DisplayName,

        [Parameter( ParameterSetName = 'ByNamedParameters' )]
        [ValidateNotNullOrEmpty()]
        [ValidateScript(
            {
                if ($_ -match '^[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,}$') { return $true }
                else {
                    $exception = ([System.ArgumentException]"Invalid Argument") #fix code highlighting]
                    $errorId = 'ParameterValue.NotEmail'
                    $errorCategory = 'InvalidArgument'
                    $errorTarget = $Issue
                    $errorItem = New-Object -TypeName System.Management.Automation.ErrorRecord $exception, $errorId, $errorCategory, $errorTarget
                    $errorItem.ErrorDetails = "The value provided does not look like an email address."
                    $PSCmdlet.ThrowTerminatingError($errorItem)
                    return $false
                }
            }
        )]
        [String]
        $EmailAddress,

        [Parameter( ParameterSetName = 'ByNamedParameters' )]
        [Boolean]
        $Active,

        [Parameter( Position = 1, Mandatory, ParameterSetName = 'ByHashtable' )]
        [Hashtable]
        $Property,

        [Parameter()]
        [Switch]
        $PassThru,

        [AtlassianPS.Connection]$Connection
    )

    begin {
        Write-Verbose "[$($MyInvocation.MyCommand.Name)] Function started"

        $RequestContext = Resolve-JiraOperationContext -BoundParameters $PSBoundParameters

        $isCloud = Test-JiraCloudServer -RequestContext $RequestContext

        if ($isCloud) { throw 'Jira Cloud does not support updating user account fields through this API. Manage the user through Atlassian account administration.' }
        $resourceURi = "/rest/api/2/user?username={0}"
    }

    process {
        Write-DebugMessage "ParameterSetName: $($PsCmdlet.ParameterSetName)"
        Write-DebugMessage -BoundParameters $PSBoundParameters

        $userObj = Resolve-JiraUser -InputObject $User -RequestContext $RequestContext -ErrorAction Stop

        $requestBody = @{}

        switch ($PSCmdlet.ParameterSetName) {
            'ByNamedParameters' {
                if (-not ($DisplayName -or $EmailAddress -or $PSBoundParameters.ContainsKey('Active'))) {
                    $errorMessage = @{
                        Category         = "InvalidArgument"
                        CategoryActivity = "Validating Arguments"
                        Message          = "The parameters provided do not change the User. No action will be performed"
                    }
                    Write-Error @errorMessage
                    return
                }

                if ($DisplayName) { $requestBody.displayName = $DisplayName }

                if ($EmailAddress) { $requestBody.emailAddress = $EmailAddress }

                if ($PSBoundParameters.ContainsKey('Active')) { $requestBody.active = $Active }
            }
            'ByHashtable' { $requestBody = $Property }
        }

        $userIdentifier = $userObj.Name
        if (-not $userIdentifier) { throw 'User requires a Data Center username.' }
        $parameter = @{
            URI    = $resourceURi -f [Uri]::EscapeDataString($userIdentifier)
            Method = "PUT"
            Body   = ConvertTo-Json -InputObject $requestBody -Depth 4
        }
        Write-DebugMessage "Invoking JiraMethod with `$parameter"
        if ($PSCmdlet.ShouldProcess($UserObj.DisplayName, "Updating user")) {
            $result = Invoke-JiraRequest -RequestContext $RequestContext @parameter

            if ($PassThru) {
                if ($userObj.AccountId -or $userObj.Name) {
                    $refreshUser = [AtlassianPS.JiraPS.User]@{
                        AccountId = $userObj.AccountId
                        Name      = $userObj.Name
                    }
                    Write-Output (Resolve-JiraUser -InputObject $refreshUser -RequestContext $RequestContext -ErrorAction Stop)
                }
                else { Write-Output (ConvertTo-JiraUser -InputObject $result) }
            }
        }
    }

    end {
        Write-Verbose "[$($MyInvocation.MyCommand.Name)] Complete"
    }
}
