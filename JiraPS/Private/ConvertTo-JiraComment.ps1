function ConvertTo-JiraComment {
    [CmdletBinding()]
    [OutputType([AtlassianPS.JiraPS.Comment])]
    param(
        [Parameter( ValueFromPipeline )]
        [PSObject[]]
        $InputObject
    )

    process {
        foreach ($i in $InputObject) {
            if ($null -eq $i) { continue }
            Write-Debug "[$($MyInvocation.MyCommand.Name)] Converting `$InputObject to AtlassianPS.JiraPS.Comment"

            $hash = @{
                ID         = $i.id
                Body       = ConvertFrom-AtlassianDocumentFormat -InputObject $i.body
                Visibility = if ($null -ne $i.visibility) { ConvertTo-JiraVisibility $i.visibility } else { $null }
                RestUrl    = [uri]$i.self
            }

            if ($i.renderedBody) { $hash.RenderedBody = [string]$i.renderedBody }

            if ($null -ne $i.properties) {
                $hash.Properties = [AtlassianPS.JiraPS.EntityProperty[]]@(
                    foreach ($property in $i.properties) {
                        [AtlassianPS.JiraPS.EntityProperty]@{ Key = $property.key; Value = $property.value }
                    }
                )
            }

            if ($i.author) { $hash.Author = ConvertTo-JiraUser -InputObject $i.author }

            if ($i.updateAuthor) { $hash.UpdateAuthor = ConvertTo-JiraUser -InputObject $i.updateAuthor }

            if ($i.created) { $hash.Created = ConvertTo-JiraDateTimeOffsetValue $i.created }

            if ($i.updated) { $hash.Updated = ConvertTo-JiraDateTimeOffsetValue $i.updated }

            [AtlassianPS.JiraPS.Comment]$hash
        }
    }
}
