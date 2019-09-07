function Get-JiraGroupMember {
    # .ExternalHelp ..\JiraPS-help.xml
    [CmdletBinding( SupportsPaging )]
    param(
        [Parameter( Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName )]
        [ValidateNotNullOrEmpty()]
        [ValidateScript(
            {
                if (("JiraPS.Group" -notin $_.PSObject.TypeNames) -and (($_ -isnot [String]))) {
                    $exception = ([System.ArgumentException]"Invalid Type for Parameter") #fix code highlighting]
                    $errorId = 'ParameterType.NotJiraGroup'
                    $errorCategory = 'InvalidArgument'
                    $errorTarget = $_
                    $errorItem = New-Object -TypeName System.Management.Automation.ErrorRecord $exception, $errorId, $errorCategory, $errorTarget
                    $errorItem.ErrorDetails = "Wrong object type provided for Group. Expected [JiraPS.Group] or [String], but was $($_.GetType().Name)"
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
        [Object[]]
        $Group,

        [Switch]
        $IncludeInactive,

        [UInt32]
        $StartIndex = 0,

        [UInt32]
        $MaxResults,

        [UInt32]
        $PageSize = $script:DefaultPageSize,

        [Alias("Credential")]
        [psobject]
        $Session
    )

    begin {
        Write-Verbose "[$($MyInvocation.MyCommand.Name)] Function started"

        $resourceURi = "rest/api/latest/group/member"

        if ($PageSize -gt 50) {
            Write-Warning "JIRA's API may not properly support MaxResults values higher than 50 for this method. If you receive inconsistent results, do not pass the MaxResults parameter to this function to return all results."
        }
    }

    process {
        Write-DebugMessage "[$($MyInvocation.MyCommand.Name)] ParameterSetName: $($PsCmdlet.ParameterSetName)"
        Write-DebugMessage "[$($MyInvocation.MyCommand.Name)] PSBoundParameters: $($PSBoundParameters | Out-String)"

        $groupObj = Get-JiraGroup -GroupName $Group -Session $Session -ErrorAction Stop

        foreach ($_group in $groupObj) {
            Write-Verbose "[$($MyInvocation.MyCommand.Name)] Processing [$_group]"
            Write-Debug "[$($MyInvocation.MyCommand.Name)] Processing `$_group [$_group]"

            $parameter = @{
                URI          = $resourceURi
                Method       = "GET"
                GetParameter = @{
                    groupname  = $_group.Name
                    maxResults = $PageSize
                }
                OutputType   = "JiraUser"
                Paging       = $true
                Session      = $Session
            }
            if ($IncludeInactive) {
                $parameter["includeInactiveUsers"] = $true
            }

            # Paging
            ($PSCmdlet.PagingParameters | Get-Member -MemberType Property).Name | ForEach-Object {
                $parameter[$_] = $PSCmdlet.PagingParameters.$_
            }
            # Make `SupportsPaging` be backwards compatible
            if ($StartIndex) {
                Write-Warning "[$($MyInvocation.MyCommand.Name)] The parameter '-StartIndex' has been marked as deprecated. For more information, plase read the help."
                $parameter["Skip"] = $StartIndex
            }
            if ($MaxResults) {
                Write-Warning "[$($MyInvocation.MyCommand.Name)] The parameter '-MaxResults' has been marked as deprecated. For more information, plase read the help."
                $parameter["First"] = $MaxResults
            }

            Write-Debug "[$($MyInvocation.MyCommand.Name)] Invoking JiraMethod with `$parameter"
            Invoke-JiraMethod @parameter
        }
    }

    end {
        Write-Verbose "[$($MyInvocation.MyCommand.Name)] Complete"
    }
}
