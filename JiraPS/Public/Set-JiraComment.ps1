function Set-JiraComment {
    <#
    .Synopsis
        Modifies an existing issue in JIRA
    .DESCRIPTION
        This function modifies the FixVersion field for an existing issue in JIRA.
    .EXAMPLE
        Set-JiraComment -Issue TEST-01 -FixVersion '1.0.0.0'
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

        # Set the Comment of the issue, this will overwrite any present Comment
        [Parameter(Mandatory = $true,            
            ValueFromPipelineByPropertyName = $true)]
        [String] $Comment,

        [Parameter(Mandatory = $true,            
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true)]
        [Alias('ID')]
        [int] $CommentID,

        [Parameter(Mandatory = $true,            
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true)]
        [uri] $RestUrl,

        <#
        Visibility not returning in result of get, unable to set without return results
        [Parameter(Mandatory = $false,            
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true)]
        [int] $Visibility,
        #>

        # Credentials to use to connect to Jira
        [Parameter(Mandatory = $false)]
        [System.Management.Automation.PSCredential] $Credential
    )

    begin {
        Write-Debug -Message '[Set-JiraComment] Reading information from config file'
        try {
            Write-Debug -Message '[Set-JiraComment] Reading Jira server from config file'
            $server = Get-JiraConfigServer -ConfigFile $ConfigFile -ErrorAction Stop
        }
        catch {
            $err = $_
            Write-Debug -Message '[Set-JiraComment] Encountered an error reading configuration data.'
            throw $err
        }

        Write-Debug "[Set-JiraComment] Completed Begin block."
    }

    process {
        foreach ($i in $Issue) {
            If($RestUrl)
            {
                $uri = $RestUrl
            }
            Else
            {
                $uri = "$server/rest/api/2/issue/$issue/comment/$CommentID"
            }
            Write-Debug "[Set-JiraComment] Set URI: $URI"

            $body = @{}
            $body.body = $Comment
            <#
            $body.visibility = @{
                type = 'role'
                value = 'Administrators'
            }
            #>
            Write-Debug "[Set-JiraComment] Preparing for blastoff!"
            $result = Invoke-JiraMethod -Method Put -URI $uri -Body ($body | ConvertTo-Json) -Credential $Credential
            if ($result) {
                Write-Debug "[Get-JiraComment] Converting to object"
                $obj = ConvertTo-JiraComment -InputObject $result

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
        Write-Debug "[Set-JiraComment] Complete"
    }
}