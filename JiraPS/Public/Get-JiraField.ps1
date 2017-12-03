function Get-JiraField {
    <#
    .Synopsis
       This function returns information about JIRA fields
    .DESCRIPTION
       This function provides information about JIRA fields, or about one field in particular.  This is a good way to identify a field's ID by its name, or vice versa.

       Typically, this information is only needed when identifying what fields are necessary to create or edit issues. See Get-JiraIssueCreateMetadata for more details.
    .EXAMPLE
       Get-JiraField
       This example returns information about all JIRA fields visible to the current user (or using anonymous access if a JiraPS session has not been defined).
    .EXAMPLE
       Get-JiraField IssueKey
       This example returns information about the IssueKey field.
    .INPUTS
       This function does not accept pipeline input.
    .OUTPUTS
       This function outputs the JiraPS.Field object(s) that represent the JIRA field(s).
    .NOTES
       This function requires either the -Credential parameter to be passed or a persistent JIRA session. See New-JiraSession for more details.  If neither are supplied, this function will run with anonymous access to JIRA.
    #>
    [CmdletBinding()]
    param(
        # The Field name or ID to search.
        [String[]]
        $Field,

        # Credentials to use to connect to JIRA.
        # If not specified, this function will use anonymous access.
        [PSCredential]
        $Credential
    )

    begin {
        Write-Verbose "[$($MyInvocation.MyCommand.Name)] Function started"

        $server = Get-JiraConfigServer -ConfigFile $ConfigFile -ErrorAction Stop

        $resourceURi = "$server/rest/api/latest/field"

        $parameter = @{
            URI        = $resourceURi
            Method     = "GET"
            Credential = $Credential
        }
        Write-Debug "[$($MyInvocation.MyCommand.Name)] Invoking JiraMethod with `$parameter"
        $result = Invoke-JiraMethod @parameter

        $allFields = ConvertTo-JiraField -InputObject $result
    }

    process {
        Write-DebugMessage "[$($MyInvocation.MyCommand.Name)] ParameterSetName: $($PsCmdlet.ParameterSetName)"
        Write-DebugMessage "[$($MyInvocation.MyCommand.Name)] PSBoundParameters: $($PSBoundParameters | Out-String)"

        if ($Field) {
            foreach ($_field in $Field) {
                Write-Verbose "[$($MyInvocation.MyCommand.Name)] Processing [$_id]"
                Write-Debug "[$($MyInvocation.MyCommand.Name)] Processing `$_id [$_id]"

                Write-Output ($allFields | Where-Object -FilterScript {$_.Id -eq $_field})
                Write-Output ($allFields | Where-Object -FilterScript {$_.Name -like $_field})
            }
        }
        else {
            Write-Output $allFields
        }
    }

    end {
        Write-Verbose "[$($MyInvocation.MyCommand.Name)] Complete"
    }
}
