function Get-JiraIssueCreateMetadata {
    # .ExternalHelp ..\JiraPS-help.xml
    [System.Diagnostics.CodeAnalysis.SuppressMessage('PSUseSingularNouns', '')]
    [CmdletBinding()]
    param(
        [Parameter( Mandatory )]
        [String]
        $Project,

        [Parameter( Mandatory )]
        [String]
        $IssueType,

        [Parameter()]
        [System.Management.Automation.PSCredential]
        [System.Management.Automation.Credential()]
        $Credential = [System.Management.Automation.PSCredential]::Empty
    )

    begin {
        Write-Verbose "[$($MyInvocation.MyCommand.Name)] Function started"

        $server = Get-JiraConfigServer -ErrorAction Stop

        $resourceURi = "$server/rest/api/2/issue/createmeta/{0}/issuetypes/{1}"
    }

    process {
        Write-DebugMessage "[$($MyInvocation.MyCommand.Name)] ParameterSetName: $($PsCmdlet.ParameterSetName)"
        Write-DebugMessage "[$($MyInvocation.MyCommand.Name)] PSBoundParameters: $($PSBoundParameters | Out-String)"

        $projectObj = Get-JiraProject -Project $Project -Credential $Credential -ErrorAction Stop
        $issueTypeObj = $projectObj.IssueTypes | Where-Object -FilterScript {$_.Id -eq $IssueType -or $_.Name -eq $IssueType}

        if ($null -eq $issueTypeObj.Id)
        {
            $errorMessage = @{
                Category         = "InvalidResult"
                CategoryActivity = "Validating parameters"
                Message          = "No issue types were found in the project [$Project] for the given issue type [$IssueType]. Use Get-JiraIssueType for more details."
            }
            Write-Error @errorMessage
        }

        $parameter = @{
            URI        = $resourceURi -f $projectObj.Id, $issueTypeObj.Id
            Method     = "GET"
            Credential = $Credential
        }
        Write-Debug "[$($MyInvocation.MyCommand.Name)] Invoking JiraMethod with `$parameter"
        $result = Invoke-JiraMethod @parameter

        if ($result) {

            if (@($result.values).Count -eq 0) {
                $errorMessage = @{
                    Category         = "InvalidResult"
                    CategoryActivity = "Validating response"
                    Message          = "No fields were found for the given project [$Project] and issue type [$IssueType]."
                }
                Write-Error @errorMessage
            }

            # Before Jira v9 there was a /createmetadata endpoint that returned
            # an object containing projects, their issue types and their fields.
            # Since then, only a list of fields is returned. To keep the old
            # format, fake the old result by creating such an object. This is a
            # workaround until the official JiraPS project fixed the issue.
            # Check the following release notes:
            # https://confluence.atlassian.com/jiracore/createmeta-rest-endpoint-to-be-removed-975040986.html
            $resultFields = @{}
            $result.values | ForEach-Object { $resultFields[$_.fieldid] = $_ }
            $result = [PSCustomObject] @{
                projects = @(
                    [PSCustomObject] @{
                        issuetypes = @(
                            [PSCustomObject] @{
                                fields = [PSCustomObject] $resultFields
                            }
                        )
                    }
                )
            }

            Write-Output (ConvertTo-JiraCreateMetaField -InputObject $result)
        }
        else {
            $exception = ([System.ArgumentException]"No results")
            $errorId = 'IssueMetadata.ObjectNotFound'
            $errorCategory = 'ObjectNotFound'
            $errorTarget = $Project
            $errorItem = New-Object -TypeName System.Management.Automation.ErrorRecord $exception, $errorId, $errorCategory, $errorTarget
            $errorItem.ErrorDetails = "No metadata found for project $Project and issueType $IssueType."
            Throw $errorItem
        }
    }

    end {
        Write-Verbose "[$($MyInvocation.MyCommand.Name)] Complete"
    }
}
