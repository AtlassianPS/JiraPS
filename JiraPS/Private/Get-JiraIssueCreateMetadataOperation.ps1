function Get-JiraIssueCreateMetadataOperation {
    [System.Diagnostics.CodeAnalysis.SuppressMessage('PSUseSingularNouns', '')]
    [CmdletBinding( SupportsPaging )]
    param(
        [Parameter( Mandatory )]
        [AtlassianPS.JiraPS.ProjectTransformation()]
        [AtlassianPS.JiraPS.Project]
        $Project,

        [Parameter( Mandatory )]
        [AtlassianPS.JiraPS.IssueTypeTransformation()]
        [AtlassianPS.JiraPS.IssueType]
        $IssueType,

        [Parameter()]
        [AtlassianPS.Connection]
        $RequestContext
    )

    begin {
        Write-Verbose "[$($MyInvocation.MyCommand.Name)] Function started"

        $isCloud = Test-JiraCloudServer -RequestContext $RequestContext
        $resourceURi = "/rest/api/2/issue/createmeta/{0}/issuetypes/{1}"
    }

    process {
        Write-DebugMessage "[$($MyInvocation.MyCommand.Name)] ParameterSetName: $($PsCmdlet.ParameterSetName)"

        $projectObj = Get-JiraProjectOperation -Project $Project -RequestContext $RequestContext -ErrorAction Stop
        $issueTypeObj = $projectObj.IssueTypes | Where-Object -FilterScript {
            if ($null -ne $IssueType.Id) { $_.Id -eq $IssueType.Id } else { $_.Name -eq $IssueType.Name }
        }

        if ($null -eq $issueTypeObj.Id) {
            $errorMessage = @{
                Category         = "InvalidResult"
                CategoryActivity = "Validating parameters"
                Message          = "No issue types were found in the project [$Project] for the given issue type [$IssueType]. Use Get-JiraIssueType for more details."
            }
            Write-Error @errorMessage
        }

        $parameter = @{
            URI          = ConvertTo-JiraRestApiV3Url -Url ($resourceURi -f $projectObj.Id, $issueTypeObj.Id) -IsCloud $isCloud
            Method       = "GET"
            GetParameter = @{ maxResults = $script:DefaultPageSize }
            Paging       = $true
        }

        # Forward PowerShell's SupportsPaging common parameters (First/Skip/IncludeTotalCount)
        ($PSCmdlet.PagingParameters | Get-Member -MemberType Property).Name | ForEach-Object {
            $parameter[$_] = $PSCmdlet.PagingParameters.$_
        }

        Write-Debug "[$($MyInvocation.MyCommand.Name)] Invoking JiraMethod with `$parameter"
        Invoke-JiraMethod -RequestContext $RequestContext @parameter | ConvertTo-JiraCreateMetaField
    }

    end {
        Write-Verbose "[$($MyInvocation.MyCommand.Name)] Complete"
    }
}
