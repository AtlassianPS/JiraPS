function Get-JiraVersionOperation {
    [CmdletBinding( SupportsPaging, DefaultParameterSetName = 'byInputVersion' )]
    param(
        [Parameter( Mandatory, ParameterSetName = 'byId' )]
        [Int[]]
        $Id,

        [Parameter( Position = 0, Mandatory, ValueFromPipeline, ParameterSetName = 'byInputVersion' )]
        [ValidateNotNull()]
        [AtlassianPS.JiraPS.VersionTransformation(AllowPipelineFallthrough = $true)]
        [AtlassianPS.JiraPS.Version]
        $InputVersion,

        [Parameter( Position = 0, Mandatory , ParameterSetName = 'byProject' )]
        [Alias('Key')]
        [String[]]
        $Project,

        [Parameter( Position = 0, Mandatory, ValueFromPipeline, ParameterSetName = 'byInputProject' )]
        [AtlassianPS.JiraPS.ProjectTransformation(AllowPipelineFallthrough = $true)]
        [AtlassianPS.JiraPS.Project[]]
        $InputProject,

        [Parameter( ParameterSetName = 'byProject' )]
        [Parameter( ParameterSetName = 'byInputProject' )]
        [Alias('Versions')]
        [String[]]
        $Name = "*",

        [Parameter( ParameterSetName = 'byProject' )]
        [Parameter( ParameterSetName = 'byInputProject' )]
        [ValidateSet("sequence",
            "name",
            "startDate",
            "releaseDate"
        )]
        [String]
        $Sort = "name",

        [UInt32]
        $PageSize = $script:DefaultPageSize,

        [Parameter()]
        [AtlassianPS.Connection]
        $RequestContext
    )

    begin {
        Write-Verbose "[$($MyInvocation.MyCommand.Name)] Function started"

        $resourceURi = "/rest/api/2/{0}"
    }

    process {
        Write-DebugMessage "ParameterSetName: $($PsCmdlet.ParameterSetName)"
        Write-DebugMessage -BoundParameters $PSBoundParameters

        $ParameterSetName = ''
        switch ($PsCmdlet.ParameterSetName) {
            'byInputProject' {
                $Project = @(
                    $InputProject | ForEach-Object {
                        if ($_.Key) { $_.Key } else { $_.Id }
                    }
                )
                $ParameterSetName = 'byProject'
            }
            'byInputVersion' {
                if (-not $InputVersion.Id) {
                    $errorItem = [System.Management.Automation.ErrorRecord]::new(
                        ([System.ArgumentException]"Version ID is required"),
                        'ParameterValue.VersionIdRequired',
                        [System.Management.Automation.ErrorCategory]::InvalidArgument,
                        $InputVersion
                    )

                    $errorItem.ErrorDetails = "Get-JiraVersion requires a version ID when -InputVersion is used. Provide a numeric version ID or an AtlassianPS.JiraPS.Version object with an ID."
                    ThrowError -ErrorRecord $errorItem
                }
                $Id = $InputVersion.Id
                $ParameterSetName = 'byId'
            }
            'byProject' { $ParameterSetName = 'byProject' }
            'byId' { $ParameterSetName = 'byId' }
        }

        switch ($ParameterSetName) {
            "byId" {
                foreach ($_id in $ID) {
                    Write-Verbose "[$($MyInvocation.MyCommand.Name)] Processing [$_id]"
                    Write-DebugMessage "Processing `$_id [$_id]"

                    $parameter = @{
                        URI    = $resourceURi -f "version/$_id"
                        Method = "GET"
                    }
                    Write-DebugMessage "Invoking JiraMethod with `$parameter"
                    $result = Invoke-JiraRequest -RequestContext $RequestContext @parameter

                    Write-Output (ConvertTo-JiraVersion -InputObject $result)
                }
            }
            "byProject" {
                foreach ($_project in $Project) {
                    Write-Verbose "[$($MyInvocation.MyCommand.Name)] Processing [$_project]"
                    Write-DebugMessage "Processing `$_project [$_project]"

                    $projectData = Get-JiraProjectOperation -Project $_project -RequestContext $RequestContext

                    $parameter = @{
                        URI          = $resourceURi -f "project/$($projectData.key)/version"
                        Method       = "GET"
                        GetParameter = @{
                            orderBy    = $Sort
                            maxResults = $PageSize
                        }
                        Paging       = $true
                        OutputType   = "JiraVersion"
                    }
                    # Paging
                    ($PSCmdlet.PagingParameters | Get-Member -MemberType Property).Name | ForEach-Object {
                        $parameter[$_] = $PSCmdlet.PagingParameters.$_
                    }

                    Write-DebugMessage "Invoking JiraMethod with `$parameter"
                    if ($result = Invoke-JiraRequest -RequestContext $RequestContext @parameter) {
                        $result | Where-Object {
                            $__ = $_.Name
                            Write-DebugMessage ($__ | Out-String)
                            $Name | ForEach-Object {
                                Write-Verbose "[$($MyInvocation.MyCommand.Name)] Matching $_ against $($__)"
                                $__ -like $_
                            }
                        }
                    }
                }
            }
        }
    }

    end {
        Write-Verbose "[$($MyInvocation.MyCommand.Name)] Complete"
    }
}
