function Get-JiraUser {
    # .ExternalHelp ..\JiraPS-help.xml
    [CmdletBinding( DefaultParameterSetName = 'Self' )]
    param(
        [Parameter( Position = 0, Mandatory, ValueFromPipelineByPropertyName, ParameterSetName = 'ByUserName' )]
        [AllowEmptyString()]
        [Alias('User', 'Name')]
        [String[]]
        $UserName,

        [Parameter( Position = 0, Mandatory, ParameterSetName = 'ByInputObject' )]
        [Object[]] $InputObject,

        [Parameter( ParameterSetName = 'ByInputObject' )]
        [Parameter( ParameterSetName = 'ByUserName' )]
        [Switch]$Exact,

        [Switch]
        $IncludeInactive,

        [Parameter( ParameterSetName = 'ByUserName' )]
        [ValidateRange(1, 1000)]
        [UInt32]
        $MaxResults = 50,

        [Parameter( ParameterSetName = 'ByUserName' )]
        [ValidateNotNullOrEmpty()]
        [UInt64]
        $Skip = 0,

        [Parameter()]
        [System.Management.Automation.PSCredential]
        [System.Management.Automation.Credential()]
        $Credential = [System.Management.Automation.PSCredential]::Empty
    )

    begin {
        Write-Verbose "[$($MyInvocation.MyCommand.Name)] Function started"

        $selfResourceUri = "rest/api/latest/myself"
        $searchResourceUri = "rest/api/latest/user/search?username={0}"
        $exactResourceUri = "rest/api/latest/user?username={0}"

        if ($IncludeInactive) {
            $searchResourceUri += "&includeInactive=true"
        }
        if ($MaxResults) {
            $searchResourceUri += "&maxResults=$MaxResults"
        }
        if ($Skip) {
            $searchResourceUri += "&startAt=$Skip"
        }
    }

    process {
        Write-DebugMessage "[$($MyInvocation.MyCommand.Name)] ParameterSetName: $($PsCmdlet.ParameterSetName)"
        Write-DebugMessage "[$($MyInvocation.MyCommand.Name)] PSBoundParameters: $($PSBoundParameters | Out-String)"

        $ParameterSetName = ''
        switch ($PsCmdlet.ParameterSetName) {
            'ByInputObject' { $UserName = $InputObject.Name; $ParameterSetName = 'ByUserName'; $Exact = $true }
            'ByUserName' { $ParameterSetName = 'ByUserName' }
            'Self' { $ParameterSetName = 'Self' }
        }

        switch ($ParameterSetName) {
            "Self" {
                $resourceURi = $selfResourceUri

                $parameter = @{
                    URI        = $resourceURi
                    Method     = "GET"
                    Credential = $Credential
                }
                Write-Debug "[$($MyInvocation.MyCommand.Name)] Invoking JiraMethod with `$parameter"
                $result = Invoke-JiraMethod @parameter

                Get-JiraUser -UserName $result.Name -Exact
            }
            "ByInputObject" {
                $UserName = $InputObject.Name

                $PsCmdlet.ParameterSetName = "ByUserName"
            }
            "ByUserName" {
                $resourceURi = if ($Exact) { $exactResourceUri } else { $searchResourceUri }

                foreach ($user in $UserName) {
                    Write-Verbose "[$($MyInvocation.MyCommand.Name)] Processing [$user]"
                    Write-Debug "[$($MyInvocation.MyCommand.Name)] Processing `$user [$user]"

                    $parameter = @{
                        URI        = $resourceURi -f $user
                        Method     = "GET"
                        Credential = $Credential
                    }
                    Write-Debug "[$($MyInvocation.MyCommand.Name)] Invoking JiraMethod with `$parameter"
                    if ($users = Invoke-JiraMethod @parameter) {
                        foreach ($item in $users) {
                            $parameter = @{
                                URI        = "{0}&expand=groups" -f $item.self
                                Method     = "GET"
                                Credential = $Credential
                            }
                            Write-Debug "[$($MyInvocation.MyCommand.Name)] Invoking JiraMethod with `$parameter"
                            $result = Invoke-JiraMethod @parameter

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
