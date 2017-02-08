function Get-JiraComponent
{
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
       [PSJira.Component]
    #>
    [CmdletBinding(DefaultParameterSetName = 'ByID')]
    param(
        # The Project ID or project key of a project to search
        [Parameter(ParameterSetName = 'ByProject',
                   ValueFromPipeline,
                   Mandatory = $true)]
        $Project,

        # The Component ID
        [Parameter(Mandatory = $true,
                   Position = 0,
                   ParameterSetName = 'ByID')]
        [Alias("Id")]
        [int[]] $ComponentId,

        # Credentials to use to connect to Jira
        [Parameter(Mandatory = $false)]
        [System.Management.Automation.PSCredential] $Credential
    )

    begin
    {
        Write-Debug "[Get-JiraComponent] Reading server from config file"
        try
        {
            $server = Get-JiraConfigServer -ConfigFile $ConfigFile -ErrorAction Stop
        } catch {
            $err = $_
            Write-Debug "[Get-JiraComponent] Encountered an error reading the Jira server."
            throw $err
        }

        $uri = "$server/rest/api/latest"
    }

    process
    {
        if ($Project)
        {
            if ($Project.PSObject.TypeNames[0] -eq 'PSJira.Project') {
                $ComponentId = @($Project.Components | select -ExpandProperty id)
            } else {
                foreach ($p in $Project)
                {
                    if ($p -is [string])
                    {
                        Write-Debug "[Get-JiraComponent] Processing project [$p]"
                        $thisUri = "$uri/project/${p}/components"

                        Write-Debug "[Get-JiraComponent] Preparing for blastoff!"

                        $result = Invoke-JiraMethod -Method Get -URI $thisUri -Credential $Credential
                        if ($result)
                        {
                            Write-Debug "[Get-JiraComponent] Converting to object"
                            $obj = ConvertTo-JiraComponent -InputObject $result

                            Write-Debug "[Get-JiraComponent] Outputting result"
                            Write-Output $obj
                        } else {
                            Write-Debug "[Get-JiraComponent] No results were returned from Jira"
                            Write-Debug "[Get-JiraComponent] No results were returned from Jira for component [$i]"
                        }
                    }
                }
            }
        }
        if ($ComponentId)
        {
            foreach ($i in $ComponentId)
            {
                Write-Debug "[Get-JiraComponent] Processing component [$i]"
                $thisUri = "$uri/component/${i}"

                Write-Debug "[Get-JiraComponent] Preparing for blastoff!"

                $result = Invoke-JiraMethod -Method Get -URI $thisUri -Credential $Credential
                if ($result)
                {
                    Write-Debug "[Get-JiraComponent] Converting to object"
                    $obj = ConvertTo-JiraComponent -InputObject $result

                    Write-Debug "[Get-JiraComponent] Outputting result"
                    Write-Output $obj
                } else {
                    Write-Debug "[Get-JiraComponent] No results were returned from Jira"
                    Write-Debug "[Get-JiraComponent] No results were returned from Jira for component [$i]"
                }
            }
        }
    }

    end
    {
        Write-Debug "[Get-JiraComponent] Complete"
    }
}
