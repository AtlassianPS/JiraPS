function ConvertTo-JiraAttachment {
    [CmdletBinding()]
    param(
        [Parameter(
            ValueFromPipeline = $true
        )]
        [PSObject[]] $InputObject
    )

    process {
        foreach ($i in $InputObject) {
            Write-Debug "[$($MyInvocation.MyCommand.Name)] Converting `$InputObject to custom object"

            $props = @{
                'ID'        = $i.id
                'Self'      = $i.self
                'FileName'  = $i.FileName
                'Author'    = ConvertTo-JiraUser -InputObject $i.Author
                'Created'   = Get-Date -Date ($i.created)
                'Size'      = ([Int]$i.size)
                'MimeType'  = $i.mimeType
                'Content'   = $i.content
                'Thumbnail' = $i.thumbnail
            }

            $result = New-Object -TypeName PSObject -Property $props
            $result.PSObject.TypeNames.Insert(0, 'JiraPS.Attachment')
            $result | Add-Member -MemberType ScriptMethod -Name "ToString" -Force -Value {
                Write-Output "$($this.FileName)"
            }

            Write-Output $result
        }
    }
}


