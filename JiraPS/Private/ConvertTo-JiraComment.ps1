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
            Write-Debug "[$($MyInvocation.MyCommand.Name)] Converting `$InputObject to AtlassianPS.JiraPS.Comment"

            $hash = @{
                ID         = $i.id
                Body       = ConvertFrom-AtlassianDocumentFormat -InputObject $i.body
                Visibility = $i.visibility
                RestUrl    = [uri]$i.self
            }

            if ($i.renderedBody) { $hash.RenderedBody = [string]$i.renderedBody }

            if ($i.properties) { $hash.Properties = [object[]]@($i.properties) }

            if ($i.author) { $hash.Author = ConvertTo-JiraUser -InputObject $i.author }

            if ($i.updateAuthor) { $hash.UpdateAuthor = ConvertTo-JiraUser -InputObject $i.updateAuthor }

            if ($i.created) { $hash.Created = ConvertTo-JiraDateTimeOffsetValue $i.created }

            if ($i.updated) { $hash.Updated = ConvertTo-JiraDateTimeOffsetValue $i.updated }

            [AtlassianPS.JiraPS.Comment]$hash
        }
    }
}
