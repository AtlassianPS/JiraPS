function Get-JiraComponent {
    # .ExternalHelp ..\JiraPS-help.xml
    [CmdletBinding(DefaultParameterSetName = 'ByID')]
    param(
        [Parameter( Position = 0, Mandatory, ValueFromPipeline, ParameterSetName = 'ByProject' )]
        [ValidateNotNullOrEmpty()]
        [ValidateScript(
            {
                if (("AtlassianPS.JiraPS.Project" -notin $_.PSObject.TypeNames) -and (($_ -isnot [String]))) {
                    $exception = ([System.ArgumentException]"Invalid Type for Parameter") #fix code highlighting]
                    $errorId = 'ParameterType.NotJiraProject'
                    $errorCategory = 'InvalidArgument'
                    $errorTarget = $_
                    $errorItem = New-Object -TypeName System.Management.Automation.ErrorRecord $exception, $errorId, $errorCategory, $errorTarget
                    $errorItem.ErrorDetails = "Wrong object type provided for Issue. Expected [AtlassianPS.JiraPS.Project] or [String], but was $($_.GetType().Name)"
                    $PSCmdlet.ThrowTerminatingError($errorItem)
                    <#
                      #ToDo:CustomClass
                      Now that we have custom classes, this polymorphic ValidateScript could be split into a parameter set with [AtlassianPS.JiraPS.<Type>] strong typing
                    #>
                }
                else {
                    return $true
                }
            }
        )]
        [Object[]]
        $Project,
        <#
          #ToDo:CustomClass
          Now that we have custom classes, these two parameters could be merged into a single one with [AtlassianPS.JiraPS.<Type>] typing
        #>

        [Parameter( Position = 0, Mandatory, ParameterSetName = 'ByID' )]
        [Alias("Id")]
        [Int[]]
        $ComponentId,

        [Parameter()]
        [System.Management.Automation.PSCredential]
        [System.Management.Automation.Credential()]
        $Credential = [System.Management.Automation.PSCredential]::Empty
    )

    begin {
        Write-Verbose "[$($MyInvocation.MyCommand.Name)] Function started"

        $resourceURi = "/rest/api/2{0}"
    }

    process {
        Write-DebugMessage "[$($MyInvocation.MyCommand.Name)] ParameterSetName: $($PsCmdlet.ParameterSetName)"
        Write-DebugMessage "[$($MyInvocation.MyCommand.Name)] PSBoundParameters: $($PSBoundParameters | Out-String)"

        switch ($PSCmdlet.ParameterSetName) {
            "ByProject" {
                foreach ($_project in $Project) {
                    Write-Verbose "[$($MyInvocation.MyCommand.Name)] Processing [$_project]"
                    Write-Debug "[$($MyInvocation.MyCommand.Name)] Processing `$_project [$_project]"

                    if ($_project -isnot [string]) {
                        $_project = $_project.Key
                    }
                    $parameter = @{
                        URI        = $resourceURi -f "/project/$_project/components"
                        Method     = "GET"
                        Credential = $Credential
                    }
                    Write-Debug "[$($MyInvocation.MyCommand.Name)] Invoking JiraMethod with `$parameter"
                    $result = Invoke-JiraMethod @parameter

                    Write-Output (ConvertTo-JiraComponent -InputObject $result)
                }
            }
            "ByID" {
                foreach ($_id in $ComponentId) {
                    Write-Verbose "[$($MyInvocation.MyCommand.Name)] Processing [$_id]"
                    Write-Debug "[$($MyInvocation.MyCommand.Name)] Processing `$_id [$_id]"

                    $parameter = @{
                        URI        = $resourceURi -f "/component/$_id"
                        Method     = "GET"
                        Credential = $Credential
                    }
                    Write-Debug "[$($MyInvocation.MyCommand.Name)] Invoking JiraMethod with `$parameter"
                    $result = Invoke-JiraMethod @parameter

                    Write-Output (ConvertTo-JiraComponent -InputObject $result)
                }
            }
        }
    }

    end {
        Write-Verbose "[$($MyInvocation.MyCommand.Name)] Complete"
    }
}
