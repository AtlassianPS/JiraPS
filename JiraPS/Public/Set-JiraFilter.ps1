function Set-JiraFilter {
    # .ExternalHelp ..\JiraPS-help.xml
    [CmdletBinding( SupportsShouldProcess )]
    param(
        [Parameter( Mandatory, ValueFromPipeline )]
        [ValidateNotNullOrEmpty()]
        [AtlassianPS.JiraPS.FilterTransformation()]
        [AtlassianPS.JiraPS.Filter]
        $InputObject,

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [String]
        $Name,

        [Parameter()]
        [String]
        $Description,

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [String]
        $JQL,

        [Parameter()]
        [Alias('Favourite')]
        [Bool]
        $Favorite,

        [Parameter()]
        [System.Management.Automation.PSCredential]
        [System.Management.Automation.Credential()]
        $Credential,

        [Alias('Session')][AtlassianPS.Connection]$Connection,

        [Alias('Server', 'ServerName')]
        [ArgumentCompleter({
                param($commandName, $parameterName, $wordToComplete)
                AtlassianPS.Configuration\Get-AtlassianConnection -Product Jira |
                    Where-Object { $_.Name -like "$wordToComplete*" } |
                    ForEach-Object { $_.Name }
            })][String]$ConnectionName,

        [Uri]$Uri,

        [Alias('Email')][String]$EmailAddress,

        [Object]$ApiToken,

        [Alias('PAT', 'BearerToken')][Object]$PersonalAccessToken,

        [Switch]$Anonymous
    )
    begin {
        try {
            Write-Verbose "[$($MyInvocation.MyCommand.Name)] Function started"

            $RequestContext = Resolve-JiraOperationContext -BoundParameters $PSBoundParameters
        }
        catch {
            if ($RequestContext -and $RequestContext.State -eq 'Standalone') { $RequestContext.Dispose() }
            throw
        }
    }

    process {
        try {
            Write-DebugMessage "[$($MyInvocation.MyCommand.Name)] ParameterSetName: $($PsCmdlet.ParameterSetName)"

            if ($InputObject -and -not $InputObject.RestUrl) {
                $InputObject = Get-JiraFilterOperation -Id $InputObject.Id -RequestContext $RequestContext -ErrorAction Stop
            }

            $requestBody = @{}
            if ($PSCmdlet.MyInvocation.BoundParameters.ContainsKey("Name")) { $requestBody["name"] = $Name }
            if ($PSCmdlet.MyInvocation.BoundParameters.ContainsKey("Description")) { $requestBody["description"] = $Description }
            if ($PSCmdlet.MyInvocation.BoundParameters.ContainsKey("JQL")) { $requestBody["jql"] = $JQL }
            if ($PSCmdlet.MyInvocation.BoundParameters.ContainsKey("Favorite")) { $requestBody["favourite"] = $Favorite }

            if ($requestBody.Keys.Count) {
                $parameter = @{
                    URI    = $InputObject.RestURL
                    Method = "PUT"
                    Body   = ConvertTo-Json -InputObject $requestBody

                }
                Write-Debug "[$($MyInvocation.MyCommand.Name)] Invoking JiraMethod with `$parameter"
                if ($PSCmdlet.ShouldProcess($InputObject.Name, "Update Filter")) {
                    $result = Invoke-JiraMethod -RequestContext $RequestContext @parameter

                    Write-Output (ConvertTo-JiraFilter -InputObject $result)
                }
            }
        }
        catch {
            if ($RequestContext -and $RequestContext.State -eq 'Standalone') { $RequestContext.Dispose() }
            throw
        }
    }

    end {
        try {
            Write-Verbose "[$($MyInvocation.MyCommand.Name)] Complete"
        }
        finally {
            if ($RequestContext.State -eq 'Standalone') { $RequestContext.Dispose() }
        }
    }
}
