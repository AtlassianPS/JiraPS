function Get-JiraIssueCreateMetadata {
    # .ExternalHelp ..\JiraPS-help.xml
    [CmdletBinding()]
    param(
        [Parameter( Mandatory )]
        [String]
        $Project,

        [Parameter( Mandatory )]
        [String]
        $IssueType,

        [Alias("Credential")]
        [psobject]
        $Session
    )

    begin {
        Write-Verbose "[$($MyInvocation.MyCommand.Name)] Function started"

        $resourceURi = "rest/api/latest/issue/createmeta?projectIds={0}&issuetypeIds={1}&expand=projects.issuetypes.fields"
    }

    process {
        Write-DebugMessage "[$($MyInvocation.MyCommand.Name)] ParameterSetName: $($PsCmdlet.ParameterSetName)"
        Write-DebugMessage "[$($MyInvocation.MyCommand.Name)] PSBoundParameters: $($PSBoundParameters | Out-String)"

        $projectObj = Get-JiraProject -Project $Project -Session $Session -ErrorAction Stop
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
            Session    = $Session
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
