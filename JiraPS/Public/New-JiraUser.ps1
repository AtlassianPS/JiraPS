function New-JiraUser {
    # .ExternalHelp ..\JiraPS-help.xml
    [CmdletBinding( SupportsShouldProcess )]
    param(
        [Parameter( Mandatory )]
        [String]
        $UserName,

        [Parameter( Mandatory )]
        [Alias('Email')]
        [String]
        $EmailAddress,

        [String]
        $DisplayName,

        [Boolean]
        $Notify = $true,

        [Parameter()]
        [System.Management.Automation.PSCredential]
        [System.Management.Automation.Credential()]
        $Credential,

        [Alias('Session')]
        [AtlassianPS.Connection]
        $Connection
    )

    begin {
        Write-Verbose "[$($MyInvocation.MyCommand.Name)] Function started"

        try {
            $RequestContext = Resolve-JiraOperationContext -BoundParameters $PSBoundParameters -UserEmailField

            $resourceURi = "/rest/api/2/user"
        }
        catch {
            if ($RequestContext -and $RequestContext.State -eq 'Standalone') { $RequestContext.Dispose() }
            throw
        }
    }

    process {
        try {
            Write-DebugMessage "ParameterSetName: $($PsCmdlet.ParameterSetName)"
            Write-DebugMessage -BoundParameters $PSBoundParameters

            $requestBody = @{
                "name"         = $UserName
                "emailAddress" = $EmailAddress
                "notification" = $Notify
            }

            if ($DisplayName) { $requestBody.displayName = $DisplayName }
            else {
                Write-DebugMessage "[New-JiraUser] DisplayName was not specified; defaulting to UserName parameter [$UserName]"
                $requestBody.displayName = $UserName
            }

            $parameter = @{
                URI    = $resourceURi
                Method = "POST"
                Body   = ConvertTo-Json -InputObject $requestBody
            }
            Write-DebugMessage "Invoking JiraMethod with `$parameter"
            if ($PSCmdlet.ShouldProcess($UserName, "Creating new User on JIRA")) {
                $result = Invoke-JiraMethod -RequestContext $RequestContext @parameter

                Write-Output (ConvertTo-JiraUser -InputObject $result)
            }
        }
        catch {
            if ($RequestContext -and $RequestContext.State -eq 'Standalone') { $RequestContext.Dispose() }
            throw
        }
    }

    end {
        try {
            Write-Verbose "[$($MyInvocation.MyCommand.Name)] Complete"
        }
        finally {
            if ($RequestContext.State -eq 'Standalone') { $RequestContext.Dispose() }
        }
    }
}
