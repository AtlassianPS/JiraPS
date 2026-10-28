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
        [System.Management.Automation.PSCredential]
        [System.Management.Automation.Credential()]
        $Credential,

        [Switch]
        $Force,

        [Alias('Session')]
        [AtlassianPS.Connection]
        $Connection
    )

    begin {
        Write-Verbose "[$($MyInvocation.MyCommand.Name)] Function started"

        try {
            $RequestContext = Resolve-JiraOperationContext -BoundParameters $PSBoundParameters

            $isCloud = Test-JiraCloudServer -RequestContext $RequestContext

            $resourceURi = if ($isCloud) { "/rest/api/2/user?accountId={0}" }
            else { "/rest/api/2/user?username={0}" }

            if ($Force) {
                Write-DebugMessage "[Remove-JiraGroup] -Force was passed. Backing up current ConfirmPreference [$ConfirmPreference] and setting to None"
                $oldConfirmPreference = $ConfirmPreference
                $ConfirmPreference = 'None'
            }
        }
        catch {
            if ($RequestContext -and $RequestContext.State -eq 'Standalone') { $RequestContext.Dispose() }
            throw
        }
    }

    process {
        try {
            Write-DebugMessage "ParameterSetName: $($PsCmdlet.ParameterSetName)"
            Write-DebugMessage -BoundParameters $PSBoundParameters

            $userObj = Resolve-JiraUser -InputObject $User -RequestContext $RequestContext -ErrorAction Stop

            $userIdentifier = if ($userObj.AccountId) { $userObj.AccountId }
            else { $userObj.Name }
            $parameter = @{
                URI    = $resourceURi -f $userIdentifier
                Method = "DELETE"
            }
            Write-DebugMessage "Invoking JiraMethod with `$parameter"
            if ($PSCmdlet.ShouldProcess($userObj.DisplayName, 'Remove user')) { Invoke-JiraMethod -RequestContext $RequestContext @parameter }
        }
        catch {
            if ($RequestContext -and $RequestContext.State -eq 'Standalone') { $RequestContext.Dispose() }
            throw
        }
    }

    end {
        try {
            if ($Force) {
                Write-DebugMessage "Restoring ConfirmPreference to [$oldConfirmPreference]"
                $ConfirmPreference = $oldConfirmPreference
            }

            Write-Verbose "[$($MyInvocation.MyCommand.Name)] Complete"
        }
        finally {
            if ($RequestContext.State -eq 'Standalone') { $RequestContext.Dispose() }
        }
    }
}
