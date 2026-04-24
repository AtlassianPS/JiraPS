function Add-JiraIssueWatcher {
    # .ExternalHelp ..\JiraPS-help.xml
    [CmdletBinding( SupportsShouldProcess )]
    param(
        [Parameter( Mandatory )]
        [String[]]
        $Watcher,
        <#
          #ToDo:CustomClass
          Now that we have custom classes, this can also accept ValueFromPipeline
        #>

        [Parameter( Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName )]
        [ValidateNotNull()]
        [AtlassianPS.JiraPS.IssueTransformation()]
        [Alias('Key')]
        [AtlassianPS.JiraPS.Issue]
        $Issue,

        [Parameter()]
        [System.Management.Automation.PSCredential]
        [System.Management.Automation.Credential()]
        $Credential = [System.Management.Automation.PSCredential]::Empty
    )

    begin {
        Write-Verbose "[$($MyInvocation.MyCommand.Name)] Function started"

        $isCloud = Test-JiraCloudServer -Credential $Credential

        $resourceURi = "{0}/watchers"
    }

    process {
        Write-DebugMessage "[$($MyInvocation.MyCommand.Name)] ParameterSetName: $($PsCmdlet.ParameterSetName)"
        Write-DebugMessage "[$($MyInvocation.MyCommand.Name)] PSBoundParameters: $($PSBoundParameters | Out-String)"

        # Find the proper object for the Issue
        $issueObj = Resolve-JiraIssueObject -InputObject $Issue -Credential $Credential

        foreach ($_watcher in $Watcher) {
            Write-Verbose "[$($MyInvocation.MyCommand.Name)] Processing [$_watcher]"
            Write-Debug "[$($MyInvocation.MyCommand.Name)] Processing `$_watcher [$_watcher]"

            if ($isCloud) {
                $watcherBody = ConvertTo-Json -InputObject $_watcher
            }
            else {
                $watcherBody = '"{0}"' -f $_watcher
            }
            $parameter = @{
                URI        = $resourceURi -f $issueObj.RestURL
                Method     = "POST"
                Body       = $watcherBody
                Credential = $Credential
            }
            Write-Debug "[$($MyInvocation.MyCommand.Name)] Invoking JiraMethod with `$parameter"
            if ($PSCmdlet.ShouldProcess($issueObj.Key, "Adding user '$_watcher' as watcher.")) {
                Invoke-JiraMethod @parameter
            }
        }
    }

    end {
        Write-Verbose "[$($MyInvocation.MyCommand.Name)] Complete"
    }
}
