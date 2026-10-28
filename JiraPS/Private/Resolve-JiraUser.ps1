function Resolve-JiraUser {
    [CmdletBinding()]
    [OutputType( [AtlassianPS.JiraPS.User] )]
    param(
        [Parameter( Mandatory, ValueFromPipeline )]
        [ValidateNotNull()]
        [AtlassianPS.JiraPS.UserTransformation()]
        [AtlassianPS.JiraPS.User]
        $InputObject,

        [Switch]
        $Exact,

        [Parameter()]
        [AtlassianPS.Connection]
        $RequestContext
    )

    begin {
        $isCloud = Test-JiraCloudServer -RequestContext $RequestContext
    }

    process {
        if ($InputObject.RestUrl) {
            Write-DebugMessage "Using `$InputObject as object"
            return $InputObject
        }

        Write-DebugMessage "Resolve User to object"

        if ($isCloud -and $InputObject.AccountId) {
            return (Get-JiraUserOperation -AccountId $InputObject.AccountId -Exact:$Exact -RequestContext $RequestContext -ErrorAction Stop)
        }

        # Legacy compatibility: if the caller handed us a stub user whose
        # Name slot looks like a Cloud accountId (24 hex chars or the modern
        # `<namespace>:<uuid>` shape), route through /accountId so the GET
        # works without first pre-classifying the input string.
        if ($isCloud -and $InputObject.Name -and (
                $InputObject.Name -match '^[0-9a-f]{24}$' -or
                $InputObject.Name -match '^[A-Za-z0-9]+:[0-9a-f]{8}(?:-[0-9a-f]{4}){3}-[0-9a-f]{12}$'
            )
        ) {
            return (Get-JiraUserOperation -AccountId $InputObject.Name -Exact:$Exact -RequestContext $RequestContext -ErrorAction Stop)
        }

        if ($InputObject.Name) {
            return (Get-JiraUserOperation -UserName $InputObject.Name -Exact:$Exact -RequestContext $RequestContext -ErrorAction Stop)
        }

        $errorItem = New-Object -TypeName System.Management.Automation.ErrorRecord (
            ([System.ArgumentException]"Cannot resolve user: neither AccountId nor Name is set."),
            'ParameterValue.NotJiraUser',
            [System.Management.Automation.ErrorCategory]::InvalidArgument,
            $InputObject
        )
        $PSCmdlet.ThrowTerminatingError($errorItem)
    }
}
