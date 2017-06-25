function Get-JiraIssueLink {
    <#
    .Synopsis
       Returns a specific issueLink from Jira
    .DESCRIPTION
       This function returns information regarding a specified issueLink from Jira.
    .EXAMPLE
       Get-JiraIssueLink 10000
       Returns information about the IssueLink with ID 10000
    .EXAMPLE
       Get-JiraIssueLink -IssueLink 10000
       Returns information about the IssueLink with ID 10000
    .EXAMPLE
       (Get-JiraIssue TEST-01).issuelinks | Get-JiraIssueLink
       Returns the information about all IssueLinks in issue TEST-01
    .INPUTS
       [Int[]] issueLink ID
       [PSCredential] Credentials to use to connect to Jira
    .OUTPUTS
       [JiraPS.IssueLink]
    #>
    [CmdletBinding()]
    param(
        # The IssueLink ID to search
        #
        # Accepts input from pipeline when the object is of type JiraPS.IssueLink
        [Parameter(
            Position = 0,
            Mandatory = $true,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true
        )]
        [Int[]] $Id,

        # Credentials to use to connect to Jira
        [Parameter(Mandatory = $false)]
        [System.Management.Automation.PSCredential] $Credential
    )

    begin {
        Write-Debug "[Get-JiraIssueLink] Reading server from config file"
        $server = Get-JiraConfigServer -ConfigFile $ConfigFile -ErrorAction Stop

        $uri = "$server/rest/api/2/issueLink/{0}"
    }

    process {
        # Validate input object from Pipeline
        if (($_) -and ($_.PSObject.TypeNames[0] -ne "JiraPS.IssueLink")) {
            $message = "Wrong object type provided for IssueLink."
            $exception = New-Object -TypeName System.ArgumentException -ArgumentList $message
            Throw $exception
        }

        foreach ($ilink in $Id) {
            Write-Debug "[Get-JiraIssueLink] Processing project [$ilink]"
            $thisUri = $uri -f $ilink

            Write-Debug "[Get-JiraIssueLink] Preparing for blastoff!"

            $result = Invoke-JiraMethod -Method Get -URI $thisUri -Credential $Credential
            if ($result) {
                Write-Debug "[Get-JiraIssueLink] Converting to object"
                $obj = ConvertTo-JiraIssueLink -InputObject $result

                Write-Debug "[Get-JiraIssueLink] Outputting result"
                Write-Output $obj
            }
            else {
                Write-Debug "[Get-JiraIssueLink] No results were returned from Jira"
                Write-Debug "[Get-JiraIssueLink] No results were returned from Jira for project [$ilink]"
            }
        }
    }

    end {
        Write-Debug "[Get-JiraIssueLink] Complete"
    }
}


