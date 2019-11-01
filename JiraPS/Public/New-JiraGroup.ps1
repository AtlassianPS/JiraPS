function New-JiraGroup {
    # .ExternalHelp ..\JiraPS-help.xml
    [CmdletBinding( SupportsShouldProcess )]
    param(
        [Parameter( Mandatory )]
        [Alias('Name')]
        [String[]]
        $GroupName,

        [Alias("Credential")]
        [psobject]
        $Session
    )

    begin {
        Write-Verbose "[$($MyInvocation.MyCommand.Name)] Function started"

        $resourceURi = "rest/api/latest/group"
    }

    process {
        Write-DebugMessage "[$($MyInvocation.MyCommand.Name)] ParameterSetName: $($PsCmdlet.ParameterSetName)"
        Write-DebugMessage "[$($MyInvocation.MyCommand.Name)] PSBoundParameters: $($PSBoundParameters | Out-String)"

        foreach ($_group in $GroupName) {
            Write-Verbose "[$($MyInvocation.MyCommand.Name)] Processing [$_group]"
            Write-Debug "[$($MyInvocation.MyCommand.Name)] Processing `$_group [$_group]"

            $requestBody = @{
                "name" = $_group
            }

            $parameter = @{
                URI        = $resourceURi
                Method     = "POST"
                Body       = ConvertTo-Json -InputObject $requestBody
                Session    = $Session
            }
            Write-Debug "[$($MyInvocation.MyCommand.Name)] Invoking JiraMethod with `$parameter"
            if ($PSCmdlet.ShouldProcess($GroupName, "Creating group [$GroupName] to JIRA")) {
                $result = Invoke-JiraMethod @parameter

                Write-Output (ConvertTo-JiraGroup -InputObject $result)
            }
        }
    }

    end {
        Write-Verbose "[$($MyInvocation.MyCommand.Name)] Complete"
    }
}
