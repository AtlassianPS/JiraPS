function Invoke-JiraMethod {
    # .ExternalHelp ..\JiraPS-help.xml
    [CmdletBinding( SupportsPaging )]
    param(
        [Parameter( Mandatory )]
        [Uri]
        $URI,

        [Microsoft.PowerShell.Commands.WebRequestMethod]
        $Method = "GET",

        [String]
        $Body,

        [Switch]
        $RawBody,

        [Hashtable]
        $Headers = @{},

        [Hashtable]
        $GetParameter = @{},

        [Switch]
        $Paging,

        [String]
        $InFile,

        [String]
        $OutFile,

        [Switch]
        $StoreSession,

        [ValidateSet(
            "JiraComment",
            "JiraIssue",
            "JiraUser",
            "JiraVersion",
            "JiraWorklogItem"
        )]
        [String]
        $OutputType,

        [Parameter()]
        [System.Management.Automation.PSCredential]
        [System.Management.Automation.Credential()]
        $Credential,

        [Parameter( DontShow )]
        [ValidateNotNullOrEmpty()]
        [System.Management.Automation.PSCmdlet]
        $Cmdlet = $PSCmdlet,

        [Parameter( DontShow )]
        [int]
        $_RetryCount = 0,

        [Parameter()]
        [String]
        $CacheKey,

        [Parameter()]
        [TimeSpan]
        $CacheExpiry = [TimeSpan]::FromHours(1),

        [Parameter()]
        [Switch]
        $BypassCache,

        [Parameter()]
        [ValidateRange(0, [int]::MaxValue)]
        [Int]
        $TimeoutSec = 100,

        [Alias('Session')][AtlassianPS.Connection]$Connection,

        [Alias('Server', 'ServerName')][String]$ConnectionName,

        [Uri]$BaseUri,

        [Alias('Email')][String]$EmailAddress,

        [Object]$ApiToken,

        [Alias('PAT', 'BearerToken')][Object]$PersonalAccessToken,

        [Switch]$Anonymous,

        [Parameter(DontShow)][AtlassianPS.Connection]$RequestContext,

        [Parameter(DontShow)][Switch]$Discovery
    )

    begin {
        try {
            Write-Verbose "[$($MyInvocation.MyCommand.Name)] Function started"

            $ownsRequestContext = -not $PSBoundParameters.ContainsKey('RequestContext')
            if ($StoreSession) { throw 'StoreSession is obsolete. Use Connect-Jira to create a reusable connection.' }
            if ($Discovery) {
                $PSDefaultParameterValues = @{}
                $discoveryResponse = Microsoft.PowerShell.Utility\Invoke-WebRequest -Uri $Uri -Method Get -Headers @{ Accept = 'application/json' } -MaximumRedirection 0 -UseBasicParsing -TimeoutSec 30 -ErrorAction Stop
                if ([int]$discoveryResponse.StatusCode -ne 200 -or $discoveryResponse.Headers['Content-Type'] -notmatch 'application/json') {
                    throw 'Expected a successful JSON discovery response.'
                }
                $discoveryResult = $discoveryResponse.Content | ConvertFrom-Json -ErrorAction Stop
                return
            }
            if ($RequestContext) {
                if (@('Connection', 'ConnectionName', 'BaseUri', 'Credential', 'EmailAddress', 'ApiToken', 'PersonalAccessToken', 'Anonymous' |
                            Where-Object { $PSBoundParameters.ContainsKey($_) }).Count) {
                    throw 'An internal context cannot be combined with another selector or authentication input.'
                }
                $RequestContext = AtlassianPS.Configuration\Resolve-AtlassianRequestContext -Product Jira -RequestContext $RequestContext
            }
            else {
                $selection = @{}
                foreach ($key in @('Connection', 'ConnectionName', 'BaseUri', 'Credential', 'EmailAddress', 'ApiToken', 'PersonalAccessToken', 'Anonymous')) {
                    if ($PSBoundParameters.ContainsKey($key)) { $selection[$key] = $PSBoundParameters[$key] }
                }
                $RequestContext = Resolve-JiraOperationContext -BoundParameters $selection
            }
            if ($RequestContext.State -eq 'Candidate' -and
                ($Method -ne 'GET' -or $Uri.OriginalString -notin @('/rest/api/2/serverInfo', '/rest/api/2/myself'))) {
                throw 'Unregistered candidates are restricted to creation-time Jira validation GETs.'
            }
            $PSBoundParameters['RequestContext'] = $RequestContext
            foreach ($key in @('Connection', 'ConnectionName', 'BaseUri', 'Credential', 'EmailAddress', 'ApiToken', 'PersonalAccessToken', 'Anonymous')) {
                $null = $PSBoundParameters.Remove($key)
            }
            Set-TlsLevel -Tls12

            Write-DebugMessage "[$($MyInvocation.MyCommand.Name)] ParameterSetName: $($PsCmdlet.ParameterSetName)"

            #region Manage URI
            $resourceContext = Resolve-JiraRequestContext -Uri $Uri -GetParameter $GetParameter -DefaultPageSize $script:DefaultPageSize -Cmdlet $PSCmdlet -RequestContext $RequestContext
            [Uri]$Uri = $resourceContext.Uri
            [Uri]$PaginatedUri = $resourceContext.PaginatedUri
            #endregion Manage URI

            # load DefaultParameters for Invoke-WebRequest
            # as the global PSDefaultParameterValues is not used
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


            #region Cache Check
            if ($CacheKey) {
                $CacheKey = '{0}:{1}:{2}' -f $RequestContext.InstanceId, $PaginatedUri.AbsoluteUri, $CacheKey
            }
            if ($RequestContext.State -ne 'Active') { $BypassCache = $true }
            $cached = Get-JiraCachedResponse -CacheKey $CacheKey -Method $Method -BypassCache:$BypassCache -CommandName $MyInvocation.MyCommand.Name
            if ($cached) {
                Set-TlsLevel -Revert
                $requestCompleted = $true
                return $cached.Data
            }
            #endregion Cache Check

            #region Headers
            # Construct the Headers with the folling priority:
            # - Headers passes as parameters
            # - User's Headers in $PSDefaultParameterValues
            # - Module's default Headers
            $_headers = Join-Hashtable -Hashtable $script:DefaultHeaders, $PSDefaultParameterValues["Invoke-WebRequest:Headers"], $Headers
            #endregion Headers

            #region Constructe IWR Parameter
            $splatParameters = New-JiraWebRequestSplat -Uri $PaginatedUri -Method $Method -Headers $_headers -Body $Body -RawBody:$RawBody -RequestContext $RequestContext -TimeoutSec $TimeoutSec -InFile $InFile -OutFile $OutFile -DefaultContentType $script:DefaultContentType
            #endregion Constructe IWR Parameter

            #region Execute the actual query
            Write-Verbose "[$($MyInvocation.MyCommand.Name)] $($splatParameters.Method) $($splatParameters.Uri.GetLeftPart([UriPartial]::Path))"
            $webRequestResult = Invoke-JiraWebRequestSafely -SplatParameters $splatParameters
            $webResponse = $webRequestResult.WebResponse
            $exception = $webRequestResult.Exception
            if ($webRequestResult.SessionVariableName -and $null -ne $webRequestResult.SessionVariableValue) {
                Set-Variable -Name $webRequestResult.SessionVariableName -Value $webRequestResult.SessionVariableValue -Scope Local
            }
            if ($exception) { Write-Verbose "[$($MyInvocation.MyCommand.Name)] Failed to get an answer from the server" }

            Write-Debug "[$($MyInvocation.MyCommand.Name)] Executed WebRequest. Access `$webResponse to see details"
            if ($webResponse -and [int]$webResponse.StatusCode -ge 300 -and [int]$webResponse.StatusCode -lt 400) {
                throw 'Jira redirected the request. Use the final product endpoint to create a new connection.'
            }
            $shouldRetry = Test-ServerResponse -InputObject $webResponse -Cmdlet $Cmdlet -RetryCount $_RetryCount
            if ($shouldRetry) {
                $PSBoundParameters['_RetryCount'] = $_RetryCount + 1
                $requestCompleted = $true
                Invoke-JiraMethod @PSBoundParameters
                return
            }
            if ($script:JiraResponseHeaderLogConfiguration) {
                Write-DebugMessage "[$($MyInvocation.MyCommand.Name)] Jira response headers"
                try { Write-JiraResponseHeaderLog -InputObject $webResponse }
                catch { Write-Debug "[$($MyInvocation.MyCommand.Name)] Failed to log response headers: $_" }
            }
            #endregion Execute the actual query
        }
        catch {
            if ($ownsRequestContext -and $RequestContext -and $RequestContext.State -eq 'Standalone') { $RequestContext.Dispose() }
            Set-TlsLevel -Revert
            throw
        }
    }

    process {
        try {
            if ($requestCompleted) { return }
            if ($Discovery) { return $discoveryResult }
            Resolve-JiraWebResponse -WebResponse $webResponse -Exception $exception -CacheKey $(if ($BypassCache) { $null } else { $CacheKey }) -Method $Method -CacheExpiry $CacheExpiry -Paging:$Paging -BoundParameters $PSBoundParameters -Cmdlet $Cmdlet -CommandName $MyInvocation.MyCommand.Name
        }
        catch {
            if ($ownsRequestContext -and $RequestContext -and $RequestContext.State -eq 'Standalone') { $RequestContext.Dispose() }
            Set-TlsLevel -Revert
            throw
        }
    }

    end {
        if ($ownsRequestContext -and $RequestContext -and $RequestContext.State -eq 'Standalone') { $RequestContext.Dispose() }
        Set-TlsLevel -Revert

        Write-Verbose "[$($MyInvocation.MyCommand.Name)] Function ended"
    }
}
