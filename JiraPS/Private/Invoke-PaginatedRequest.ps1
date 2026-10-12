function Invoke-PaginatedRequest {
    [CmdletBinding(SupportsPaging)]
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

        [Parameter( Mandatory )]
        [PSCustomObject]
        $Response,

        [ValidateNotNullOrEmpty()]
        [System.Management.Automation.PSCmdlet]
        $Cmdlet = $PSCmdlet
    )

    process {
        $null = $PSBoundParameters.Remove("Paging")
        $null = $PSBoundParameters.Remove("Skip")
        $null = $PSBoundParameters.Remove("Response")

        if (-not $PSBoundParameters["GetParameter"]) { $PSBoundParameters["GetParameter"] = $GetParameter }

        $total = 0
        $offset = if ($PSCmdlet.PagingParameters.Skip) { $PSCmdlet.PagingParameters.Skip } else { 0 }

        if ($PSCmdlet.PagingParameters.IncludeTotalCount) {
            if ($null -ne $Response.total) { $PSCmdlet.PagingParameters.NewTotalCount($Response.total, 1.0) }
            else { $PSCmdlet.PagingParameters.NewTotalCount(0, 0.0) }
        }

        $isTokenPaged = $Response.PSObject.Properties.Name -contains "nextPageToken"

        do {
            Write-Verbose "[$($MyInvocation.MyCommand.Name)] Invoking pagination [currentTotal: $total]"
            $result = Expand-Result -InputObject $Response

            $total += @($result).Count
            $pageSize = if (-not [string]::IsNullOrEmpty($Response.maxResults)) { $Response.maxResults }
            else { $script:DefaultPageSize }

            if ($total -gt $PSCmdlet.PagingParameters.First) {
                $remaining = $PSCmdlet.PagingParameters.First - ($total - @($result).Count)
                Write-DebugMessage "[$($MyInvocation.MyCommand.Name)] Only output the first $remaining of page"
                $result = $result | Select-Object -First $remaining
            }

            Convert-Result -InputObject $result -OutputType $OutputType

            if ($Response.isLast -eq $true) {
                Write-DebugMessage "[$($MyInvocation.MyCommand.Name)] Stopping paging, as isLast is true"
                break
            }

            if ($total -ge $PSCmdlet.PagingParameters.First) {
                Write-DebugMessage "[$($MyInvocation.MyCommand.Name)] Stopping paging, as $total reached $($PSCmdlet.PagingParameters.First)"
                break
            }

            if ($isTokenPaged) {
                # Enhanced search uses tokens; other v3 endpoints still use offsets.
                # The response omits maxResults, so the page-count heuristic is unreliable.
                if ($Response.PSObject.Properties.Name -contains "nextPageToken" -and $Response.nextPageToken) {
                    $PSBoundParameters["GetParameter"]["nextPageToken"] = $Response.nextPageToken
                }
                else { Write-DebugMessage "[$($MyInvocation.MyCommand.Name)] No nextPageToken found; stopping pagination"; break }
            }
            else {
                # Both v2 and v3 APIs support offset-based pagination.
                if ($null -ne $Response.total -and ($total + $offset) -ge $Response.total) { break }

                if (@($result).Count -lt $pageSize) {
                    Write-DebugMessage "[$($MyInvocation.MyCommand.Name)] Stopping paging, as page had less entries than $pageSize"
                    break
                }

                $PSBoundParameters["GetParameter"]["startAt"] = $total + $offset
                $expectedTotal = $total + $pageSize
                if ($expectedTotal -gt $PSCmdlet.PagingParameters.First) {
                    $reduceBy = $expectedTotal - $PSCmdlet.PagingParameters.First
                    $PSBoundParameters["GetParameter"]["maxResults"] = $pageSize - $reduceBy
                }
            }

            $Response = Invoke-JiraMethod @PSBoundParameters

            if ($null -eq $Response) {
                Write-Warning "[$($MyInvocation.MyCommand.Name)] Received null response during pagination (possible auth failure or server error); stopping pagination with $total results collected"
                break
            }

            $result = Expand-Result -InputObject $Response
        } while (@($result).Count -gt 0)
    }
}
