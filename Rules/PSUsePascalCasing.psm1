function Test-FunctionCasing {
    [CmdletBinding()]
    [OutputType([PSCustomObject[]])]
    param (
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [System.Management.Automation.Language.ScriptBlockAst]$ScriptBlockAst
    )

    process {
        try {
            $functions = $ScriptBlockAst.FindAll(
                { $args[0] -is [System.Management.Automation.Language.FunctionDefinitionAst] -and
                $args[0].Name -cmatch '[A-Z]{2,}'
            }, $true )
            foreach ( $function in $functions ) {
                [PSCustomObject]@{
                    Message  = "Avoid function names with adjacent caps in their name"
                    Extent   = $function.Extent
                    RuleName = $PSCmdlet.MyInvocation.InvocationName
                    Severity = "Warning"
                }
            }
        }
        catch {
            $PSCmdlet.ThrowTerminatingError( $_ )
        }
    }
}
