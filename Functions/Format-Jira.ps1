function Format-Jira
{
    [CmdletBinding()]
    param(
        # List of properties to display. If omitted, all properties will be shown.
        [Parameter(Mandatory = $false,
                   Position = 0)]
        [Object[]] $Property,

        # Object to format
        [Parameter(Mandatory = $true,
                   ValueFromPipeline = $true,
                   ValueFromRemainingArguments = $true)]
        [ValidateNotNull()]
        [PSObject[]] $InputObject
    )

    begin
    {
        $headers = New-Object -TypeName System.Collections.ArrayList
        $thisLine = New-Object -TypeName System.Text.StringBuilder
        $allText = New-Object -TypeName System.Text.StringBuilder

        $headerDefined = $false

        $n = [System.Environment]::NewLine

        if ($Property)
        {
            if ($Property -eq '*')
            {
                Write-Debug "[Format-Jira] -Property * was passed. Adding all properties."
            } else {

                foreach ($p in $Property)
                {
                    Write-Debug "[Format-Jira] Adding header [$p]"
                    [void] $headers.Add($p.ToString())   
                }

                $headerString = "||$(($headers.ToArray()) -join '||')||"
                Write-Debug "[Format-Jira] Full header: [$headerString]"
                [void] $allText.Append($headerString)
                $headerDefined = $true
            }
        } else {
            Write-Debug "[Format-Jira] Property parameter was not specified. Checking first InputObject for property names."
        }
    }

    process
    {
        foreach ($i in $InputObject)
        {
            if (-not ($headerDefined))
            {
                # This should only be called if Property was not supplied and this is the first object in the InputObject array.
                if ($Property -and $Property -eq '*')
                {
                    Write-Debug "[Format-Jira] Adding all properties from object [$i]"
                    $allProperties = Get-Member -InputObject $i -MemberType '*Property'
                    foreach ($a in $allProperties)
                    {
                        Write-Debug "[Format-Jira] Adding header [$($a.Name)]"
                        [void] $headers.Add($a.Name)
                    }
                } else {
                    
                    # TODO: find a way to format output objects based on PowerShell's own Format-Table
                    # Identify default table properties if possible and use them to create a Jira table


#                    Write-Debug "[Format-Jira] Checking for format data for type [$($i.GetType())]"
#                    $formatData = Get-FormatData -TypeName ($i.GetType()) -ErrorAction SilentlyContinue
#                    if (Get-FormatData -TypeName ($i.GetType()) -ErrorAction SilentlyContinue)
#                    {
#                        foreach ($d in $formatData.FormatViewDefinition)
#                        {
#                            if (-not ($headers.Contains($d.Name)))
#                            {
#                                Write-Debug "[Format-Jira] Adding header [$($d.Name)]"
#                                [void] $headers.Add($d.Name)
#                            } else {
#                                Write-Debug "[Format-Jira] Skipping header [$($d.Name)] because it has already been added"
#                            }
#                        }
#                    } else {
#                        Write-Debug "[Format-Jira] No format data exists for InputObject (type=[$($i.GetType())]). All properties will be used."
                        $allProperties = Get-Member -InputObject $i -MemberType '*Property'
                        foreach ($a in $allProperties)
                        {
                            Write-Debug "[Format-Jira] Adding header [$($a.Name)]"
                            [void] $headers.Add($a.Name)
                        }
#                    }
                }
                
                $headerString = "||$(($headers.ToArray()) -join '||')||"
                Write-Debug "[Format-Jira] Full header: [$headerString]"
                [void] $allText.Append($headerString)
                $headerDefined = $true
            }

            Write-Debug "[Format-Jira] Processing object [$i]"
            [void] $thisLine.Clear()
            [void] $thisLine.Append("$n|")

            foreach ($h in $headers)
            {
                $value = $InputObject.$h
                if ($value)
                {
                    Write-Debug "[Format-Jira] Adding property (name=[$h], value=[$value])"
                    [void] $thisLine.Append("$value|")
                } else {
                    Write-Debug "[Format-Jira] Property [$h] does not exist on this object."
                    [void] $thisLine.Append(' |')
                }
            }

            $thisLineString = $thisLine.ToString()
            Write-Debug "[Format-Jira] Completed line: [$thisLineString]"
            [void] $allText.Append($thisLineString)
        }
    }

    end
    {
        $allTextString = $allText.ToString()
        Write-Output $allTextString
        Write-Debug "[Format-Jira] Complete"
    }
}