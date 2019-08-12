function Find-JiraFilter {
    # .ExternalHelp ..\JiraPS-help.xml
    [CmdletBinding( DefaultParameterSetName='ByAccountId', SupportsPaging )]
    param(
        [Parameter(ValueFromPipeline,ValueFromPipelineByPropertyName)]
        [string[]]$Name,

        [Parameter(ParameterSetName='ByAccountId',ValueFromPipelineByPropertyName)]
        [string]$AccountId,

        [Parameter(ParameterSetName='ByOwner',ValueFromPipelineByPropertyName)]
        [ValidateNotNullOrEmpty()]
        [ValidateScript(
            {
                if (("JiraPS.User" -notin $_.PSObject.TypeNames) -and (($_ -isnot [String]))) {
                    $exception = ([System.ArgumentException]"Invalid Type for Parameter") #fix code highlighting]
                    $errorId = 'ParameterType.NotJiraUser'
                    $errorCategory = 'InvalidArgument'
                    $errorTarget = $_
                    $errorItem = New-Object -TypeName System.Management.Automation.ErrorRecord $exception, $errorId, $errorCategory, $errorTarget
                    $errorItem.ErrorDetails = "Wrong object type provided for Owner. Expected [JiraPS.User] or [String], but was $($_.GetType().Name)"
                    $PSCmdlet.ThrowTerminatingError($errorItem)
                    <#
                      #ToDo:CustomClass
                      Once we have custom classes, this check can be done with Type declaration
                    #>
                }
                else {
                    return $true
                }
            }
        )]
        [Alias('UserName')]
        [Object]
        $Owner,

        [Parameter(ValueFromPipelineByPropertyName)]
        [string]$GroupName,

        [Parameter(ValueFromPipelineByPropertyName)]
        [ValidateScript(
            {
                if (("JiraPS.Project" -notin $_.PSObject.TypeNames) -and (($_ -isnot [String]))) {
                    $exception = ([System.ArgumentException]"Invalid Type for Parameter") #fix code highlighting]
                    $errorId = 'ParameterType.NotJiraProject'
                    $errorCategory = 'InvalidArgument'
                    $errorTarget = $_
                    $errorItem = New-Object -TypeName System.Management.Automation.ErrorRecord $exception, $errorId, $errorCategory, $errorTarget
                    $errorItem.ErrorDetails = "Wrong object type provided for Project. Expected [JiraPS.Project] or [String], but was $($_.GetType().Name)"
                    $PSCmdlet.ThrowTerminatingError($errorItem)
                    <#
                      #ToDo:CustomClass
                      Once we have custom classes, this check can be done with Type declaration
                    #>
                }
                else {
                    return $true
                }
            }
        )]
        [Object]
        $Project,

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
        if ($PSCmdlet.MyInvocation.BoundParameters.ContainsKey('AccountId')) {
            $parameter['GetParameter']['accountId'] = $AccountId
        }
        elseif ($PSCmdlet.ParameterSetName -eq 'ByOwner') {
            $userObj = Get-JiraUser -InputObject $Owner -Credential $Credential -ErrorAction Stop
            $parameter['GetParameter']['accountId'] = $userObj.AccountId
        }
        if ($PSCmdlet.MyInvocation.BoundParameters.ContainsKey('GroupName')) {
            $parameter['GetParameter']['groupName'] = $GroupName
        }
        if ($PSCmdlet.MyInvocation.BoundParameters.ContainsKey('Project')) {
            $projectObj = Get-JiraProject -Project $Project -Credential $Credential -ErrorAction Stop
            $parameter['GetParameter']['projectId'] = $projectObj.Id
        }
        if ($PSCmdlet.MyInvocation.BoundParameters.ContainsKey('Sort')) {
            $parameter['GetParameter']['orderBy'] = $Sort
        }
        # Paging
        ($PSCmdlet.PagingParameters | Get-Member -MemberType Property).Name | ForEach-Object {
            $parameter[$_] = $PSCmdlet.PagingParameters.$_
        }
        if ($PSCmdlet.MyInvocation.BoundParameters.ContainsKey('Name')) {
            foreach($_name in $Name) {
                $parameter['GetParameter']['filterName'] = $_name
                Write-Debug "[$($MyInvocation.MyCommand.Name)] Invoking JiraMethod with `$parameter"

                Write-Output (Invoke-JiraMethod @parameter | ConvertTo-JiraFilter)
            }
        }
        else {
            Write-Debug "[$($MyInvocation.MyCommand.Name)] Invoking JiraMethod with `$parameter"

            Write-Output (Invoke-JiraMethod @parameter | ConvertTo-JiraFilter)
        }

    }

    end {
        Write-Verbose "[$($MyInvocation.MyCommand.Name)] Complete"
    }
}
