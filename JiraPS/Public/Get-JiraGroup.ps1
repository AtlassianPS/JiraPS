function Get-JiraGroup {
    # .ExternalHelp ..\JiraPS-help.xml
    [CmdletBinding()]
    param(
        [Parameter( Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName )]
        [ValidateNotNullOrEmpty()]
        [Alias('Name')]
        [String[]]
        $GroupName,

        [Parameter()]
        [System.Management.Automation.PSCredential]
        [System.Management.Automation.Credential()]
        $Credential = [System.Management.Automation.PSCredential]::Empty
    )

    begin {
        Write-Verbose "[$($MyInvocation.MyCommand.Name)] Function started"

        $isCloud = Test-JiraCloudServer -Credential $Credential

        $cloudResourceUri = "/rest/api/2/group/bulk"
        $serverResourceUri = "/rest/api/2/group/member"
    }

    process {
        Write-DebugMessage "[$($MyInvocation.MyCommand.Name)] ParameterSetName: $($PsCmdlet.ParameterSetName)"
        Write-DebugMessage "[$($MyInvocation.MyCommand.Name)] PSBoundParameters: $($PSBoundParameters | Out-String)"

        foreach ($group in $GroupName) {
            Write-Verbose "[$($MyInvocation.MyCommand.Name)] Processing [$group]"
            Write-Debug "[$($MyInvocation.MyCommand.Name)] Processing `$group [$group]"

            if ($isCloud) {
                $parameter = @{
                    Uri          = $cloudResourceUri
                    Method       = "GET"
                    GetParameter = @{ groupName = $group }
                    Paging       = $true
                    Credential   = $Credential
                }

                Write-Debug "[$($MyInvocation.MyCommand.Name)] Invoking JiraMethod with `$parameter"
                $result = Invoke-JiraMethod @parameter

                $result = @($result | Where-Object { $_.name -eq $group })

                if ($result.Count -ne 1) {
                    $message = "Jira did not return exactly one canonical group for '$group'."
                    WriteError -Cmdlet $PSCmdlet -ExceptionType 'System.Management.Automation.ItemNotFoundException' -Message $message -TargetObject $group -ErrorId 'GroupNotFound' -Category ObjectNotFound
                    continue
                }

                $groupResult = Resolve-JiraGroupPayload -InputObject $result[0] -RequestedGroupName $group
            }
            else {
                $parameter = @{
                    Uri          = $serverResourceUri
                    Method       = "GET"
                    GetParameter = @{
                        groupname  = $group
                        maxResults = 1
                    }
                    Credential   = $Credential
                }

                Write-Debug "[$($MyInvocation.MyCommand.Name)] Invoking JiraMethod with `$parameter"
                $result = Invoke-JiraMethod @parameter

                if (-not $result) {
                    $message = "Jira did not return a canonical group payload for '$group'."
                    WriteError -Cmdlet $PSCmdlet -ExceptionType 'System.Management.Automation.ItemNotFoundException' -Message $message -TargetObject $group -ErrorId 'GroupNotFound' -Category ObjectNotFound
                    continue
                }

                $groupResult = Resolve-JiraGroupPayload -InputObject $result -RequestedGroupName $group
            }

            Write-Output (ConvertTo-JiraGroup -InputObject $groupResult)
        }
    }

    end {
        Write-Verbose "[$($MyInvocation.MyCommand.Name)] Complete"
    }
}
