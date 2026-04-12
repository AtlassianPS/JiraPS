function ConvertFrom-AtlassianDocumentFormat {
    # .ExternalHelp ..\JiraPS-help.xml
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter(ValueFromPipeline)]
        [Object]$InputObject
    )

    begin {
        Write-Verbose "[$($MyInvocation.MyCommand.Name)] Function started"
    }

    process {
        Write-DebugMessage "[$($MyInvocation.MyCommand.Name)] PSBoundParameters: $($PSBoundParameters | Out-String)"

        if ($null -eq $InputObject) {
            Write-Debug "[$($MyInvocation.MyCommand.Name)] InputObject is `$null — returning `$null"
            return $null
        }

        # Resolve the ADF 'type' field for both PSCustomObject (API JSON) and hashtable (round-trip)
        $docType = $null
        if ($InputObject -is [hashtable]) {
            $docType = $InputObject['type']
        }
        elseif ($InputObject.PSObject.Properties['type']) {
            $docType = $InputObject.type
        }

        # Data Center, API v2 and non-ADF objects
        if ($docType -ne 'doc') {
            Write-Debug "[$($MyInvocation.MyCommand.Name)] Input is not ADF (type='$docType') — returning as string"
            return $InputObject.ToString()
        }

        Write-Debug "[$($MyInvocation.MyCommand.Name)] ADF document with $($InputObject.content.Count) top-level node(s)"

        $rawBlocks = foreach ($node in $InputObject.content) {
            ConvertFrom-AdfBlock -Node $node
        }

        $formattedBlocks = $rawBlocks | Where-Object { $null -ne $_ -and '' -ne $_ }
        return ($formattedBlocks -join "`n`n" |
                ForEach-Object { $_.TrimEnd() })
    }

    end {
        Write-Verbose "[$($MyInvocation.MyCommand.Name)] Complete"
    }
}

New-Alias -Name "ConvertFrom-ADF" -Value "ConvertFrom-AtlassianDocumentFormat" -ErrorAction SilentlyContinue

# ---------------------------------------------------------------------------
# Block-level renderers
# ---------------------------------------------------------------------------

function script:ConvertFrom-AdfBlock {
    param($Node)
    switch ($Node.type) {
        'heading' {
            $hashes = '#' * [int]$Node.attrs.level
            return "$hashes $(ConvertFrom-AdfInline $Node.content)"
        }
        'paragraph' {
            if (-not $Node.content) { return $null }
            return ConvertFrom-AdfInline $Node.content
        }
        'bulletList' {
            return ConvertFrom-AdfList -Node $Node -ListType 'bullet' -IndentLevel 0
        }
        'orderedList' {
            return ConvertFrom-AdfList -Node $Node -ListType 'ordered' -IndentLevel 0
        }
        'taskList' {
            return ($Node.content |
                    ForEach-Object {
                        $box = if ($_.attrs -and $_.attrs.state -eq 'DONE') { '[x]' } else { '[ ]' }
                        "* $box $(ConvertFrom-AdfInline $_.content)"
                    }) -join "`n"
        }
        'decisionList' {
            return ($Node.content |
                    ForEach-Object {
                        ConvertFrom-AdfInline $_.content
                    }) -join "`n"
        }
        'blockquote' {
            return ($Node.content |
                    ForEach-Object {
                        "> $((ConvertFrom-AdfBlock $_).Trim())"
                    }) -join "`n"
        }
        'codeBlock' {
            $lang = if ($Node.attrs -and $Node.attrs.language) { $Node.attrs.language } else { '' }
            $code = ConvertFrom-AdfInline $Node.content
            return "``````$lang`n$code`n``````"
        }
        'panel' {
            return ConvertFrom-AdfContent $Node.content
        }
        'mediaSingle' {
            $media = $Node.content | Where-Object { $_.type -eq 'media' } | Select-Object -First 1
            if ($media -and $media.attrs.url) {
                $alt = if ($media.attrs -and $media.attrs.alt) { $media.attrs.alt } else { 'image' }
                return "![$alt]($($media.attrs.url))"
            }
            return $null
        }
        'table' {
            return ConvertFrom-AdfTable $Node
        }
        default {
            $nodeContent = if ($Node -is [hashtable]) { $Node['content'] }
            elseif ($Node.PSObject.Properties['content']) { $Node.content }
            else { $null }
            if ($nodeContent) {
                return ConvertFrom-AdfContent $nodeContent
            }
            return $null
        }
    }
}

function script:ConvertFrom-AdfContent {
    param($Nodes)
    if (-not $Nodes) { return '' }
    ($Nodes |
        ForEach-Object { ConvertFrom-AdfBlock $_ } |
        Where-Object { $null -ne $_ }) -join "`n"
}

# ---------------------------------------------------------------------------
# Inline renderers
# ---------------------------------------------------------------------------

function script:ConvertFrom-AdfInline {
    param($Nodes)
    if (-not $Nodes) { return '' }
    -join ($Nodes | ForEach-Object { ConvertFrom-AdfInlineNode $_ })
}

function script:ConvertFrom-AdfInlineNode {
    param($Node)
    switch ($Node.type) {
        'text' {
            $t = $Node.text
            if (-not $Node.marks) { return $t }

            $link = $Node.marks | Where-Object { $_.type -eq 'link' } | Select-Object -First 1
            $strong = $Node.marks | Where-Object { $_.type -eq 'strong' }
            $em = $Node.marks | Where-Object { $_.type -eq 'em' }
            $strike = $Node.marks | Where-Object { $_.type -eq 'strike' }
            $code = $Node.marks | Where-Object { $_.type -eq 'code' }

            if ($link) { return "[$t]($($link.attrs.href))" }
            if ($code) { return "``$t``" }
            if ($strike) { $t = "~~$t~~" }
            if ($strong) { $t = "**$t**" }
            if ($em) { $t = "_${t}_" }
            return $t
        }
        'hardBreak' { return "  `n" }
        'mention' { return $Node.attrs.text }
        'emoji' { return $Node.attrs.text }
        'inlineCard' {
            return "<$($Node.attrs.url)>"
        }
        'date' {
            $ts = [long]$Node.attrs.timestamp
            return [System.DateTimeOffset]::FromUnixTimeMilliseconds($ts).UtcDateTime.ToString('yyyy-MM-dd')
        }
        default {
            $nodeContent = if ($Node -is [hashtable]) { $Node['content'] }
            elseif ($Node.PSObject.Properties['content']) { $Node.content }
            else { $null }
            if ($nodeContent) {
                return ConvertFrom-AdfInline $nodeContent
            }
            return ''
        }
    }
}

# ---------------------------------------------------------------------------
# Table renderer
# ---------------------------------------------------------------------------

function script:ConvertFrom-AdfTable {
    param($Node)
    $lines = [System.Collections.Generic.List[string]]::new()
    $separatorInserted = $false
    foreach ($row in ($Node.content | Where-Object { $_.type -eq 'tableRow' })) {
        $cells = @($row.content |
                ForEach-Object {
                    (ConvertFrom-AdfContent $_.content).Trim()
                })

        # Skip rows where every cell is empty (trailing blank rows from Jira editor)
        if ($separatorInserted -and -not ($cells | Where-Object { $_ -ne '' })) { continue }

        $lines.Add("| $($cells -join ' | ') |")

        $isHeaderRow = ($row.content | Where-Object { $_.type -eq 'tableHeader' }) -as [bool]
        if ($isHeaderRow -and -not $separatorInserted) {
            $sep = @($cells | ForEach-Object { '-' * [Math]::Max(3, $_.Length) })
            $lines.Add("| $($sep -join ' | ') |")
            $separatorInserted = $true
        }
    }
    $lines -join "`n"
}

# ---------------------------------------------------------------------------
# List renderer with nesting support
# ---------------------------------------------------------------------------

function script:ConvertFrom-AdfList {
    param(
        $Node,
        [ValidateSet('bullet', 'ordered')]
        [string]$ListType,
        [int]$IndentLevel
    )

    $indent = '  ' * $IndentLevel
    $lines = [System.Collections.Generic.List[string]]::new()
    $n = if ($Node.attrs -and $Node.attrs.order) { [int]$Node.attrs.order } else { 1 }

    foreach ($item in $Node.content) {
        # Render the paragraph content of this list item
        $paragraphContent = $item.content | Where-Object { $_.type -eq 'paragraph' } | Select-Object -First 1
        $itemText = if ($paragraphContent) { (ConvertFrom-AdfInline $paragraphContent.content).Trim() } else { '' }

        if ($ListType -eq 'bullet') {
            $lines.Add("$indent* $itemText")
        }
        else {
            $lines.Add("$indent$n. $itemText")
            $n++
        }

        # Check for nested lists in this list item's content
        foreach ($child in $item.content) {
            if ($child.type -eq 'bulletList') {
                $nestedLines = ConvertFrom-AdfList -Node $child -ListType 'bullet' -IndentLevel ($IndentLevel + 1)
                $lines.Add($nestedLines)
            }
            elseif ($child.type -eq 'orderedList') {
                $nestedLines = ConvertFrom-AdfList -Node $child -ListType 'ordered' -IndentLevel ($IndentLevel + 1)
                $lines.Add($nestedLines)
            }
        }
    }

    $lines -join "`n"
}
