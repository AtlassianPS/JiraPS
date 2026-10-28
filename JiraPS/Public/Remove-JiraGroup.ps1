function Remove-JiraGroup {
    # .ExternalHelp ..\JiraPS-help.xml
    [CmdletBinding( SupportsShouldProcess, ConfirmImpact = 'High' )]
    param(
        [Parameter( Mandatory, ValueFromPipeline )]
        [ValidateNotNull()]
        [AtlassianPS.JiraPS.GroupTransformation()]
        [Alias('GroupName')]
        [AtlassianPS.JiraPS.Group[]]
        $Group,

        [Parameter()]
        [AtlassianPS.Connection]
        $Connection
    )

    begin {
        Write-Verbose "[$($MyInvocation.MyCommand.Name)] Function started"

        $RequestContext = Resolve-JiraOperationContext -BoundParameters $PSBoundParameters

        $isCloud = Test-JiraCloudServer -RequestContext $RequestContext

        $resourceUri = "/rest/api/2/group"
    }

    process {
        Write-DebugMessage "ParameterSetName: $($PsCmdlet.ParameterSetName)"
        Write-DebugMessage -BoundParameters $PSBoundParameters

        foreach ($_group in $Group) {
            Write-Verbose "[$($MyInvocation.MyCommand.Name)] Processing [$_group]"
            Write-DebugMessage "Processing `$_group [$_group]"

            $getParameter = if ($isCloud -and $_group.Id) { @{ groupId = $_group.Id } }
            else { @{ groupname = $_group.Name } }

            $target = if ($_group.Name) { $_group.Name } else { $_group.Id }

            $parameter = @{
                URI          = $resourceUri
                Method       = "DELETE"
                GetParameter = $getParameter
            }
            Write-DebugMessage "Invoking JiraMethod with `$parameter"
            if ($PSCmdlet.ShouldProcess($target, "Remove group")) { Invoke-JiraRequest -RequestContext $RequestContext @parameter }
        }
    }

    end {
        Write-Verbose "[$($MyInvocation.MyCommand.Name)] Complete"
    }
}
