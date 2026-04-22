# Tools/Migrate-PlatyPSDoc.ps1
#
# One-shot migration helper that turns a freshly generated v1 schema markdown
# file (output of Microsoft.PowerShell.PlatyPS 1.0's New-MarkdownCommandHelp)
# into the production-ready shape JiraPS' docs site and Get-Help -Full need.
# This file is deleted at the end of the migration; nothing in the runtime
# build depends on it.
#
# Operations (mirrors the Phase 4 spec in the migration plan):
#   * Frontmatter
#       - Drop:  document type, PlatyPS schema version, title, ms.date
#       - Rename: HelpUri  -> online version  (legacy site key Jekyll uses)
#       - Lowercase: Locale -> locale         (legacy casing the site uses)
#       - Drop:  any non-en-US locale leak (e.g. Locale: en-DE)
#       - Add (if missing): layout: documentation, permalink: <site path>
#       - Output keys in the legacy order so generated -> transformer is a
#         small, reviewable diff against commands.legacy/.
#   * SYNTAX
#       - Replace bare ``` fences with ```powershell so the site syntax
#         highlights, matching the legacy markdown.
#       - Strip parameter set sub-headings ("### Foo") only when a single
#         set named __AllParameterSets exists (legacy didn't emit those).
#       - Strip DontShow parameters (e.g. _RetryCount) from each set's line
#         so they don't appear in Get-Help syntax / website syntax.
#   * EXAMPLES
#       - Wrap unfenced example code in ```powershell ... ``` fences.
#       - Collapse the double blank line PlatyPS emits between code and
#         remarks down to a single blank.
#   * PARAMETERS
#       - Drop the entire block for parameters whose name starts with
#         '_' (DontShow convention in this module) or whose YAML has
#         DontShow: true. Without this the underscore prefix confuses
#         Markdig's emphasis parser and Get-Help renders the param as
#         "[-]" (empty name).
#   * ALIASES
#       - Drop the placeholder "## ALIASES" section entirely (it never
#         carried real content; per-parameter aliases live in YAML).
#   * INPUTS / OUTPUTS
#       - Drop spurious "### System.Object" headings PlatyPS emits next
#         to real type headings (legacy never had them).
#   * RELATED LINKS
#       - Drop the auto-emitted "- [Online Version](...)" line (the same
#         URL is already in the online version frontmatter key).
#       - Re-emit links as plain "[Name](url)" instead of "- [Name](url)"
#         to match legacy formatting.
#   * Whitespace / placeholders
#       - Strip "{{ Fill ... Description }}" and "{{Insert list of aliases}}"
#         placeholder lines.
#       - Trim leading / trailing blank lines per section.
#
# Usage:
#   .\Tools\Migrate-PlatyPSDoc.ps1 -Path docs/en-US/commands -LegacyFolder docs/en-US/commands.legacy
#   .\Tools\Migrate-PlatyPSDoc.ps1 -Path docs/en-US/commands/Get-JiraIssue.md -LegacyFolder docs/en-US/commands.legacy

[CmdletBinding(SupportsShouldProcess)]
param(
    [Parameter(Mandatory)]
    [string] $Path,

    [Parameter(Mandatory)]
    [string] $LegacyFolder,

    [string] $PermalinkBase = '/docs/JiraPS/commands/',
    [string] $OnlineVersionBase = 'https://atlassianps.org/docs/JiraPS/commands/',
    # Path to a module manifest (.psd1). When provided, the helper imports
    # the module and patches per-parameter YAML blocks with metadata that
    # PlatyPS 1.0 omits or strips: PSTypeName-decorated types, default
    # values from AST literals, and ValidateSet AcceptedValues.
    [string] $ModuleManifest
)

$ErrorActionPreference = 'Stop'

# Output order matches commands.legacy/ frontmatter so Phase-7 git diffs are
# easy to review. Anything not listed is appended afterwards, sorted.
$FrontmatterKeyOrder = @(
    'external help file'
    'Module Name'
    'online version'
    'locale'
    'schema'
    'layout'
    'permalink'
)

function Read-Frontmatter {
    param([string[]] $Lines)
    if (-not $Lines -or $Lines[0] -ne '---') {
        return @{ Frontmatter = [ordered]@{}; BodyStart = 0 }
    }
    $fm = [ordered]@{}
    for ($i = 1; $i -lt $Lines.Count; $i++) {
        if ($Lines[$i] -eq '---') { return @{ Frontmatter = $fm; BodyStart = $i + 1 } }
        if ($Lines[$i] -match '^([^:]+):\s*(.*)$') {
            $fm[$matches[1].Trim()] = $matches[2].Trim()
        }
    }
    return @{ Frontmatter = $fm; BodyStart = 0 }
}

function Format-Frontmatter {
    param([System.Collections.IDictionary] $Map)
    $lines = New-Object System.Collections.Generic.List[string]
    $lines.Add('---')
    foreach ($k in $FrontmatterKeyOrder) {
        if ($Map.Contains($k)) { $lines.Add(('{0}: {1}' -f $k, $Map[$k])) }
    }
    foreach ($k in ($Map.Keys | Where-Object { $_ -notin $FrontmatterKeyOrder } | Sort-Object)) {
        $lines.Add(('{0}: {1}' -f $k, $Map[$k]))
    }
    $lines.Add('---')
    $lines
}

# Walks the body line-by-line, splitting on top-level "## " headings into a
# preserved-order map of { sectionName -> List[string] }.
function Split-Body {
    param([string[]] $BodyLines)
    $result = [ordered]@{}
    $current = '__intro'
    $result[$current] = New-Object System.Collections.Generic.List[string]
    foreach ($line in $BodyLines) {
        if ($line -match '^##\s+(.+?)\s*$' -and $line -notmatch '^###') {
            $current = $matches[1].Trim()
            $result[$current] = New-Object System.Collections.Generic.List[string]
            continue
        }
        $result[$current].Add($line)
    }
    $result
}

function Strip-PlaceholderLines {
    param([System.Collections.Generic.List[string]] $Lines)
    $out = New-Object System.Collections.Generic.List[string]
    foreach ($l in $Lines) {
        if ($l -match '\{\{\s*Fill\s.*Description\s*\}\}') { continue }
        if ($l -match '\{\{\s*Insert list of aliases\s*\}\}') { continue }
        $out.Add($l)
    }
    $out
}

# SYNTAX:
# - Drop "### __AllParameterSets" sub-heading and the blank line below
#   (legacy single-set commands jumped straight to the code fence).
# - Replace bare ``` with ```powershell.
# - Drop tokens "[-_*]"  / "[[-_*]]" from the syntax line (DontShow).
function Rewrite-SyntaxSection {
    param([System.Collections.Generic.List[string]] $Lines)

    # If the only sub-heading is "### __AllParameterSets" we elide it.
    $subHeadings = @($Lines | Where-Object { $_ -match '^###\s+\S' })
    $hasOnlyDefault = ($subHeadings.Count -eq 1) -and ($subHeadings[0] -match '^###\s+__AllParameterSets\s*$')

    $out = New-Object System.Collections.Generic.List[string]
    for ($i = 0; $i -lt $Lines.Count; $i++) {
        $line = $Lines[$i]

        if ($hasOnlyDefault -and $line -match '^###\s+__AllParameterSets\s*$') {
            # Skip the heading and the (likely-blank) line that follows it.
            if ($i + 1 -lt $Lines.Count -and $Lines[$i + 1].Trim() -eq '') { $i++ }
            continue
        }

        if ($line -match '^```\s*$') {
            # Bare opening fence: only re-tag opening fences (heuristic: previous
            # non-blank line is a heading or blank). Closing fences inside code
            # blocks should stay bare. We track an "in-fence" toggle.
            if (-not $script:__synInFence) {
                $out.Add('```powershell')
                $script:__synInFence = $true
            }
            else {
                $out.Add('```')
                $script:__synInFence = $false
            }
            continue
        }

        # Strip DontShow tokens like "[-_RetryCount <int>]" or
        # "[[-_RetryCount] <int>]" anywhere on a syntax line.
        if ($script:__synInFence) {
            $line = $line -replace '\s*\[\[?-_[A-Za-z0-9]+(?:\]\s*<[^>]+>)?\]', ''
            $line = $line -replace '\s*\[-_[A-Za-z0-9]+\s+<[^>]+>\]', ''
            # Collapse leftover double spaces.
            $line = $line -replace '  +', ' '
        }
        $out.Add($line)
    }
    $script:__synInFence = $false
    $out
}

# EXAMPLES: wrap each "### Example N" block's unfenced code in ```powershell
# fences. Collapse double blank lines between code and remarks.
function Wrap-Examples {
    param([System.Collections.Generic.List[string]] $Lines)
    $out = New-Object System.Collections.Generic.List[string]
    $i = 0
    while ($i -lt $Lines.Count) {
        $line = $Lines[$i]
        $out.Add($line)
        if ($line -notmatch '^###\s+(?:Example|EXAMPLE)\s') { $i++; continue }

        $j = $i + 1
        while ($j -lt $Lines.Count -and $Lines[$j].Trim() -eq '') { $out.Add($Lines[$j]); $j++ }
        if ($j -ge $Lines.Count) { $i = $j; continue }

        if ($Lines[$j] -match '^\s*```') {
            # Already fenced. Emit fence + body + closing fence verbatim.
            $out.Add($Lines[$j]); $j++
            while ($j -lt $Lines.Count -and $Lines[$j] -notmatch '^\s*```\s*$') {
                $out.Add($Lines[$j]); $j++
            }
            if ($j -lt $Lines.Count) { $out.Add($Lines[$j]); $j++ }
        }
        else {
            $codeStart = $j
            while ($j -lt $Lines.Count -and $Lines[$j].Trim() -ne '') { $j++ }
            $codeEnd = $j - 1
            if ($codeEnd -ge $codeStart) {
                $out.Add('```powershell')
                for ($k = $codeStart; $k -le $codeEnd; $k++) { $out.Add($Lines[$k]) }
                $out.Add('```')
            }
        }

        # Now emit the remarks: collapse multiple consecutive blank lines.
        $blanks = 0
        while ($j -lt $Lines.Count -and $Lines[$j] -notmatch '^(##|###)\s') {
            if ($Lines[$j].Trim() -eq '') {
                $blanks++
                if ($blanks -le 1) { $out.Add($Lines[$j]) }
            } else {
                $blanks = 0
                $out.Add($Lines[$j])
            }
            $j++
        }
        $i = $j
    }
    $out
}

# PARAMETERS: drop blocks whose heading starts with "### -_" (the JiraPS
# DontShow naming convention). The block extends from the heading through
# the closing ``` of its YAML body up to the next "### " heading.
function Drop-DontShowParameters {
    param([System.Collections.Generic.List[string]] $Lines)
    $out = New-Object System.Collections.Generic.List[string]
    $i = 0
    while ($i -lt $Lines.Count) {
        $line = $Lines[$i]
        if ($line -match '^###\s+-_[A-Za-z0-9]') {
            $j = $i + 1
            while ($j -lt $Lines.Count -and $Lines[$j] -notmatch '^###\s') { $j++ }
            $i = $j
            continue
        }
        $out.Add($line)
        $i++
    }
    $out
}

# INPUTS / OUTPUTS: drop spurious "### System.Object" headings when at least
# one other "### Type" heading exists in the section.
function Drop-SpuriousObjectType {
    param([System.Collections.Generic.List[string]] $Lines)

    $headings = @($Lines | Where-Object { $_ -match '^###\s+\S' })
    if ($headings.Count -le 1) { return $Lines }
    if (-not ($headings | Where-Object { $_ -match '^###\s+System\.Object\s*$' })) { return $Lines }

    $out = New-Object System.Collections.Generic.List[string]
    $i = 0
    while ($i -lt $Lines.Count) {
        if ($Lines[$i] -match '^###\s+System\.Object\s*$') {
            $j = $i + 1
            while ($j -lt $Lines.Count -and $Lines[$j] -notmatch '^###\s' -and $Lines[$j] -notmatch '^##\s') { $j++ }
            # Drop heading + body up to next ### / ##.
            $i = $j
            continue
        }
        $out.Add($Lines[$i])
        $i++
    }
    $out
}

# RELATED LINKS: drop the auto-generated Online Version link, rewrite
# remaining "- [Name](url)" entries to legacy plain "[Name](url)" form, and
# emit a blank line between consecutive link entries (legacy style).
function Rewrite-RelatedLinks {
    param([System.Collections.Generic.List[string]] $Lines)
    $tmp = New-Object System.Collections.Generic.List[string]
    foreach ($l in $Lines) {
        if ($l -match '^\s*-\s*\[Online Version\]') { continue }
        if ($l -match '^\s*-?\s*(\[[^\]]+\]\([^\)]+\))\s*$') { $tmp.Add($matches[1]); continue }
        $tmp.Add($l)
    }
    $out = New-Object System.Collections.Generic.List[string]
    for ($i = 0; $i -lt $tmp.Count; $i++) {
        $out.Add($tmp[$i])
        $isLink = $tmp[$i] -match '^\[[^\]]+\]\([^\)]+\)\s*$'
        $nextIsLink = ($i + 1 -lt $tmp.Count) -and ($tmp[$i + 1] -match '^\[[^\]]+\]\([^\)]+\)\s*$')
        if ($isLink -and $nextIsLink) { $out.Add('') }
    }
    $out
}

# Builds a per-cmdlet metadata map by reflecting on a loaded module:
#   { CmdletName = @{
#         ParamName = @{
#             PSTypeName     = '...'   # if [PSTypeName('X')] decorates the param
#             DefaultValue   = '...'   # AST literal, e.g. $null / 'GET' / 0
#             AcceptedValues = @(...)  # values from [ValidateSet]
#         }
#     } }
function Get-ModuleParameterMetadata {
    param([string] $ManifestPath)

    if (-not (Test-Path $ManifestPath)) {
        throw "Module manifest not found: $ManifestPath"
    }

    Import-Module -Force -Name (Resolve-Path $ManifestPath).Path -ErrorAction Stop -WarningAction SilentlyContinue | Out-Null
    $module = Get-Module ([IO.Path]::GetFileNameWithoutExtension($ManifestPath))

    $map = @{}
    foreach ($cmd in (Get-Command -Module $module.Name -CommandType Function, Cmdlet -ErrorAction Ignore)) {
        $params = @{}
        $ast = $cmd.ScriptBlock.Ast
        # Locate the param block AST so we can pull defaults from initializer expressions.
        $paramAst = $null
        if ($ast -is [System.Management.Automation.Language.FunctionDefinitionAst]) {
            $paramAst = $ast.Body.ParamBlock
        } elseif ($ast.PSObject.Properties['ParamBlock']) {
            $paramAst = $ast.ParamBlock
        }

        foreach ($name in $cmd.Parameters.Keys) {
            $info = $cmd.Parameters[$name]
            $entry = @{}

            $pst = $info.Attributes | Where-Object { $_ -is [System.Management.Automation.PSTypeNameAttribute] } | Select-Object -First 1
            if ($pst) { $entry.PSTypeName = $pst.PSTypeName }

            $vs = $info.Attributes | Where-Object { $_ -is [System.Management.Automation.ValidateSetAttribute] } | Select-Object -First 1
            if ($vs) { $entry.AcceptedValues = @($vs.ValidValues) }

            if ($paramAst) {
                $pAst = $paramAst.Parameters | Where-Object { $_.Name.VariablePath.UserPath -eq $name } | Select-Object -First 1
                if ($pAst -and $pAst.DefaultValue) {
                    $entry.DefaultValue = $pAst.DefaultValue.Extent.Text
                }
            }

            if ($entry.Count -gt 0) { $params[$name] = $entry }
        }

        if ($params.Count -gt 0) { $map[$cmd.Name] = $params }
    }

    $map
}

# Patches the parameter YAML blocks under "## PARAMETERS" using the metadata
# map produced by Get-ModuleParameterMetadata for the given cmdlet.
function Patch-ParameterMetadata {
    param(
        [System.Collections.Generic.List[string]] $Lines,
        [hashtable] $ParamMap   # { ParamName = @{ PSTypeName, DefaultValue, AcceptedValues } }
    )
    if (-not $ParamMap -or $ParamMap.Count -eq 0) { return $Lines }

    $out = New-Object System.Collections.Generic.List[string]
    $i = 0
    while ($i -lt $Lines.Count) {
        $line = $Lines[$i]
        $out.Add($line)

        if ($line -notmatch '^###\s+-([A-Za-z0-9]+)\s*$') { $i++; continue }
        $paramName = $matches[1]
        $i++

        # Copy until we reach the opening ```yaml fence for this parameter.
        while ($i -lt $Lines.Count -and $Lines[$i] -notmatch '^```yaml\s*$') {
            $out.Add($Lines[$i]); $i++
        }
        if ($i -ge $Lines.Count) { continue }
        $out.Add($Lines[$i]); $i++   # the ```yaml line itself

        # Buffer the YAML body until the closing fence.
        $yamlBuf = New-Object System.Collections.Generic.List[string]
        while ($i -lt $Lines.Count -and $Lines[$i] -notmatch '^```\s*$') {
            $yamlBuf.Add($Lines[$i]); $i++
        }

        $meta = $ParamMap[$paramName]
        if ($meta) {
            for ($k = 0; $k -lt $yamlBuf.Count; $k++) {
                if ($meta.ContainsKey('PSTypeName') -and $yamlBuf[$k] -match '^Type:\s+System\.Object(\[\])?\s*$') {
                    $arr = if ($matches[1]) { '[]' } else { '' }
                    $yamlBuf[$k] = "Type: $($meta.PSTypeName)$arr"
                }
                if ($meta.ContainsKey('DefaultValue') -and $yamlBuf[$k] -match "^DefaultValue:\s*''\s*$") {
                    # Strip the leading $ from PowerShell variable defaults so the
                    # value reads as a literal in MAML (e.g. $null -> None).
                    $dv = $meta.DefaultValue
                    if ($dv -match '^\$') { $dv = $dv.Substring(1) }
                    # Single-quote unconditionally to keep arbitrary literals
                    # (e.g. "[System.Management.Automation.PSCredential]::Empty")
                    # from being parsed as YAML inline lists / aliases.
                    $escaped = $dv.Replace("'", "''")
                    $yamlBuf[$k] = "DefaultValue: '$escaped'"
                }
                if ($meta.ContainsKey('AcceptedValues') -and $yamlBuf[$k] -match '^AcceptedValues:\s*\[\]\s*$') {
                    # Replace the empty inline list with a YAML block list.
                    $yamlBuf[$k] = 'AcceptedValues:'
                    $insertAt = $k + 1
                    foreach ($v in $meta.AcceptedValues) {
                        $yamlBuf.Insert($insertAt, "- $v")
                        $insertAt++
                    }
                    $k = $insertAt - 1
                }
            }
        }

        foreach ($l in $yamlBuf) { $out.Add($l) }
        if ($i -lt $Lines.Count) { $out.Add($Lines[$i]); $i++ }
    }
    $out
}

# Trim leading and trailing blank lines of a list (interior blanks preserved).
function Trim-BlankEdges {
    param([System.Collections.Generic.List[string]] $Lines)
    $start = 0
    while ($start -lt $Lines.Count -and $Lines[$start].Trim() -eq '') { $start++ }
    $end = $Lines.Count - 1
    while ($end -ge $start -and $Lines[$end].Trim() -eq '') { $end-- }
    $out = New-Object System.Collections.Generic.List[string]
    for ($i = $start; $i -le $end; $i++) { $out.Add($Lines[$i]) }
    $out
}

function Convert-File {
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [string] $FilePath,
        [string] $LegacyFolder,
        [string] $PermalinkBase,
        [string] $OnlineVersionBase,
        [hashtable] $MetadataMap
    )

    $name = [IO.Path]::GetFileNameWithoutExtension($FilePath)
    $raw = Get-Content -LiteralPath $FilePath
    $parsed = Read-Frontmatter -Lines $raw
    $fm = $parsed.Frontmatter
    $body = if ($parsed.BodyStart -gt 0) { @($raw[$parsed.BodyStart..($raw.Count - 1)]) } else { $raw }

    # ---- Frontmatter rewrite ----------------------------------------------
    foreach ($drop in @('document type', 'PlatyPS schema version', 'title', 'ms.date')) {
        if ($fm.Contains($drop)) { $fm.Remove($drop) }
    }
    if ($fm.Contains('HelpUri')) {
        $fm['online version'] = $fm['HelpUri']
        $fm.Remove('HelpUri')
    }
    if ($fm.Contains('Locale')) {
        $fm['locale'] = $fm['Locale']
        $fm.Remove('Locale')
    }
    $fm['locale'] = 'en-US'
    if (-not $fm.Contains('online version')) {
        $fm['online version'] = $OnlineVersionBase.TrimEnd('/') + '/' + $name + '/'
    }
    if (-not $fm.Contains('layout')) { $fm['layout'] = 'documentation' }
    if (-not $fm.Contains('permalink')) {
        $fm['permalink'] = $PermalinkBase.TrimEnd('/') + '/' + $name + '/'
    }

    # ---- Body section split & rewrites ------------------------------------
    $sections = Split-Body -BodyLines $body

    if ($sections.Contains('ALIASES')) { $sections.Remove('ALIASES') | Out-Null }

    foreach ($k in @($sections.Keys)) {
        $sections[$k] = Strip-PlaceholderLines -Lines $sections[$k]
    }

    if ($sections.Contains('SYNTAX')) {
        $sections['SYNTAX'] = Rewrite-SyntaxSection -Lines $sections['SYNTAX']
    }

    if ($sections.Contains('EXAMPLES')) {
        $sections['EXAMPLES'] = Wrap-Examples -Lines $sections['EXAMPLES']
    }

    if ($sections.Contains('PARAMETERS')) {
        $sections['PARAMETERS'] = Drop-DontShowParameters -Lines $sections['PARAMETERS']
        if ($MetadataMap -and $MetadataMap.ContainsKey($name)) {
            $sections['PARAMETERS'] = Patch-ParameterMetadata -Lines $sections['PARAMETERS'] -ParamMap $MetadataMap[$name]
        }
    }

    foreach ($k in 'INPUTS', 'OUTPUTS') {
        if ($sections.Contains($k)) {
            $sections[$k] = Drop-SpuriousObjectType -Lines $sections[$k]
        }
    }

    if ($sections.Contains('RELATED LINKS')) {
        $sections['RELATED LINKS'] = Rewrite-RelatedLinks -Lines $sections['RELATED LINKS']
    }

    foreach ($k in @($sections.Keys)) {
        $sections[$k] = Trim-BlankEdges -Lines $sections[$k]
    }

    # ---- Reassemble --------------------------------------------------------
    $out = New-Object System.Collections.Generic.List[string]
    foreach ($l in (Format-Frontmatter -Map $fm)) { $out.Add($l) }

    $intro = Trim-BlankEdges -Lines $sections['__intro']
    foreach ($l in $intro) { $out.Add($l) }
    $sections.Remove('__intro') | Out-Null

    foreach ($k in $sections.Keys) {
        $out.Add('')
        $out.Add("## $k")
        $body = $sections[$k]
        if ($body.Count -gt 0) {
            $out.Add('')
            foreach ($l in $body) { $out.Add($l) }
        }
    }

    if ($PSCmdlet.ShouldProcess($FilePath, 'Apply v1 markdown migration transforms')) {
        # Single trailing newline, LF endings; .gitattributes normalizes.
        $text = ($out -join "`n") + "`n"
        Set-Content -LiteralPath $FilePath -Value $text -Encoding utf8 -NoNewline
    }
}

# ---------- main ----------

if (-not (Test-Path $Path)) { throw "Path not found: $Path" }
$LegacyFolder = (Resolve-Path $LegacyFolder).Path

if (Test-Path $Path -PathType Container) {
    $files = Get-ChildItem $Path -Filter '*.md' -File | Where-Object Name -ne 'index.md'
} else {
    $files = ,(Get-Item $Path)
}

$metadataMap = $null
if ($ModuleManifest) {
    Write-Verbose "Loading module metadata from $ModuleManifest"
    $metadataMap = Get-ModuleParameterMetadata -ManifestPath $ModuleManifest
    Write-Verbose "Captured metadata for $($metadataMap.Count) cmdlets."
}

foreach ($f in $files) {
    Write-Verbose "Migrating $($f.FullName)"
    $script:__synInFence = $false
    Convert-File -FilePath $f.FullName -LegacyFolder $LegacyFolder -PermalinkBase $PermalinkBase -OnlineVersionBase $OnlineVersionBase -MetadataMap $metadataMap
}

Write-Host ("Processed {0} file(s)." -f $files.Count)
