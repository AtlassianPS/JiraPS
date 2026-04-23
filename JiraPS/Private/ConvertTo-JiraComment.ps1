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
                RestUrl    = $i.self
            }

            if ($i.author) {
                $hash.Author = ConvertTo-JiraUser -InputObject $i.author
            }

            if ($i.updateAuthor) {
                $hash.UpdateAuthor = ConvertTo-JiraUser -InputObject $i.updateAuthor
            }

            if ($i.created) {
                $hash.Created = (Get-Date ($i.created))
            }

            if ($i.updated) {
                $hash.Updated = (Get-Date ($i.updated))
            }

            [AtlassianPS.JiraPS.Comment]$hash
        }
    }
}
