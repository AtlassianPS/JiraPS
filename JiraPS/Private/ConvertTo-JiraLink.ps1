function ConvertTo-JiraLink {
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
            Write-Debug "[$($MyInvocation.MyCommand.Name)] Converting `$InputObject to AtlassianPS.JiraPS.Link"

            $props = @{
                'Id'      = ConvertTo-JiraNullableInt64 $i.id
                'RestUrl' = [uri]$i.self
            }

            if ($i.globalId) {
                $props.GlobalId = $i.globalId
            }

            if ($i.application) {
                $props.Application = [AtlassianPS.JiraPS.LinkApplication]@{
                    type = $i.application.type
                    name = $i.application.name
                }
            }

            if ($i.relationship) {
                $props.Relationship = $i.relationship
            }

            if ($i.object) {
                if ($i.object.icon) {
                    $icon = [AtlassianPS.JiraPS.RemoteLinkIcon]@{
                        title    = $i.object.icon.title
                        url16x16 = $i.object.icon.url16x16
                    }
                }
                else { $icon = $null }

                if ($i.object.status.icon) {
                    $statusIcon = [AtlassianPS.JiraPS.RemoteLinkIcon]@{
                        link     = $i.object.status.icon.link
                        title    = $i.object.status.icon.title
                        url16x16 = $i.object.status.icon.url16x16
                    }
                }
                else { $statusIcon = $null }

                if ($i.object.status) {
                    $status = [AtlassianPS.JiraPS.RemoteLinkStatus]@{
                        resolved = if ($null -ne $i.object.status.resolved) { [System.Convert]::ToBoolean($i.object.status.resolved) } else { $null }
                        icon     = $statusIcon
                    }
                }
                else { $status = $null }

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
