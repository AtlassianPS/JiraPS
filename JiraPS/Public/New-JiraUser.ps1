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

        [Alias("Credential")]
        [psobject]
        $Session
    )

    begin {
        Write-Verbose "[$($MyInvocation.MyCommand.Name)] Function started"

        $resourceURi = "rest/api/latest/user"
    }

    process {
        Write-DebugMessage "[$($MyInvocation.MyCommand.Name)] ParameterSetName: $($PsCmdlet.ParameterSetName)"
        Write-DebugMessage "[$($MyInvocation.MyCommand.Name)] PSBoundParameters: $($PSBoundParameters | Out-String)"

        $requestBody = @{
            "name"         = $UserName
            "emailAddress" = $EmailAddress
            "notify"       = $Notify
        }

        if ($DisplayName) {
            $requestBody.displayName = $DisplayName
        }
        else {
            Write-DebugMessage "[New-JiraUser] DisplayName was not specified; defaulting to UserName parameter [$UserName]"
            $requestBody.displayName = $UserName
        }

        $parameter = @{
            URI        = $resourceURi
            Method     = "POST"
            Body       = ConvertTo-Json -InputObject $requestBody
            Session    = $Session
        }
        Write-Debug "[$($MyInvocation.MyCommand.Name)] Invoking JiraMethod with `$parameter"
        if ($PSCmdlet.ShouldProcess($UserName, "Creating new User on JIRA")) {
            $result = Invoke-JiraMethod @parameter

            Write-Output (ConvertTo-JiraUser -InputObject $result)
        }
    }

    end {
        Write-Verbose "[$($MyInvocation.MyCommand.Name)] Complete"
    }
}
