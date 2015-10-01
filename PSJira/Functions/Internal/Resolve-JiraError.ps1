function Resolve-JiraError
{
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true,
                   Position = 0)]
        [Object[]] $InputObject,

        # Write error results to the error stream (Write-Error) instead of to the output stream
        [Switch] $WriteError
    )

    process
    {
        foreach ($i in $InputObject)
        {
            Write-Debug "[Resolve-JiraError] Processing object [$i]"
            if ($i.errorMessages)
            {
                foreach ($e in $i.errorMessages)
                {
                    if ($WriteError)
                    {
                        Write-Debug "[Resolve-JiraError] Writing Error output for error [$e]"
                        Write-Error "Jira encountered an error: [$($e)]"
                    } else {
                        Write-Debug "[Resolve-JiraError] Creating PSObject for error [$e]"
                        $obj = [PSCustomObject] @{
                            'Message' = $e;
                        }

                        $obj.PSObject.TypeNames.Insert(0, 'PSJira.Error')
                        $obj | Add-Member -MemberType ScriptMethod -Name "ToString" -Force -Value {
                            Write-Output "Jira error [$($this.Message)"
                        }
                        Write-Output $obj
                    }
                }
            } elseif ($i.errors) {
                $keys = (Get-Member -InputObject $i.errors | Where-Object -FilterScript {$_.MemberType -eq 'NoteProperty'}).Name
                foreach ($k in $keys)
                {
                    if ($WriteError)
                    {
                        Write-Debug "[Resolve-JiraError] Writing Error output for error [$k]"
                        Write-Error "Jira encountered an error: [$($k)] - $($i.errors.$k)"
                    } else {
                        Write-Debug "[Resolve-JiraError] Creating PSObject for error [$k]"
                        $obj = [PSCustomObject] @{
                            'Key' = $k;
                            'Message' = $i.errors.$k;
                        }

                        $obj.PSObject.TypeNames.Insert(0, 'PSJira.Error')
                        $obj | Add-Member -MemberType ScriptMethod -Name "ToString" -Force -Value {
                            Write-Output "Jira error [$($this.ID)]: $($this.Message)"
                        }

                        Write-Output $obj
                    }
                }
            } else {
                Write-Debug "[Resolve-JiraError] Object [$i] does not have an errors property"
            }
        }
    }
}
