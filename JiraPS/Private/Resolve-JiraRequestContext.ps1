function Resolve-JiraRequestContext {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [Uri]
        $Uri,

        [Hashtable]
        $GetParameter = @{},

        [Parameter(Mandatory)]
        [ValidateRange(1, [int]::MaxValue)]
        [int]
        $DefaultPageSize,

        [System.Management.Automation.PSCmdlet]
        $Cmdlet
    )

    $providedUriValue = $Uri.OriginalString
    if (-not $Uri.IsAbsoluteUri) {
        if (-not $providedUriValue.StartsWith('/')) {
            $errorParameter = @{
                Cmdlet       = $Cmdlet
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
                Cmdlet       = $Cmdlet
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
            Cmdlet       = $Cmdlet
            Exception    = [System.ArgumentException]::new("Invoke-JiraMethod: -Uri must be an absolute URI. Got '$providedUriValue'.")
            ErrorId      = 'ParameterValue.UriMustBeAbsolute'
            Category     = [System.Management.Automation.ErrorCategory]::InvalidArgument
            TargetObject = $providedUriValue
        }
        ThrowError @errorParameter
    }

    $uriQuery = ConvertTo-ParameterHash -Uri $Uri
    $internalGetParameter = Join-Hashtable $uriQuery, $GetParameter

    [Uri]$resolvedUri = $Uri.GetLeftPart("Path")

    if (-not $internalGetParameter.ContainsKey("maxResults")) {
        $internalGetParameter["maxResults"] = $DefaultPageSize
    }

    if ($Cmdlet -and $Cmdlet.PagingParameters) {
        if ($Cmdlet.PagingParameters.Skip) {
            $internalGetParameter["startAt"] = $Cmdlet.PagingParameters.Skip
        }

        if ($Cmdlet.PagingParameters.First -lt $internalGetParameter["maxResults"]) {
            $internalGetParameter["maxResults"] = $Cmdlet.PagingParameters.First
        }
    }

    [Uri]$paginatedUri = "{0}{1}" -f $resolvedUri, (ConvertTo-GetParameter $internalGetParameter)

    [PSCustomObject]@{
        Uri          = $resolvedUri
        PaginatedUri = $paginatedUri
        GetParameter = $internalGetParameter
    }
}
