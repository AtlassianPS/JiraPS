function Invoke-PaginatedRequest {
    param() # NOTE: We probably need all parameters for Invoke-JiraMethod

    process {
        # Remove Parameters that don't need propagation
        $script:PSDefaultParameterValues.Remove("$($MyInvocation.MyCommand.Name):IncludeTotalCount")
        $null = $PSBoundParameters.Remove("Paging")
        $null = $PSBoundParameters.Remove("Skip")
        if (-not $PSBoundParameters["GetParameter"]) {
            $PSBoundParameters["GetParameter"] = $internalGetParameter
        }

        $total = 0
        $onceMore = $true
        do {
            Write-Verbose "[$($MyInvocation.MyCommand.Name)] Invoking pagination [currentTotal: $total]"

            $result = Expand-Result -InputObject $response # NOTE: $response still need to be added as input to this function

            $total += @($result).Count
            $pageSize = $response.maxResults

            if ($total -gt $PSCmdlet.PagingParameters.First) {
                Write-DebugMessage "[$($MyInvocation.MyCommand.Name)] Only output the first $($PSCmdlet.PagingParameters.First % $pageSize) of page"
                $result = $result | Select-Object -First ($PSCmdlet.PagingParameters.First % $pageSize)
            }

            Convert-Result -InputObject $result -OutputType $OutputType
            Write-DebugMessage ($result | Out-String)

            if (@($result).Count -lt $response.maxResults) {
                Write-DebugMessage "[$($MyInvocation.MyCommand.Name)] Stopping paging, as page had less entries than $($response.maxResults)"
                break
            }

            if ($total -ge $PSCmdlet.PagingParameters.First) {
                Write-DebugMessage "[$($MyInvocation.MyCommand.Name)] Stopping paging, as $total reached $($PSCmdlet.PagingParameters.First)"
                break
            }

            switch -regex ($PSBoundParameters["Uri"]) {
                '\/rest\/api\/3' {
                    # v3 of the API implemented pagination by token
                    if ($null -ne $response.Contains("nextPageToken")) {
                        $PSBoundParameters["GetParameter"]["nextPageToken"] = $response.nextPageToken
                    }
                    else {
                        # Fix Last page
                        $onceMore = $false # NOTE: I would like to remove this and have the same behavior as v2: it's fine if we query 1 empty page at the end
                    }
                }
                default {
                    # calculate the size of the next page
                    $PSBoundParameters["GetParameter"]["startAt"] = $total + $offset
                    $expectedTotal = $PSBoundParameters["GetParameter"]["startAt"] + $pageSize
                    if ($expectedTotal -gt $PSCmdlet.PagingParameters.First) {
                        $reduceBy = $expectedTotal - $PSCmdlet.PagingParameters.First
                        $PSBoundParameters["GetParameter"]["maxResults"] = $pageSize - $reduceBy # TODO: I think we can drop this. Why change the maxResults only for the last page?
                    }
                }
            }

            # Inquire the next page
            $response = Invoke-JiraMethod @PSBoundParameters
            Expand-Result -InputObject $response # NOTE: I would like to write to the pipeline here without capturing

        } while (($response.isLast -eq $false) -or $onceMore ) # keep the previous logic: fetch one more page and repeat if not empty -- or: optimize by comparing results on page to pagesize

        if ($PSCmdlet.PagingParameters.IncludeTotalCount) {
            [double]$Accuracy = 1.0
            $PSCmdlet.PagingParameters.NewTotalCount($total, $Accuracy)
        }
    }
}
