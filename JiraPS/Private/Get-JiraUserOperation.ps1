function Get-JiraUserOperation {
    [CmdletBinding( DefaultParameterSetName = 'Self' )]
    param(
        [Parameter( Position = 0, Mandatory, ValueFromPipelineByPropertyName, ParameterSetName = 'ByUserName' )]
        [AllowEmptyString()]
        [Alias('User', 'Name')]
        [String[]]
        $UserName,

        [Parameter( Position = 0, Mandatory, ValueFromPipelineByPropertyName, ParameterSetName = 'ByAccountId' )]
        [ValidateNotNullOrEmpty()]
        [String[]]
        $AccountId,

        [Parameter( Position = 0, Mandatory, ParameterSetName = 'ByInputObject' )]
        [ValidateNotNull()]
        [AtlassianPS.JiraPS.UserTransformation()]
        [AtlassianPS.JiraPS.User[]]
        $InputObject,

        [Parameter( ParameterSetName = 'ByInputObject' )]
        [Parameter( ParameterSetName = 'ByUserName' )]
        [Parameter( ParameterSetName = 'ByAccountId' )]
        [Switch]
        $Exact,

        [Switch]
        $IncludeInactive,

        [Parameter( ParameterSetName = 'ByUserName' )]
        [Parameter( ParameterSetName = 'ByAccountId' )]
        [ValidateRange(1, 1000)]
        [UInt32]
        $MaxResults = 50,

        [Parameter( ParameterSetName = 'ByUserName' )]
        [Parameter( ParameterSetName = 'ByAccountId' )]
        [ValidateNotNullOrEmpty()]
        [UInt64]
        $Skip = 0,

        [Parameter()]
        [AtlassianPS.Connection]
        $RequestContext
    )

    begin {
        Write-Verbose "[$($MyInvocation.MyCommand.Name)] Function started"

        $isCloud = Test-JiraCloudServer -RequestContext $RequestContext

        $selfResourceUri = "/rest/api/2/myself"

        if ($isCloud) {
            $searchResourceUri = "/rest/api/2/user/search?query={0}"
            $exactResourceUri = "/rest/api/2/user?accountId={0}"
        }
        else {
            $searchResourceUri = "/rest/api/2/user/search?username={0}"
            $exactResourceUri = "/rest/api/2/user?username={0}"
        }

        if ($IncludeInactive) { $searchResourceUri += "&includeInactive=true" }
        if ($MaxResults) { $searchResourceUri += "&maxResults=$MaxResults" }
        if ($Skip) { $searchResourceUri += "&startAt=$Skip" }
    }

    process {
        Write-DebugMessage "ParameterSetName: $($PsCmdlet.ParameterSetName)"
        Write-DebugMessage -BoundParameters $PSBoundParameters

        $ParameterSetName = ''
        switch ($PsCmdlet.ParameterSetName) {
            'ByInputObject' {
                if ($isCloud) {
                    $lookupValue = foreach ($inputUser in $InputObject) {
                        if ($inputUser.AccountId) { $inputUser.AccountId } else { $inputUser.Name }
                    }
                }
                else {
                    $lookupValue = foreach ($inputUser in $InputObject) { $inputUser.Name }
                }
                $ParameterSetName = 'ByLookupValue'
                $Exact = $true
            }
            'ByAccountId' {
                $lookupValue = $AccountId
                $ParameterSetName = 'ByLookupValue'
                $Exact = $true
            }
            'ByUserName' {
                $lookupValue = $UserName
                $ParameterSetName = 'ByLookupValue'
            }
            'Self' { $ParameterSetName = 'Self' }
        }

        switch ($ParameterSetName) {
            "Self" {
                $resourceURi = $selfResourceUri

                $parameter = @{
                    URI    = $resourceURi
                    Method = "GET"
                }
                Write-DebugMessage "Invoking JiraMethod with `$parameter"
                $result = Invoke-JiraMethod -RequestContext $RequestContext @parameter

                if ($isCloud -and $result.accountId) {
                    Get-JiraUserOperation -AccountId $result.accountId -Exact -RequestContext $RequestContext
                }
                elseif ($result.Name) {
                    Get-JiraUserOperation -UserName $result.Name -Exact -RequestContext $RequestContext
                }
                else { Write-Output (ConvertTo-JiraUser -InputObject $result) }
            }
            "ByLookupValue" {
                $resourceURi = if ($Exact) { $exactResourceUri } else { $searchResourceUri }

                foreach ($user in $lookupValue) {
                    Write-Verbose "[$($MyInvocation.MyCommand.Name)] Processing [$user]"
                    Write-DebugMessage "Processing `$user [$user]"

                    $parameter = @{
                        URI    = $resourceURi -f $user
                        Method = "GET"
                    }
                    Write-DebugMessage "Invoking JiraMethod with `$parameter"
                    if ($users = Invoke-JiraMethod -RequestContext $RequestContext @parameter) {
                        foreach ($item in $users) {
                            $parameter = @{
                                URI    = "{0}&expand=groups" -f $item.self
                                Method = "GET"
                            }
                            Write-DebugMessage "Invoking JiraMethod with `$parameter"
                            $result = Invoke-JiraMethod -RequestContext $RequestContext @parameter

                            Write-Output (ConvertTo-JiraUser -InputObject $result)
                        }
                    }
                    else {
                        $errorMessage = @{
                            Category         = "ObjectNotFound"
                            CategoryActivity = "Searching for user"
                            Message          = "No results when searching for user $user"
                        }
                        Write-Error @errorMessage
                    }
                }
            }
        }
    }

    end {
        Write-Verbose "[$($MyInvocation.MyCommand.Name)] Complete"
    }
}
