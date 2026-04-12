function ConvertTo-AtlassianDocumentFormat {
    # .ExternalHelp ..\JiraPS-help.xml
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, ValueFromPipeline)]
        [AllowEmptyString()]
        [string]$Markdown
    )

    begin {
        Write-Verbose "[$($MyInvocation.MyCommand.Name)] Function started"
    }

    process {
        Write-DebugMessage "[$($MyInvocation.MyCommand.Name)] PSBoundParameters: $($PSBoundParameters | Out-String)"

        if ([string]::IsNullOrWhiteSpace($Markdown)) {
            Write-Debug "[$($MyInvocation.MyCommand.Name)] Input is empty or whitespace — returning empty ADF doc"
            return @{ version = 1; type = 'doc'; content = @() }
        }

        $lines = @($Markdown -split "`r?`n")
        Write-Debug "[$($MyInvocation.MyCommand.Name)] Parsing $($lines.Count) line(s) of Markdown"
        $content = @(ConvertTo-AdfContent -Lines $lines)

        Write-Debug "[$($MyInvocation.MyCommand.Name)] Produced $($content.Count) top-level ADF node(s)"
        @{ version = 1; type = 'doc'; content = $content }
    }

    end {
        Write-Verbose "[$($MyInvocation.MyCommand.Name)] Complete"
    }
}

New-Alias -Name "ConvertTo-ADF" -Value "ConvertTo-AtlassianDocumentFormat" -ErrorAction SilentlyContinue

# ---------------------------------------------------------------------------
# Block-level parser
# ---------------------------------------------------------------------------

function script:ConvertTo-AdfContent {
    param([string[]]$Lines)

    $nodes = [System.Collections.Generic.List[hashtable]]::new()
    $i = 0

    while ($i -lt $Lines.Count) {
        $line = $Lines[$i]

        # ── Heading ──────────────────────────────────────────────────────────
        if ($line -match '^(#{1,6})\s+(.+)$') {
            $nodes.Add(@{
                    type    = 'heading'
                    attrs   = @{ level = $matches[1].Length }
                    content = @(ConvertTo-AdfInline $matches[2])
                })
            $i++
            continue
        }

        # ── Fenced code block ────────────────────────────────────────────────
        if ($line -match '^```(\w*)$') {
            $lang = $matches[1]
            $codeLines = [System.Collections.Generic.List[string]]::new()
            $i++
            while ($i -lt $Lines.Count -and $Lines[$i] -notmatch '^```+$') {
                $codeLines.Add($Lines[$i])
                $i++
            }
            $i++ # skip closing ```
            $nodes.Add(@{
                    type    = 'codeBlock'
                    attrs   = @{ language = $lang }
                    content = @(@{ type = 'text'; text = ($codeLines -join "`n") })
                })
            continue
        }

        # ── Block image ───────────────────────────────────────────────────────
        if ($line -match '^!\[(?<alt>[^\]]*)\]\((?<url>[^\)]+)\)\s*$') {
            $nodes.Add(@{
                    type    = 'mediaSingle'
                    attrs   = @{ layout = 'align-start' }
                    content = @(@{
                            type  = 'media'
                            attrs = @{ type = 'external'; url = $matches['url']; alt = $matches['alt'] }
                        })
                })
            $i++
            continue
        }

        # ── Blockquote ────────────────────────────────────────────────────────
        if ($line -match '^>\s*(.*)$') {
            $quoteParas = [System.Collections.Generic.List[hashtable]]::new()
            while ($i -lt $Lines.Count -and $Lines[$i] -match '^>\s*(.*)$') {
                $quoteParas.Add(@{
                        type    = 'paragraph'
                        content = @(ConvertTo-AdfInline $matches[1])
                    })
                $i++
            }
            $nodes.Add(@{ type = 'blockquote'; content = @($quoteParas) })
            continue
        }

        # ── Table ─────────────────────────────────────────────────────────────
        if ($line -match '^\|') {
            $tableLines = [System.Collections.Generic.List[string]]::new()
            while ($i -lt $Lines.Count -and $Lines[$i] -match '^\|') {
                $tableLines.Add($Lines[$i])
                $i++
            }
            $tableNode = ConvertTo-AdfTable -TableLines $tableLines
            if ($tableNode) { $nodes.Add($tableNode) }
            continue
        }

        # ── Task list (must be tested before bullet list) ────────────────────
        if ($line -match '^\*\s+\[[ x]\]\s') {
            $taskItems = [System.Collections.Generic.List[hashtable]]::new()
            while ($i -lt $Lines.Count -and $Lines[$i] -match '^\*\s+\[([ x])\]\s+(.+)$') {
                $state = if ($matches[1] -eq 'x') { 'DONE' } else { 'TODO' }
                $taskItems.Add(@{
                        type    = 'taskItem'
                        content = @(ConvertTo-AdfInline $matches[2])
                        attrs   = @{ localId = [guid]::NewGuid().ToString(); state = $state }
                    })
                $i++
            }
            $nodes.Add(@{
                    type    = 'taskList'
                    content = @($taskItems)
                    attrs   = @{ localId = [guid]::NewGuid().ToString() }
                })
            continue
        }

        # ── Bullet list (with 2-level nesting support) ─────────────────────────
        if ($line -match '^\*\s+(?!\[[ x]\])(.+)$') {
            $listResult = ConvertTo-AdfList -Lines $Lines -StartIndex $i -ListType 'bullet' -IndentLevel 0
            $nodes.Add($listResult.Node)
            $i = $listResult.NextIndex
            continue
        }

        # ── Ordered list (with 2-level nesting support) ────────────────────────
        if ($line -match '^\d+\.\s+(.+)$') {
            $listResult = ConvertTo-AdfList -Lines $Lines -StartIndex $i -ListType 'ordered' -IndentLevel 0
            $nodes.Add($listResult.Node)
            $i = $listResult.NextIndex
            continue
        }

        # ── Empty line ────────────────────────────────────────────────────────
        if ([string]::IsNullOrWhiteSpace($line)) {
            $i++
            continue
        }

        # ── Paragraph (default) ───────────────────────────────────────────────
        # Handle hard breaks: lines ending with two spaces continue into the next line
        $paraContent = [System.Collections.Generic.List[hashtable]]::new()
        while ($i -lt $Lines.Count) {
            $currentLine = $Lines[$i]
            # Skip if we hit a blank line (end of paragraph)
            if ([string]::IsNullOrWhiteSpace($currentLine)) { break }
            # Skip if we hit a block-level element
            if ($currentLine -match '^(#{1,6}\s|```|!\[|>\s*|\||\*\s|\d+\.\s)') { break }

            $endsWithHardBreak = $currentLine -match '  $'
            $trimmedLine = $currentLine -replace '  $', ''

            foreach ($inlineNode in (ConvertTo-AdfInline $trimmedLine)) {
                $paraContent.Add($inlineNode)
            }
            $i++

            if ($endsWithHardBreak -and $i -lt $Lines.Count -and -not [string]::IsNullOrWhiteSpace($Lines[$i])) {
                $paraContent.Add(@{ type = 'hardBreak' })
            }
            else {
                break
            }
        }
        if ($paraContent.Count -gt 0) {
            $nodes.Add(@{
                    type    = 'paragraph'
                    content = @($paraContent)
                })
        }
    }

    $nodes.ToArray()
}

# ---------------------------------------------------------------------------
# Inline parser
# ---------------------------------------------------------------------------

function script:ConvertTo-AdfInline {
    param([string]$Text)

    if ([string]::IsNullOrEmpty($Text)) { return }

    $nodes = [System.Collections.Generic.List[hashtable]]::new()

    # Combined regex (single-quoted — no PS escape processing on backticks)
    # Priority order: combined marks → link → bold → italic → strikethrough → code
    # biText = ***bold italic*** (3 asterisks)
    # beText = **_bold italic_** (bold wrapping italic)
    # ebText = _**bold italic**_ (italic wrapping bold)
    $pattern = '\*\*\*(?<biText>[^\*\n]+)\*\*\*|\*\*_(?<beText>[^_\n]+)_\*\*|_\*\*(?<ebText>[^\*\n]+)\*\*_|\[(?<lText>[^\]]+)\]\((?<lUrl>[^\)]+)\)|\*\*(?<bText>[^\*\n]+)\*\*|_(?<eText>[^_\n]+)_|~~(?<sText>[^~\n]+)~~|`(?<cText>[^`\n]+)`'

    $lastEnd = 0
    foreach ($m in [regex]::Matches($Text, $pattern)) {
        # Plain text before this match
        if ($m.Index -gt $lastEnd) {
            $nodes.Add(@{ type = 'text'; text = $Text.Substring($lastEnd, $m.Index - $lastEnd) })
        }

        if ($m.Groups['biText'].Success) {
            # ***bold italic*** - combined strong + em
            $nodes.Add(@{ type = 'text'; text = $m.Groups['biText'].Value; marks = @(@{ type = 'strong' }, @{ type = 'em' }) })
        }
        elseif ($m.Groups['beText'].Success) {
            # **_bold italic_** - combined strong + em
            $nodes.Add(@{ type = 'text'; text = $m.Groups['beText'].Value; marks = @(@{ type = 'strong' }, @{ type = 'em' }) })
        }
        elseif ($m.Groups['ebText'].Success) {
            # _**bold italic**_ - combined em + strong
            $nodes.Add(@{ type = 'text'; text = $m.Groups['ebText'].Value; marks = @(@{ type = 'em' }, @{ type = 'strong' }) })
        }
        elseif ($m.Groups['lText'].Success) {
            $nodes.Add(@{
                    type  = 'text'
                    text  = $m.Groups['lText'].Value
                    marks = @(@{ type = 'link'; attrs = @{ href = $m.Groups['lUrl'].Value } })
                })
        }
        elseif ($m.Groups['bText'].Success) {
            $nodes.Add(@{ type = 'text'; text = $m.Groups['bText'].Value; marks = @(@{ type = 'strong' }) })
        }
        elseif ($m.Groups['eText'].Success) {
            $nodes.Add(@{ type = 'text'; text = $m.Groups['eText'].Value; marks = @(@{ type = 'em' }) })
        }
        elseif ($m.Groups['sText'].Success) {
            $nodes.Add(@{ type = 'text'; text = $m.Groups['sText'].Value; marks = @(@{ type = 'strike' }) })
        }
        elseif ($m.Groups['cText'].Success) {
            $nodes.Add(@{ type = 'text'; text = $m.Groups['cText'].Value; marks = @(@{ type = 'code' }) })
        }

        $lastEnd = $m.Index + $m.Length
    }

    # Remaining plain text
    if ($lastEnd -lt $Text.Length) {
        $nodes.Add(@{ type = 'text'; text = $Text.Substring($lastEnd) })
    }

    $nodes.ToArray()
}

# ---------------------------------------------------------------------------
# Table parser
# ---------------------------------------------------------------------------

function script:ConvertTo-AdfTable {
    param([System.Collections.Generic.List[string]]$TableLines)

    if ($TableLines.Count -lt 2) { return $null }

    $tableRows = [System.Collections.Generic.List[hashtable]]::new()
    $isHeader = $true

    foreach ($tLine in $TableLines) {
        # Skip separator rows: | --- | :---: | ---: | (with or without spaces)
        if ($tLine -match '^\|[-:\s|]+\|$') { continue }

        # Split on | and trim — the leading/trailing | produce empty strings, filter those out
        $cells = @($tLine -split '\|' |
                Where-Object { $_ -ne '' } |
                ForEach-Object { $_.Trim() })

        $cellType = if ($isHeader) { 'tableHeader' } else { 'tableCell' }
        $cellNodes = @($cells |
                ForEach-Object {
                    @{
                        type    = $cellType
                        attrs   = @{}
                        content = @(@{
                                type    = 'paragraph'
                                content = @(ConvertTo-AdfInline $_)
                            })
                    }
                })

        $tableRows.Add(@{ type = 'tableRow'; content = $cellNodes })
        $isHeader = $false
    }

    if ($tableRows.Count -eq 0) { return $null }

    @{
        type    = 'table'
        attrs   = @{ isNumberColumnEnabled = $false; layout = 'align-start'; localId = [guid]::NewGuid().ToString() }
        content = @($tableRows)
    }
}

# ---------------------------------------------------------------------------
# List parser with 2-level nesting support
# ---------------------------------------------------------------------------

function script:ConvertTo-AdfList {
    param(
        [string[]]$Lines,
        [int]$StartIndex,
        [ValidateSet('bullet', 'ordered')]
        [string]$ListType,
        [int]$IndentLevel
    )

    $listItems = [System.Collections.Generic.List[hashtable]]::new()
    $i = $StartIndex

    # Indentation pattern for current level (each level = 2 spaces)
    $indentSpaces = ' ' * ($IndentLevel * 2)
    if ($ListType -eq 'bullet') {
        $itemPattern = "^$indentSpaces\*\s+(?!\[[ x]\])(.+)$"
    }
    else {
        $itemPattern = "^$indentSpaces\d+\.\s+(.+)$"
    }

    # Pattern to detect nested items (one level deeper)
    $nestedIndent = ' ' * (($IndentLevel + 1) * 2)
    $nestedBulletPattern = "^$nestedIndent\*\s+"
    $nestedOrderedPattern = "^$nestedIndent\d+\.\s+"

    while ($i -lt $Lines.Count -and $Lines[$i] -match $itemPattern) {
        $itemText = $matches[1]
        $itemContent = [System.Collections.Generic.List[hashtable]]::new()
        $itemContent.Add(@{
                type    = 'paragraph'
                content = @(ConvertTo-AdfInline $itemText)
            })
        $i++

        # Check for nested list (only if we haven't reached max depth of 2)
        if ($IndentLevel -lt 1 -and $i -lt $Lines.Count) {
            if ($Lines[$i] -match $nestedBulletPattern) {
                $nestedResult = ConvertTo-AdfList -Lines $Lines -StartIndex $i -ListType 'bullet' -IndentLevel ($IndentLevel + 1)
                $itemContent.Add($nestedResult.Node)
                $i = $nestedResult.NextIndex
            }
            elseif ($Lines[$i] -match $nestedOrderedPattern) {
                $nestedResult = ConvertTo-AdfList -Lines $Lines -StartIndex $i -ListType 'ordered' -IndentLevel ($IndentLevel + 1)
                $itemContent.Add($nestedResult.Node)
                $i = $nestedResult.NextIndex
            }
        }

        $listItems.Add(@{
                type    = 'listItem'
                content = @($itemContent)
            })
    }

    $listNode = if ($ListType -eq 'bullet') {
        @{ type = 'bulletList'; content = @($listItems) }
    }
    else {
        @{ type = 'orderedList'; attrs = @{ order = 1 }; content = @($listItems) }
    }

    @{
        Node      = $listNode
        NextIndex = $i
    }
}
