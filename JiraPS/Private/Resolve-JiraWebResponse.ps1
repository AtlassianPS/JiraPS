function Resolve-JiraWebResponse {
    [CmdletBinding()]
    param(
        $WebResponse,

        $Exception,

        [Switch]
        $StoreSession,

        [Parameter()]
        [System.Management.Automation.PSCredential]
        [System.Management.Automation.Credential()]
        $Credential = [System.Management.Automation.PSCredential]::Empty,

        [ValidateNotNullOrEmpty()]
        [String]
        $SessionTransformationMethod = "ConvertTo-JiraSession",

        $Session,

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

        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [System.Management.Automation.PSCmdlet]
        $Cmdlet,

        [String]
        $CommandName = "Invoke-JiraMethod"
    )

    if (-not $WebResponse) {
        Write-Verbose "[$CommandName] No Web result object was returned from. This is unusual!"
        return
    }

    # In PowerShellCore (v6+) the StatusCode of an exception is somewhere else
    if (-not ($statusCode = $WebResponse.StatusCode)) {
        $statusCode = $WebResponse.Exception.Response.StatusCode
    }
    Write-Verbose "[$CommandName] Status code: $($statusCode)"

    if ($statusCode.value__ -ge 400) {
        Resolve-ErrorWebResponse -Exception $Exception -StatusCode $statusCode -Cmdlet $Cmdlet
        return
    }

    if ($StoreSession) {
        return & $SessionTransformationMethod -Session $Session -Username $Credential.UserName
    }

    if (-not $WebResponse.Content) {
        # No content, although statusCode < 400
        # This could be wanted behavior of the API
        Write-Verbose "[$CommandName] No content was returned from."
        return
    }

    $response = ConvertFrom-Json ([Text.Encoding]::UTF8.GetString($WebResponse.RawContentStream.ToArray()))

    # ConvertFrom-Json yields $null (PS7+) or @() (PS5.1) for an empty JSON array ("[]"); only cache when there is actual content.
    # Check both null and empty collection to handle cross-version differences.
    if ($null -ne $response -and @($response).Count -gt 0) {
        Set-JiraCachedResponse -CacheKey $CacheKey -Method $Method -Response $response -CacheExpiry $CacheExpiry -CommandName $CommandName
    }

    if ($Paging) {
        Invoke-PaginatedRequest -Response $response @BoundParameters
    }
    else {
        $response
    }
}
