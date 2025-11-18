function ConvertTo-JiraIssueType {
    [CmdletBinding()]
    param(
        [Parameter( ValueFromPipeline )]
        [PSObject[]]
        $InputObject
    )

    process {
        foreach ($i in $InputObject) {
            Write-Debug "[$($MyInvocation.MyCommand.Name)] Converting `$InputObject to custom object"

            # Convert Description from ADF to plain text for API v3 compatibility
            $descriptionText = if ($i.description) {
                ConvertFrom-AtlassianDocumentFormat -InputObject $i.description
            } else {
                $null
            }

            $props = @{
                'ID'          = $i.id
                'Name'        = $i.name
                'Description' = $descriptionText
                'IconUrl'     = $i.iconUrl
                'RestUrl'     = $i.self
                'Subtask'     = [System.Convert]::ToBoolean($i.subtask)
            }

            $result = New-Object -TypeName PSObject -Property $props
            $result.PSObject.TypeNames.Insert(0, 'JiraPS.IssueType')
            $result | Add-Member -MemberType ScriptMethod -Name "ToString" -Force -Value {
                Write-Output "$($this.Name)"
            }

            Write-Output $result
        }
    }
}
