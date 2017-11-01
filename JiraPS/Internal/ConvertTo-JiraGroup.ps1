function ConvertTo-JiraGroup {
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
                'Name'    = $i.name
                'RestUrl' = $i.self
            }

            if ($i.users) {
                $props.Size = $i.users.size

                if ($i.users.items) {
                    $allUsers = New-Object -TypeName System.Collections.ArrayList
                    foreach ($user in $i.users.items) {
                        [void] $allUsers.Add( (ConvertTo-JiraUser -InputObject $user) )
                    }

                    $props.Member = ($allUsers.ToArray())
                }
            }

            $result = New-Object -TypeName PSObject -Property $props
            $result.PSObject.TypeNames.Insert(0, 'JiraPS.Group')
            $result | Add-Member -MemberType ScriptMethod -Name "ToString" -Force -Value {
                Write-Output "$($this.Name)"
            }

            Write-Output $result
        }
    }
}
