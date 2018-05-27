function Get-JiraIssue {
    [CmdletBinding(DefaultParameterSetName = 'ByIssueKey')]
    param(
        [Parameter( Position = 0, Mandatory, ParameterSetName = 'ByIssueKey' )]
        [ValidateNotNullOrEmpty()]
        [String[]]
        $Key,

        [Parameter( Position = 0, Mandatory, ParameterSetName = 'ByInputObject' )]
        [ValidateNotNullOrEmpty()]
        [ValidateScript(
            {
                if (("JiraPS.Issue" -notin $_.PSObject.TypeNames) -and (($_ -isnot [String]))) {
                    $errorItem = [System.Management.Automation.ErrorRecord]::new(
                        ([System.ArgumentException]"Invalid Type for Parameter"),
                        'ParameterType.NotJiraIssue',
                        [System.Management.Automation.ErrorCategory]::InvalidArgument,
                        $_
                    )
                    $errorItem.ErrorDetails = "Wrong object type provided for Issue. Expected [JiraPS.Issue] or [String], but was $($_.GetType().Name)"
                    $PSCmdlet.ThrowTerminatingError($errorItem)
                }
                else {
                    return $true
                }
            }
        )]
        [Object[]]
        $InputObject,
        <#
          #ToDo:Deprecate
          This is not necessary if $Key uses ValueFromPipelineByPropertyName
          #ToDo:CustomClass
          Once we have custom classes, this check can be done with Type declaration
        #>

        [Parameter( Mandatory, ParameterSetName = 'ByJQL' )]
        [Alias('JQL')]
        [String]
        $Query,

        [Parameter( Mandatory, ParameterSetName = 'ByFilter' )]
        [ValidateNotNullOrEmpty()]
        [ValidateScript(
            {
                if (("JiraPS.Filter" -notin $_.PSObject.TypeNames) -and (($_ -isnot [String]))) {
                    $errorItem = [System.Management.Automation.ErrorRecord]::new(
                        ([System.ArgumentException]"Invalid Type for Parameter"),
                        'ParameterType.NotJiraFilter',
                        [System.Management.Automation.ErrorCategory]::InvalidArgument,
                        $_
                    )
                    $errorItem.ErrorDetails = "Wrong object type provided for Filter. Expected [JiraPS.Filter] or [String], but was $($_.GetType().Name)"
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
        [Object]
        $Filter,

        [Parameter( ParameterSetName = 'ByJQL' )]
        [Parameter( ParameterSetName = 'ByFilter' )]
        [Int]
        $StartIndex = 0,

        [Parameter( ParameterSetName = 'ByJQL' )]
        [Parameter( ParameterSetName = 'ByFilter' )]
        [Int]
        $MaxResults = 0,

        [Parameter( ParameterSetName = 'ByJQL' )]
        [Parameter( ParameterSetName = 'ByFilter' )]
        [Int]
        $PageSize = 50,

        [PSCredential]
        $Credential
    )

    begin {
        Write-Verbose "[$($MyInvocation.MyCommand.Name)] Function started"

        $server = Get-JiraConfigServer -ErrorAction Stop

        if (($PSCmdlet.ParameterSetName -in @('ByJQL', 'ByFilter')) -and $MaxResults -eq 0) {
            Write-DebugMessage "[$($MyInvocation.MyCommand.Name)] Using loop mode to obtain all results"
            $MaxResults = 1
            $loopMode = $true
        }
        else {
            $loopMode = $false
        }

        $resourceURi = "$server/rest/api/latest/issue/{0}?expand=transitions"
        $searchURi = "$server/rest/api/latest/search?jql={0}&validateQuery=true&expand=transitions&startAt={1}&maxResults={2}"
    }

    process {
        Write-DebugMessage "[$($MyInvocation.MyCommand.Name)] ParameterSetName: $($PsCmdlet.ParameterSetName)"
        Write-DebugMessage "[$($MyInvocation.MyCommand.Name)] PSBoundParameters: $($PSBoundParameters | Out-String)"

        switch ($PSCmdlet.ParameterSetName) {
            'ByIssueKey' {
                foreach ($_key in $Key) {
                    Write-Verbose "[$($MyInvocation.MyCommand.Name)] Processing [$_key]"
                    Write-Debug "[$($MyInvocation.MyCommand.Name)] Processing `$_key [$_key]"

                    $parameter = @{
                        URI        = $resourceURi -f $_key
                        Method     = "GET"
                        Credential = $Credential
                    }
                    Write-Debug "[$($MyInvocation.MyCommand.Name)] Invoking JiraMethod with `$parameter"
                    $result = Invoke-JiraMethod @parameter

                    Write-Output (ConvertTo-JiraIssue -InputObject $result)
                }
            }
            'ByInputObject' {
                # Write-Warning "[$($MyInvocation.MyCommand.Name)] The parameter '-InputObject' has been marked as deprecated."
                foreach ($_issue in $InputObject) {
                    Write-Verbose "[$($MyInvocation.MyCommand.Name)] Processing [$_issue]"
                    Write-Debug "[$($MyInvocation.MyCommand.Name)] Processing `$_issue [$_issue]"

                    Write-Output (Get-JiraIssue -Key $_issue.Key -Credential $Credential)
                }
            }
            'ByJQL' {
                $escapedQuery = ConvertTo-URLEncoded $Query

                $parameter = @{
                    URI        = $searchURi -f $escapedQuery, $StartIndex, $MaxResults
                    Method     = "GET"
                    Credential = $Credential
                }
                Write-Debug "[$($MyInvocation.MyCommand.Name)] Invoking JiraMethod with `$parameter"
                $result = Invoke-JiraMethod @parameter

                if ($result) {
                    # {"startAt":0,"maxResults":50,"total":0,"issues":[]}

                    if ($loopMode) {
                        $totalResults = $result.total

                        Write-DebugMessage "[$($MyInvocation.MyCommand.Name)] Paging through all issues (loop mode)"
                        $allIssues = New-Object -TypeName System.Collections.ArrayList

                        for ($i = 0; $i -lt $totalResults; $i = $i + $PageSize) {
                            $percentComplete = ($i / $totalResults) * 100
                            Write-Progress -Activity "$($MyInvocation.MyCommand.Name)" -Status "Obtaining issues ($i - $($i + $PageSize))..." -PercentComplete $percentComplete

                            Write-DebugMessage "[$($MyInvocation.MyCommand.Name)] Obtaining issues $i - $($i + $PageSize)..."
                            $thisSection = Get-JiraIssue -Query $Query -StartIndex $i -MaxResults $PageSize -Credential $Credential

                            foreach ($t in $thisSection) {
                                [void] $allIssues.Add($t)
                            }
                        }
                        Write-Progress -Activity "$($MyInvocation.MyCommand.Name)" -Status 'Obtaining issues' -Completed
                        Write-Output ($allIssues.ToArray())
                    }
                    elseif ($result.total -gt 0) {
                        Write-Output (ConvertTo-JiraIssue -InputObject $result.issues)
                    }
                    else {
                        $errorMessage = @{
                            Category         = "ObjectNotFound"
                            CategoryActivity = "Searching for resource"
                            Message          = "The JQL query did not return any results"
                        }
                        Write-Error @errorMessage
                    }
                }
            }
            'ByFilter' {
                $filterObj = Get-JiraFilter -InputObject $Filter -Credential $Credential -ErrorAction Stop
                $jql = $filterObj.JQL
                <#
                  #ToDo:CustomClass
                  Once we have custom classes, this will no longer be necessary
                #>

                # MaxResults would have been set to 1 in the Begin block if it
                # was not supplied as a parameter. We don't want to explicitly
                # invoke this method recursively with a MaxResults value of 1
                # if it wasn't initially provided to us.
                if ($loopMode) {
                    Write-Output (Get-JiraIssue -Query $jql -Credential $Credential)
                }
                else {
                    Write-Output (Get-JiraIssue -Query $jql -Credential $Credential -MaxResults $MaxResults)
                }
            }
        }
    }

    end {
        Write-Verbose "[$($MyInvocation.MyCommand.Name)] Complete"
    }
}
