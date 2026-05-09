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
            Write-Debug "[$($MyInvocation.MyCommand.Name)] Converting `$InputObject to AtlassianPS.JiraPS.Link"

            $props = @{
                'Id'      = ConvertTo-JiraNullableInt64 $i.id
                'RestUrl' = [uri]$i.self
            }

            if ($i.globalId) {
                $props.GlobalId = $i.globalId
            }

            if ($i.application) {
                $props.Application = New-Object PSObject -Prop @{
                    type = $i.application.type
                    name = $i.application.name
                }
            }

            if ($i.relationship) {
                $props.Relationship = $i.relationship
            }

            if ($i.object) {
                if ($i.object.icon) {
                    $icon = New-Object PSObject -Prop @{
                        title    = $i.object.icon.title
                        url16x16 = $i.object.icon.url16x16
                    }
                }
                else { $icon = $null }

                if ($i.object.status.icon) {
                    $statusIcon = New-Object PSObject -Prop @{
                        link     = $i.object.status.icon.link
                        title    = $i.object.status.icon.title
                        url16x16 = $i.object.status.icon.url16x16
                    }
                }
                else { $statusIcon = $null }

                if ($i.object.status) {
                    $status = New-Object PSObject -Prop @{
                        resolved = $i.object.status.resolved
                        icon     = $statusIcon
                    }
                }
                else { $status = $null }

                $props.RemoteObject = New-Object PSObject -Prop @{
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
