function Format-Jira {
    <#
    .Synopsis
       Converts an object into a table formatted according to JIRA's markdown syntax
    .DESCRIPTION
       This function converts a PowerShell object into a table using JIRA's markdown syntax. This can then be added to a JIRA issue description or comment.

       Like the native Format-* cmdlets, this is a destructive operation, so as always, remember to "filter left, format right!"
    .EXAMPLE
       Get-Process | Format-Jira | Add-JiraIssueComment -Issue TEST-001
       This example illustrates converting the output from Get-Process into a JIRA table, which is then added as a comment to issue TEST-001.
    .EXAMPLE
       Get-Process chrome | Format-Jira Name,Id,VM
       This example obtains all Google Chrome processes, then creates a JIRA table with only the Name,ID, and VM properties of each object.
    .INPUTS
       [System.Object[]] - accepts any Object via pipeline
    .OUTPUTS
       [System.String]
    .NOTES
       This is a destructive operation, since it permanently reduces InputObjects to Strings.  Remember to "filter left, format right."
    #>
    [CmdletBinding()]
    [OutputType([System.String])]
    param(
        # List of properties to display. If omitted, only the default properties will be shown.
        #
        # To display all properties, use -Property *.
        [Parameter(
            Mandatory = $false
        )]
        [Object[]] $Property,

        # Object to format.
        [Parameter(
            Mandatory = $true,
            ValueFromPipeline = $true,
            ValueFromRemainingArguments = $true
        )]
        [ValidateNotNull()]
        [PSObject[]] $InputObject
    )

    begin {
        Write-Verbose "[$($MyInvocation.MyCommand.Name)] Function started"

        $headers = New-Object -TypeName System.Collections.ArrayList
        $thisLine = New-Object -TypeName System.Text.StringBuilder
        $allText = New-Object -TypeName System.Text.StringBuilder

        $headerDefined = $false

        $n = [System.Environment]::NewLine

        if ($Property) {
            if ($Property -eq '*') {
                Write-DebugMessage "[$($MyInvocation.MyCommand.Name)] -Property * was passed. Adding all properties."
            }
            else {

                foreach ($p in $Property) {
                    Write-DebugMessage "[$($MyInvocation.MyCommand.Name)] Adding header [$p]"
                    [void] $headers.Add($p.ToString())
                }

                $headerString = "||$(($headers.ToArray()) -join '||')||"
                Write-DebugMessage "[$($MyInvocation.MyCommand.Name)] Full header: [$headerString]"
                [void] $allText.Append($headerString)
                $headerDefined = $true
            }
        }
        else {
            Write-DebugMessage "[$($MyInvocation.MyCommand.Name)] Property parameter was not specified. Checking first InputObject for property names."
        }
    }

    process {
        Write-DebugMessage "[$($MyInvocation.MyCommand.Name)] ParameterSetName: $($PsCmdlet.ParameterSetName)"
        Write-DebugMessage "[$($MyInvocation.MyCommand.Name)] PSBoundParameters: $($PSBoundParameters | Out-String)"

        foreach ($i in $InputObject) {
            if (-not ($headerDefined)) {
                # This should only be called if Property was not supplied and this is the first object in the InputObject array.
                if ($Property -and $Property -eq '*') {
                    Write-DebugMessage "[$($MyInvocation.MyCommand.Name)] Adding all properties from object [$i]"
                    $allProperties = Get-Member -InputObject $i -MemberType '*Property'
                    foreach ($a in $allProperties) {
                        Write-DebugMessage "[$($MyInvocation.MyCommand.Name)] Adding header [$($a.Name)]"
                        [void] $headers.Add($a.Name)
                    }
                }
                else {

                    # TODO: find a way to format output objects based on PowerShell's own Format-Table
                    # Identify default table properties if possible and use them to create a Jira table

                    if ($i.PSStandardMembers.DefaultDisplayPropertySet) {
                        Write-DebugMessage "[$($MyInvocation.MyCommand.Name)] Identifying default properties for object [$i]"
                        $propertyNames = $i.PSStandardMembers.DefaultDisplayPropertySet.ReferencedPropertyNames
                        foreach ($p in $propertyNames) {
                            Write-DebugMessage "[$($MyInvocation.MyCommand.Name)] Adding header [$p]"
                            [void] $headers.Add($p)
                        }
                    }
                    else {
                        Write-DebugMessage "[$($MyInvocation.MyCommand.Name)] No default format data exists for object [$i] (type=[$($i.GetType())]). All properties will be used."
                        $allProperties = Get-Member -InputObject $i -MemberType '*Property'
                        foreach ($a in $allProperties) {
                            Write-DebugMessage "[$($MyInvocation.MyCommand.Name)] Adding header [$($a.Name)]"
                            [void] $headers.Add($a.Name)
                        }
                    }
                }

                $headerString = "||$(($headers.ToArray()) -join '||')||"
                Write-DebugMessage "[$($MyInvocation.MyCommand.Name)] Full header: [$headerString]"
                [void] $allText.Append($headerString)
                $headerDefined = $true
            }

            Write-DebugMessage "[$($MyInvocation.MyCommand.Name)] Processing object [$i]"
            [void] $thisLine.Clear()
            [void] $thisLine.Append("$n|")

            foreach ($h in $headers) {
                $value = $InputObject.$h
                if ($value) {
                    Write-DebugMessage "[$($MyInvocation.MyCommand.Name)] Adding property (name=[$h], value=[$value])"
                    [void] $thisLine.Append("$value|")
                }
                else {
                    Write-DebugMessage "[$($MyInvocation.MyCommand.Name)] Property [$h] does not exist on this object."
                    [void] $thisLine.Append(' |')
                }
            }

            $thisLineString = $thisLine.ToString()
            Write-DebugMessage "[$($MyInvocation.MyCommand.Name)] Completed line: [$thisLineString]"
            [void] $allText.Append($thisLineString)
        }
    }

    end {
        Write-Output $allText.ToString()

        Write-Verbose "[$($MyInvocation.MyCommand.Name)] Complete"
    }
}
