function Get-JiraStatus {
    # .ExternalHelp ..\JiraPS-help.xml
    [CmdletBinding( DefaultParameterSetName = '_All' )]
    param(
        [Parameter( Position = 0, Mandatory, ValueFromPipeline, ParameterSetName = '_Search' )]
        [Alias('IdOrName')]
        [AtlassianPS.JiraPS.StatusTransformation()]
        [AtlassianPS.JiraPS.Status[]]
        $Status,

        [Parameter()]
        [System.Management.Automation.PSCredential]
        [System.Management.Automation.Credential()]
        $Credential,

        [Alias('Session')]
        [AtlassianPS.Connection]$Connection,

        [Alias('Server', 'ServerName')]
        [ArgumentCompleter({
                param($commandName, $parameterName, $wordToComplete)
                AtlassianPS.Configuration\Get-AtlassianConnection -Product Jira |
                    Where-Object { $_.Name -like "$wordToComplete*" } |
                    ForEach-Object { $_.Name }
            })]
        [String]$ConnectionName,

        [Uri]$Uri,

        [Alias('Email')]
        [String]$EmailAddress,

        [Object]$ApiToken,

        [Alias('PAT', 'BearerToken')]
        [Object]$PersonalAccessToken,

        [Switch]$Anonymous
    )

    begin {
        try {
            Write-Verbose "[$($MyInvocation.MyCommand.Name)] Function started"

            $RequestContext = Resolve-JiraOperationContext -BoundParameters $PSBoundParameters

            $server = $RequestContext.BaseUri.AbsoluteUri.TrimEnd('/')

            $resourceURi = "$server/rest/api/latest/status{0}"
        }
        catch {
            if ($RequestContext -and $RequestContext.State -eq 'Standalone') { $RequestContext.Dispose() }
            throw
        }
    }

    process {
        try {
            Write-DebugMessage "[$($MyInvocation.MyCommand.Name)] ParameterSetName: $($PsCmdlet.ParameterSetName)"

            switch ($PSCmdlet.ParameterSetName) {
                '_All' {
                    $parameter = @{
                        URI    = $resourceURi -f ""
                        Method = "GET"

                    }
                    Write-Debug "[$($MyInvocation.MyCommand.Name)] Invoking JiraMethod with `$parameter"
                    $result = Invoke-JiraMethod -RequestContext $RequestContext @parameter

                    Write-Output (ConvertTo-JiraStatus -InputObject $result)
                }
                '_Search' {
                    foreach ($_status in $Status) {
                        Write-Verbose "[$($MyInvocation.MyCommand.Name)] Processing [$_status]"
                        Write-Debug "[$($MyInvocation.MyCommand.Name)] Processing `$_status [$_status]"

                        $statusIdentifier = if ($null -ne $_status.Id) { [String] $_status.Id }
                        else { $_status.Name }
                        $encodedIdentifier = ConvertTo-URLEncoded -InputString $statusIdentifier

                        $parameter = @{
                            URI    = $resourceURi -f "/$encodedIdentifier"
                            Method = "GET"

                        }
                        Write-Debug "[$($MyInvocation.MyCommand.Name)] Invoking JiraMethod with `$parameter"
                        $result = Invoke-JiraMethod -RequestContext $RequestContext @parameter

                        Write-Output (ConvertTo-JiraStatus -InputObject $result)
                    }
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
