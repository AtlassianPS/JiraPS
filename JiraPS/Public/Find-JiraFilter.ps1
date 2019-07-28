function Find-JiraFilter {
    # .ExternalHelp ..\JiraPS-help.xml
    [CmdletBinding( SupportsPaging )]
    param(
        [string]$Name,

        [string]$AccountId,

        [string]$GroupName,

        [uint32]$ProjectId,

        [Validateset('description','favourite','favouritedCount','jql','owner','searchUrl','sharePermissions','subscriptions','viewUrl')]
        [String[]]
        $Fields = @('description','favourite','favouritedCount','jql','owner','searchUrl','sharePermissions','subscriptions','viewUrl'),

        [Validateset('description','favourite_count','is_favourite','id','name','owner')]
        [string]$Sort,

        [System.Management.Automation.PSCredential]
        [System.Management.Automation.Credential()]
        $Credential = [System.Management.Automation.PSCredential]::Empty
    )

    begin {
        Write-Verbose "[$($MyInvocation.MyCommand.Name)] Function started"

        $server = Get-JiraConfigServer -ErrorAction Stop

        $searchURi = "$server/rest/api/latest/filter/search"

        [String]$Fields = $Fields -join ','
    }

    process {
        Write-DebugMessage "[$($MyInvocation.MyCommand.Name)] PSBoundParameters: $($PSBoundParameters | Out-String)"
        $parameter = @{
            URI          = $searchURi
            Method       = 'GET'
            GetParameter = @{
                expand = $Fields
            }
            Paging       = $true
            Credential   = $Credential
        }
        if ($Name) {
            $parameter['GetParameter']['filterName'] = $Name
        }
        if ($AccountId) {
            $parameter['GetParameter']['accountId'] = $AccountId
        }
        if ($GroupName) {
            $parameter['GetParameter']['groupName'] = $GroupName
        }
        if ($ProjectId) {
            $parameter['GetParameter']['projectId'] = $ProjectId
        }
        if ($Name) {
            $parameter['GetParameter']['orderBy'] = $Sort
        }
        # Paging
        ($PSCmdlet.PagingParameters | Get-Member -MemberType Property).Name | ForEach-Object {
            $parameter[$_] = $PSCmdlet.PagingParameters.$_
        }

        Write-Debug "[$($MyInvocation.MyCommand.Name)] Invoking JiraMethod with `$parameter"

        $result = Invoke-JiraMethod @parameter

        Write-Output (ConvertTo-JiraFilter -InputObject $result)
    }

    end {
        Write-Verbose "[$($MyInvocation.MyCommand.Name)] Complete"
    }
}
