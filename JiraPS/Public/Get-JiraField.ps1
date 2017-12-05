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
    [CmdletBinding( DefaultParameterSetName = '_All' )]
    param(
        # The Field name or ID to search.
        [Parameter( Position = 0, Mandatory, ValueFromPipeline, ParameterSetName = '_Search' )]
        [String[]]
        $Field,

        # Credentials to use to connect to JIRA.
        # If not specified, this function will use anonymous access.
        [PSCredential]
        $Credential
    )

    begin {
        Write-Verbose "[$($MyInvocation.MyCommand.Name)] Function started"

        $server = Get-JiraConfigServer -ErrorAction Stop

        $resourceURi = "$server/rest/api/latest/field"
    }

    process {
        Write-DebugMessage "[$($MyInvocation.MyCommand.Name)] ParameterSetName: $($PsCmdlet.ParameterSetName)"
        Write-DebugMessage "[$($MyInvocation.MyCommand.Name)] PSBoundParameters: $($PSBoundParameters | Out-String)"

        switch ($PSCmdlet.ParameterSetName) {
            '_All' {
                $parameter = @{
                    URI        = $resourceURi
                    Method     = "GET"
                    Credential = $Credential
                }
                Write-Debug "[$($MyInvocation.MyCommand.Name)] Invoking JiraMethod with `$parameter"
                $result = Invoke-JiraMethod @parameter

                Write-Output (ConvertTo-JiraField -InputObject $result)
            }
            '_Search' {
                foreach ($_field in $Field) {
                    Write-Verbose "[$($MyInvocation.MyCommand.Name)] Processing [$_field]"
                    Write-Debug "[$($MyInvocation.MyCommand.Name)] Processing `$_field [$_field]"

                    $allFields = Get-JiraField -Credential $Credential

                    Write-Output ($allFields | Where-Object -FilterScript {$_.Id -eq $_field})
                    Write-Output ($allFields | Where-Object -FilterScript {$_.Name -like $_field})
                }
            }
        }
    }

    end {
        Write-Verbose "[$($MyInvocation.MyCommand.Name)] Complete"
    }
}
