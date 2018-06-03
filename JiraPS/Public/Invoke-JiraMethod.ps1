function Invoke-JiraMethod {
    #Requires -Version 3
    [CmdletBinding( SupportsPaging )]
    param
    (
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

        [Hashtable]$GetParameter = @{},

        [Switch]$Paging,

        [String]
        $InFile,

        [String]
        $OutFile,

        [Switch]
        $StoreSession,

        [ValidateSet("JiraIssue")]
        [String]
        $OutputType,

        [Parameter()]
        [System.Management.Automation.PSCredential]
        [System.Management.Automation.Credential()]
        $Credential = [System.Management.Automation.PSCredential]::Empty,

        [ValidateNotNullOrEmpty()]
        [System.Management.Automation.PSCmdlet]
        $Cmdlet = $PSCmdlet
    )

    begin {
        Write-Verbose "[$($MyInvocation.MyCommand.Name)] Function started"

        Write-DebugMessage "[$($MyInvocation.MyCommand.Name)] ParameterSetName: $($PsCmdlet.ParameterSetName)"
        Write-DebugMessage "[$($MyInvocation.MyCommand.Name)] PSBoundParameters: $($PSBoundParameters | Out-String)"

        # load DefaultParameters for Invoke-WebRequest
        # as the global PSDefaultParameterValues is not used
        $PSDefaultParameterValues = $global:PSDefaultParameterValues

        # Construct the Headers with the folling priority:
        # - Headers passes as parameters
        # - User's Headers in $PSDefaultParameterValues
        # - Module's default Headers
        $_headers = $script:DefaultHeaders
        if ($PSDefaultParameterValues.ContainsKey("Invoke-WebRequest:Headers")) {
            $userSpecificHeaders = $PSDefaultParameterValues["Invoke-WebRequest:Headers"]
            foreach ($item in $userSpecificHeaders.Key) { $_headers[$item] = $userSpecificHeaders[$item] }
        }
        foreach ($item in $Headers.Key) { $_headers[$item] = $Headers[$item] }

        # Amend query from URI with GetParameter
        $uriQuery = ConvertTo-ParameterHash -Uri $Uri
        foreach ($item in $uriQuery.Keys) { $GetParameter[$item] = $uriQuery[$item] }
        # And remove it from URI
        [Uri]$Uri = $Uri.GetLeftPart("Path")
        $PaginatedUri = $Uri

        # Use default PageSize
        if (-not $GetParameter.ContainsKey("maxResults")) {
            $GetParameter["maxResults"] = $script:DefaultPageSize
        }

        # Append GET parameters to URi
        if ($PSCmdlet.PagingParameters) {
            if ($PSCmdlet.PagingParameters.Skip) {
                $GetParameter["startAt"] = $PSCmdlet.PagingParameters.Skip
            }
            if ($PSCmdlet.PagingParameters.First -lt $GetParameter["maxResults"]) {
                $GetParameter["maxResults"] = $PSCmdlet.PagingParameters.First
            }
        }

        [Uri]$PaginatedUri = "$PaginatedUri$(ConvertTo-GetParameter $GetParameter)"

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
            $_headers.Remove("Content-Type")
            $splatParameters["Headers"] = $_headers
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

        if ($StoreSession) {
            $splatParameters["SessionVariable"] = "newSessionVar"
            $splatParameters.Remove("WebSession")
        }

        if ((-not $Credential) -or ($Credential -eq [System.Management.Automation.PSCredential]::Empty)) {
            $splatParameters.Remove("Credential")
            if ($session = Get-JiraSession -ErrorAction SilentlyContinue) {
                $splatParameters["WebSession"] = $session.WebSession
            }
        }

        if ($InFile) {
            $splatParameters["InFile"] = $InFile
        }
        if ($OutFile) {
            $splatParameters["OutFile"] = $OutFile
        }

        # Invoke the API
        Write-Verbose "[$($MyInvocation.MyCommand.Name)] $($splatParameters.Method) $($splatParameters.Uri)"
        Write-Debug "[$($MyInvocation.MyCommand.Name)] Invoke-WebRequest with `$splatParameters: $($splatParameters | Out-String)"
        try {
            $webResponse = Invoke-WebRequest @splatParameters
        }
        catch {
            Write-Verbose "[$($MyInvocation.MyCommand.Name)] Failed to get an answer from the server"
            # Invoke-WebRequest is hard-coded to throw an exception if the Web request returns a 4xx or 5xx error.
            # This is the best workaround I can find to retrieve the actual results of the request.
            $webResponse = $_
            # ErrorDetails behavior is erratic and may not always be available
            # See https://windowsserver.uservoice.com/forums/301869-powershell/suggestions/17142518--errordetails-is-null-when-invoke-webrequest-or
            # PSv6+ appears to be unaffected
            if ($webResponse.ErrorDetails) {
                $responseBody = $webResponse.ErrorDetails.Message
            }
            else {
                $webResponse = $webResponse.Exception.Response
            }
        }

        if ($WebResponse.ErrorDetails) {
            Test-ServerResponse -InputObject $webResponse.Exception.Response -Cmdlet $Cmdlet
        } Else {
            Test-ServerResponse -InputObject $webResponse -Cmdlet $Cmdlet
        }



        Write-Debug "[$($MyInvocation.MyCommand.Name)] Executed WebRequest. Access `$webResponse to see details"

        if ($webResponse) {
            # In PowerShellCore (v6+) the StatusCode of an exception is somewhere else
            if (-not ($statusCode = $webResponse.StatusCode)) {
                $statusCode = $webresponse.Exception.Response.StatusCode
            }
            Write-Verbose "[$($MyInvocation.MyCommand.Name)] Status code: $($statusCode)"

            if ($statusCode.value__ -ge 400) {
                if ((!($responseBody)) -and ($webResponse | Get-Member -Name "GetResponseStream")) {
                    # Retrieve body of HTTP response - this contains more useful information about exactly why the error occurred
                    $readStream = New-Object -TypeName System.IO.StreamReader -ArgumentList ($webResponse.GetResponseStream())
                    $responseBody = $readStream.ReadToEnd()
                    $readStream.Close()
                }

                If ($responseBody) {
                    # Clear the body in case it is not a JSON (but rather html)
                    if ($responseBody -match "^[\s\t]*\<html\>") { $responseBody = '{"errorMessages": "Invalid server response. HTML returned."}' }

                    Write-Verbose "[$($MyInvocation.MyCommand.Name)] Retrieved body of HTTP response for more information about the error (`$responseBody)"
                    Write-Debug "[$($MyInvocation.MyCommand.Name)] Got the following error as `$responseBody"
                    try {
                        $result = ConvertFrom-Json -InputObject $responseBody

                    } catch [ArgumentException] { # handle $responseBody being neither JSON nor HTML
                        $result = [PSCustomObject]@{
                            errorMessages = @(
                                $responseBody
                            )
                        }
                    }

                }

            }
            else {
                if ($StoreSession) {
                    return ConvertTo-JiraSession -Session $newSessionVar -Username $Credential.UserName
                }

                if ($webResponse.Content) {
                    $response = ConvertFrom-Json ([Text.Encoding]::UTF8.GetString($webResponse.RawContentStream.ToArray()))

                    if ($Paging) {
                        # Remove Parameters that don't need propagation
                        $script:PSDefaultParameterValues.Remove("$($MyInvocation.MyCommand.Name):IncludeTotalCount")
                        $null = $PSBoundParameters.Remove("Paging")
                        $null = $PSBoundParameters.Remove("Skip")
                        if (-not $PSBoundParameters["GetParameter"]) {
                            $PSBoundParameters["GetParameter"] = $GetParameter
                        }

                        $total = 0
                        do {
                            Write-Verbose "[$($MyInvocation.MyCommand.Name)] Invoking pagination [currentTotal: $total]"

                            foreach ($container in $script:PagingContainers) {
                                if (($response) -and ($response | Get-Member -Name $container)) {
                                    $result = $response.$container
                                }
                            }

                            $total += $result.Count
                            Write-DebugMessage "[$($MyInvocation.MyCommand.Name)] New total: $total"
                            $pageSize = $response.maxResults
                            Write-DebugMessage "[$($MyInvocation.MyCommand.Name)] New pageSize: $pageSize"

                            if ($total -gt $PSCmdlet.PagingParameters.First) {
                                Write-DebugMessage "[$($MyInvocation.MyCommand.Name)] Only output the first $($PSCmdlet.PagingParameters.First % $pageSize) of page"
                                $result = $result | Select-Object -First ($PSCmdlet.PagingParameters.First % $pageSize)
                            }

                            $converter = "ConvertTo-$($OutputType)"
                            if (Test-Path function:\$converter) {
                                # Results shall be casted to custom objects (see ValidateSet)
                                Write-Verbose "[$($MyInvocation.MyCommand.Name)] Outputting results as $($OutputType)"
                                Write-Output ($result | & $converter)
                            }
                            else {
                                Write-Output ($result)
                            }

                            if ($total -ge $PSCmdlet.PagingParameters.First) {
                                Write-DebugMessage "[$($MyInvocation.MyCommand.Name)] breaking as $total is more than $($PSCmdlet.PagingParameters.First)"
                                break
                            }

                            # calculate the size of the next page
                            Write-DebugMessage "[$($MyInvocation.MyCommand.Name)] next page begins at $total"
                            $PSBoundParameters["GetParameter"]["startAt"] = $total
                            Write-DebugMessage "[$($MyInvocation.MyCommand.Name)] doesn't it? $($PSBoundParameters["GetParameter"]["startAt"])"
                            $expectedTotal = $PSBoundParameters["GetParameter"]["startAt"] + $pageSize
                            Write-DebugMessage "[$($MyInvocation.MyCommand.Name)] expecting to have $expectedTotal entries in total with next page"
                            if ($expectedTotal -gt $PSCmdlet.PagingParameters.First) {
                                $reduceBy = $expectedTotal - $PSCmdlet.PagingParameters.First
                                Write-DebugMessage "[$($MyInvocation.MyCommand.Name)] reducing next pagesize by $reduceBy"
                                $PSBoundParameters["GetParameter"]["maxResults"] = $pageSize - $reduceBy
                            }

                            # Inquire the next page
                            Write-DebugMessage "[$($MyInvocation.MyCommand.Name)] about to invoke with : $($PSBoundParameters | Out-String)"
                            Write-DebugMessage "[$($MyInvocation.MyCommand.Name)] about to invoke with : $($PSBoundParameters["GetParameter"] | Out-String)"
                            $response = Invoke-JiraMethod @PSBoundParameters

                            # Expand data container of paged results
                            $result = @()
                            foreach ($container in $script:PagingContainers) {
                                if (($response) -and ($response | Get-Member -Name $container)) {
                                    $result = $response.$container
                                }
                            }
                        } while ($result.Count)

                        if ($PSCmdlet.PagingParameters.IncludeTotalCount) {
                            [double]$Accuracy = 1.0
                            $PSCmdlet.PagingParameters.NewTotalCount($total, $Accuracy)
                        }
                    }
                    else {
                        Write-Output $response
                    }
                }
                else {
                    # No content, although statusCode < 400
                    # This could be wanted behavior of the API
                    Write-Verbose "[$($MyInvocation.MyCommand.Name)] No content was returned from."
                }
            }
        }
        else {
            Write-Verbose "[$($MyInvocation.MyCommand.Name)] No Web result object was returned from. This is unusual!"
        }

        if ($result) {
            if (Get-Member -Name "Errors","errorMessages" -InputObject $result -ErrorAction SilentlyContinue) {
                Resolve-JiraError $result -WriteError -Cmdlet $Cmdlet
            }
            else {
                Write-Output $result
            }
        }
    }

    end {
        Write-Verbose "[$($MyInvocation.MyCommand.Name)] Function ended"
    }
}
