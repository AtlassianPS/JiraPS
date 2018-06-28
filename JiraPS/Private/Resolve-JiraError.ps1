function Resolve-JiraError {
    [CmdletBinding()]
    param(
        [Parameter( ValueFromPipeline )]
        [Object[]]
        $InputObject,

        # Write error results to the error stream (Write-Error) instead of to the output stream
        [Switch]
        $WriteError,

        [ValidateNotNullOrEmpty()]
        [System.Management.Automation.PSCmdlet]
        $Cmdlet = $PSCmdlet
    )

    process {
        foreach ($i in $InputObject) {
            Write-Debug "[$($MyInvocation.MyCommand.Name)] Converting `$InputObject to custom object"

            if ($i.errorMessages) {
                foreach ($e in $i.errorMessages) {
                    if ($WriteError) {
                        $exception = ([System.ArgumentException]"Server responded with Error")
                        $errorId = "ServerResponse"
                        $errorCategory = 'NotSpecified'
                        $errorTarget = $i
                        $errorItem = New-Object -TypeName System.Management.Automation.ErrorRecord $exception, $errorId, $errorCategory, $errorTarget
                        $errorItem.ErrorDetails = "Jira encountered an error: [$e]"
                        $Cmdlet.WriteError($errorItem)
                    }
                    else {
                        $obj = [PSCustomObject] @{
                            'Message' = $e
                        }

                        $obj.PSObject.TypeNames.Insert(0, 'JiraPS.Error')
                        $obj | Add-Member -MemberType ScriptMethod -Name "ToString" -Force -Value {
                            Write-Output "Jira error [$($this.Message)]"
                        }

                        Write-Output $obj
                    }
                }
            }
            elseif ($i.errors) {
                $keys = (Get-Member -InputObject $i.errors | Where-Object -FilterScript {$_.MemberType -eq 'NoteProperty'}).Name
                foreach ($k in $keys) {
                    if ($WriteError) {
                        $exception = ([System.ArgumentException]"Server responded with Error")
                        $errorId = "ServerResponse.$k"
                        $errorCategory = 'NotSpecified'
                        $errorTarget = $i
                        $errorItem = New-Object -TypeName System.Management.Automation.ErrorRecord $exception, $errorId, $errorCategory, $errorTarget
                        $errorItem.ErrorDetails = "Jira encountered an error: [$k] - $($i.errors.$k)"
                        $Cmdlet.WriteError($errorItem)
                    }
                    else {
                        $obj = [PSCustomObject] @{
                            'Key'     = $k
                            'Message' = $i.errors.$k
                        }

                        $obj.PSObject.TypeNames.Insert(0, 'JiraPS.Error')
                        $obj | Add-Member -MemberType ScriptMethod -Name "ToString" -Force -Value {
                            Write-Output "Jira error [$($this.ID)]: $($this.Message)"
                        }

                        Write-Output $obj
                    }
                }
            }
        }
    }
}
