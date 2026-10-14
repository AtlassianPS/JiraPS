function Select-JiraConnection {
    # .ExternalHelp ..\JiraPS-help.xml
    [CmdletBinding(DefaultParameterSetName = 'Object')]
    [OutputType([AtlassianPS.Connection])]
    param(
        [Parameter(Mandatory, ValueFromPipeline, ParameterSetName = 'Object')]
        [Alias('Session')]
        [AtlassianPS.Connection]$Connection,

        [Parameter(Mandatory, ParameterSetName = 'Name')]
        [String]$Name,

        [Parameter(Mandatory, ParameterSetName = 'Id')]
        [Int]$Id
    )

    process {
        if ($PSCmdlet.ParameterSetName -eq 'Name') { $Connection = Get-JiraConnection -Name $Name }
        elseif ($PSCmdlet.ParameterSetName -eq 'Id') { $Connection = Get-JiraConnection -Id $Id }

        $Connection = AtlassianPS.Configuration\Resolve-AtlassianRequestContext -Product Jira -Connection $Connection
        AtlassianPS.Configuration\Select-AtlassianConnection -Connection $Connection
    }
}
