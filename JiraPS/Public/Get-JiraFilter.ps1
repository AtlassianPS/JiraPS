function Get-JiraFilter {
    # .ExternalHelp ..\JiraPS-help.xml
    [CmdletBinding(DefaultParameterSetName = 'ByFilterID')]
    param(
        [Parameter( Position = 0, Mandatory, ParameterSetName = 'ByFilterID' )]
        [String[]]
        $Id,

        [Parameter( Mandatory, ValueFromPipeline, ParameterSetName = 'ByInputObject' )]
        [ValidateNotNull()]
        [AtlassianPS.JiraPS.FilterTransformation()]
        [AtlassianPS.JiraPS.Filter[]]
        $InputObject,

        [Parameter( Mandatory, ParameterSetName = 'MyFavorite' )]
        [Alias('Favourite')]
        [Switch]
        $Favorite,

        [Parameter()]
        [System.Management.Automation.PSCredential]
        [System.Management.Automation.Credential()]
        $Credential = [System.Management.Automation.PSCredential]::Empty
    )

    begin {
        Write-Verbose "[$($MyInvocation.MyCommand.Name)] Function started"

        $resourceURi = "/rest/api/2/filter/{0}"
    }

    process {
        Write-DebugMessage "[$($MyInvocation.MyCommand.Name)] ParameterSetName: $($PsCmdlet.ParameterSetName)"
        Write-DebugMessage "[$($MyInvocation.MyCommand.Name)] PSBoundParameters: $($PSBoundParameters | Out-String)"

        switch ($PSCmdlet.ParameterSetName) {
            "ByFilterID" {
                foreach ($_id in $Id) {
                    Write-Verbose "[$($MyInvocation.MyCommand.Name)] Processing [$_id]"
                    Write-Debug "[$($MyInvocation.MyCommand.Name)] Processing `$_id [$_id]"

                    $parameter = @{
                        URI        = $resourceURi -f $_id
                        Method     = "GET"
                        Credential = $Credential
                    }
                    Write-Debug "[$($MyInvocation.MyCommand.Name)] Invoking JiraMethod with `$parameter"
                    $result = Invoke-JiraMethod @parameter

                    Write-Output (ConvertTo-JiraFilter -InputObject $result)
                }
            }
            "ByInputObject" {
                foreach ($object in $InputObject) {
                    Write-Verbose "[$($MyInvocation.MyCommand.Name)] Processing [$object]"
                    Write-Debug "[$($MyInvocation.MyCommand.Name)] Processing `$object [$object]"

                    Write-Output (Get-JiraFilter -Id $object.ID -Credential $Credential)
                }
            }
            "MyFavorite" {
                $parameter = @{
                    URI        = $resourceURi -f "favourite"
                    Method     = "GET"
                    Credential = $Credential
                }
                Write-Debug "[$($MyInvocation.MyCommand.Name)] Invoking JiraMethod with `$parameter"
                $result = Invoke-JiraMethod @parameter

                Write-Output (ConvertTo-JiraFilter -InputObject $result)
            }
        }
    }

    end {
        Write-Verbose "[$($MyInvocation.MyCommand.Name)] Complete"
    }
}
