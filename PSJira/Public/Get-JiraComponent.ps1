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
    .INPUTS
       [String[]] Component ID
       [PSCredential] Credentials to use to connect to Jira
    .OUTPUTS
       [PSJira.Component]
    #>
    [CmdletBinding()]
    param(
        # The Component ID
        [Parameter(Mandatory = $true,
                   Position = 0,
                   ParameterSetName = 'ID')]
        [String[]] $Id,

        # Credentials to use to connect to Jira
        [Parameter(Mandatory = $false)]
        [System.Management.Automation.PSCredential] $Credential,

        # Credentials to use to connect to Jira
        [Parameter(Mandatory = $true,
                   ValueFromPipeline,
                   ParameterSetName = 'InputObject')]
        [PSObject] $InputObject
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

        $uri = "$server/rest/api/latest/component"
    }

    process
    {
        if ($InputObject -and ($InputObject.PSObject.TypeNames[0] -eq 'PSJira.Project')) {
            $Id = @($InputObject.Components | select -ExpandProperty id)
        }
        if ($Id)
        {
            foreach ($i in $Id)
            {
                Write-Debug "[Get-JiraComponent] Processing project [$i]"
                $thisUri = "$uri/${i}"

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
        Write-Debug "Complete"
    }
}


