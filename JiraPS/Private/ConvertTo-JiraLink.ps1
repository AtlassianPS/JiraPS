function ConvertTo-JiraLink {
    [CmdletBinding()]
    param(
        [Parameter( ValueFromPipeline )]
        [PSObject[]]
        $InputObject
    )

    process {
        foreach ($i in $InputObject) {
            Write-Debug "[$($MyInvocation.MyCommand.Name)] Converting `$InputObject to custom object"

            $props = @{
                'Id'      = $i.id
                'RestUrl' = $i.self
            }

            if ($i.globalId) {
                $props.globalId = $i.globalId
            }

            if ($i.application) {
                $props.application = New-Object PSObject -Prop @{
                    type = $i.application.type
                    name = $i.application.name
                }
            }

            if ($i.relationship) {
                $props.relationship = $i.relationship
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

                $props.object = New-Object PSObject -Prop @{
                    url     = $i.object.url
                    title   = $i.object.title
                    summary = $i.object.summary
                    icon    = $icon
                    status  = $status
                }
            }

            $result = New-Object -TypeName PSObject -Property $props
            $result.PSObject.TypeNames.Insert(0, 'JiraPS.Link')
            $result | Add-Member -MemberType ScriptMethod -Name "ToString" -Force -Value {
                Write-Output "$($this.Id)"
            }

            Write-Output $result
        }
    }
}
