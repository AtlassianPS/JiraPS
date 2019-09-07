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

        $resourceURi = "rest/api/latest/group?groupname={0}"
    }

    process {
        Write-DebugMessage "[$($MyInvocation.MyCommand.Name)] ParameterSetName: $($PsCmdlet.ParameterSetName)"
        Write-DebugMessage "[$($MyInvocation.MyCommand.Name)] PSBoundParameters: $($PSBoundParameters | Out-String)"

        foreach ($group in $GroupName) {
            Write-Verbose "[$($MyInvocation.MyCommand.Name)] Processing [$group]"
            Write-Debug "[$($MyInvocation.MyCommand.Name)] Processing `$group [$group]"

            $escapedGroupName = ConvertTo-URLEncoded $group

            $parameter = @{
                URI        = $resourceURi -f $escapedGroupName
                Method     = "GET"
                Credential = $Credential
            }
            Write-Debug "[$($MyInvocation.MyCommand.Name)] Invoking JiraMethod with `$parameter"
            $result = Invoke-JiraMethod @parameter

            Write-Output (ConvertTo-JiraGroup -InputObject $result)
        }
    }

    end {
        Write-Verbose "[$($MyInvocation.MyCommand.Name)] Complete"
    }
}
