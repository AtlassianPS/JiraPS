function Get-JiraIssueEditMetadata {
    # .ExternalHelp ..\JiraPS-help.xml
    [System.Diagnostics.CodeAnalysis.SuppressMessage('PSUseSingularNouns', '')]
    [CmdletBinding()]
    param(
        [Parameter( Mandatory )]
        [String]
        $Issue,
        <#
          #ToDo:CustomClass
          Once we have custom classes, this should be a JiraPS.Issue
        #>

        [Parameter()]
        [System.Management.Automation.PSCredential]
        [System.Management.Automation.Credential()]
        $Credential = [System.Management.Automation.PSCredential]::Empty
    )

    begin {
        Write-Verbose "[$($MyInvocation.MyCommand.Name)] Function started"

        $server = Get-JiraConfigServer -ErrorAction Stop

        $resourceURi = "$server/rest/api/2/issue/{0}/editmeta"
    }

    process {
        Write-DebugMessage "[$($MyInvocation.MyCommand.Name)] ParameterSetName: $($PsCmdlet.ParameterSetName)"
        Write-DebugMessage "[$($MyInvocation.MyCommand.Name)] PSBoundParameters: $($PSBoundParameters | Out-String)"

        $parameter = @{
            URI        = $resourceURi -f $Issue
            <#
              #ToDo:CustomClass
              When the Input is typecasted to a JiraPS.Issue, the `self` of the issue can be used
            #>
            Method     = "GET"
            Credential = $Credential
        }
        Write-Debug "[$($MyInvocation.MyCommand.Name)] Invoking JiraMethod with `$parameter"
        $result = Invoke-JiraMethod @parameter

        Write-Debug ($result | Out-String)

        if ($result) {
            if (@($result.fields.projects).Count -eq 0) {
                $errorMessage = @{
                    Category         = "InvalidResult"
                    CategoryActivity = "Validating response"
                    Message          = "No projects were found for the given project [$Project]. Use Get-JiraProject for more details."
                }
                Write-Error @errorMessage
            }
            elseif (@($result.fields.projects).Count -gt 1) {
                $errorMessage = @{
                    Category         = "InvalidResult"
                    CategoryActivity = "Validating response"
                    Message          = "Multiple projects were found for the given project [$Project]. Refine the parameters to return only one project."
                }
                Write-Error @errorMessage
            }

            if (@($result.fields.projects.issuetypes) -eq 0) {
                $errorMessage = @{
                    Category         = "InvalidResult"
                    CategoryActivity = "Validating response"
                    Message          = "No issue types were found for the given issue type [$IssueType]. Use Get-JiraIssueType for more details."
                }
                Write-Error @errorMessage
            }
            elseif (@($result.fields.projects.issuetypes).Count -gt 1) {
                $errorMessage = @{
                    Category         = "InvalidResult"
                    CategoryActivity = "Validating response"
                    Message          = "Multiple issue types were found for the given issue type [$IssueType]. Refine the parameters to return only one issue type."
                }
                Write-Error @errorMessage
            }

            Write-Output (ConvertTo-JiraEditMetaField -InputObject $result)
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
