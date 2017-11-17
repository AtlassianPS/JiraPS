function Get-JiraWorkflow
{
    <#
    .Synopsis

    .DESCRIPTION
       Get workflow from Jira
    .EXAMPLE
       Get-JiraWorkflow -WorkFlowName 'My New WorkFlow'

       Returns a single workflow
    .EXAMPLE
        Get-JiraWorkflow

        Lists all workflows
    .INPUTS
    .OUTPUTS
    #>
    [CmdletBinding()]
    param(
        # Workflow name
        [Parameter(Mandatory = $false)]
        [string] $WorkflowName,

        # Credentials to use to connect to JIRA.
        # If not specified, this function will use anonymous access.
        [Parameter(Mandatory = $false)]
        [System.Management.Automation.PSCredential] $Credential
    )

    begin
    {
        Write-Debug "[Get-JiraWorkflow] Reading server from config file"
        $server = Get-JiraConfigServer -ConfigFile $ConfigFile -ErrorAction Stop

        Write-Debug "[Get-JiraWorkflow] ParameterSetName=$($PSCmdlet.ParameterSetName)"

        Write-Debug "[Get-JiraWorkflow] Building URI for REST call"
        $restUri = "$server/rest/api/2/workflow"
    }

    process
    {
        If ($WorkflowName)
        {
            [uri]$restUri = '{0}?workflowName={1}' -f $restUri, $WorkflowName
        }
        Write-Verbose "rest URI: [$restUri]"
        Write-Debug "[Get-JiraWorkflow] Preparing for blastoff!"
        $results = Invoke-JiraMethod -Method GET -URI $restUri -Credential $Credential
        If ($results)
        {
            Write-Output $results
        }
        else
        {
            Write-Debug "[Get-JiraWorkflow] JIRA returned no results."
            Write-Verbose "JIRA returned no results."
        }
    }
    end
    {
        Write-Debug "[Get-JiraWorkflow] Complete"
    }
}
