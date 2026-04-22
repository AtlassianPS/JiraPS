#Requires -Version 5.1
<#
.SYNOPSIS
    Audit `## INPUTS` headings against the pre-PlatyPS-migration master.

.DESCRIPTION
    Detecting "spurious" pipeline inputs from parameter metadata alone is
    not reliable: ValueFromPipelineByPropertyName lets any object bind via
    property names, so `JiraPS.Issue` legitimately binds to a `-Key:String`
    parameter when the issue object has a `Key` property. There is no
    pure-introspection rule that distinguishes hand-curated input types
    from PlatyPS-auto-added ones.

    The signal we DO have is the previous markdown corpus. Pre-migration
    master used hand-curated INPUTS sections; the v1 generator added
    extra `### System.<Type>` headings via parameter introspection. This
    script compares each current INPUTS heading against the heading list
    in the same file at the pre-migration git revision and reports any
    heading that did not exist before. Those are the candidates for
    removal.

    Run from the worktree root.
#>
[CmdletBinding()]
param(
    [string] $DocsPath = "$PSScriptRoot/../docs/en-US/commands",
    [string] $PreMigrationRev = '0ad69bf'
)

$ErrorActionPreference = 'Stop'

function Get-InputHeading {
    param([string] $Markdown)
    if (-not $Markdown) { return @() }
    $sections = $Markdown -split '## INPUTS', 2
    if ($sections.Count -lt 2) { return @() }
    $inSection = ($sections[1] -split '## OUTPUTS', 2)[0]
    return @([regex]::Matches($inSection, '(?m)^### (.+)$') |
            ForEach-Object { $_.Groups[1].Value.Trim() })
}

function ConvertTo-NormalisedHeading {
    # Pre-migration headings used [Type] / [Type[]] / [A] / [B] notation.
    # Strip outer square brackets that wrap a token so heading-level
    # equality matches across the bracket-stripping migration. The
    # regex matches a `[...]` that contains either non-bracket chars or
    # the empty `[]` array suffix, so `[Int[]]` -> `Int[]` works.
    param([string] $Heading)
    # Match `[Token]` or `[Token[]]` where Token has no inner brackets.
    # This matches master's notation `[Type]`/`[Type[]]` without
    # accidentally consuming a bare `String[]` array suffix.
    $stripped = [regex]::Replace($Heading, '\[([^\[\]]+(?:\[\])?)\]', '$1')
    return $stripped.Trim()
}

$report = foreach ($mdFile in (Get-ChildItem -Path $DocsPath -Filter '*.md' -File | Where-Object Name -NE 'index.md')) {
    $current = Get-Content $mdFile.FullName -Raw
    $previousLines = git show "${PreMigrationRev}:docs/en-US/commands/$($mdFile.Name)" 2>$null
    if (-not $previousLines) { continue }
    $previous = $previousLines -join "`n"

    $curHeadings = Get-InputHeading -Markdown $current | ForEach-Object { ConvertTo-NormalisedHeading $_ }
    $preHeadings = Get-InputHeading -Markdown $previous | ForEach-Object { ConvertTo-NormalisedHeading $_ }

    $preSet = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase)
    foreach ($p in $preHeadings) { [void]$preSet.Add($p) }
    foreach ($h in $curHeadings) {
        if (-not $preSet.Contains($h)) {
            [pscustomobject]@{
                Cmd               = $mdFile.BaseName
                Added             = $h
                MasterHadNoInputs = ($preHeadings.Count -eq 0)
            }
        }
    }
}

"=== INPUTS headings present in current but absent from pre-migration master ==="
$report | Format-Table -AutoSize | Out-String

"=== Summary ==="
"Total cmdlets with new INPUTS headings : " + (($report | Group-Object Cmd).Count)
"Total new headings to review           : " + $report.Count
"Of which: master had EMPTY INPUTS      : " + (@($report | Where-Object MasterHadNoInputs).Count)
"          master had SOME INPUTS       : " + (@($report | Where-Object { -not $_.MasterHadNoInputs }).Count)
