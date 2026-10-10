function ConvertTo-JiraIssueSecurityLevel {
    [CmdletBinding()]
    [OutputType([AtlassianPS.JiraPS.IssueSecurityLevel])]
    param(
        [Parameter(ValueFromPipeline)]
        [PSObject[]]
        $InputObject
    )

    process {
        foreach ($i in $InputObject) {
            if ($null -eq $i) { continue }
            [AtlassianPS.JiraPS.IssueSecurityLevel]@{
                Id          = $i.id
                Name        = $i.name
                Description = $i.description
                Self        = [uri]$i.self
            }
        }
    }
}
