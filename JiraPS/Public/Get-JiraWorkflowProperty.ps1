function Get-JiraWorkflowProperty {
    <#
    .Synopsis

    .DESCRIPTION
       Get workflow
    .EXAMPLE
       Get-JiraWorkflowProperty
    .EXAMPLE
    .INPUTS
    .OUTPUTS
    #>
    [CmdletBinding()]
    param(
        # Workflow name
        [Parameter(Mandatory = $false)]
        [string] $WorkflowName,

        # Workflow name
        [Parameter(Mandatory = $false)]
        [ValidateSet('Live', 'Draft')]
        [string] $WorkflowMode,

        # Workflow name
        [Parameter(Mandatory = $false)]
        [string] $Key,

        # Workflow name
        [Parameter(Mandatory = $false)]
        [Switch] $IncludeReversedKeys,

        # Credentials to use to connect to JIRA.
        # If not specified, this function will use anonymous access.
        [Parameter(Mandatory = $false)]
        [System.Management.Automation.PSCredential] $Credential
    )

    begin {
        Write-Debug "[Get-JiraWorkflowProperty] Reading server from config file"
        $server = Get-JiraConfigServer -ConfigFile $ConfigFile -ErrorAction Stop

        Write-Debug "[Get-JiraWorkflowProperty] ParameterSetName=$($PSCmdlet.ParameterSetName)"

        Write-Debug "[Get-JiraWorkflowProperty] Building URI for REST call"
        $restUri = "$server/rest/api/2/workflow/{id}/properties"
    }

    process {
        If ($Key) {
            [uri]$restUri = $restUri -f $Key
        }
        If ($WorkflowName) {
            [uri]$restUri = '{0}?workflowName={1}' -f $restUri, $WorkflowName
        }
        If ($WorkflowMode) {
            [uri]$restUri = '{0}?WorkflowMode={1}' -f $restUri, $WorkflowMode
        }
        Write-Verbose "rest URI: [$restUri]"
        Write-Debug "[Get-JiraWorkflowProperty] Preparing for blastoff!"
        $results = Invoke-JiraMethod -Method GET -URI $restUri -Credential $Credential
        If ($results) {
            Write-Output $results
        }
        else {
            Write-Debug "[Get-JiraWorkflowProperty] JIRA returned no results."
            Write-Verbose "JIRA returned no results."
        }
    }
    end {
        Write-Debug "[Get-JiraWorkflowProperty] Complete"
    }
}
