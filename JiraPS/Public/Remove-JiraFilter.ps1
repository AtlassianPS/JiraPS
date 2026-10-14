function Remove-JiraFilter {
    # .ExternalHelp ..\JiraPS-help.xml
    [CmdletBinding( ConfirmImpact = 'Medium', SupportsShouldProcess )]
    param(
        [Parameter( Position = 0, Mandatory, ValueFromPipeline )]
        [ValidateNotNullOrEmpty()]
        [Alias('Id', 'FilterId')]
        [AtlassianPS.JiraPS.FilterTransformation()]
        [AtlassianPS.JiraPS.Filter[]]
        $InputObject,

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
        }
        catch {
            if ($RequestContext -and $RequestContext.State -eq 'Standalone') { $RequestContext.Dispose() }
            throw
        }
    }

    process {
        try {
            Write-DebugMessage "[$($MyInvocation.MyCommand.Name)] ParameterSetName: $($PsCmdlet.ParameterSetName)"

            $filters = foreach ($item in $InputObject) {
                if ($item.RestUrl) { $item }
                else {
                    Get-JiraFilterOperation -Id $item.Id -RequestContext $RequestContext -ErrorAction Stop
                }
            }

            foreach ($filter in $filters) {
                Write-Verbose "[$($MyInvocation.MyCommand.Name)] Processing [$filter]"
                Write-Debug "[$($MyInvocation.MyCommand.Name)] Processing `$filter [$filter]"

                $parameter = @{
                    URI    = $filter.RestURL
                    Method = 'DELETE'

                }
                Write-Debug "[$($MyInvocation.MyCommand.Name)] Invoking JiraMethod with `$parameter"
                if ($PSCmdlet.ShouldProcess($filter.Name, "Deleting Filter")) { Invoke-JiraMethod -RequestContext $RequestContext @parameter }
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
