function ConvertFrom-JiraLink {
    [CmdletBinding()]
    param(
        [Parameter( ValueFromPipeline )]
        [PSObject[]]
        $InputObject
    )

    process {
        foreach ($i in $InputObject) {
            Write-Debug "[$($MyInvocation.MyCommand.Name)] Converting `$InputObject to custom object"

            $props = @{}
            if ($i.Id) {
                $props.Add('id', $i.Id)
            }
            if ($i.RestUrl) {
                $props.Add('self', $i.RestUrl)
            }

            if ($i.globalId) {
                $props.globalId = $i.globalId
            }

            if ($i.application -and ($i.application.type -or $i.application.name) ) {
                $props.application = New-Object PSObject -Prop @{
                    type = $i.application.type
                    name = $i.application.name
                }
            }

            if ($i.relationship) {
                $props.relationship = $i.relationship
            }

            if ($i.object) {
                if ($i.object.icon -and ($i.object.icon.title -or $i.object.icon.url16x16)) {
                    $icon = New-Object PSObject -Prop @{
                        url16x16 = $i.object.icon.url16x16
                    }
                    if ( $i.object.icon.title ) {
                        $icon = $icon | Add-Member -MemberType NoteProperty -Name "title" -Value $i.object.icon.title -PassThru
                    }
                }
                else { $icon = $null }

                if ($i.object.status.icon -and ($i.object.status.icon.link -or $i.object.status.icon.title -or $i.object.status.icon.url16x16)) {
                    $statusIcon = New-Object PSObject
                    if ( $i.object.status.icon.title ) {
                        $statusIcon = $statusIcon | Add-Member -MemberType NoteProperty -Name "title" -Value $i.object.status.icon.title -PassThru
                    }
                    if ( $i.object.status.icon.link ) {
                        $statusIcon = $statusIcon | Add-Member -MemberType NoteProperty -Name "link" -Value $i.object.status.icon.link -PassThru
                    }
                    if ( $i.object.status.icon.url16x16 ) {
                        $statusIcon = $statusIcon | Add-Member -MemberType NoteProperty -Name "url16x16" -Value $i.object.status.icon.url16x16 -PassThru
                    }
                }
                else { $statusIcon = $null }

                if ($i.object.status -and ($i.object.status.resolved -or $statusIcon)) {
                    $status = New-Object PSObject -Prop @{
                        resolved = $i.object.status.resolved
                        icon     = $statusIcon
                    }
                }
                else { $status = $null }

                $props.object = New-Object PSObject -Prop @{
                    url     = $i.object.url
                }
                if ( $icon ) {
                    $props.object = $props.object | Add-Member -MemberType NoteProperty -Name "icon" -Value $icon -PassThru
                }
                if ( $status ) {
                    $props.object = $props.object | Add-Member -MemberType NoteProperty -Name "status" -Value $status -PassThru
                }
                if ( $i.object.title ) {
                    $props.object = $props.object | Add-Member -MemberType NoteProperty -Name "title" -Value $i.object.title -PassThru
                }
                if ( $i.object.summary ) {
                    $props.object = $props.object | Add-Member -MemberType NoteProperty -Name "summary" -Value $i.object.summary -PassThru
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
