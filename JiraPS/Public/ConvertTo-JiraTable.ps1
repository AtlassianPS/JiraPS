function ConvertTo-JiraTable {
    # .ExternalHelp ..\JiraPS-help.xml
    [CmdletBinding()]
    [OutputType([System.String])]
    param(
        [Parameter( Mandatory, ValueFromPipeline, ValueFromRemainingArguments )]
        [ValidateNotNull()]
        [PSObject[]]
        $InputObject,

        [Object[]]
        $Property
    )

    begin {
        Write-Verbose "[$($MyInvocation.MyCommand.Name)] Function started"

        $headers = New-Object -TypeName System.Collections.ArrayList
        $thisLine = New-Object -TypeName System.Text.StringBuilder
        $allText = New-Object -TypeName System.Text.StringBuilder

        $headerDefined = $false

        $n = [System.Environment]::NewLine

        if ($Property) {
            if ($Property -eq '*') { Write-DebugMessage "-Property * was passed. Adding all properties." }
            else {

                foreach ($p in $Property) {
                    Write-DebugMessage "Adding header [$p]"
                    [void] $headers.Add($p.ToString())
                }

                $headerString = "||$(($headers.ToArray()) -join '||')||"
                Write-DebugMessage "Full header: [$headerString]"
                [void] $allText.Append($headerString)
                $headerDefined = $true
            }
        }
        else {
            Write-DebugMessage "Property parameter was not specified. Checking first InputObject for property names."
        }
    }

    process {
        Write-DebugMessage "ParameterSetName: $($PsCmdlet.ParameterSetName)"
        Write-DebugMessage -BoundParameters $PSBoundParameters

        foreach ($i in $InputObject) {
            if (-not ($headerDefined)) {
                # This should only be called if Property was not supplied and this is the first object in the InputObject array.
                if ($Property -and $Property -eq '*') {
                    Write-DebugMessage "Adding all properties from object [$i]"
                    foreach ($a in $i.PSObject.Properties) {
                        Write-DebugMessage "Adding header [$($a.Name)]"
                        [void] $headers.Add($a.Name)
                    }
                }
                else {

                    # TODO: find a way to format output objects based on PowerShell's own Format-Table
                    # Identify default table properties if possible and use them to create a Jira table

                    if ($i.PSStandardMembers.DefaultDisplayPropertySet) {
                        Write-DebugMessage "Identifying default properties for object [$i]"
                        $propertyNames = $i.PSStandardMembers.DefaultDisplayPropertySet.ReferencedPropertyNames
                        foreach ($p in $propertyNames) {
                            Write-DebugMessage "Adding header [$p]"
                            [void] $headers.Add($p)
                        }
                    }
                    else {
                        Write-DebugMessage "No default format data exists for object [$i] (type=[$($i.GetType())]). All properties will be used."
                        foreach ($a in $i.PSObject.Properties) {
                            Write-DebugMessage "Adding header [$($a.Name)]"
                            [void] $headers.Add($a.Name)
                        }
                    }
                }

                $headerString = "||$(($headers.ToArray()) -join '||')||"
                Write-DebugMessage "Full header: [$headerString]"
                [void] $allText.Append($headerString)
                $headerDefined = $true
            }

            Write-DebugMessage "Processing object [$i]"
            [void] $thisLine.Clear()
            [void] $thisLine.Append("$n|")

            foreach ($h in $headers) {
                $value = $i.$h
                if ($value) {
                    Write-DebugMessage "Adding property (name=[$h], value=[$value])"
                    [void] $thisLine.Append("$value|")
                }
                else {
                    Write-DebugMessage "Property [$h] does not exist on this object."
                    [void] $thisLine.Append(' |')
                }
            }

            $thisLineString = $thisLine.ToString()
            Write-DebugMessage "Completed line: [$thisLineString]"
            [void] $allText.Append($thisLineString)
        }
    }

    end {
        Write-Output $allText.ToString()

        Write-Verbose "[$($MyInvocation.MyCommand.Name)] Complete"
    }
}

