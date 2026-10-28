function Get-JiraUser {
    # .ExternalHelp ..\JiraPS-help.xml
    [CmdletBinding(SupportsPaging, DefaultParameterSetName = 'Self')]
    param(
        [Parameter(Mandatory, Position = 0, ValueFromPipeline, ParameterSetName = 'User')]
        [ValidateNotNull()]
        [AtlassianPS.JiraPS.UserTransformation()]
        [AtlassianPS.JiraPS.User[]]$User,

        [Parameter(Mandatory, ParameterSetName = 'Query')]
        [ValidateNotNullOrEmpty()]
        [String]$Query,

        [Parameter(Mandatory, ParameterSetName = 'All')]
        [Switch]$All,

        [Parameter(ParameterSetName = 'Query')]
        [Switch]$IncludeInactive,

        [Parameter(ParameterSetName = 'Query')]
        [Parameter(ParameterSetName = 'All')]
        [ValidateRange(1, 1000)]
        [Int]$PageSize = $script:DefaultPageSize,

        [AtlassianPS.Connection]$Connection
    )

    begin {
        if ($PSCmdlet.ParameterSetName -in @('Self', 'User') -and @('First', 'Skip', 'IncludeTotalCount' | Where-Object { $PSBoundParameters.ContainsKey($_) }).Count) {
            throw 'User paging parameters require -Query or -All.'
        }
        $requestContext = Resolve-JiraOperationContext -BoundParameters $PSBoundParameters

        $isCloud = Test-JiraCloudServer -RequestContext $RequestContext
        if ($isCloud -and $IncludeInactive) { throw 'Cloud user search returns active users only. Use -All to include inactive and deleted users.' }
        if ($PSCmdlet.ParameterSetName -eq 'All' -and -not $All) { throw 'Supply -All to enumerate Jira users.' }
        $apiVersion = if ($isCloud) { '3' } else { '2' }
    }

    process {
        switch ($PSCmdlet.ParameterSetName) {
            'Self' {
                $result = Invoke-JiraRequest -RequestContext $RequestContext -Uri "/rest/api/$apiVersion/myself" -Method Get -GetParameter @{ expand = 'groups' }
                ConvertTo-JiraUser -InputObject $result
            }
            'User' {
                foreach ($item in $User) {
                    $identifier = if ($isCloud -and $item.AccountId) { $item.AccountId } else { $item.Name }
                    if (-not $identifier -or ($isCloud -and $item.RestUrl -and -not $item.AccountId)) {
                        throw 'User requires an accountId on Cloud or a username on Data Center. Display names are not identifiers.'
                    }
                    $queryParameters = @{ expand = 'groups' }
                    $identifierField = if ($isCloud) { 'accountId' } else { 'username' }
                    $queryParameters[$identifierField] = $identifier
                    $result = Invoke-JiraRequest -RequestContext $RequestContext -Uri "/rest/api/$apiVersion/user" -Method Get -GetParameter $queryParameters
                    ConvertTo-JiraUser -InputObject $result
                }
            }
            default {
                $resource = if ($PSCmdlet.ParameterSetName -eq 'Query') { 'user/search' }
                elseif ($isCloud) { 'users/search' }
                else { 'user/list' }
                $queryParameters = @{ maxResults = $PageSize }
                if ($PSCmdlet.ParameterSetName -eq 'Query') {
                    $queryField = if ($isCloud) { 'query' } else { 'username' }
                    $queryParameters[$queryField] = $Query
                    if ($IncludeInactive) { $queryParameters['includeInactive'] = 'true' }
                }
                $parameters = @{
                    Uri               = "/rest/api/$apiVersion/$resource"
                    Method            = 'Get'
                    GetParameter      = $queryParameters
                    Paging            = $true
                    PageSize          = $PageSize
                    OutputType        = 'JiraUser'
                    First             = $PSCmdlet.PagingParameters.First
                    Skip              = $PSCmdlet.PagingParameters.Skip
                    IncludeTotalCount = $PSCmdlet.PagingParameters.IncludeTotalCount
                }
                try { Invoke-JiraRequest -RequestContext $RequestContext @parameters -ErrorAction Stop }
                catch {
                    if (-not $isCloud -and $All -and $_.FullyQualifiedErrorId -like '*NotFound*') {
                        throw 'This Data Center installation does not expose /rest/api/2/user/list. Use -Query for supported user searches or upgrade to a version with user enumeration.'
                    }
                    throw
                }
            }
        }
    }
}
