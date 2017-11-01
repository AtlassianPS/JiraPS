function ConvertTo-JiraComment {
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
                'ID'         = $i.id
                'Body'       = $i.body
                'Visibility' = $i.visibility
                'RestUrl'    = $i.self
            }

            if ($i.author) {
                $props.Author = ConvertTo-JiraUser -InputObject $i.author
            }

            if ($i.updateAuthor) {
                $props.UpdateAuthor = ConvertTo-JiraUser -InputObject $i.updateAuthor
            }

            if ($i.created) {
                $props.Created = (Get-Date ($i.created))
            }

            if ($i.updated) {
                $props.Updated = (Get-Date ($i.updated))
            }

            $result = New-Object -TypeName PSObject -Property $props
            $result.PSObject.TypeNames.Insert(0, 'JiraPS.Comment')
            $result | Add-Member -MemberType ScriptMethod -Name "ToString" -Force -Value {
                Write-Output "$($this.Body)"
            }

            Write-Output $result
        }
    }
}
