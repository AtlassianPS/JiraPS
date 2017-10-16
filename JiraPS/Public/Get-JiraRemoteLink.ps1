function Get-JiraRemoteLink {
    <#
    .Synopsis
       Returns a remote link from a Jira issue
    .DESCRIPTION
       This function returns information on remote links from a  JIRA issue.
    .EXAMPLE
       Get-JiraRemoteLink -Issue Project1-1000 -Credential $cred
       Returns information about all remote links from the issue "Project1-1000"
    .EXAMPLE
       Get-JiraRemoteLink -Issue Project1-1000 -LinkId 100000 -Credential $cred
       Returns information about a specific remote link from the issue "Project1-1000"
    .INPUTS
       [Object[]] The issue to look up in JIRA. This can be a String or a JiraPS.Issue object.
    .OUTPUTS
       [JiraPS.Link]
    #>
    [CmdletBinding()]
    param(
        # The Issue Object or ID to link.
        [Parameter(
            Position = 0,
            Mandatory = $true,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true
        )]
        [Alias("Key")]
        [String[]]$Issue,

        # Get a single link by it's id.
        [Int]$LinkId,

        # Credentials to use to connect to JIRA.
        # If not specified, this function will use anonymous access.
        [Parameter(Mandatory = $false)]
        [PSCredential] $Credential
    )

    Begin {
        Write-Debug "[Get-JiraRemoteLink] Reading server from config file"
        $server = Get-JiraConfigServer -ConfigFile $ConfigFile -ErrorAction Stop

        Write-Debug "[Get-JiraRemoteLink] ParameterSetName=$($PSCmdlet.ParameterSetName)"

        Write-Debug "[Get-JiraRemoteLink] Building URI for REST call"
        $linkUrl = "$server/rest/api/latest/issue/{0}/remotelink"
    }

    Process {
        foreach ($k in $Issue) {
            Write-Debug "[Get-JiraRemoteLink] Processing issue key [$k]"
            $thisUrl = $linkUrl -f $k

            if ($linkId) {
                $thisUrl += "/$l"
            }

            Write-Debug "[Get-JiraRemoteLink] Preparing for blastoff!"
            $result = Invoke-JiraMethod -Method Get -URI $thisUrl -Credential $Credential

            if ($result) {
                Write-Debug "[Get-JiraRemoteLink] Converting results to JiraPS.Group"
                $obj = ConvertTo-JiraLink -InputObject $result

                Write-Debug "[Get-JiraRemoteLink] Outputting results"
                Write-Output $obj
            }
            else {
                Write-Debug "[Get-JiraRemoteLink] No results were returned from JIRA"
                Write-Verbose "No results were returned from JIRA."
            }
        }
    }

    End {
        Write-Debug "[Get-JiraRemoteLink] Complete"
    }
}
