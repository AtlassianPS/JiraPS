function ConvertTo-JiraUriMap {
    <#
    .SYNOPSIS
        Convert named Jira URL properties to a dictionary of URI values.
    #>
    [CmdletBinding()]
    [OutputType([System.Collections.Generic.IDictionary[string, uri]])]
    param(
        [Parameter( ValueFromPipeline )]
        [PSObject[]]
        $InputObject
    )

    process {
        foreach ($i in $InputObject) {
            if ($null -eq $i) { continue }
            Write-DebugMessage "Converting `$InputObject to URI map"

            $result = [System.Collections.Generic.Dictionary[string, uri]]::new()
            if ($i -is [System.Collections.IDictionary]) {
                foreach ($key in $i.Keys) {
                    if ($null -ne $i[$key]) { $result[$key] = [uri]$i[$key] }
                }
            }
            else {
                foreach ($property in $i.PSObject.Properties) {
                    if ($null -ne $property.Value) { $result[$property.Name] = [uri]$property.Value }
                }
            }
            , $result
        }
    }
}
