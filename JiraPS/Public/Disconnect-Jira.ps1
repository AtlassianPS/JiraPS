function Disconnect-Jira {
    # .ExternalHelp ..\JiraPS-help.xml
    [CmdletBinding(SupportsShouldProcess, DefaultParameterSetName = 'Default')]
    param(
        [Parameter(Mandatory, ValueFromPipeline, ParameterSetName = 'Object')]
        [Alias('Session')]
        [AtlassianPS.Connection]$Connection,

        [Parameter(Mandatory, ParameterSetName = 'Name')]
        [String]$Name,

        [Parameter(Mandatory, ParameterSetName = 'Id')]
        [Int]$Id,

        [Parameter(Mandatory, ParameterSetName = 'All')]
        [Switch]$All
    )

    process {
        if ($PSCmdlet.ParameterSetName -eq 'All' -and -not $All) { throw 'All must be enabled explicitly.' }

        $targets = switch ($PSCmdlet.ParameterSetName) {
            'Object' { AtlassianPS.Configuration\Resolve-AtlassianRequestContext -Product Jira -Connection $Connection }
            'Name' { Get-JiraConnection -Name $Name }
            'Id' { Get-JiraConnection -Id $Id }
            'All' { Get-JiraConnection }
            'Default' { Get-JiraConnection -Default }
        }
        if (-not $targets -and $PSCmdlet.ParameterSetName -ne 'Default') { throw 'Jira connection not found.' }

        foreach ($target in $targets) {
            if ($PSCmdlet.ShouldProcess($target.ToString(), 'Disconnect Jira')) {
                AtlassianPS.Configuration\Disconnect-AtlassianConnection -Connection $target -Confirm:$false
            }
        }
    }
}
