function Invoke-PaginatedRequest {
    [CmdletBinding(SupportsPaging = $true)]
    # TODO: rethink design of recursion
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

        [Parameter( Mandatory = $true )]
        [PSCustomObject]
        $Response,

        # [Parameter( DontShow )]
        [ValidateNotNullOrEmpty()]
        [System.Management.Automation.PSCmdlet]
        $Cmdlet = $PSCmdlet
    )

    process {
        # Remove Parameters that don't need propagation
        #$script:PSDefaultParameterValues.Remove("$($MyInvocation.MyCommand.Name):IncludeTotalCount")
        $null = $PSBoundParameters.Remove("Paging")
        $null = $PSBoundParameters.Remove("Skip")
        $null = $PSBoundParameters.Remove("Response")

        if (-not $PSBoundParameters["GetParameter"]) {
            $PSBoundParameters["GetParameter"] = $internalGetParameter
        }

        $total = 0
        $onceMore = $true
        do {
            Write-Verbose "[$($MyInvocation.MyCommand.Name)] Invoking pagination [currentTotal: $total]"
            $result = Expand-Result -InputObject $response

            $total += @($result).Count
            $pageSize = $script:DefaultPageSize
            if ([string]::IsNullOrEmpty($response.maxResults)) {
                $pageSize = $response.maxResults
            }

            if ($total -gt $PSCmdlet.PagingParameters.First) {
                Write-DebugMessage "[$($MyInvocation.MyCommand.Name)] Only output the first $($PSCmdlet.PagingParameters.First % $pageSize) of page"
                $result = $result | Select-Object -First ($PSCmdlet.PagingParameters.First % $pageSize)
            }

            Convert-Result -InputObject $result -OutputType $OutputType # TODO: should this not be in `Invoke-JiraMethod`?

            if ($response.isLast) {
                Write-DebugMessage "[$($MyInvocation.MyCommand.Name)] Stopping paging, as isLast is true"
                break
            }

            if (@($result).Count -lt $pageSize) {
                Write-DebugMessage "[$($MyInvocation.MyCommand.Name)] Stopping paging, as page had less entries than $($pageSize)"
                break
            }

            if ($total -ge $PSCmdlet.PagingParameters.First) {
                Write-DebugMessage "[$($MyInvocation.MyCommand.Name)] Stopping paging, as $total reached $($PSCmdlet.PagingParameters.First)"
                break
            }

            switch -regex ($PSBoundParameters["Uri"]) {
                '\/rest\/api\/3' {
                    # v3 of the API implemented pagination by token
                    if ($response.PSObject.properties.name.Contains("nextPageToken")) {
                        $PSBoundParameters["GetParameter"]["nextPageToken"] = $response.nextPageToken
                    }
                    else { break } # safe-guard. Should not happen
                }
                default {
                    # calculate the size of the next page
                    $PSBoundParameters["GetParameter"]["startAt"] = $total + $offset
                    $expectedTotal = $PSBoundParameters["GetParameter"]["startAt"] + $pageSize
                    if ($expectedTotal -gt $PSCmdlet.PagingParameters.First) {
                        $reduceBy = $expectedTotal - $PSCmdlet.PagingParameters.First
                        $PSBoundParameters["GetParameter"]["maxResults"] = $pageSize - $reduceBy
                    }
                }
            }

            # Inquire the next page
            $response = Invoke-JiraMethod @PSBoundParameters
        } while (@($result).Count -gt 0)

        if ($PSCmdlet.PagingParameters.IncludeTotalCount) {
            [double]$Accuracy = 1.0
            $PSCmdlet.PagingParameters.NewTotalCount($total, $Accuracy)
        }
    }
}
