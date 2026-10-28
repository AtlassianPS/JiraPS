function Get-JiraVersionOperation {
    <#
    .SYNOPSIS
        Retrieve typed versions and apply output limits after name matching.
    #>
    [CmdletBinding(SupportsPaging, DefaultParameterSetName = 'Version')]
    param(
        [Parameter(Mandatory, Position = 0, ValueFromPipeline, ParameterSetName = 'Version')]
        [ValidateNotNull()]
        [Alias('Id')]
        [AtlassianPS.JiraPS.VersionTransformation(AllowPipelineFallthrough = $true)]
        [AtlassianPS.JiraPS.Version[]]$Version,

        [Parameter(Mandatory, ValueFromPipeline, ParameterSetName = 'Project')]
        [ValidateNotNull()]
        [Alias('Key')]
        [AtlassianPS.JiraPS.ProjectTransformation(AllowPipelineFallthrough = $true)]
        [AtlassianPS.JiraPS.Project[]]$Project,

        [Parameter(ParameterSetName = 'Project')]
        [String[]]$Name = '*',

        [Parameter(ParameterSetName = 'Project')]
        [ValidateSet('sequence', 'name', 'startDate', 'releaseDate')]
        [String]$Sort = 'name',

        [ValidateRange(1, [int]::MaxValue)]
        [Int]$PageSize = $script:DefaultPageSize,

        [AtlassianPS.Connection]$RequestContext
    )

    begin { $matches = [Collections.Generic.List[Object]]::new() }
    process {
        if ($PSCmdlet.ParameterSetName -eq 'Version') {
            foreach ($item in $Version) {
                if (-not $item.Id) { throw 'Version requires a numeric version ID. Use -Project and -Name to match version names.' }
                $result = Invoke-JiraRequest -RequestContext $RequestContext -Uri "/rest/api/2/version/$($item.Id)" -Method Get
                foreach ($value in @(ConvertTo-JiraVersion -InputObject $result)) { $matches.Add($value) }
            }
        }
        else {
            foreach ($item in $Project) {
                $projectValue = if ($item.Key) { $item.Key } else { $item.Id }
                $projectObject = Get-JiraProjectOperation -Project $projectValue -RequestContext $RequestContext -ErrorAction Stop
                $parameters = @{
                    Uri          = "/rest/api/2/project/$($projectObject.Key)/version"
                    Method       = 'Get'
                    GetParameter = @{ orderBy = $Sort; maxResults = $PageSize }
                    Paging       = $true
                    PageSize     = $PageSize
                    OutputType   = 'JiraVersion'
                }
                foreach ($value in @(Invoke-JiraRequest -RequestContext $RequestContext @parameters)) {
                    if (@($Name | Where-Object { $value.Name -like $_ }).Count) { $matches.Add($value) }
                }
            }
        }
    }
    end {
        if ($PSCmdlet.PagingParameters.IncludeTotalCount) { $PSCmdlet.PagingParameters.NewTotalCount($matches.Count, 1.0) }
        $skip = [int][Math]::Min($PSCmdlet.PagingParameters.Skip, $matches.Count)
        $first = [int][Math]::Min($PSCmdlet.PagingParameters.First, $matches.Count)
        if ($first) { $matches | Select-Object -Skip $skip -First $first }
    }
}
