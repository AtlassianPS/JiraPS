function Get-JiraFilter {
    <#
    .Synopsis
       Returns information about a filter in JIRA
    .DESCRIPTION
       This function returns information about a filter in JIRA, including the JQL syntax of the filter, its owner, and sharing status.

       This function is only capable of returning filters by their Filter ID. This is a limitation of JIRA's REST API.  The easiest way to obtain the ID of a filter is to load the filter in the "regular" Web view of JIRA, then copy the ID from the URL of the page.
    .EXAMPLE
       Get-JiraFilter -Id 12345
       Gets a reference to filter ID 12345 from JIRA
    .EXAMPLE
        $filterObject | Get-JiraFilter
        Gets the information of a filter by providing a filter object
    .INPUTS
       [Object[]] The filter to look up in JIRA. This can be a String (filter ID) or a JiraPS.Filter object.
    .OUTPUTS
       [JiraPS.Filter[]] Filter objects
    #>
    [CmdletBinding(DefaultParameterSetName = 'ByFilterID')]
    param(
        # ID of the filter to search for.
        [Parameter(
            Position = 0,
            Mandatory = $true,
            ParameterSetName = 'ByFilterID'
        )]
        [String[]] $Id,

        # Object of the filter to search for.
        [Parameter(
            Mandatory = $true,
            ValueFromPipeline = $true,
            ParameterSetName = 'ByInputObject',
            ValueFromPipelineByPropertyName = $true
        )]
        [Object[]] $InputObject,

        # Credentials to use to connect to JIRA.
        # If not specified, this function will use anonymous access.
        [PSCredential] $Credential
    )

    begin {
        Write-Verbose "[$($MyInvocation.MyCommand.Name)] Function started"

        $server = Get-JiraConfigServer -ConfigFile $ConfigFile -ErrorAction Stop

        $uri = "$server/rest/api/latest/filter/{0}"
    }

    process {
        Write-DebugMessage "[$($MyInvocation.MyCommand.Name)] ParameterSetName: $($PsCmdlet.ParameterSetName)"
        Write-DebugMessage "[$($MyInvocation.MyCommand.Name)] PSBoundParameters: $($PSBoundParameters | Out-String)"

        if ($PSCmdlet.ParameterSetName -eq 'ByFilterID') {
            foreach ($i in $Id) {
                Write-Debug "[Get-JiraFilter] Processing filter [$i]"
                $thisUri = $uri -f $i

                Write-Debug "[$($MyInvocation.MyCommand.Name)] Invoking JiraMethod with `$parameter"
                $result = Invoke-JiraMethod -Method Get -URI $thisUri -Credential $Credential

                if ($result) {
                    Write-Debug "[Get-JiraFilter] Converting result to JiraFilter object"
                    $obj = ConvertTo-JiraFilter -InputObject $result

                    Write-Debug "Outputting result"
                    Write-Output $obj
                }
                else {
                    Write-Debug "[Get-JiraFilter] Invoke-JiraFilter returned no results to output."
                }

            }
        }
        else {
            foreach ($i in $InputObject) {
                Write-Debug "[Get-JiraFilter] Processing InputObject [$i]"
                if ((Get-Member -InputObject $i).TypeName -eq 'JiraPS.Filter') {
                    Write-Debug "[Get-JiraFilter] User parameter is a JiraPS.Filter object"
                    $thisId = $i.ID
                }
                else {
                    $thisId = $i.ToString()
                    Write-Debug "[Get-JiraFilter] ID is assumed to be [$thisId] via ToString()"
                }

                Write-Debug "[Get-JiraFilter] Invoking myself with the FilterID parameter set to search for filter ID [$thisId]"
                $filterObj = Get-JiraFilter -Id $thisId -Credential $Credential
                Write-Debug "[Get-JiraFilter] Returned from invoking myself; outputting results"
                Write-Output $filterObj
            }
        }
    }

    end {
        Write-Verbose "[$($MyInvocation.MyCommand.Name)] Complete"
    }
}
