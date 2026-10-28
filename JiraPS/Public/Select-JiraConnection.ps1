function Select-JiraConnection {
    # .ExternalHelp ..\JiraPS-help.xml
    [CmdletBinding( DefaultParameterSetName = 'Object' )]
    [OutputType( [AtlassianPS.Connection] )]
    param(
        [Parameter( Mandatory, ValueFromPipeline, ParameterSetName = 'Object' )]
        [AtlassianPS.Connection]
        $Connection,

        [Parameter( Mandatory, ParameterSetName = 'Name' )]
        [String]
        $Name,

        [Parameter( Mandatory, ParameterSetName = 'Id' )]
        [Int]
        $Id
    )

    process {
        $Connection = if ($PSCmdlet.ParameterSetName -eq 'Name') { Get-JiraConnection -Name $Name }
        elseif ($PSCmdlet.ParameterSetName -eq 'Id') { Get-JiraConnection -Id $Id }
        else { $Connection }

        $Connection = AtlassianPS.Configuration\Resolve-AtlassianRequestContext -Product Jira -Connection $Connection
        AtlassianPS.Configuration\Select-AtlassianConnection -Connection $Connection
    }
}
