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
        $Credential = [System.Management.Automation.PSCredential]::Empty,

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
        $TimeoutSec = 100
    )

    begin {
        Write-Verbose "[$($MyInvocation.MyCommand.Name)] Function started"

        Set-TlsLevel -Tls12

        Write-DebugMessage "[$($MyInvocation.MyCommand.Name)] ParameterSetName: $($PsCmdlet.ParameterSetName)"
        Write-DebugMessage "[$($MyInvocation.MyCommand.Name)] PSBoundParameters: $($PSBoundParameters | Out-String)"

        #region Manage URI
        $providedUriValue = $Uri.OriginalString
        if (-not $Uri.IsAbsoluteUri) {
            if (-not $providedUriValue.StartsWith('/')) {
                $errorParameter = @{
                    Cmdlet       = $PSCmdlet
                    Exception    = [System.ArgumentException]::new("Invalid URI path '$providedUriValue'. Relative URIs must start with '/'.")
                    ErrorId      = 'ParameterValue.UriPathMustStartWithSlash'
                    Category     = [System.Management.Automation.ErrorCategory]::InvalidArgument
                    TargetObject = $providedUriValue
                }
                ThrowError @errorParameter
            }

            $server = Get-JiraConfigServer -ErrorAction SilentlyContinue
            if ([String]::IsNullOrWhiteSpace($server)) {
                $errorParameter = @{
                    Cmdlet       = $PSCmdlet
                    Exception    = [System.ArgumentException]::new("Cannot resolve relative URI '$providedUriValue' because no Jira server is configured. Use Set-JiraConfigServer first.")
                    ErrorId      = 'ParameterValue.JiraServerNotConfigured'
                    Category     = [System.Management.Automation.ErrorCategory]::InvalidArgument
                    TargetObject = $providedUriValue
                }
                ThrowError @errorParameter
            }

            [Uri]$Uri = "{0}{1}" -f $server.TrimEnd('/'), $providedUriValue
        }

        if (-not $Uri.IsAbsoluteUri) {
            $errorParameter = @{
                Cmdlet       = $PSCmdlet
                Exception    = [System.ArgumentException]::new("Invoke-JiraMethod: -Uri must be an absolute URI. Got '$providedUriValue'.")
                ErrorId      = 'ParameterValue.UriMustBeAbsolute'
                Category     = [System.Management.Automation.ErrorCategory]::InvalidArgument
                TargetObject = $providedUriValue
            }
            ThrowError @errorParameter
        }

        # Amend query from URI with GetParameter
        $uriQuery = ConvertTo-ParameterHash -Uri $Uri
        $internalGetParameter = Join-Hashtable $uriQuery, $GetParameter

        # And remove it from URI
        [Uri]$Uri = $Uri.GetLeftPart("Path")
        $PaginatedUri = $Uri
        #endregion Manage URI

        #region Cache Check
        if ($CacheKey -and $Method -eq 'GET' -and -not $BypassCache) {
            if (-not $script:JiraCache) {
                $script:JiraCache = @{}
            }
            $cacheServer = Get-JiraConfigServer -ErrorAction SilentlyContinue
            $fullCacheKey = "${CacheKey}:${cacheServer}"
            $cached = $script:JiraCache[$fullCacheKey]
            if ($cached -and (Get-Date) -lt $cached.Expiry) {
                Write-Verbose "[$($MyInvocation.MyCommand.Name)] Cache hit for $CacheKey"
                Set-TlsLevel -Revert
                return $cached.Data
            }
        }
        #endregion Cache Check

        # load DefaultParameters for Invoke-WebRequest
        # as the global PSDefaultParameterValues is not used
        $PSDefaultParameterValues = Resolve-DefaultParameterValue -Reference $global:PSDefaultParameterValues -CommandName 'Invoke-WebRequest'

        #region Headers
        # Construct the Headers with the folling priority:
        # - Headers passes as parameters
        # - User's Headers in $PSDefaultParameterValues
        # - Module's default Headers
        $_headers = Join-Hashtable -Hashtable $script:DefaultHeaders, $PSDefaultParameterValues["Invoke-WebRequest:Headers"], $Headers
        #endregion Headers

        # Use default PageSize
        if (-not $internalGetParameter.ContainsKey("maxResults")) {
            $internalGetParameter["maxResults"] = $script:DefaultPageSize
        }

        # Append GET parameters to URi
        if ($PSCmdlet.PagingParameters) {
            if ($PSCmdlet.PagingParameters.Skip) {
                $internalGetParameter["startAt"] = $PSCmdlet.PagingParameters.Skip
            }
            if ($PSCmdlet.PagingParameters.First -lt $internalGetParameter["maxResults"]) {
                $internalGetParameter["maxResults"] = $PSCmdlet.PagingParameters.First
            }
        }

        [Uri]$PaginatedUri = "{0}{1}" -f $PaginatedUri, (ConvertTo-GetParameter $internalGetParameter)

        #region Constructe IWR Parameter
        $splatParameters = @{
            Uri             = $PaginatedUri
            Method          = $Method
            Headers         = $_headers
            UseBasicParsing = $true
            Credential      = $Credential
            ErrorAction     = "Stop"
            Verbose         = $false
        }

        if ($TimeoutSec -gt 0) {
            $splatParameters["TimeoutSec"] = $TimeoutSec
        }

        if ($_headers.ContainsKey("Content-Type")) {
            $splatParameters["ContentType"] = $_headers["Content-Type"]
            $splatParameters["Headers"].Remove("Content-Type")
            $_headers.Remove("Content-Type")
        }
        elseif ($Body) {
            $splatParameters["ContentType"] = $script:DefaultContentType
        }

        if ($Body) {
            if ($RawBody) {
                $splatParameters["Body"] = $Body
            }
            else {
                # Encode Body to preserve special chars
                # http://stackoverflow.com/questions/15290185/invoke-webrequest-issue-with-special-characters-in-json
                $splatParameters["Body"] = [System.Text.Encoding]::UTF8.GetBytes($Body)
            }
        }

        if ((-not $Credential) -or ($Credential -eq [System.Management.Automation.PSCredential]::Empty)) {
            $splatParameters.Remove("Credential")
            if ($session = Get-JiraSession -ErrorAction SilentlyContinue) {
                $splatParameters["WebSession"] = $session.WebSession
            }
        }

        if ($StoreSession) {
            $splatParameters["SessionVariable"] = "newSessionVar"
            $splatParameters.Remove("WebSession")
        }

        if ($InFile) {
            $splatParameters["InFile"] = $InFile
        }
        if ($OutFile) {
            $splatParameters["OutFile"] = $OutFile
        }
        #endregion Constructe IWR Parameter

        #region Execute the actual query
        # Normal ProgressPreference really slows down invoke-webrequest as it tries to update the screen for bytes received.
        # By setting ProgressPreference to silentlyContinue it doesn't try to update the screen and speeds up the downloads.
        # See https://stackoverflow.com/a/43477248/2641196
        $oldProgressPreference = $progressPreference
        $progressPreference = 'silentlyContinue'

        try {
            Write-Verbose "[$($MyInvocation.MyCommand.Name)] $($splatParameters.Method) $($splatParameters.Uri)"
            Write-Debug "[$($MyInvocation.MyCommand.Name)] Invoke-WebRequest with `$splatParameters: $($splatParameters | Out-String)"
            # Invoke the API
            $webResponse = Invoke-WebRequest @splatParameters
        }
        catch {
            Write-Verbose "[$($MyInvocation.MyCommand.Name)] Failed to get an answer from the server"

            $exception = $_
            $webResponse = $exception.Exception.Response
        }

        $progressPreference = $oldProgressPreference

        Write-Debug "[$($MyInvocation.MyCommand.Name)] Executed WebRequest. Access `$webResponse to see details"
        $shouldRetry = Test-ServerResponse -InputObject $webResponse -Cmdlet $Cmdlet -RetryCount $_RetryCount
        if ($shouldRetry) {
            $PSBoundParameters['_RetryCount'] = $_RetryCount + 1
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

    process {
        if ($webResponse) {
            # In PowerShellCore (v6+) the StatusCode of an exception is somewhere else
            if (-not ($statusCode = $webResponse.StatusCode)) {
                $statusCode = $webResponse.Exception.Response.StatusCode
            }
            Write-Verbose "[$($MyInvocation.MyCommand.Name)] Status code: $($statusCode)"

            #region Code 400+
            if ($statusCode.value__ -ge 400) {
                Resolve-ErrorWebResponse -Exception $exception -StatusCode $statusCode -Cmdlet $Cmdlet
            }
            #endregion Code 400+

            #region Code 399-
            else {
                if ($StoreSession) {
                    return & $script:SessionTransformationMethod -Session $newSessionVar -Username $Credential.UserName
                }

                if ($webResponse.Content) {
                    $response = ConvertFrom-Json ([Text.Encoding]::UTF8.GetString($webResponse.RawContentStream.ToArray()))

                    #region Cache Store
                    if ($CacheKey -and $Method -eq 'GET') {
                        if (-not $script:JiraCache) {
                            $script:JiraCache = @{}
                        }
                        $cacheServer = Get-JiraConfigServer -ErrorAction SilentlyContinue
                        $fullCacheKey = "${CacheKey}:${cacheServer}"
                        $script:JiraCache[$fullCacheKey] = @{
                            Data   = $response
                            Expiry = (Get-Date).Add($CacheExpiry)
                        }
                        Write-Verbose "[$($MyInvocation.MyCommand.Name)] Cached response for $CacheKey (expires in $CacheExpiry)"
                    }
                    #endregion Cache Store

                    if ($Paging) {
                        Invoke-PaginatedRequest -Response $response @PSBoundParameters
                    }
                    else {
                        $response
                    }
                }
                else {
                    # No content, although statusCode < 400
                    # This could be wanted behavior of the API
                    Write-Verbose "[$($MyInvocation.MyCommand.Name)] No content was returned from."
                }
            }
            #endregion Code 399-
        }
        else {
            Write-Verbose "[$($MyInvocation.MyCommand.Name)] No Web result object was returned from. This is unusual!"
        }
    }

    end {
        Set-TlsLevel -Revert

        Write-Verbose "[$($MyInvocation.MyCommand.Name)] Function ended"
    }
}
