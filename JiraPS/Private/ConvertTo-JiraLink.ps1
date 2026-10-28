function ConvertTo-JiraLink {
    <#
    .SYNOPSIS
        Convert Jira response data to AtlassianPS.JiraPS.Link objects.
    #>
    [CmdletBinding()]
    [OutputType([AtlassianPS.JiraPS.Link])]
    param(
        [Parameter( ValueFromPipeline )]
        [PSObject[]]
        $InputObject
    )

    process {
        foreach ($i in $InputObject) {
            if ($null -eq $i) { continue }
            Write-DebugMessage "Converting `$InputObject to AtlassianPS.JiraPS.Link"

            $props = @{
                'Id'      = ConvertTo-JiraNullableInt64 $i.id
                'RestUrl' = [uri]$i.self
            }

            if ($i.globalId) { $props.GlobalId = $i.globalId }

            if ($i.application) {
                $props.Application = [AtlassianPS.JiraPS.LinkApplication]@{
                    type = $i.application.type
                    name = $i.application.name
                }
            }

            if ($i.relationship) { $props.Relationship = $i.relationship }

            if ($i.object) {
                $icon = if ($i.object.icon) {
                    [AtlassianPS.JiraPS.RemoteLinkIcon]@{
                        title    = $i.object.icon.title
                        url16x16 = $i.object.icon.url16x16
                    }
                }
                else { $null }

                $statusIcon = if ($i.object.status.icon) {
                    [AtlassianPS.JiraPS.RemoteLinkIcon]@{
                        link     = $i.object.status.icon.link
                        title    = $i.object.status.icon.title
                        url16x16 = $i.object.status.icon.url16x16
                    }
                }
                else { $null }

                $status = if ($i.object.status) {
                    [AtlassianPS.JiraPS.RemoteLinkStatus]@{
                        resolved = if ($null -ne $i.object.status.resolved) { [System.Convert]::ToBoolean($i.object.status.resolved) }
                        else { $null }
                        icon     = $statusIcon
                    }
                }
                else { $null }

                $props.RemoteObject = [AtlassianPS.JiraPS.RemoteLinkObject]@{
                    url     = $i.object.url
                    title   = $i.object.title
                    summary = $i.object.summary
                    icon    = $icon
                    status  = $status
                }
            }

            [AtlassianPS.JiraPS.Link]$props
        }
    }
}
