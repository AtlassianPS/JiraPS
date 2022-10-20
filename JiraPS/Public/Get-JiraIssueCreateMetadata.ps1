function Get-JiraIssueCreateMetadata-Fix {
    # .ExternalHelp ..\JiraPS-help.xml
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
    }

    process {
        Write-DebugMessage "[$($MyInvocation.MyCommand.Name)] ParameterSetName: $($PsCmdlet.ParameterSetName)"
        Write-DebugMessage "[$($MyInvocation.MyCommand.Name)] PSBoundParameters: $($PSBoundParameters | Out-String)"

        $projectObj = Get-JiraProject -Project $Project -Credential $Credential -ErrorAction Stop
        $issueTypeObj = $projectObj.IssueTypes | Where-Object -FilterScript {$_.Id -eq $IssueType -or $_.Name -eq $IssueType}

        # Endpoint to get the fields
        $fieldsResourceURi = "$server/rest/api/2/issue/createmeta/$($projectObj.Id)/issuetypes/$($issueTypeObj.Id)"

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
            URI        = $fieldsResourceURi
            Method     = "GET"
            Credential = $Credential
        }
        Write-Debug "[$($MyInvocation.MyCommand.Name)] Invoking JiraMethod with `$parameter"
        $result = Invoke-JiraMethod @parameter

        if ($result) {
            if (@($result.projects).Count -eq 0) {
                $errorMessage = @{
                    Category         = "InvalidResult"
                    CategoryActivity = "Validating response"
                    Message          = "No projects were found for the given project [$Project]. Use Get-JiraProject for more details."
                }
                Write-Error @errorMessage
            }
            elseif (@($result.projects).Count -gt 1) {
                $errorMessage = @{
                    Category         = "InvalidResult"
                    CategoryActivity = "Validating response"
                    Message          = "Multiple projects were found for the given project [$Project]. Refine the parameters to return only one project."
                }
                Write-Error @errorMessage
            }

            if (@($result.projects.issuetypes) -eq 0) {
                $errorMessage = @{
                    Category         = "InvalidResult"
                    CategoryActivity = "Validating response"
                    Message          = "No issue types were found for the given issue type [$IssueType]. Use Get-JiraIssueType for more details."
                }
                Write-Error @errorMessage
            }
            elseif (@($result.projects.issuetypes).Count -gt 1) {
                $errorMessage = @{
                    Category         = "InvalidResult"
                    CategoryActivity = "Validating response"
                    Message          = "Multiple issue types were found for the given issue type [$IssueType]. Refine the parameters to return only one issue type."
                }
                Write-Error @errorMessage
            }

            # Seems unnecessary for our purposes.
            # Write-Output (ConvertTo-JiraCreateMetaField -InputObject $result)
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
