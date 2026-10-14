function Set-JiraIssueLabel {
    # .ExternalHelp ..\JiraPS-help.xml
    [CmdletBinding( SupportsShouldProcess, DefaultParameterSetName = 'ReplaceLabels' )]
    param(
        [Parameter( Mandatory, Position = 0, ValueFromPipeline, ValueFromPipelineByPropertyName )]
        [ValidateNotNull()]
        [AtlassianPS.JiraPS.IssueTransformation()]
        [Alias('Key')]
        [AtlassianPS.JiraPS.Issue]
        $Issue,

        [Parameter( Mandatory, ParameterSetName = 'ReplaceLabels' )]
        [Alias('Label', 'Replace')]
        [String[]]
        $Set,

        [Parameter( ParameterSetName = 'ModifyLabels' )]
        [String[]]
        $Add,

        [Parameter( ParameterSetName = 'ModifyLabels' )]
        [String[]]
        $Remove,

        [Parameter( Mandatory, ParameterSetName = 'ClearLabels' )]
        [Switch]
        $Clear,

        [Parameter()]
        [System.Management.Automation.PSCredential]
        [System.Management.Automation.Credential()]
        $Credential,

        [Switch]
        $PassThru,

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
        Write-Verbose "[$($MyInvocation.MyCommand.Name)] Function started"
        $requestContext = Resolve-JiraOperationContext -BoundParameters $PSBoundParameters
        $operationParameters = @{ RequestContext = $requestContext }
        foreach ($parameterName in $PSBoundParameters.Keys) {
            if ($parameterName -notin @(
                    'Connection',
                    'ConnectionName',
                    'Uri',
                    'Credential',
                    'EmailAddress',
                    'ApiToken',
                    'PersonalAccessToken',
                    'Anonymous'
                )
            ) {
                $operationParameters[$parameterName] = $PSBoundParameters[$parameterName]
            }
        }
        try {
            $operation = { Set-JiraIssueLabelOperation @operationParameters }.GetSteppablePipeline($MyInvocation.CommandOrigin)
            $operation.Begin($PSCmdlet)
        }
        catch {
            if ($requestContext.State -eq 'Standalone') { $requestContext.Dispose() }
            throw
        }
    }

    process {
        try { $operation.Process($_) }
        catch {
            if ($requestContext.State -eq 'Standalone') { $requestContext.Dispose() }
            throw
        }
    }

    end {
        try { $operation.End() }
        finally {
            if ($requestContext.State -eq 'Standalone') { $requestContext.Dispose() }
        }
        Write-Verbose "[$($MyInvocation.MyCommand.Name)] Complete"
    }
}
