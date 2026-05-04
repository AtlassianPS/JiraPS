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
        $requestContext = Resolve-JiraRequestContext -Uri $Uri -GetParameter $GetParameter -DefaultPageSize $script:DefaultPageSize -Cmdlet $PSCmdlet
        [Uri]$Uri = $requestContext.Uri
        [Uri]$PaginatedUri = $requestContext.PaginatedUri
        #endregion Manage URI

        #region Cache Check
        $cached = Get-JiraCachedResponse -CacheKey $CacheKey -Method $Method -BypassCache:$BypassCache -CommandName $MyInvocation.MyCommand.Name
        if ($cached) {
            Set-TlsLevel -Revert
            return $cached.Data
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

        #region Constructe IWR Parameter
        $splatParameters = New-JiraWebRequestSplat -Uri $PaginatedUri -Method $Method -Headers $_headers -Body $Body -RawBody:$RawBody -Credential $Credential -TimeoutSec $TimeoutSec -InFile $InFile -OutFile $OutFile -StoreSession:$StoreSession -DefaultContentType $script:DefaultContentType
        #endregion Constructe IWR Parameter

        #region Execute the actual query
        Write-Verbose "[$($MyInvocation.MyCommand.Name)] $($splatParameters.Method) $($splatParameters.Uri)"
        Write-Debug "[$($MyInvocation.MyCommand.Name)] Invoke-WebRequest with `$splatParameters: $($splatParameters | Out-String)"
        $webRequestResult = Invoke-JiraWebRequestSafely -SplatParameters $splatParameters
        $webResponse = $webRequestResult.WebResponse
        $exception = $webRequestResult.Exception
        if ($webRequestResult.SessionVariableName -and $null -ne $webRequestResult.SessionVariableValue) {
            Set-Variable -Name $webRequestResult.SessionVariableName -Value $webRequestResult.SessionVariableValue -Scope Local
        }
        if ($exception) {
            Write-Verbose "[$($MyInvocation.MyCommand.Name)] Failed to get an answer from the server"
        }

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
        Resolve-JiraWebResponse -WebResponse $webResponse -Exception $exception -StoreSession:$StoreSession -Credential $Credential -SessionTransformationMethod $script:SessionTransformationMethod -Session $newSessionVar -CacheKey $CacheKey -Method $Method -CacheExpiry $CacheExpiry -Paging:$Paging -BoundParameters $PSBoundParameters -Cmdlet $Cmdlet -CommandName $MyInvocation.MyCommand.Name
    }

    end {
        Set-TlsLevel -Revert

        Write-Verbose "[$($MyInvocation.MyCommand.Name)] Function ended"
    }
}
