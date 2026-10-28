function Invoke-JiraMethod {
    # .ExternalHelp ..\JiraPS-help.xml
    [CmdletBinding(SupportsPaging, SupportsShouldProcess, PositionalBinding = $false, DefaultParameterSetName = 'Connection')]
    param(
        [Parameter(Mandatory, Position = 0)]
        [Uri]
        $Uri,

        [Microsoft.PowerShell.Commands.WebRequestMethod]
        $Method = 'Get',

        [Object]
        $Body,

        [ValidateNotNullOrEmpty()]
        [String]
        $ContentType,

        [ValidateNotNull()]
        [Hashtable]
        $Headers = @{},

        [ValidateNotNull()]
        [Hashtable]
        $QueryParameter = @{},

        [Switch]
        $Paging,

        [ValidateRange(1, [int]::MaxValue)]
        [Int]
        $PageSize = $script:DefaultPageSize,

        [ValidateNotNullOrEmpty()]
        [String]
        $OutFile,

        [Switch]
        $RawResponse,

        [ValidateRange(0, [int]::MaxValue)]
        [Int]
        $TimeoutSec = 100,

        [Parameter(ParameterSetName = 'Connection')]
        [ValidateNotNull()]
        [AtlassianPS.Connection]
        $Connection,

        [Parameter(Mandatory, ParameterSetName = 'NamedConnection')]
        [ValidateNotNullOrEmpty()]
        [String]
        $ConnectionName,

        [Parameter(Mandatory, ParameterSetName = 'Basic')]
        [Parameter(Mandatory, ParameterSetName = 'CloudToken')]
        [Parameter(Mandatory, ParameterSetName = 'PersonalAccessToken')]
        [Parameter(Mandatory, ParameterSetName = 'Anonymous')]
        [ValidateNotNull()]
        [Uri]
        $BaseUri,

        [Parameter(Mandatory, ParameterSetName = 'Basic')]
        [ValidateNotNull()]
        [System.Management.Automation.Credential()]
        [PSCredential]
        $Credential,

        [Parameter(Mandatory, ParameterSetName = 'CloudToken')]
        [ValidateNotNullOrEmpty()]
        [String]
        $EmailAddress,

        [Parameter(Mandatory, ParameterSetName = 'CloudToken')]
        [ValidateNotNull()]
        [Object]
        $ApiToken,

        [Parameter(Mandatory, ParameterSetName = 'PersonalAccessToken')]
        [Alias('PAT', 'BearerToken')]
        [ValidateNotNull()]
        [Object]
        $PersonalAccessToken,

        [Parameter(Mandatory, ParameterSetName = 'Anonymous')]
        [Switch]
        $Anonymous
    )

    process {
        if (-not $Paging -and @('PageSize', 'First', 'Skip', 'IncludeTotalCount' | Where-Object { $PSBoundParameters.ContainsKey($_) }).Count) {
            throw 'PageSize, First, Skip and IncludeTotalCount require -Paging.'
        }
        if (@($Paging, $RawResponse, [bool]$OutFile | Where-Object { $_ }).Count -gt 1) {
            throw 'Choose only one response mode: Paging, RawResponse or OutFile.'
        }
        if ($Paging -and $Method -ne 'Get') { throw 'Automatic paging supports GET requests. Manage continuation explicitly for other methods.' }
        if ($PSBoundParameters.ContainsKey('PageSize') -and $QueryParameter.ContainsKey('maxResults')) {
            throw 'Supply PageSize or QueryParameter.maxResults, not both.'
        }
        if ($PSCmdlet.ParameterSetName -eq 'Anonymous' -and -not $Anonymous) { throw 'Supply -Anonymous to request anonymous access.' }

        if ($OutFile) {
            $provider = $null
            $drive = $null
            $OutFile = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($OutFile, [ref]$provider, [ref]$drive)
            if ($provider.Name -ne 'FileSystem') { throw 'OutFile must be a file-system path.' }
            if (Test-Path -LiteralPath $OutFile -PathType Container) { throw 'OutFile must name a file, not a directory.' }
        }
        $target = $Uri.OriginalString.Split('?')[0]
        if ($OutFile) { $target = "$target -> $OutFile" }
        if (($Method -notin @('Get', 'Head', 'Options') -or $OutFile) -and -not $PSCmdlet.ShouldProcess($target, "$Method Jira request")) { return }

        if ($BaseUri) {
            $authentication = Get-JiraAuthenticationParameter -BoundParameters $PSBoundParameters
            $context = New-JiraCandidate -Name Standalone -Uri $BaseUri -Authentication $authentication
        }
        else { $context = Resolve-JiraOperationContext -BoundParameters $PSBoundParameters }
        try {
            if ($BaseUri) { $context.MakeStandalone([Guid]::Empty) }
            $request = @{
                Uri            = $Uri
                Method         = $Method
                GetParameter   = $QueryParameter
                RequestContext = $context
                Cmdlet         = $PSCmdlet
            }
            foreach ($key in @('Body', 'ContentType', 'Headers', 'Paging', 'PageSize', 'RawResponse', 'TimeoutSec', 'First', 'Skip', 'IncludeTotalCount')) {
                if ($PSBoundParameters.ContainsKey($key)) { $request[$key] = $PSBoundParameters[$key] }
            }
            if ($OutFile) { $request['OutFile'] = $OutFile }
            Invoke-JiraRequest @request
        }
        finally {
            if ($BaseUri) { $context.Dispose() }
        }
    }
}
