function Get-JiraComponent {
    <#
    .Synopsis
       Returns a Component from Jira
    .DESCRIPTION
       This function returns information regarding a specified component from Jira.
       If -InputObject is given via parameter or pipe all components for
       the given project are returned.
       It is not possible to get all components with this function.
    .EXAMPLE
       Get-JiraComponent -Id 10000 -Credential $cred
       Returns information about the component with ID 10000
    .EXAMPLE
       Get-JiraComponent 20000 -Credential $cred
       Returns information about the component with ID 20000
    .EXAMPLE
       Get-JiraProject Project1 | Get-JiraComponent -Credential $cred
       Returns information about all components within project 'Project1'
    .EXAMPLE
        Get-JiraComponent ABC,DEF
        Return information about all components within projects 'ABC' and 'DEF'
    .INPUTS
       [String[]] Component ID
       [PSCredential] Credentials to use to connect to Jira
    .OUTPUTS
       [JiraPS.Component]
    #>
    [CmdletBinding(DefaultParameterSetName = 'ByID')]
    param(
        # The Project ID or project key of a project to search.
        [Parameter(
            Mandatory = $true,
            ValueFromPipeline = $true,
            ParameterSetName = 'ByProject'
        )]
        [Object[]] $Project,

        # The Component ID.
        [Parameter(
            Position = 0,
            Mandatory = $true,
            ParameterSetName = 'ByID'
        )]
        [Alias("Id")]
        [Int[]] $ComponentId,

        # Credentials to use to connect to JIRA.
        # If not specified, this function will use anonymous access.
        [PSCredential] $Credential
    )

    begin {
        Write-Verbose "[$($MyInvocation.MyCommand.Name)] Function started"

        $server = Get-JiraConfigServer -ConfigFile $ConfigFile -ErrorAction Stop

        $resourceURi = "$server/rest/api/latest{0}"
    }

    process {
        Write-DebugMessage "[$($MyInvocation.MyCommand.Name)] ParameterSetName: $($PsCmdlet.ParameterSetName)"
        Write-DebugMessage "[$($MyInvocation.MyCommand.Name)] PSBoundParameters: $($PSBoundParameters | Out-String)"

        switch ($PSCmdlet.ParameterSetName) {
            "ByProject" {
                if ($Project.PSObject.TypeNames -contains 'JiraPS.Project') {
                    Get-JiraComponent -ComponentId ($Project.Components).id
                }
                else {
                    foreach ($p in $Project) {
                        Write-Debug "[$($MyInvocation.MyCommand.Name)] Processing project [$p]"

                        if ($p -is [string]) {
                            $parameter = @{
                                URI        = $resourceURi -f "/project/${p}/components"
                                Method     = "GET"
                                Credential = $Credential
                            }
                            Write-Debug "[$($MyInvocation.MyCommand.Name)] Invoking JiraMethod with `$parameter"
                            $result = Invoke-JiraMethod @parameter

                            ConvertTo-JiraComponent -InputObject $result
                        }
                    }
                }
            }
            "ByID" {
                foreach ($i in $ComponentId) {
                    Write-Debug "[$($MyInvocation.MyCommand.Name)] Processing component [$i]"

                    $parameter = @{
                        URI        = $resourceURi -f "/component/${i}"
                        Method     = "GET"
                        Credential = $Credential
                    }
                    Write-Debug "[$($MyInvocation.MyCommand.Name)] Invoking JiraMethod with `$parameter"
                    $result = Invoke-JiraMethod @parameter

                    ConvertTo-JiraComponent -InputObject $result
                }
            }
        }
    }

    end {
        Write-Verbose "[$($MyInvocation.MyCommand.Name)] Complete"
    }
}
