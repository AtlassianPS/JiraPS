function Set-JiraFilter {
    # .ExternalHelp ..\JiraPS-help.xml
    [CmdletBinding( SupportsShouldProcess )]
    param(
        [Parameter( Mandatory, ValueFromPipeline )]
        [ValidateNotNullOrEmpty()]
        [AtlassianPS.JiraPS.FilterTransformation()]
        [AtlassianPS.JiraPS.Filter]
        $Filter,

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [String]
        $Name,

        [Parameter()]
        [String]
        $Description,

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [String]
        $JQL,

        [Parameter()]
        [Alias('Favourite')]
        [Bool]
        $Favorite,

        [Switch]
        $PassThru,

        [Parameter()]
        [AtlassianPS.Connection]
        $Connection
    )

    begin {
        Write-Verbose "[$($MyInvocation.MyCommand.Name)] Function started"

        $RequestContext = Resolve-JiraOperationContext -BoundParameters $PSBoundParameters
    }

    process {
        Write-DebugMessage "ParameterSetName: $($PsCmdlet.ParameterSetName)"
        Write-DebugMessage -BoundParameters $PSBoundParameters

        if ($Filter -and -not $Filter.RestUrl) {
            $Filter = Get-JiraFilterOperation -Id $Filter.Id -RequestContext $RequestContext -ErrorAction Stop
        }

        $requestBody = @{}
        if ($PSCmdlet.MyInvocation.BoundParameters.ContainsKey("Name")) { $requestBody["name"] = $Name }
        if ($PSCmdlet.MyInvocation.BoundParameters.ContainsKey("Description")) { $requestBody["description"] = $Description }
        if ($PSCmdlet.MyInvocation.BoundParameters.ContainsKey("JQL")) { $requestBody["jql"] = $JQL }
        if ($PSCmdlet.MyInvocation.BoundParameters.ContainsKey("Favorite")) { $requestBody["favourite"] = $Favorite }

        if ($requestBody.Keys.Count) {
            $parameter = @{
                URI    = $Filter.RestURL
                Method = "PUT"
                Body   = ConvertTo-Json -InputObject $requestBody
            }
            Write-DebugMessage "Invoking JiraMethod with `$parameter"
            if ($PSCmdlet.ShouldProcess($Filter.Name, "Update Filter")) {
                $result = Invoke-JiraRequest -RequestContext $RequestContext @parameter

                if ($PassThru) { ConvertTo-JiraFilter -InputObject $result }
            }
        }
    }

    end {
        Write-Verbose "[$($MyInvocation.MyCommand.Name)] Complete"
    }
}
