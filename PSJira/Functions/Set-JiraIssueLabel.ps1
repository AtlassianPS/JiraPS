function Set-JiraIssueLabel
{
    [CmdletBinding(DefaultParameterSetName = 'ReplaceLabels')]
    param(
        # Issue key or PSJira.Issue object returned from Get-JiraIssue
        [Parameter(Mandatory = $true,
                   Position = 0,
                   ValueFromPipeline = $true,
                   ValueFromPipelineByPropertyName = $true)]
        [Alias('Key')]
        [Object[]] $Issue,

        [Parameter(ParameterSetName = 'ReplaceLabels',
                   Mandatory = $true)]
        [Alias('Label')]
        [String[]] $Set,

        # Existing labels to be added
        [Parameter(ParameterSetName = 'ModifyLabels')]
        [String[]] $Add,

        # Existing labels to be removed
        [Parameter(ParameterSetName = 'ModifyLabels')]
        [String[]] $Remove,

        # Remove all labels
        [Parameter(ParameterSetName = 'ClearLabels')]
        [Switch] $Clear,

        # Credentials to use to connect to Jira
        [Parameter(Mandatory = $false)]
        [System.Management.Automation.PSCredential] $Credential,

        [Switch] $PassThru
    )

    begin
    {
        Write-Debug "[Set-JiraIssueLabel] Reading server from config file"
        $server = Get-JiraConfigServer -ConfigFile $ConfigFile -ErrorAction Stop
    }

    process
    {
        foreach ($i in $Issue)
        {
            Write-Debug "[Set-JiraIssueLabel] Obtaining reference to issue"
            $issueObj = Get-JiraIssue -InputObject $i -Credential $Credential

            if ($issueObj)
            {
                $currentLabels = $issueObj.labels
                $url = $issueObj.RestURL
                $isDirty = $true

                # As of JIRA 6.4, the Add and Remove verbs in the REST API for
                # updating issues do not support arrays of parameters - you
                # need to pass a single label to add or remove per API call.
                
                # Instead, we'll do some fancy footwork with the existing
                # issue object and use the Set verb for everything, so we only
                # have to make one call to JIRA.

                if ($Clear)
                {
                    Write-Debug "[Set-JiraIssueLabel] Clearing all labels"
                    $newLabels = @()
                } elseif ($PSCmdlet.ParameterSetName -eq 'ReplaceLabels') {
                    Write-Debug "[Set-JiraIssueLabel] Set parameter was used; existing labels will be overwritten"
                    $newLabels = $Set
                } elseif ($currentLabels -eq $null -or $currentLabels.Count -eq 0) {
                    Write-Debug "[Set-JiraIssueLabel] Issue currently has no labels"
                    if ($Add)
                    {
                        Write-Debug "[Set-JiraIssueLabel] Setting labels to Add parameter"
                        $newLabels = $Add
                    } else {
                        Write-Debug "[Set-JiraIssueLabel] No labels were specified to be added; nothing to do"
                        $isDirty = $false
                    }
                } else {
                    Write-Debug "[Set-JiraIssueLabel] Calculating new labels"
                    # If $Add is not provided (null), this can end up with an
                    # extra $null being added to the array, so we need to
                    # account for that in the Where-Object as well as the
                    # Remove parameter.
                    $newLabels = $currentLabels + $Add | Where-Object -FilterScript {$_ -ne $null -and $Remove -notcontains $_}
                }

                if ($isDirty)
                {
                    Write-Debug "[Set-JiraIssueLabel] New labels for the issue: [$($newLabels -join ',')]"
                
                    $props = @{
                        'update' = @{
                            'labels' = @(
                                @{
                                    'set' = @($newLabels);
                                }
                            );
                        }
                    }

                    Write-Debug "[Set-JiraIssueLabel] Converting labels to JSON"
                    $json = ConvertTo-Json -InputObject $props -Depth 4

                    Write-Debug "[Set-JiraIssueLabel] JSON:`n$json"
                    Write-Debug "[Set-JiraIssueLabel] Preparing for blastoff!"
                    # Should return no results
                    $result = Invoke-JiraMethod -Method Put -URI $url -Body $json -Credential $Credential
                } else {
                    Write-Debug "[Set-JiraIssueLabel] No changes are necessary."
                }

                if ($PassThru)
                {
                    Write-Debug "[Set-JiraIssue] PassThru was specified. Obtaining updated reference to issue"
                    Get-JiraIssue -Key $issueObj.Key -Credential $Credential
                }
            } else {
                Write-Debug "[Set-JiraIssue] Unable to identify issue [$i]. Writing error message."
                Write-Error "Unable to identify issue [$i]"
            }
        }
    }

    end
    {
        Write-Debug "[Set-JiraIssueLabel] Complete"
    }
}