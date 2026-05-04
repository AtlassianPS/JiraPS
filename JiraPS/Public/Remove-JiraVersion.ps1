function Remove-JiraVersion {
    # .ExternalHelp ..\JiraPS-help.xml
    [CmdletBinding( ConfirmImpact = 'High', SupportsShouldProcess )]
    param(
        [Parameter( Mandatory, ValueFromPipeline )]
        [ValidateNotNull()]
        [AtlassianPS.JiraPS.VersionTransformation()]
        [AtlassianPS.JiraPS.Version[]]
        $Version,

        [Parameter()]
        [System.Management.Automation.PSCredential]
        [System.Management.Automation.Credential()]
        $Credential = [System.Management.Automation.PSCredential]::Empty,

        [Switch]
        $Force
    )

    begin {
        Write-Verbose "[$($MyInvocation.MyCommand.Name)] Function started"

        $maxDeleteAttempts = 6
        $retryDelayMs = 500

        if ($Force) {
            Write-DebugMessage "[Remove-JiraVersion] -Force was passed. Backing up current ConfirmPreference [$ConfirmPreference] and setting to None"
            $oldConfirmPreference = $ConfirmPreference
            $ConfirmPreference = 'None'
        }
    }

    process {
        Write-DebugMessage "[$($MyInvocation.MyCommand.Name)] ParameterSetName: $($PsCmdlet.ParameterSetName)"
        Write-DebugMessage "[$($MyInvocation.MyCommand.Name)] PSBoundParameters: $($PSBoundParameters | Out-String)"

        foreach ($_version in $Version) {
            Write-Verbose "[$($MyInvocation.MyCommand.Name)] Processing [$_version]"
            Write-Debug "[$($MyInvocation.MyCommand.Name)] Processing `$_version [$_version]"

            $versionObj = Get-JiraVersion -Id $_version.Id -Credential $Credential -ErrorAction Stop

            $deleteParameter = @{
                URI        = "/rest/api/2/version/$($versionObj.Id)"
                Method     = "DELETE"
                Credential = $Credential
            }
            Write-Debug "[$($MyInvocation.MyCommand.Name)] Invoking JiraMethod with `$deleteParameter"
            if ($PSCmdlet.ShouldProcess($versionObj.Name, "Removing Version")) {
                $deleteHitMethodNotAllowed = $false
                for ($attempt = 1; $attempt -le $maxDeleteAttempts; $attempt++) {
                    try {
                        Invoke-JiraMethod @deleteParameter
                        break
                    }
                    catch {
                        $isMethodNotAllowed = (
                            $_.FullyQualifiedErrorId -match 'InvalidResponse.Status405' -or
                            $_.Exception.Message -match 'HTTP 405 Method Not Allowed'
                        )
                        $isLastAttempt = ($attempt -eq $maxDeleteAttempts)

                        if (-not $isMethodNotAllowed -or $isLastAttempt) {
                            if ($isMethodNotAllowed -and $isLastAttempt) {
                                $deleteHitMethodNotAllowed = $true
                                break
                            }
                            throw
                        }

                        Write-Verbose "[$($MyInvocation.MyCommand.Name)] Jira returned HTTP 405 while deleting version id [$($versionObj.Id)] (attempt $attempt/$maxDeleteAttempts). Retrying after $retryDelayMs ms."
                        Start-Sleep -Milliseconds $retryDelayMs
                    }
                }

                if ($deleteHitMethodNotAllowed) {
                    $swapParameter = @{
                        URI        = "/rest/api/2/version/$($versionObj.Id)/removeAndSwap"
                        Method     = "POST"
                        Credential = $Credential
                    }
                    Write-Verbose "[$($MyInvocation.MyCommand.Name)] Falling back to removeAndSwap for version id [$($versionObj.Id)] after repeated HTTP 405 responses on DELETE."
                    Invoke-JiraMethod @swapParameter
                }
            }
        }
    }

    end {
        if ($Force) {
            Write-Debug "[Remove-JiraVersion] Restoring ConfirmPreference to [$oldConfirmPreference]"
            $ConfirmPreference = $oldConfirmPreference
        }

        Write-Verbose "[$($MyInvocation.MyCommand.Name)] Complete"
    }
}
