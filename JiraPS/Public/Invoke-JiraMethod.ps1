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
            "JiraVersion"
        )]
        [String]
        $OutputType,

        [Parameter()]
        [System.Management.Automation.PSCredential]
        [System.Management.Automation.Credential()]
        $Credential = [System.Management.Automation.PSCredential]::Empty,

        # [Parameter( DontShow )]
        [ValidateNotNullOrEmpty()]
        [System.Management.Automation.PSCmdlet]
        $Cmdlet = $PSCmdlet
    )

    begin {
        Write-Verbose "[$($MyInvocation.MyCommand.Name)] Function started"

        Set-TlsLevel -Tls12

        Write-DebugMessage "[$($MyInvocation.MyCommand.Name)] ParameterSetName: $($PsCmdlet.ParameterSetName)"
        Write-DebugMessage "[$($MyInvocation.MyCommand.Name)] PSBoundParameters: $($PSBoundParameters | Out-String)"

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

        #region Manage URI
        # Amend query from URI with GetParameter
        $uriQuery = ConvertTo-ParameterHash -Uri $Uri
        $internalGetParameter = Join-Hashtable $uriQuery, $GetParameter

        # And remove it from URI
        [Uri]$Uri = $Uri.GetLeftPart("Path")
        $PaginatedUri = $Uri

        # Use default PageSize
        if (-not $internalGetParameter.ContainsKey("maxResults")) {
            $internalGetParameter["maxResults"] = $script:DefaultPageSize
        }

        # Append GET parameters to URi
        $offset = 0
        if ($PSCmdlet.PagingParameters) {
            if ($PSCmdlet.PagingParameters.Skip) {
                $internalGetParameter["startAt"] = $PSCmdlet.PagingParameters.Skip
                $offset = $PSCmdlet.PagingParameters.Skip
            }
            if ($PSCmdlet.PagingParameters.First -lt $internalGetParameter["maxResults"]) {
                $internalGetParameter["maxResults"] = $PSCmdlet.PagingParameters.First
            }
        }

        [Uri]$PaginatedUri = "{0}{1}" -f $PaginatedUri, (ConvertTo-GetParameter $internalGetParameter)
        #endregion Manage URI

        #region Constructe IWR Parameter
        $splatParameters = @{
            Uri             = $PaginatedUri
            Method          = $Method
            Headers         = $_headers
            ContentType     = $script:DefaultContentType
            UseBasicParsing = $true
            Credential      = $Credential
            ErrorAction     = "Stop"
            Verbose         = $false
        }

        if ($_headers.ContainsKey("Content-Type")) {
            $splatParameters["ContentType"] = $_headers["Content-Type"]
            $splatParameters["Headers"].Remove("Content-Type")
            $_headers.Remove("Content-Type")
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

        Write-Debug "[$($MyInvocation.MyCommand.Name)] Executed WebRequest. Access `$webResponse to see details"
        Test-ServerResponse -InputObject $webResponse -Cmdlet $Cmdlet
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

                    if ($Paging) {
                        # Remove Parameters that don't need propagation
                        $script:PSDefaultParameterValues.Remove("$($MyInvocation.MyCommand.Name):IncludeTotalCount")
                        $null = $PSBoundParameters.Remove("Paging")
                        $null = $PSBoundParameters.Remove("Skip")
                        if (-not $PSBoundParameters["GetParameter"]) {
                            $PSBoundParameters["GetParameter"] = $internalGetParameter
                        }

                        $total = 0
                        do {
                            Write-Verbose "[$($MyInvocation.MyCommand.Name)] Invoking pagination [currentTotal: $total]"

                            $result = Expand-Result -InputObject $response

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

                            # calculate the size of the next page
                            $PSBoundParameters["GetParameter"]["startAt"] = $total + $offset
                            $expectedTotal = $PSBoundParameters["GetParameter"]["startAt"] + $pageSize
                            if ($expectedTotal -gt $PSCmdlet.PagingParameters.First) {
                                $reduceBy = $expectedTotal - $PSCmdlet.PagingParameters.First
                                $PSBoundParameters["GetParameter"]["maxResults"] = $pageSize - $reduceBy
                            }

                            # Inquire the next page
                            $response = Invoke-JiraMethod @PSBoundParameters

                            $result = Expand-Result -InputObject $response
                        } while (@($result).Count -gt 0)

                        if ($PSCmdlet.PagingParameters.IncludeTotalCount) {
                            [double]$Accuracy = 1.0
                            $PSCmdlet.PagingParameters.NewTotalCount($total, $Accuracy)
                        }
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
