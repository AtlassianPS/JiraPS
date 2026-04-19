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

        if (-not $PSBoundParameters["GetParameter"]) {
            $PSBoundParameters["GetParameter"] = $GetParameter
        }

        $total = 0
        $offset = 0
        if ($PSCmdlet.PagingParameters.Skip) {
            $offset = $PSCmdlet.PagingParameters.Skip
        }

        $isTokenPaged = "$URI" -match '/rest/api/3'

        do {
            Write-Verbose "[$($MyInvocation.MyCommand.Name)] Invoking pagination [currentTotal: $total]"
            $result = Expand-Result -InputObject $Response

            $total += @($result).Count
            $pageSize = $script:DefaultPageSize
            if (-not [string]::IsNullOrEmpty($Response.maxResults)) {
                $pageSize = $Response.maxResults
            }

            if ($total -gt $PSCmdlet.PagingParameters.First) {
                Write-DebugMessage "[$($MyInvocation.MyCommand.Name)] Only output the first $($PSCmdlet.PagingParameters.First % $pageSize) of page"
                $result = $result | Select-Object -First ($PSCmdlet.PagingParameters.First % $pageSize)
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
                # v3 API: token-based pagination driven by nextPageToken/isLast.
                # The response omits maxResults, so the page-count heuristic is unreliable.
                if ($Response.PSObject.Properties.Name -contains "nextPageToken" -and $Response.nextPageToken) {
                    $PSBoundParameters["GetParameter"]["nextPageToken"] = $Response.nextPageToken
                }
                else {
                    Write-DebugMessage "[$($MyInvocation.MyCommand.Name)] No nextPageToken found; stopping pagination"
                    break
                }
            }
            else {
                # v2 API: offset-based pagination using startAt/maxResults
                if (@($result).Count -lt $pageSize) {
                    Write-DebugMessage "[$($MyInvocation.MyCommand.Name)] Stopping paging, as page had less entries than $pageSize"
                    break
                }

                $PSBoundParameters["GetParameter"]["startAt"] = $total + $offset
                $expectedTotal = $PSBoundParameters["GetParameter"]["startAt"] + $pageSize
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

        if ($PSCmdlet.PagingParameters.IncludeTotalCount) {
            [double]$Accuracy = 1.0
            $PSCmdlet.PagingParameters.NewTotalCount($total, $Accuracy)
        }
    }
}
