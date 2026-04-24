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

        # Jira wiki markup is the native format for Jira Server / Data Center and for the
        # legacy v2 REST API. Cloud REST v3 endpoints expect Atlassian Document Format (ADF)
        # and render `||header||` / `|cell|` syntax as literal text. Warn once per invocation
        # if we can confirm the connected deployment is Cloud — but stay silent when no
        # session is configured (this cmdlet is also valid as a pure offline string formatter).
        try {
            if (Test-JiraCloudServer -ErrorAction Stop) {
                Write-Warning "[$($MyInvocation.MyCommand.Name)] You are connected to a Jira Cloud deployment. The output of this cmdlet is Jira wiki markup, which is the native format for Jira Server / Data Center; Jira Cloud REST v3 endpoints expect Atlassian Document Format (ADF) and will render `||header||` syntax as literal text. The output remains valid for Cloud's legacy v2 endpoints. Suppress this warning with -WarningAction SilentlyContinue."
            }
        }
        catch {
            Write-Debug "[$($MyInvocation.MyCommand.Name)] Could not determine deployment type ($($_.Exception.Message)); skipping Cloud-deployment warning."
        }

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
                    foreach ($a in $i.PSObject.Properties) {
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
                        foreach ($a in $i.PSObject.Properties) {
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
                $value = $i.$h
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

New-Alias -Name "Format-Jira" -Value "ConvertTo-JiraTable" -ErrorAction SilentlyContinue
