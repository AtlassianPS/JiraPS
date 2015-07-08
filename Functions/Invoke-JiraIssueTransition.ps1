function Invoke-JiraIssueTransition
{
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