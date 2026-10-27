function Add-JiraIssueAttachment {
    # .ExternalHelp ..\JiraPS-help.xml
    [CmdletBinding( SupportsShouldProcess )]
    param(
        [Parameter( Mandatory, Position = 0, ValueFromPipeline, ValueFromPipelineByPropertyName )]
        [ValidateNotNull()]
        [AtlassianPS.JiraPS.IssueTransformation()]
        [Alias('Key')]
        [AtlassianPS.JiraPS.Issue]
        $Issue,

        [Parameter( Mandatory, Position = 1, ValueFromPipeline, ValueFromPipelineByPropertyName )]
        [ValidateScript(
            {
                if (-not (Test-Path $_ -PathType Leaf)) {
                    $exception = ([System.ArgumentException]"File not found") #fix code highlighting]
                    $errorId = 'ParameterValue.FileNotFound'
                    $errorCategory = 'ObjectNotFound'
                    $errorTarget = $_
                    $errorItem = New-Object -TypeName System.Management.Automation.ErrorRecord $exception, $errorId, $errorCategory, $errorTarget
                    $errorItem.ErrorDetails = "No file could be found with the provided path '$_'."
                    $PSCmdlet.ThrowTerminatingError($errorItem)
                }
                else { return $true }
            }
        )]
        [Alias('InFile', 'FullName', 'Path')]
        [String[]]
        $FilePath,

        [Parameter()]
        [System.Management.Automation.PSCredential]
        [System.Management.Automation.Credential()]
        $Credential,

        [Switch]
        $PassThru,

        [Alias('Session')][AtlassianPS.Connection]$Connection,

        [Alias('Server', 'ServerName')]
        [ArgumentCompleter( {
                param($commandName, $parameterName, $wordToComplete)
                AtlassianPS.Configuration\Get-AtlassianConnection -Product Jira |
                    Where-Object { $_.Name -like "$wordToComplete*" } |
                    ForEach-Object { $_.Name }
            }
        )]
        [String]
        $ConnectionName,

        [Uri]
        $Uri,

        [Alias('Email')][String]$EmailAddress,

        [Object]
        $ApiToken,

        [Alias('PAT', 'BearerToken')][Object]$PersonalAccessToken,

        [Switch]
        $Anonymous
    )

    begin {
        try {
            Write-Verbose "[$($MyInvocation.MyCommand.Name)] Function started"

            $RequestContext = Resolve-JiraOperationContext -BoundParameters $PSBoundParameters

            $resourceURi = "{0}/attachments"
        }
        catch {
            if ($RequestContext -and $RequestContext.State -eq 'Standalone') { $RequestContext.Dispose() }
            throw
        }
    }

    process {
        try {
            Write-DebugMessage "[$($MyInvocation.MyCommand.Name)] ParameterSetName: $($PsCmdlet.ParameterSetName)"

            $issueObj = Resolve-JiraIssueObject -InputObject $Issue -RequestContext $RequestContext

            foreach ($file in $FilePath) {
                $file = Resolve-FilePath -Path $file

                $fileName = Split-Path -Path $file -Leaf

                $headers = @{
                    'X-Atlassian-Token' = 'nocheck'
                }

                $parameter = @{
                    URI     = $resourceURi -f $issueObj.RestURL
                    Method  = "POST"
                    InFile  = $file
                    Headers = $headers
                }
                Write-Debug "[$($MyInvocation.MyCommand.Name)] Invoking JiraMethod with `$parameter"
                if ($PSCmdlet.ShouldProcess($IssueObj.Key, "Adding attachment '$($fileName)'.")) {
                    $rawResult = Invoke-JiraMethod -RequestContext $RequestContext @parameter

                    if ($PassThru) { Write-Output (ConvertTo-JiraAttachment -InputObject $rawResult) }
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
