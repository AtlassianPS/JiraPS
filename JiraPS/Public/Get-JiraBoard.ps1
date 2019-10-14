function Get-JiraBoard {
    # .ExternalHelp ..\JiraPS-help.xml
    [CmdletBinding( SupportsPaging, DefaultParameterSetName = '_All' )]
    param(
        [Parameter( Position = 0, Mandatory, ValueFromPipeline, ParameterSetName = '_Search' )]
        [String[]]
        $Board,

        [UInt32]
        $StartIndex = 0,

        [UInt32]
        $MaxResults,

        [UInt32]
        $PageSize = $script:DefaultPageSize,

        [Parameter()]
        [System.Management.Automation.PSCredential]
        [System.Management.Automation.Credential()]
        $Credential = [System.Management.Automation.PSCredential]::Empty
    )

    begin {
        Write-Verbose "[$($MyInvocation.MyCommand.Name)] Function started"

        $server = Get-JiraConfigServer -ErrorAction Stop

        $resourceURi = "$server/rest/agile/1.0/board/"

        if ($PageSize -gt 50) {
            Write-Warning "JIRA's API may not properly support MaxResults values higher than 50 for this method. If you receive inconsistent results, do not pass the MaxResults parameter to this function to return all results."
        }
    }

    process {
        Write-DebugMessage "[$($MyInvocation.MyCommand.Name)] ParameterSetName: $($PsCmdlet.ParameterSetName)"
        Write-DebugMessage "[$($MyInvocation.MyCommand.Name)] PSBoundParameters: $($PSBoundParameters | Out-String)"

        switch ($PSCmdlet.ParameterSetName) {
            '_All' {
                $parameter = @{
                    URI        = $resourceURi
                    Method     = "GET"
                    GetParameter = @{
                        maxResults = $PageSize
                    }
                    Credential = $Credential
                    Paging = $true
                }
                Write-Debug "[$($MyInvocation.MyCommand.Name)] Invoking JiraMethod with `$parameter"
                $result = Invoke-JiraMethod @parameter

                Write-Output (ConvertTo-JiraBoard -InputObject $result)
            }
            '_Search' {
                foreach ($_board in $Board) {
                    Write-Verbose "[$($MyInvocation.MyCommand.Name)] Processing [$_board]"
                    Write-Debug "[$($MyInvocation.MyCommand.Name)] Processing `$_board [$_board]"

                    $parameter = @{
                        URI        = $resourceURi
                        Method     = "GET"
                        GetParameter = @{
                            name  = $_board
                            maxResults = $PageSize
                        }
                        Credential = $Credential
                        Paging = $true
                    }

                    # Paging
                    ($PSCmdlet.PagingParameters | Get-Member -MemberType Property).Name | ForEach-Object {
                        $parameter[$_] = $PSCmdlet.PagingParameters.$_
                    }
                    # Make `SupportsPaging` be backwards compatible
                    if ($StartIndex) {
                        Write-Warning "[$($MyInvocation.MyCommand.Name)] The parameter '-StartIndex' has been marked as deprecated. For more information, plase read the help."
                        $parameter["Skip"] = $StartIndex
                    }
                    if ($MaxResults) {
                        Write-Warning "[$($MyInvocation.MyCommand.Name)] The parameter '-MaxResults' has been marked as deprecated. For more information, plase read the help."
                        $parameter["First"] = $MaxResults
                    }

                    Write-Debug "[$($MyInvocation.MyCommand.Name)] Invoking JiraMethod with `$parameter"
                    $result = Invoke-JiraMethod @parameter

                    Write-Output (ConvertTo-JiraBoard -InputObject $result)
                }
            }
        }
    }

    end {
        Write-Verbose "[$($MyInvocation.MyCommand.Name)] Complete"
    }
}
