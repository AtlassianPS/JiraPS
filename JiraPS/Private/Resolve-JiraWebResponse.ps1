function Invoke-JiraRequest {
    <#
    .SYNOPSIS
        Execute a Jira request through the shared authenticated transport.
    .DESCRIPTION
        Public commands own connection selection and confirmation.
        This helper handles URI resolution, request encoding, safe retries, caching and response processing.
        Discovery is an unauthenticated, creation-time GET with redirects disabled.
    #>
    [CmdletBinding(SupportsPaging, PositionalBinding = $false, DefaultParameterSetName = 'Authenticated')]
    param(
        [Parameter(Mandatory)]
        [Uri]$Uri,
        [Microsoft.PowerShell.Commands.WebRequestMethod]$Method = 'Get',
        [Object]$Body,
        [String]$ContentType,
        [Hashtable]$Headers = @{},
        [Hashtable]$GetParameter = @{},
        [Switch]$Paging,
        [ValidateRange(1, [int]::MaxValue)]
        [Int]$PageSize = $script:DefaultPageSize,
        [String]$InFile,
        [String]$OutFile,
        [Switch]$RawResponse,
        [String]$OutputType,
        [String]$CacheKey,
        [TimeSpan]$CacheExpiry = [TimeSpan]::FromHours(1),
        [Switch]$BypassCache,
        [ValidateRange(0, [int]::MaxValue)]
        [Int]$TimeoutSec = 100,
        [Parameter(Mandatory, ParameterSetName = 'Authenticated')]
        [ValidateNotNull()]
        [AtlassianPS.Connection]$RequestContext,
        [System.Management.Automation.PSCmdlet]$Cmdlet = $PSCmdlet,
        [Int]$_RetryCount = 0,
        [Parameter(Mandatory, ParameterSetName = 'Discovery')]
        [Switch]$Discovery
    )

    if ($PSCmdlet.ParameterSetName -eq 'Discovery') {
        if (-not $Discovery) { throw 'Supply -Discovery to request unauthenticated endpoint discovery.' }
        $PSDefaultParameterValues = @{}
        $parameters = @{
            Uri                = $Uri
            Method             = 'Get'
            Headers            = @{ Accept = 'application/json' }
            MaximumRedirection = 0
            UseBasicParsing    = $true
            TimeoutSec         = 30
            ErrorAction        = 'Stop'
        }
        $response = Microsoft.PowerShell.Utility\Invoke-WebRequest @parameters
        if ([int]$response.StatusCode -ne 200 -or $response.Headers['Content-Type'] -notmatch 'application/json') {
            throw 'Expected a successful JSON discovery response.'
        }
        return ($response.Content | ConvertFrom-Json -ErrorAction Stop)
    }

    $RequestContext = AtlassianPS.Configuration\Resolve-AtlassianRequestContext -Product Jira -RequestContext $RequestContext
    if ($RequestContext.State -eq 'Candidate' -and
        ($Method -ne 'Get' -or $Uri.OriginalString -notin @('/rest/api/2/serverInfo', '/rest/api/2/myself'))
    ) {
        throw 'Unregistered candidates are restricted to creation-time Jira validation GETs.'
    }
    if ($InFile -and $PSBoundParameters.ContainsKey('Body')) { throw 'An attachment upload cannot also supply Body.' }
    if ($Paging -and $PSCmdlet.PagingParameters.First -eq 0 -and -not $PSCmdlet.PagingParameters.IncludeTotalCount) { return }

    Set-TlsLevel -Tls12
    try {
        Write-DebugMessage -BoundParameters $PSBoundParameters
        $resource = Resolve-JiraRequestContext -Uri $Uri -RequestContext $RequestContext -GetParameter $GetParameter -DefaultPageSize $PageSize -Paging:$Paging -Cmdlet $PSCmdlet
        $PSBoundParameters['RequestContext'] = $RequestContext
        $PSBoundParameters['GetParameter'] = $resource.GetParameter
        if ($Paging) { $PSBoundParameters['Uri'] = $resource.Uri }

        $PSDefaultParameterValues = Resolve-DefaultParameterValue -Reference $global:PSDefaultParameterValues -CommandName 'Invoke-WebRequest'
        foreach ($key in $PSDefaultParameterValues.Keys) {
            if ($key -match ':(Credential|Certificate|CertificateThumbprint|UseDefaultCredentials|WebSession|SessionVariable|Authentication|Token|PreserveAuthorizationOnRedirect)$') {
                throw "Remove conflicting low-level authentication default $key and use Jira authentication parameters."
            }
        }
        foreach ($headerSet in @($Headers, $PSDefaultParameterValues['Invoke-WebRequest:Headers'])) {
            if ($headerSet -and @($headerSet.Keys | Where-Object { $_ -match '^(Authorization|Proxy-Authorization|Cookie|Cookie2)$' }).Count) {
                throw 'Authentication headers are unsupported. Use the Jira authentication parameters.'
            }
        }

        $fullCacheKey = if ($CacheKey -and $RequestContext.State -eq 'Active' -and -not ($RawResponse -or $OutFile)) {
            '{0}:{1}:{2}' -f $RequestContext.InstanceId, $resource.PaginatedUri.AbsoluteUri, $CacheKey
        }
        $cached = Get-JiraCachedResponse -CacheKey $fullCacheKey -Method $Method -BypassCache:$BypassCache
        $responseParameters = @{
            CacheKey        = $fullCacheKey
            CacheExpiry     = $CacheExpiry
            Method          = $Method
            Paging          = $Paging
            RawResponse     = $RawResponse
            OutFile         = $OutFile
            BoundParameters = $PSBoundParameters
            Cmdlet          = $Cmdlet
            CommandName     = $Cmdlet.MyInvocation.MyCommand.Name
        }
        if ($cached) {
            Resolve-JiraWebResponse @responseParameters -CachedResponse $cached.Data
            return
        }

        $request = @{
            Uri                = $resource.PaginatedUri
            Method             = $Method
            Headers            = (Join-Hashtable -Hashtable $script:DefaultHeaders, $PSDefaultParameterValues['Invoke-WebRequest:Headers'], $Headers)
            RequestContext     = $RequestContext
            TimeoutSec         = $TimeoutSec
            DefaultContentType = $script:DefaultContentType
        }
        foreach ($key in @('Body', 'ContentType', 'InFile', 'OutFile')) {
            if ($PSBoundParameters.ContainsKey($key)) { $request[$key] = $PSBoundParameters[$key] }
        }
        $splat = New-JiraWebRequestSplat @request
        Write-Verbose "[$($Cmdlet.MyInvocation.MyCommand.Name)] $Method $($splat.Uri.GetLeftPart([UriPartial]::Path))"
        $result = Invoke-JiraWebRequestSafely -SplatParameters $splat
        $webResponse = $result.WebResponse
        if ($webResponse -and [int]$webResponse.StatusCode -ge 300 -and [int]$webResponse.StatusCode -lt 400) {
            throw 'Jira redirected the request. Use the final product endpoint to create a new connection.'
        }
        $maxRetries = if ($Method -in @('Get', 'Head', 'Options')) { 3 } else { 0 }
        if (Test-ServerResponse -InputObject $webResponse -Cmdlet $Cmdlet -RetryCount $_RetryCount -MaxRetries $maxRetries) {
            $PSBoundParameters['_RetryCount'] = $_RetryCount + 1
            Invoke-JiraRequest @PSBoundParameters
            return
        }
        if ($script:JiraResponseHeaderLogConfiguration) {
            try { Write-JiraResponseHeaderLog -InputObject $webResponse }
            catch { Write-Debug "[$($Cmdlet.MyInvocation.MyCommand.Name)] Failed to log response headers: $_" }
        }
        Resolve-JiraWebResponse @responseParameters -WebResponse $webResponse -Exception $result.Exception
    }
    finally {
        Set-TlsLevel -Revert
    }
}

function Resolve-JiraWebResponse {
    <#
    .SYNOPSIS
        Process fresh and cached Jira responses through the same output path.
    #>
    [CmdletBinding()]
    param(
        $WebResponse,

        $Exception,

        $CachedResponse,

        [Switch]
        $RawResponse,

        [String]
        $OutFile,

        [String]
        $CacheKey,

        [Microsoft.PowerShell.Commands.WebRequestMethod]
        $Method = "GET",

        [TimeSpan]
        $CacheExpiry = [TimeSpan]::FromHours(1),

        [Switch]
        $Paging,

        [Hashtable]
        $BoundParameters = @{},

        [Parameter( Mandatory )]
        [ValidateNotNullOrEmpty()]
        [System.Management.Automation.PSCmdlet]
        $Cmdlet,

        [String]
        $CommandName = "Invoke-JiraRequest"
    )

    $fromCache = $PSBoundParameters.ContainsKey('CachedResponse')
    if (-not $fromCache -and -not $WebResponse) {
        if ($Exception) {
            WriteError -ErrorRecord $Exception -ErrorId $Exception.FullyQualifiedErrorId -Category $Exception.CategoryInfo.Category -Cmdlet $Cmdlet
        }
        else { Write-Verbose "[$CommandName] No Web result object was returned from. This is unusual!" }
        return
    }

    # In PowerShellCore (v6+) the StatusCode of an exception is somewhere else
    if (-not ($statusCode = $WebResponse.StatusCode)) { $statusCode = $WebResponse.Exception.Response.StatusCode }
    Write-Verbose "[$CommandName] Status code: $($statusCode)"

    if (-not $fromCache -and [int]$statusCode -ge 400) {
        Resolve-ErrorWebResponse -Exception $Exception -StatusCode ([Net.HttpStatusCode][int]$statusCode) -Cmdlet $Cmdlet
        return
    }

    if ($RawResponse) { return $WebResponse }
    if ($OutFile) { return (Get-Item -LiteralPath $OutFile -ErrorAction Stop) }
    if (-not $fromCache -and -not $WebResponse.Content) {
        # No content, although statusCode < 400
        # This could be wanted behavior of the API
        Write-Verbose "[$CommandName] No content was returned from."
        return
    }

    $response = if ($fromCache) { $CachedResponse }
    else {
        try { ConvertFrom-Json -InputObject ([Text.Encoding]::UTF8.GetString($WebResponse.RawContentStream.ToArray())) -ErrorAction Stop }
        catch { throw 'Jira did not return valid JSON. Use -RawResponse to inspect the response or -OutFile to save its bytes.' }
    }

    # ConvertFrom-Json yields $null (PS7+) or @() (PS5.1) for an empty JSON array ("[]"); only cache when there is actual content.
    # Check both null and empty collection to handle cross-version differences.
    if (-not $fromCache -and $null -ne $response -and @($response).Count -gt 0) {
        Set-JiraCachedResponse -CacheKey $CacheKey -Method $Method -Response $response -CacheExpiry $CacheExpiry -CommandName $CommandName
    }

    if ($Paging) { Invoke-PaginatedRequest -Response $response @BoundParameters } else { $response }
}
