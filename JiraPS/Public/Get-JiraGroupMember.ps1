function Get-JiraGroupMember {
    [CmdletBinding()]
    param(
        [Parameter( Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName )]
        [ValidateNotNullOrEmpty()]
        [ValidateScript(
            {
                if (("JiraPS.Group" -notin $_.PSObject.TypeNames) -and (($_ -isnot [String]))) {
                    $errorItem = [System.Management.Automation.ErrorRecord]::new(
                        ([System.ArgumentException]"Invalid Type for Parameter"),
                        'ParameterType.NotJiraGroup',
                        [System.Management.Automation.ErrorCategory]::InvalidArgument,
                        $_
                    )
                    $errorItem.ErrorDetails = "Wrong object type provided for Group. Expected [JiraPS.Group] or [String], but was $($_.GetType().Name)"
                    $PSCmdlet.ThrowTerminatingError($errorItem)
                    <#
                      #ToDo:CustomClass
                      Once we have custom classes, this check can be done with Type declaration
                    #>
                }
                else {
                    return $true
                }
            }
        )]
        [Object[]]
        $Group,

        [ValidateRange(0, [Int]::MaxValue)]
        [Int]
        $StartIndex = 0,

        [ValidateRange(0, [Int]::MaxValue)]
        [Int]
        $MaxResults = 0,

        [PSCredential]
        $Credential
    )

    begin {
        Write-Verbose "[$($MyInvocation.MyCommand.Name)] Function started"

        # This is a parameter in Get-JiraIssue, but in testing, JIRA doesn't
        # reliably return more than 50 results at a time.
        $pageSize = 50

        if ($MaxResults -eq 0) {
            Write-DebugMessage "[$($MyInvocation.MyCommand.Name)] MaxResults was not specified. Using loop mode to obtain all members."
            $loopMode = $true
        }
        else {
            $loopMode = $false
            if ($MaxResults -gt 50) {
                Write-Warning "JIRA's API may not properly support MaxResults values higher than 50 for this method. If you receive inconsistent results, do not pass the MaxResults parameter to this function to return all results."
            }
        }
    }

    process {
        Write-DebugMessage "[$($MyInvocation.MyCommand.Name)] ParameterSetName: $($PsCmdlet.ParameterSetName)"
        Write-DebugMessage "[$($MyInvocation.MyCommand.Name)] PSBoundParameters: $($PSBoundParameters | Out-String)"

        $groupObj = Get-JiraGroup -GroupName $Group -Credential $Credential -ErrorAction Stop

        foreach ($_group in $groupObj) {
            Write-Verbose "[$($MyInvocation.MyCommand.Name)] Processing [$_group]"
            Write-Debug "[$($MyInvocation.MyCommand.Name)] Processing `$_group [$_group]"

            if ($loopMode) {
                # Using the Size property of the group object, iterate
                # through all users in a given group.

                $totalResults = $_group.Size
                $allUsers = New-Object -TypeName System.Collections.ArrayList

                for ($i = 0; $i -lt $totalResults; $i = $i + $PageSize) {
                    if ($PageSize -gt ($i + $totalResults)) {
                        $thisPageSize = $totalResults - $i
                    }
                    else {
                        $thisPageSize = $PageSize
                    }
                    $percentComplete = ($i / $totalResults) * 100
                    Write-Progress -Activity "$($MyInvocation.MyCommand.Name)" -Status "Obtaining members ($i - $($i + $thisPageSize) of $totalResults)..." -PercentComplete $percentComplete

                    Write-DebugMessage "[$($MyInvocation.MyCommand.Name)] Obtaining members $i - $($i + $thisPageSize)..."
                    $thisSection = Get-JiraGroupMember -Group $_group -StartIndex $i -MaxResults $thisPageSize -Credential $Credential

                    foreach ($_user in $thisSection) {
                        [void] $allUsers.Add($_user)
                    }
                }

                Write-Progress -Activity "$($MyInvocation.MyCommand.Name)" -Completed
                Write-Output ($allUsers.ToArray())
            }
            else {
                # Since user is an expandable property of the returned
                # group from JIRA, JIRA doesn't use the MaxResults argument
                # found in other REST endpoints.  Instead, we need to pass
                # expand=users[0:15] for users 0-15 (inclusive).
                $parameter = @{
                    URI        = '{0}&expand=users[{1}:{2}]' -f $_group.RestUrl, $StartIndex, ($StartIndex + $MaxResults)
                    Method     = "GET"
                    Credential = $Credential
                }
                Write-Debug "[$($MyInvocation.MyCommand.Name)] Invoking JiraMethod with `$parameter"
                $result = Invoke-JiraMethod @parameter

                Write-Output (ConvertTo-JiraGroup -InputObject $result).Member
            }
        }
    }

    end {
        Write-Verbose "[$($MyInvocation.MyCommand.Name)] Complete"
    }
}
