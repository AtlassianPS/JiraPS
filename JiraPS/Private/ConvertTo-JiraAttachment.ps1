function ConvertTo-JiraAttachment {
    [CmdletBinding()]
    [OutputType([AtlassianPS.JiraPS.Attachment])]
    param(
        [Parameter( ValueFromPipeline )]
        [PSObject[]]
        $InputObject
    )

    process {
        foreach ($i in $InputObject) {
            if ($null -eq $i) { continue }
            if ($i -is [AtlassianPS.JiraPS.Attachment]) { $i; continue }

            Write-Debug "[$($MyInvocation.MyCommand.Name)] Converting `$InputObject to AtlassianPS.JiraPS.Attachment"

            $props = @{
                'ID'        = $i.id
                'Self'      = [uri]$i.self
                'FileName'  = $i.FileName
                'Author'    = if ($null -ne $i.Author) { ConvertTo-JiraUser -InputObject $i.Author } else { $null }
                'Created'   = ConvertTo-JiraDateTimeOffsetValue $i.created
                'Size'      = ConvertTo-JiraNullableInt64 $i.size
                'MimeType'  = $i.mimeType
                'Content'   = [uri]$i.content
                'Thumbnail' = [uri]$i.thumbnail
            }

            [AtlassianPS.JiraPS.Attachment]$props
        }
    }
}
