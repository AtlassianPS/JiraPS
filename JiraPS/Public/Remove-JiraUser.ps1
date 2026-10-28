function Remove-JiraUser {
    # .ExternalHelp ..\JiraPS-help.xml
    [CmdletBinding( ConfirmImpact = 'High', SupportsShouldProcess )]
    param(
        [Parameter( Mandatory, ValueFromPipeline )]
        [ValidateNotNull()]
        [AtlassianPS.JiraPS.UserTransformation()]
        [Alias('UserName')]
        [AtlassianPS.JiraPS.User]
        $User,

        [Parameter()]
        [AtlassianPS.Connection]
        $Connection
    )

    begin {
        Write-Verbose "[$($MyInvocation.MyCommand.Name)] Function started"

        $RequestContext = Resolve-JiraOperationContext -BoundParameters $PSBoundParameters

        $isCloud = Test-JiraCloudServer -RequestContext $RequestContext

        $resourceURi = if ($isCloud) { "/rest/api/2/user?accountId={0}" }
        else { "/rest/api/2/user?username={0}" }
    }

    process {
        Write-DebugMessage "ParameterSetName: $($PsCmdlet.ParameterSetName)"
        Write-DebugMessage -BoundParameters $PSBoundParameters

        $userObj = Resolve-JiraUser -InputObject $User -RequestContext $RequestContext -ErrorAction Stop

        $userIdentifier = if ($isCloud) { $userObj.AccountId } else { $userObj.Name }
        if (-not $userIdentifier) { throw 'User requires an accountId on Cloud or a username on Data Center.' }
        $parameter = @{
            URI    = $resourceURi -f [Uri]::EscapeDataString($userIdentifier)
            Method = "DELETE"
        }
        Write-DebugMessage "Invoking JiraMethod with `$parameter"
        if ($PSCmdlet.ShouldProcess($userObj.DisplayName, 'Remove user')) { Invoke-JiraRequest -RequestContext $RequestContext @parameter }
    }

    end {
        Write-Verbose "[$($MyInvocation.MyCommand.Name)] Complete"
    }
}
