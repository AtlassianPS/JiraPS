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
            Write-Debug "[$($MyInvocation.MyCommand.Name)] Converting `$InputObject to custom object"

            $result = [AtlassianPS.JiraPS.Comment]@{
                ID         = $i.id
                Body       = ConvertFrom-AtlassianDocumentFormat -InputObject $i.body
                Visibility = $i.visibility
                RestUrl    = $i.self
            }

            if ($i.author) {
                $result.Author = ConvertTo-JiraUser -InputObject $i.author
            }

            if ($i.updateAuthor) {
                $result.UpdateAuthor = ConvertTo-JiraUser -InputObject $i.updateAuthor
            }

            if ($i.created) {
                $result.Created = (Get-Date ($i.created))
            }

            if ($i.updated) {
                $result.Updated = (Get-Date ($i.updated))
            }

            Add-LegacyTypeAlias -InputObject $result -LegacyName 'JiraPS.Comment'
        }
    }
}
