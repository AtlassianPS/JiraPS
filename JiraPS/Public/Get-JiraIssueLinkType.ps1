function Get-JiraIssueLinkType {
    # .ExternalHelp ..\JiraPS-help.xml
    [CmdletBinding(DefaultParameterSetName = '_All')]
    param(
        [Parameter( Position = 0, Mandatory, ParameterSetName = '_Search' )]
        [ValidateNotNullOrEmpty()]
        [AtlassianPS.JiraPS.IssueLinkTypeTransformation()]
        [AtlassianPS.JiraPS.IssueLinkType]
        $LinkType,

        [Parameter()]
        [System.Management.Automation.PSCredential]
        [System.Management.Automation.Credential()]
        $Credential = [System.Management.Automation.PSCredential]::Empty
    )

    begin {
        Write-Verbose "[$($MyInvocation.MyCommand.Name)] Function started"

        $resourceURi = "/rest/api/2/issueLinkType{0}"
    }

    process {
        Write-DebugMessage "[$($MyInvocation.MyCommand.Name)] ParameterSetName: $($PsCmdlet.ParameterSetName)"
        Write-DebugMessage "[$($MyInvocation.MyCommand.Name)] PSBoundParameters: $($PSBoundParameters | Out-String)"

        if ($LinkType -and $LinkType.Id) {
            $parameter = @{
                URI        = $resourceURi -f "/$($LinkType.Id)"
                Method     = "GET"
                Credential = $Credential
            }
            Write-Debug "[$($MyInvocation.MyCommand.Name)] Invoking JiraMethod with `$parameter"
            $result = Invoke-JiraMethod @parameter

            Write-Output (ConvertTo-JiraIssueLinkType -InputObject $result)
        }
        else {
            $parameter = @{
                URI        = $resourceURi -f ""
                Method     = "GET"
                Credential = $Credential
            }
            Write-Debug "[$($MyInvocation.MyCommand.Name)] Invoking JiraMethod with `$parameter"
            $result = Invoke-JiraMethod @parameter
            $allLinkTypes = ConvertTo-JiraIssueLinkType -InputObject $result.issueLinkTypes

            if ($LinkType) {
                Write-Output ($allLinkTypes | Where-Object { $_.Name -like $LinkType.Name })
            }
            else {
                Write-Output $allLinkTypes
            }
        }
    }

    end {
        Write-Verbose "[$($MyInvocation.MyCommand.Name)] Complete"
    }
}
