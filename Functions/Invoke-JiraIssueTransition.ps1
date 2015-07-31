function Invoke-JiraIssueTransition
{
    <#
    .Synopsis
       Performs an issue transition on a JIRA issue, changing its status
    .DESCRIPTION
       This function performs an issue transition on a JIRA issue.  Transitions are 
       defined in JIRA through workflows, and allow the issue to move from one status 
       to the next.  For example, the "Start Progress" transition typically moves 
       an issue from an Open status to an "In Progress" status.

       To identify the transitions that an issue can perform, use Get-JiraIssue and 
       check the Transition property of the issue object returned.  Attempting to 
       perform a transition that does not apply to the issue (for example, trying 
       to "start progress" on an issue in progress) will result in an exception.
    .EXAMPLE
       Invoke-JiraIssueTransition -Issue TEST-01 -Transition 11
       Invokes transition ID 11 on issue TEST-01.
    .EXAMPLE
       $transition = Get-JiraIssue -Issue TEST-01 | Select-Object -ExpandProperty Transition | ? {$_.ResultStatus.Name -eq 'In Progress'}
       Invoke-JiraIssueTransition -Issue TEST-01 -Transition $transition
       This example identifies the correct transition based on the result status of 
       "In Progress," and invokes that transition on issue TEST-01.
    .INPUTS
       [PSJira.Issue] Issue (can also be provided as a String)
       [PSJira.Transition] Transition to perform (can also be provided as an int ID)
    .OUTPUTS
       This function does not provide output.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true,
                   Position = 0,
                   ValueFromPipeline = $true,
                   ValueFromPipelineByPropertyName = $true)]
        [Alias('Key')]
        [Object] $Issue,

        [Parameter(Mandatory = $true,
                   Position = 1)]
        [Object] $Transition,

        # Credentials to use to connect to Jira
        [Parameter(Mandatory = $false)]
        [System.Management.Automation.PSCredential] $Credential
    )

    begin
    {
        # We can't validate pipeline input here, since pipeline input doesn't exist in the Begin block.
    }

    process
    {
        Write-Debug "[Invoke-JiraIssueTransition] Obtaining a reference to Jira issue [$Issue]"
        $issueObj = Get-JiraIssue -InputObject $Issue -Credential $jCred

        if (-not $issueObj)
        {
            Write-Debug "[Invoke-JiraIssueTransition] No Jira issues were found for parameter [$Issue]. An exception will be thrown."
            throw "Unable to identify Jira issue [$Issue]. Use Get-JiraIssue for more information."
        }

        Write-Debug "[Invoke-JiraIssueTransition] Checking Transition parameter"
        if ($Transition.PSObject.TypeNames[0] -eq 'PSJira.Transition')
        {
            Write-Debug "[Invoke-JiraIssueTransition] Transition parameter is a PSJira.Transition object"
            $transitionId = $Transition.ID
        } else {
            Write-Debug "[Invoke-JiraIssueTransition] Attempting to cast Transition parameter [$Transition] as int for transition ID"
            try
            {
                $transitionId = [int] "$Transition"
            } catch {
                $err = $_
                Write-Debug "[Invoke-JiraIssueTransition] Encountered an error converting transition to Int. An exception will be thrown."
                throw $err
            }
        }

        Write-Debug "[Invoke-JiraIssueTransition] Checking that the issue can perform the given transition"
        if (($issueObj.Transition | Select-Object -ExpandProperty ID) -contains $transitionId)
        {
            Write-Debug "[Invoke-JiraIssueTransition] Transition [$transitionId] is valid for issue [$issueObj]"
        } else {
            Write-Debug "[Invoke-JiraIssueTransition] Transition [$transitionId] is not valid for issue [$issueObj]. An exception will be thrown."
            throw "The specified Jira issue cannot perform transition [$transitionId]. Check the issue's Transition property and provide a transition valid for its current state."
        }

        $transitionUrl = "$($issueObj.RestURL)/transitions"

        Write-Debug "[Invoke-JiraIssueTransition] Creating properties"
        $props = @{
            'transition' = @{
                'id' = $transitionId;
            }
        }
        $json = ConvertTo-Json -InputObject $props -Depth 3
        Write-Debug "[Invoke-JiraIssueTransition] Converted properties to JSON"

        Write-Debug "[Invoke-JiraIssueTransition] Preparing for blastoff!"
        $result = Invoke-JiraMethod -Method Post -URI $transitionUrl -Body $json -Credential $Credential
        Write-Output $result
    }

    end
    {
        Write-Debug "Complete"
    }
}