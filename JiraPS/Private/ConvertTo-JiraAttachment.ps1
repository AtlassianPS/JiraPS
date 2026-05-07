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
            if ($i -is [AtlassianPS.JiraPS.Attachment]) {
                $i
                continue
            }

            Write-Debug "[$($MyInvocation.MyCommand.Name)] Converting `$InputObject to AtlassianPS.JiraPS.Attachment"

            $props = @{
                'ID'        = $i.id
                'Self'      = ConvertTo-JiraUriValue $i.self
                'FileName'  = $i.FileName
                'Author'    = ConvertTo-JiraUser -InputObject $i.Author
                'Created'   = ConvertTo-JiraDateTimeOffsetValue $i.created
                'Size'      = ConvertTo-JiraNullableInt64 $i.size
                'MimeType'  = $i.mimeType
                'Content'   = ConvertTo-JiraUriValue $i.content
                'Thumbnail' = ConvertTo-JiraUriValue $i.thumbnail
            }

            [AtlassianPS.JiraPS.Attachment]$props
        }
    }
}
