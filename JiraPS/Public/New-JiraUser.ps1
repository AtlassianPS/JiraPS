function New-JiraUser {
    # .ExternalHelp ..\JiraPS-help.xml
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [Alias('Email')]
        [String]$EmailAddress,

        [ValidateNotNullOrEmpty()]
        [String]$UserName,

        [String]$DisplayName,

        [AllowEmptyCollection()]
        [ValidateSet('jira-core', 'jira-servicedesk', 'jira-product-discovery', 'jira-software')]
        [String[]]$Products,

        [AtlassianPS.Connection]$Connection
    )

    process {
        $requestContext = Resolve-JiraOperationContext -BoundParameters $PSBoundParameters
        $isCloud = Test-JiraCloudServer -RequestContext $requestContext
        $body = @{ emailAddress = $EmailAddress }
        if ($isCloud) {
            if ($PSBoundParameters.ContainsKey('UserName') -or $PSBoundParameters.ContainsKey('DisplayName')) {
                throw 'Cloud user creation does not accept UserName or DisplayName. Supply EmailAddress and Products.'
            }
            if (-not $PSBoundParameters.ContainsKey('Products')) { throw 'Cloud user creation requires an explicit Products array. Use @() for no product access.' }
            $body['products'] = @($Products)
        }
        else {
            if (-not $UserName) { throw 'Data Center user creation requires UserName.' }
            if ($PSBoundParameters.ContainsKey('Products')) { throw 'Products is a Cloud user-creation parameter.' }
            $body['name'] = $UserName
            $body['displayName'] = if ($PSBoundParameters.ContainsKey('DisplayName')) { $DisplayName } else { $UserName }
        }
        $apiVersion = if ($isCloud) { '3' } else { '2' }
        if ($PSCmdlet.ShouldProcess($EmailAddress, 'Create Jira user')) {
            $result = Invoke-JiraRequest -RequestContext $requestContext -Uri "/rest/api/$apiVersion/user" -Method Post -Body $body
            ConvertTo-JiraUser -InputObject $result
        }
    }
}
