function New-JiraFilter {
    # .ExternalHelp ..\JiraPS-help.xml
    [CmdletBinding( SupportsShouldProcess )]
    param(
        [Parameter( Mandatory, ValueFromPipelineByPropertyName )]
        [ValidateNotNullOrEmpty()]
        [String]
        $Name,

        [Parameter( ValueFromPipelineByPropertyName )]
        [String]
        $Description,

        [Parameter( Mandatory, ValueFromPipelineByPropertyName )]
        [ValidateNotNullOrEmpty()]
        [String]
        $JQL,

        [Parameter( ValueFromPipelineByPropertyName )]
        [Alias('Favourite')]
        [Switch]
        $Favorite,

        [Parameter()]
        [System.Management.Automation.PSCredential]
        [System.Management.Automation.Credential()]
        $Credential = [System.Management.Automation.PSCredential]::Empty
    )

    begin {
        Write-Verbose "[$($MyInvocation.MyCommand.Name)] Function started"

        $server = Get-JiraConfigServer -ErrorAction Stop

        $resourceURi = "$server/rest/api/latest/filter"
    }

    process {
        Write-DebugMessage "[$($MyInvocation.MyCommand.Name)] ParameterSetName: $($PsCmdlet.ParameterSetName)"
        Write-DebugMessage "[$($MyInvocation.MyCommand.Name)] PSBoundParameters: $($PSBoundParameters | Out-String)"

        $requestBody = @{
            name = $Name
            jql  = $JQL
        }
        if ($PSCmdlet.MyInvocation.BoundParameters.ContainsKey("Description")) {
            $requestBody["description"] = $Description
        }
        $requestBody["favourite"] = [Bool]$Favorite

        $parameter = @{
            URI        = $resourceURi
            Method     = "POST"
            Body       = ConvertTo-Json -InputObject $requestBody
            Credential = $Credential
        }
        Write-Debug "[$($MyInvocation.MyCommand.Name)] Invoking JiraMethod with `$parameter"
        if ($PSCmdlet.ShouldProcess($Name, "Creating new Filter")) {
            $result = Invoke-JiraMethod @parameter

            Write-Output (ConvertTo-JiraFilter -InputObject $result)
        }
    }

    end {
        Write-Verbose "[$($MyInvocation.MyCommand.Name)] Complete"
    }
}
