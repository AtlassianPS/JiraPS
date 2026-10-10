function ConvertTo-JiraIssueHistoryEntry {
    [CmdletBinding()]
    [OutputType([AtlassianPS.JiraPS.IssueHistoryEntry])]
    param(
        [Parameter(ValueFromPipeline)]
        [PSObject[]]
        $InputObject
    )

    process {
        foreach ($i in $InputObject) {
            if ($null -eq $i) { continue }
            $items = foreach ($item in $i.items) {
                if ($null -eq $item) { continue }
                [AtlassianPS.JiraPS.IssueHistoryItem]@{
                    Field      = $item.field
                    FieldType  = $item.fieldtype
                    FieldId    = $item.fieldId
                    From       = $item.from
                    FromString = $item.fromString
                    To         = $item.to
                    ToString   = $item.toString
                }
            }
            [AtlassianPS.JiraPS.IssueHistoryEntry]@{
                Id      = $i.id
                Author  = if ($i.author) { ConvertTo-JiraUser $i.author } else { $null }
                Created = ConvertTo-JiraDateTimeOffsetValue $i.created
                Items   = [AtlassianPS.JiraPS.IssueHistoryItem[]]@($items)
            }
        }
    }
}
