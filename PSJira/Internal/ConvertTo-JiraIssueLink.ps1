function ConvertTo-JiraIssueLink {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true,
            Position = 0,
            ValueFromPipeline = $true)]
        [PSObject[]] $InputObject,

        [Switch] $ReturnError
    )

    process {
        foreach ($i in $InputObject) {
            if ($i.errorMessages) {
                if ($ReturnError) {
                    $props = @{
                        'ErrorMessages' = $i.errorMessages;
                    }

                    $result = New-Object -TypeName PSObject -Property $props
                    $result.PSObject.TypeNames.Insert(0, 'PSJira.Error')

                    Write-Output $result
                }
            }
            else {
                $props = @{
                    'ID'   = $i.id
                    'Type' = (ConvertTo-JiraIssueLinkType $i.type)
                }
                if ($i.inwardIssue) { $props['InwardIssue']  = (ConvertTo-JiraIssue $i.inwardIssue) }
                if ($i.outwardIssue) { $props['OutwardIssue'] = (ConvertTo-JiraIssue $i.outwardIssue) }

                $result = New-Object -TypeName PSObject -Property $props
                $result.PSObject.TypeNames.Insert(0, 'PSJira.IssueLink')

                $result | Add-Member -MemberType ScriptMethod -Name "ToString" -Force -Value {
                    Write-Output "$($this.ID)"
                }

                Write-Output $result
            }
        }
    }

    end
    {
    }
}
