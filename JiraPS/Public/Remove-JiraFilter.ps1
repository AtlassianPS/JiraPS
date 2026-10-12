function Remove-JiraFilter {
    # .ExternalHelp ..\JiraPS-help.xml
    [CmdletBinding( ConfirmImpact = 'Medium', SupportsShouldProcess )]
    param(
        [Parameter( Position = 0, Mandatory, ValueFromPipeline )]
        [ValidateNotNullOrEmpty()]
        [Alias('Id', 'FilterId')]
        [AtlassianPS.JiraPS.FilterTransformation()]
        [AtlassianPS.JiraPS.Filter[]]
        $InputObject,

        [Parameter()]
        [System.Management.Automation.PSCredential]
        [System.Management.Automation.Credential()]
        $Credential = [System.Management.Automation.PSCredential]::Empty
    )

    begin {
        Write-Verbose "[$($MyInvocation.MyCommand.Name)] Function started"
    }

    process {
        Write-DebugMessage "[$($MyInvocation.MyCommand.Name)] ParameterSetName: $($PsCmdlet.ParameterSetName)"
        Write-DebugMessage "[$($MyInvocation.MyCommand.Name)] PSBoundParameters: $($PSBoundParameters | Out-String)"

        $filters = foreach ($item in $InputObject) {
            if ($item.RestUrl) { $item }
            else {
                Get-JiraFilter -Id $item.Id -Credential $Credential -ErrorAction Stop
            }
        }

        foreach ($filter in $filters) {
            Write-Verbose "[$($MyInvocation.MyCommand.Name)] Processing [$filter]"
            Write-Debug "[$($MyInvocation.MyCommand.Name)] Processing `$filter [$filter]"

            $parameter = @{
                URI        = $filter.RestURL
                Method     = 'DELETE'
                Credential = $Credential
            }
            Write-Debug "[$($MyInvocation.MyCommand.Name)] Invoking JiraMethod with `$parameter"
            if ($PSCmdlet.ShouldProcess($filter.Name, "Deleting Filter")) { Invoke-JiraMethod @parameter }
        }
    }

    end {
        Write-Verbose "[$($MyInvocation.MyCommand.Name)] Complete"
    }
}
