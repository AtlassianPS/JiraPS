function Save-JiraIssueAttachment {
    # .ExternalHelp ..\JiraPS-help.xml
    [CmdletBinding(SupportsShouldProcess)]
    [OutputType([IO.FileInfo])]
    param(
        [Parameter(Mandatory, ValueFromPipeline)]
        [ValidateNotNull()]
        [AtlassianPS.JiraPS.Attachment[]]$Attachment,

        [ValidateNotNullOrEmpty()]
        [String]$Path = '.',

        [Switch]$Force,

        [AtlassianPS.Connection]$Connection
    )

    begin {
        $requestContext = Resolve-JiraOperationContext -BoundParameters $PSBoundParameters
        $provider = $null
        $drive = $null
        $destination = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($Path, [ref]$provider, [ref]$drive)
        if ($provider.Name -ne 'FileSystem') { throw 'Path must be a file-system path.' }
        $isDirectory = Test-Path -LiteralPath $destination -PathType Container
        $fileDestinationUsed = $false
        if (-not $isDirectory -and -not (Test-Path -LiteralPath (Split-Path $destination -Parent) -PathType Container)) {
            throw 'The destination directory must exist.'
        }
    }
    process {
        if (-not $isDirectory -and ($Attachment.Count -gt 1 -or $fileDestinationUsed)) { throw 'Use a directory destination when saving multiple attachments.' }
        $fileDestinationUsed = $true
        foreach ($item in $Attachment) {
            if (-not $item.FileName -or $item.FileName -in @('.', '..') -or $item.FileName -match '[/\\]') {
                throw 'Attachment must contain a file name without path separators.'
            }
            $filename = if ($isDirectory) { Join-Path $destination $item.FileName } else { $destination }
            if ((Test-Path -LiteralPath $filename) -and -not $Force) { throw "Destination exists: $filename. Use -Force to overwrite it." }
            $contentUri = $item.Content
            if ($requestContext.DeploymentType -eq 'Cloud') {
                if ([string]::IsNullOrWhiteSpace($item.ID)) { throw 'Cloud attachment download requires an attachment ID.' }
                $attachmentId = [Uri]::EscapeDataString($item.ID)
                $contentUri = [Uri]::new("/rest/api/3/attachment/content/$($attachmentId)?redirect=false", [UriKind]::Relative)
            }
            if (-not $contentUri) { throw 'Attachment must contain a content URI.' }
            if ($PSCmdlet.ShouldProcess($filename, 'Save Jira attachment')) {
                $null = Invoke-JiraRequest -RequestContext $requestContext -Uri $contentUri -Method Get -OutFile $filename -ErrorAction Stop
                Get-Item -LiteralPath $filename -ErrorAction Stop
            }
        }
    }
}
