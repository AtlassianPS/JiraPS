function Get-JiraField {
    # .ExternalHelp ..\JiraPS-help.xml
    [CmdletBinding( DefaultParameterSetName = '_All' )]
    param(
        [Parameter( Position = 0, Mandatory, ValueFromPipeline, ParameterSetName = '_Search' )]
        [String[]]
        $Field,

        [Alias("Credential")]
        [psobject]
        $Session
    )

    begin {
        Write-Verbose "[$($MyInvocation.MyCommand.Name)] Function started"

        $resourceURi = "rest/api/latest/field"
    }

    process {
        Write-DebugMessage "[$($MyInvocation.MyCommand.Name)] ParameterSetName: $($PsCmdlet.ParameterSetName)"
        Write-DebugMessage "[$($MyInvocation.MyCommand.Name)] PSBoundParameters: $($PSBoundParameters | Out-String)"

        switch ($PSCmdlet.ParameterSetName) {
            '_All' {
                $parameter = @{
                    URI        = $resourceURi
                    Method     = "GET"
                    Session    = $Session
                }
                Write-Debug "[$($MyInvocation.MyCommand.Name)] Invoking JiraMethod with `$parameter"
                $result = Invoke-JiraMethod @parameter

                Write-Output (ConvertTo-JiraField -InputObject $result)
            }
            '_Search' {
                foreach ($_field in $Field) {
                    Write-Verbose "[$($MyInvocation.MyCommand.Name)] Processing [$_field]"
                    Write-Debug "[$($MyInvocation.MyCommand.Name)] Processing `$_field [$_field]"

                    $allFields = Get-JiraField -Session $Session

                    Write-Output ($allFields | Where-Object -FilterScript {($_.Id -eq $_field) -or ($_.Name -like $_field)})
                }
            }
        }
    }

    end {
        Write-Verbose "[$($MyInvocation.MyCommand.Name)] Complete"
    }
}
