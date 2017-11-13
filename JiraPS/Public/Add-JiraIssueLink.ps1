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
        [JiraPS.Issue[]] The JIRA issue that should be linked
        [JiraPS.IssueLink[]] The JIRA issue link that should be used
    #>
    [CmdletBinding()]
    param(
        # Issue key or JiraPS.Issue object returned from Get-JiraIssue
        [Parameter(
            Mandatory = $true,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true
        )]
        [Alias('Key')]
        [Object[]] $Issue,

        # Issue Link to be created.
        [Parameter(Mandatory = $true)]
        [Object[]] $IssueLink,

        # Write a comment to the issue
        [String] $Comment,

        # Credentials to use to connect to JIRA.
        # If not specified, this function will use anonymous access.
        [PSCredential] $Credential
    )

    begin {
        Write-Verbose "[$($MyInvocation.MyCommand.Name)] Function started"

        $server = Get-JiraConfigServer -ConfigFile $ConfigFile -ErrorAction Stop

        $resourceURi = "$server/rest/api/latest/issueLink"
    }

    process {
        Write-DebugMessage "[$($MyInvocation.MyCommand.Name)] ParameterSetName: $($PsCmdlet.ParameterSetName)"
        Write-DebugMessage "[$($MyInvocation.MyCommand.Name)] PSBoundParameters: $($PSBoundParameters | Out-String)"

        # Validate IssueLink object
        $objectProperties = $IssueLink | Get-Member -MemberType *Property
        if (-not(
                ($objectProperties.Name -contains "type") -and
                (($objectProperties.Name -contains "outwardIssue") -or ($objectProperties.Name -contains "inwardIssue"))
            )) {
            $message = "The IssueLink provided does not contain the information needed."
            $exception = New-Object -TypeName System.ArgumentException -ArgumentList $message
            Throw $exception
        }

        # Validate input object from Pipeline
        if (($_) -and ($_.PSObject.TypeNames[0] -ne "JiraPS.Issue")) {
            $message = "Wrong object type provided for Issue. Only JiraPS.Issue is accepted"
            $exception = New-Object -TypeName System.ArgumentException -ArgumentList $message
            Throw $exception
        }

        foreach ($i in $Issue) {
            # Find the porper object for the Issue
            $issueObj = Resolve-JiraIssueObject -InputObject $Issue -Credential $Credential

            foreach ($link in $IssueLink) {

                if ($link.inwardIssue) {
                    $inwardIssue = @{ key = $link.inwardIssue.key }
                }
                else {
                    $inwardIssue = @{ key = $issueObj.key }
                }

                if ($link.outwardIssue) {
                    $outwardIssue = @{ key = $link.outwardIssue.key }
                }
                else {
                    $outwardIssue = @{ key = $issueObj.key }
                }

                $body = @{
                    type         = @{ name = $link.type.name }
                    inwardIssue  = $inwardIssue
                    outwardIssue = $outwardIssue
                }

                if ($Comment) {
                    $body.comment = @{ body = $Comment }
                }

                $parameter = @{
                    URI        = $resourceURi
                    Method     = "POST"
                    Body       = ConvertTo-Json -InputObject $body
                    Credential = $Credential
                }
                Write-Debug "[$($MyInvocation.MyCommand.Name)] Invoking JiraMethod with `$parameter"
                $result = Invoke-JiraMethod @parameter
            }
        }
    }

    end {
        Write-Verbose "[$($MyInvocation.MyCommand.Name)] Complete"
    }
}
