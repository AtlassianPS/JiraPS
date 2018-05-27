function Get-JiraVersion {
    [CmdletBinding( DefaultParameterSetName = 'byId' )]
    param(
        [Parameter( Mandatory, ParameterSetName = 'byId' )]
        [Int[]]
        $Id,

        [Parameter( Position = 0, Mandatory, ValueFromPipeline, ParameterSetName = 'byInputVersion' )]
        [PSTypeName('JiraPS.Version')]
        $InputVersion,

        [Parameter( Position = 0, Mandatory , ParameterSetName = 'byProject' )]
        [Alias('Key')]
        [String[]]
        $Project,

        [Parameter( Position = 0, Mandatory, ValueFromPipeline, ParameterSetName = 'byInputProject' )]
        [PSTypeName('JiraPS.Project')]
        $InputProject,

        [Parameter( ParameterSetName = 'byProject' )]
        [Parameter( ParameterSetName = 'byInputProject' )]
        [Alias('Versions')]
        [String[]]
        $Name,

        [Parameter()]
        [System.Management.Automation.PSCredential]
        [System.Management.Automation.Credential()]
        $Credential = [System.Management.Automation.PSCredential]::Empty
    )

    begin {
        Write-Verbose "[$($MyInvocation.MyCommand.Name)] Function started"

        $server = Get-JiraConfigServer -ErrorAction Stop

        $resourceURi = "$server/rest/api/latest/{0}"
    }

    process {
        Write-DebugMessage "[$($MyInvocation.MyCommand.Name)] ParameterSetName: $($PsCmdlet.ParameterSetName)"
        Write-DebugMessage "[$($MyInvocation.MyCommand.Name)] PSBoundParameters: $($PSBoundParameters | Out-String)"

        $ParameterSetName = ''
        switch ($PsCmdlet.ParameterSetName) {
            'byInputProject' { $Project = $InputProject.Key; $ParameterSetName = 'byProject' }
            'byInputVersion' { $Id = $InputVersion.Id; $ParameterSetName = 'byId' }
            'byProject' { $ParameterSetName = 'byProject' }
            'byId' { $ParameterSetName = 'byId' }
        }

        switch ($ParameterSetName) {
            "byId" {
                foreach ($_id in $ID) {
                    Write-Verbose "[$($MyInvocation.MyCommand.Name)] Processing [$_id]"
                    Write-Debug "[$($MyInvocation.MyCommand.Name)] Processing `$_id [$_id]"

                    $parameter = @{
                        URI        = $resourceURi -f "version/$_id"
                        Method     = "GET"
                        Credential = $Credential
                    }
                    Write-Debug "[$($MyInvocation.MyCommand.Name)] Invoking JiraMethod with `$parameter"
                    $result = Invoke-JiraMethod @parameter

                    Write-Output (ConvertTo-JiraVersion -InputObject $result)
                }
            }
            "byProject" {
                foreach ($_project in $Project) {
                    Write-Verbose "[$($MyInvocation.MyCommand.Name)] Processing [$_project]"
                    Write-Debug "[$($MyInvocation.MyCommand.Name)] Processing `$_project [$_project]"

                    $projectData = Get-JiraProject -Project $_project -Credential $Credential

                    $parameter = @{
                        URI        = $resourceURi -f "project/$($projectData.key)/versions"
                        Method     = "GET"
                        Credential = $Credential
                    }
                    Write-Debug "[$($MyInvocation.MyCommand.Name)] Invoking JiraMethod with `$parameter"
                    $result = Invoke-JiraMethod @parameter

                    if ($Name) {
                        $result = $result | Where-Object {$_.Name -in $Name}
                    }

                    Write-Output (ConvertTo-JiraVersion -InputObject $result)
                }
            }
        }
    }
    end {
        Write-Verbose "[$($MyInvocation.MyCommand.Name)] Complete"
    }
}
