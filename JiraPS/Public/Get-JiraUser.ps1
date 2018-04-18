function Get-JiraUser {
    [CmdletBinding( DefaultParameterSetName = 'ByUserName' )]
    param(
        [Parameter( Position = 0, Mandatory, ValueFromPipelineByPropertyName, ParameterSetName = 'ByUserName' )]
        [ValidateNotNullOrEmpty()]
        [Alias('User', 'Name')]
        [String[]]
        $UserName,

        [Parameter( Position = 0, Mandatory, ParameterSetName = 'ByInputObject' )]
        [Object[]] $InputObject,

        [Switch]
        $IncludeInactive,

        [PSCredential]
        $Credential
    )

    begin {
        Write-Verbose "[$($MyInvocation.MyCommand.Name)] Function started"

        $server = Get-JiraConfigServer -ErrorAction Stop

        $resourceURi = "$server/rest/api/latest/user/search?username={0}"

        if ($IncludeInactive) {
            $resourceURi += "&includeInactive=true"
        }
    }

    process {
        Write-DebugMessage "[$($MyInvocation.MyCommand.Name)] ParameterSetName: $($PsCmdlet.ParameterSetName)"
        Write-DebugMessage "[$($MyInvocation.MyCommand.Name)] PSBoundParameters: $($PSBoundParameters | Out-String)"

        if ($InputObject) {
            $UserName = $InputObject.Name
        }

        foreach ($user in $UserName) {
            Write-Verbose "[$($MyInvocation.MyCommand.Name)] Processing [$user]"
            Write-Debug "[$($MyInvocation.MyCommand.Name)] Processing `$user [$user]"

            $parameter = @{
                URI        = $resourceURi -f $user
                Method     = "GET"
                Credential = $Credential
            }
            Write-Debug "[$($MyInvocation.MyCommand.Name)] Invoking JiraMethod with `$parameter"
            if ($result = Invoke-JiraMethod @parameter) {
                $parameter = @{
                    URI        = "{0}&expand=groups" -f $result.self
                    Method     = "GET"
                    Credential = $Credential
                }
                Write-Debug "[$($MyInvocation.MyCommand.Name)] Invoking JiraMethod with `$parameter"
                $result = Invoke-JiraMethod @parameter

                Write-Output (ConvertTo-JiraUser -InputObject $result)
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

    end {
        Write-Verbose "[$($MyInvocation.MyCommand.Name)] Complete"
    }
}
