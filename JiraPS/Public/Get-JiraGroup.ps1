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
        $Credential,

        [Alias('Session')]
        [AtlassianPS.Connection]
        $Connection
    )

    begin {
        Write-Verbose "[$($MyInvocation.MyCommand.Name)] Function started"

        try {
            $RequestContext = Resolve-JiraOperationContext -BoundParameters $PSBoundParameters

            $isCloud = Test-JiraCloudServer -RequestContext $RequestContext

            $cloudResourceUri = "/rest/api/2/group/bulk"
            $serverResourceUri = "/rest/api/2/group/member"
        }
        catch {
            if ($RequestContext -and $RequestContext.State -eq 'Standalone') { $RequestContext.Dispose() }
            throw
        }
    }

    process {
        try {
            Write-DebugMessage "ParameterSetName: $($PsCmdlet.ParameterSetName)"
            Write-DebugMessage -BoundParameters $PSBoundParameters

            foreach ($group in $GroupName) {
                Write-Verbose "[$($MyInvocation.MyCommand.Name)] Processing [$group]"
                Write-DebugMessage "Processing `$group [$group]"

                if ($isCloud) {
                    $parameter = @{
                        Uri          = $cloudResourceUri
                        Method       = "GET"
                        GetParameter = @{ groupName = $group }
                        Paging       = $true
                    }

                    Write-DebugMessage "Invoking JiraMethod with `$parameter"
                    $result = Invoke-JiraMethod -RequestContext $RequestContext @parameter

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
                    }

                    Write-DebugMessage "Invoking JiraMethod with `$parameter"
                    $result = Invoke-JiraMethod -RequestContext $RequestContext @parameter

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
        catch {
            if ($RequestContext -and $RequestContext.State -eq 'Standalone') { $RequestContext.Dispose() }
            throw
        }
    }

    end {
        try {
            Write-Verbose "[$($MyInvocation.MyCommand.Name)] Complete"
        }
        finally {
            if ($RequestContext.State -eq 'Standalone') { $RequestContext.Dispose() }
        }
    }
}
