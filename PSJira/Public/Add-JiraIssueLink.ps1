function Add-JiraIssueLink {
    <#
    .Synopsis
        Adds a link between two Issues on Jira
    .DESCRIPTION
        Creates a new link of the specified type between two Issue.
    .EXAMPLE
        $link = [PSCustomObject]@{
            outwardIssue = [PSCustomObject]@{key = "TEST-10"}
            type = [PSCustomObject]@{name = "Composition"}
        }
        Add-JiraIssueLink -Issue TEST-01 -IssueLink $link
        Creates a link "is part of" between TEST-01 and TEST-10
    .INPUTS
        [PSJira.Issue[]] The JIRA issue that should be modified
        [PSJira.Issue[]] The JIRA issue that should be modified
    #>
    [CmdletBinding()]
    param(
        # Issue key or PSJira.Issue object returned from Get-JiraIssue
        [Parameter(
            Position = 0,
            Mandatory = $true,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true
        )]
        [Alias('Key')]
        [Object[]] $Issue,

        # Issue Link to be created.
        [Parameter(Mandatory = $true)]
        [Object[]] $IssueLink,

        # Credentials to use to connect to Jira
        [Parameter(Mandatory = $false)]
        [System.Management.Automation.PSCredential] $Credential<#,

        [Switch] $PassThru#>
    )

    begin {
        Write-Debug "[Add-JiraIssueLink] Reading server from config file"
        $server = Get-JiraConfigServer -ConfigFile $ConfigFile -ErrorAction Stop

        $issueLinkURL = "$($server)/rest/api/latest/issueLink"
    }

    process {
        # Validate IssueLink object
        $objectProperties = $IssueLink | Get-Member -MemberType *Property
        if (-not(($objectProperties.Name -contains "type") -and (($objectProperties.Name -contains "outwardIssue") -or ($objectProperties.Name -contains "inwardIssue")))) {
            $message = "The IssueLink provided does not contain the information needed."
            $exception = New-Object -TypeName System.ArgumentException -ArgumentList $message
            Throw $exception
        }

        # Validate input object from Pipeline
        if (($_) -and ($_.PSObject.TypeNames[0] -ne "PSJira.Issue")) {
            $message = "Wrong object type provided for Issue. Only PSJira.Issue is accepted"
            $exception = New-Object -TypeName System.ArgumentException -ArgumentList $message
            Throw $exception
        }

        foreach ($i in $Issue) {
            Write-Debug "[Add-JiraIssueLink] Obtaining reference to issue"
            $issueObj = Get-JiraIssue -InputObject $i -Credential $Credential

            foreach ($link in $IssueLink) {
                if ($link.inwardIssue) {
                    $inwardIssue = [PSCustomObject]@{key = $link.inwardIssue.key}
                }
                else {
                    $inwardIssue = [PSCustomObject]@{key = $issueObj.key}
                }

                if ($link.outwardIssue) {
                    $outwardIssue = [PSCustomObject]@{key = $link.outwardIssue.key}
                }
                else {
                    $outwardIssue = [PSCustomObject]@{key = $issueObj.key}
                }

                $body = [PSCustomObject]@{
                    type         = [PSCustomObject]@{name = $link.type.name}
                    inwardIssue  = $inwardIssue
                    outwardIssue = $outwardIssue
                }
                $json = ConvertTo-Json $body

                $null = Invoke-JiraMethod -Method POST -URI $issueLinkURL -Body $json -Credential $Credential
            }
        }
    }

    end {
        Write-Debug "[Add-JiraIssueLink] Complete"
    }
}
