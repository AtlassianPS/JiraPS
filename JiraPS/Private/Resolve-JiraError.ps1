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

    begin {
        function Write-JiraError {
            param([string]$Message, [string]$Key, [object]$Target)

            if ($WriteError) {
                $exception = ([System.ArgumentException]"Server responded with Error")
                $errorId = if ($Key) { "ServerResponse.$Key" } else { "ServerResponse" }
                $errorCategory = 'NotSpecified'
                $errorItem = New-Object -TypeName System.Management.Automation.ErrorRecord $exception, $errorId, $errorCategory, $Target
                $errorDetails = if ($Key) { "Jira encountered an error: [$Key] - $Message" } else { "Jira encountered an error: [$Message]" }
                $errorItem.ErrorDetails = $errorDetails
                $Cmdlet.WriteError($errorItem)
            }
            else {
                $obj = [PSCustomObject] @{
                    'Key'     = $Key
                    'Message' = $Message
                }

                $obj.PSObject.TypeNames.Insert(0, 'JiraPS.Error')
                $obj | Add-Member -MemberType ScriptMethod -Name "ToString" -Force -Value {
                    if ($this.Key) {
                        Write-Output "Jira error [$($this.Key)]: $($this.Message)"
                    }
                    else {
                        Write-Output "Jira error [$($this.Message)]"
                    }
                }

                Write-Output $obj
            }
        }
    }

    process {
        foreach ($i in $InputObject) {
            Write-Debug "[$($MyInvocation.MyCommand.Name)] Converting `$InputObject to custom object"

            $hasErrors = $false

            if ($i.message) {
                $hasErrors = $true
                Write-JiraError -Message $i.message -Target $i
            }

            if ($i.errorMessage) {
                $hasErrors = $true
                Write-JiraError -Message $i.errorMessage -Target $i
            }

            if ($i.errorMessages -and $i.errorMessages.Count -gt 0) {
                $hasErrors = $true
                foreach ($e in $i.errorMessages) {
                    Write-JiraError -Message $e -Target $i
                }
            }

            if ($i.errors) {
                $keys = (Get-Member -InputObject $i.errors | Where-Object -FilterScript { $_.MemberType -eq 'NoteProperty' }).Name
                if ($keys.Count -gt 0) {
                    $hasErrors = $true
                    foreach ($k in $keys) {
                        Write-JiraError -Message $i.errors.$k -Key $k -Target $i
                    }
                }
            }

            if (-not $hasErrors -and $i) {
                $rawContent = if ($i -is [string]) { $i } else { $i | ConvertTo-Json -Compress -ErrorAction SilentlyContinue }
                if ($rawContent) {
                    Write-JiraError -Message "Unknown error: $rawContent" -Target $i
                }
            }
        }
    }
}
