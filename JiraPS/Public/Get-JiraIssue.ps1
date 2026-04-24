function Get-JiraIssue {
    # .ExternalHelp ..\JiraPS-help.xml
    [CmdletBinding( SupportsPaging, DefaultParameterSetName = 'ByIssueKey' )]
    param(
        [Parameter( Position = 0, Mandatory, ValueFromPipelineByPropertyName, ParameterSetName = 'ByIssueKey' )]
        [ValidateNotNullOrEmpty()]
        [Alias('Issue')]
        [String[]]
        $Key,

        [Parameter( Position = 0, Mandatory, ValueFromPipeline, ParameterSetName = 'ByInputObject' )]
        [ValidateNotNull()]
        [AtlassianPS.JiraPS.IssueTransformation()]
        [AtlassianPS.JiraPS.Issue]
        $InputObject,
        <#
          #ToDo:Deprecate
          This is not necessary if $Key uses ValueFromPipelineByPropertyName
        #>

        [Parameter( Mandatory, ParameterSetName = 'ByJQL' )]
        [Alias('JQL')]
        [String]
        $Query,

        [Parameter( Mandatory, ParameterSetName = 'ByFilter' )]
        [ValidateNotNullOrEmpty()]
        [ValidateScript(
            {
                if (("AtlassianPS.JiraPS.Filter" -notin $_.PSObject.TypeNames) -and (($_ -isnot [String]))) {
                    $exception = ([System.ArgumentException]"Invalid Type for Parameter") #fix code highlighting]
                    $errorId = 'ParameterType.NotJiraFilter'
                    $errorCategory = 'InvalidArgument'
                    $errorTarget = $_
                    $errorItem = New-Object -TypeName System.Management.Automation.ErrorRecord $exception, $errorId, $errorCategory, $errorTarget
                    $errorItem.ErrorDetails = "Wrong object type provided for Filter. Expected [AtlassianPS.JiraPS.Filter] or [String], but was $($_.GetType().Name)"
                    $PSCmdlet.ThrowTerminatingError($errorItem)
                    <#
                      #ToDo:CustomClass
                      Now that we have custom classes, this polymorphic ValidateScript could be split into a parameter set with [AtlassianPS.JiraPS.<Type>] strong typing
                    #>
                }
                else {
                    return $true
                }
            }
        )]
        [Object]
        $Filter,

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [String[]]
        $Fields = "*all",

        [Parameter( ParameterSetName = 'ByJQL' )]
        [Parameter( ParameterSetName = 'ByFilter' )]
        [UInt32]
        $PageSize = $script:DefaultPageSize,

        [Parameter()]
        [System.Management.Automation.PSCredential]
        [System.Management.Automation.Credential()]
        $Credential = [System.Management.Automation.PSCredential]::Empty
    )

    begin {
        Write-Verbose "[$($MyInvocation.MyCommand.Name)] Function started"

        $isCloud = Test-JiraCloudServer -Credential $Credential

        $searchURi = "/rest/api/2/search"
        $searchURi_v3 = "/rest/api/3/search/jql"
        $resourceURi = "/rest/api/2/issue/{0}"

        [String]$Fields = $Fields -join ","
    }

    process {
        Write-DebugMessage "[$($MyInvocation.MyCommand.Name)] ParameterSetName: $($PsCmdlet.ParameterSetName)"
        Write-DebugMessage "[$($MyInvocation.MyCommand.Name)] PSBoundParameters: $($PSBoundParameters | Out-String)"

        switch ($PSCmdlet.ParameterSetName) {
            'ByIssueKey' {
                foreach ($_key in $Key) {
                    Write-Verbose "[$($MyInvocation.MyCommand.Name)] Processing [$_key]"
                    Write-Debug "[$($MyInvocation.MyCommand.Name)] Processing `$_key [$_key]"

                    $getParameter = @{ expand = "transitions" }
                    if ($Fields) {
                        $getParameter["fields"] = $Fields
                    }

                    $parameter = @{
                        URI          = $resourceURi -f $_key
                        Method       = "GET"
                        GetParameter = $getParameter
                        Credential   = $Credential
                    }

                    Write-Debug "[$($MyInvocation.MyCommand.Name)] Invoking JiraMethod with `$parameter"
                    $result = Invoke-JiraMethod @parameter

                    Write-Output (ConvertTo-JiraIssue -InputObject $result)
                }
            }
            'ByInputObject' {
                # Write-Warning "[$($MyInvocation.MyCommand.Name)] The parameter '-InputObject' has been marked as deprecated."
                Write-Verbose "[$($MyInvocation.MyCommand.Name)] Processing [$InputObject]"
                Write-Debug "[$($MyInvocation.MyCommand.Name)] Processing `$InputObject [$InputObject]"

                Write-Output (Get-JiraIssue -Key $InputObject.Key -Fields $Fields -Credential $Credential)
            }
            'ByJQL' {
                $parameter = @{
                    URI          = if ($isCloud) { $searchURi_v3 } else { $searchURi }
                    Method       = "GET"
                    GetParameter = @{
                        jql           = (ConvertTo-URLEncoded $Query)
                        validateQuery = $true
                        expand        = "transitions"
                        maxResults    = $PageSize
                    }
                    OutputType   = "JiraIssue"
                    Paging       = $true
                    Credential   = $Credential
                }
                if ($Fields) {
                    $parameter["GetParameter"]["fields"] = $Fields
                }
                # Paging
                ($PSCmdlet.PagingParameters | Get-Member -MemberType Property).Name | ForEach-Object {
                    $parameter[$_] = $PSCmdlet.PagingParameters.$_
                }

                Write-Debug "[$($MyInvocation.MyCommand.Name)] Invoking JiraMethod with `$parameter"
                Invoke-JiraMethod @parameter
            }
            'ByFilter' {
                $filterObj = (Get-JiraFilter -InputObject $Filter -Credential $Credential -ErrorAction Stop).searchurl
                <#
                  #ToDo:CustomClass
                  Now that we have custom classes, this Resolve-* shim could be replaced by a parameter set that takes [AtlassianPS.JiraPS.<Type>] directly
                #>

                $parameter = @{
                    URI          = $filterObj
                    Method       = "GET"
                    GetParameter = @{
                        validateQuery = $true
                        expand        = "transitions"
                        maxResults    = $PageSize
                    }
                    OutputType   = "JiraIssue"
                    Paging       = $true
                    Credential   = $Credential

                }
                if ($Fields) {
                    $parameter["GetParameter"]["fields"] = $Fields
                }
                # Paging
                ($PSCmdlet.PagingParameters | Get-Member -MemberType Property).Name | ForEach-Object {
                    $parameter[$_] = $PSCmdlet.PagingParameters.$_
                }

                Write-Debug "[$($MyInvocation.MyCommand.Name)] Invoking JiraMethod with `$parameter"
                Invoke-JiraMethod @parameter
            }
        }
    }

    end {
        Write-Verbose "[$($MyInvocation.MyCommand.Name)] Complete"
    }
}
