function Get-JiraComment {
    <#
    .Synopsis
        Modifies an existing issue in JIRA
    .DESCRIPTION
        This function modifies the FixVersion field for an existing issue in JIRA.
    .EXAMPLE
        Get-JiraComment -Issue TEST-01 -FixVersion '1.0.0.0'
        This example assigns the fixversion 1.0.0.0 to the JIRA issue TEST-01.
    .INPUTS
        [PSJira.Issue[]] The JIRA issue that should be modified
    .OUTPUTS
        No Output on success
    #>
    [CmdletBinding()]
    param(
        # Issue key or PSJira.Issue object returned from Get-JiraIssue
        [Parameter(Mandatory = $true,
            Position = 0,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true)]
        [Alias('Key')]
        [Object[]] $Issue,

        # Credentials to use to connect to Jira
        [Parameter(Mandatory = $false)]
        [System.Management.Automation.PSCredential] $Credential
    )

    begin {
        Write-Debug -Message '[Get-JiraComment] Reading information from config file'
        try {
            Write-Debug -Message '[Get-JiraComment] Reading Jira server from config file'
            $server = Get-JiraConfigServer -ConfigFile $ConfigFile -ErrorAction Stop
        }
        catch {
            $err = $_
            Write-Debug -Message '[Get-JiraComment] Encountered an error reading configuration data.'
            throw $err
        }

        Write-Debug "[Get-JiraComment] Completed Begin block."
    }

    process {
        foreach ($i in $Issue) {
            $uri = "$server/rest/api/2/issue/$issue/comment"
            Write-Debug "[Get-JiraComment] Set URI: $URI"

            Write-Debug "[Get-JiraComment] Preparing for blastoff!"
            $result = Invoke-JiraMethod -Method Get -URI $uri -Credential $Credential
            #Results not returning visiblity
            if ($result) {
                Write-Debug "[Get-JiraComment] Converting to object"
                $obj = ConvertTo-JiraComment -InputObject $result.comments

                Write-Debug "[Get-JiraComment] Outputting result"
                Write-Output $obj
            }
            else {
                Write-Debug "[Get-JiraComment] No results were returned from Jira"
                Write-Debug "[Get-JiraComment] No project results were returned from Jira"
            }
        }
    }

    end {
        Write-Debug "[Get-JiraComment] Complete"
    }
}