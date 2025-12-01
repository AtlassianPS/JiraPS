#requires -modules @{ ModuleName = "Pester"; ModuleVersion = "5.7"; MaximumVersion = "5.999" }

Describe "Style rules" -Tag "Unit" {
    BeforeAll {
        $script:module = Join-Path $PSScriptRoot "..\JiraPS"
        $script:codeFiles = Get-ChildItem $module -Include *.ps1, *.psm1 -Recurse
        $script:docFiles = Get-ChildItem "$PSScriptRoot/.." -Include *.md -Recurse
    }

    It "has no trailing whitespace in code files" {
        $badLines = @(
            foreach ($file in $codeFiles) {
                $lines = [System.IO.File]::ReadAllLines($file.FullName)
                $lineCount = $lines.Count

                for ($i = 0; $i -lt $lineCount; $i++) {
                    if ($lines[$i] -match '\s+$') {
                        'File: {0}, Line: {1}' -f $file.FullName, ($i + 1)
                    }
                }
            }
        )

        if ($badLines.Count -gt 0) {
            throw "The following $($badLines.Count) lines contain trailing whitespace: `r`n`r`n$($badLines -join "`r`n")"
        }
    }

    It "has one newline at the end of the file" {
        $badFiles = @(
            foreach ($file in @($codeFiles + $docFiles)) {
                $string = [System.IO.File]::ReadAllText($file.FullName)
                if ($string.Length -gt 0 -and $string[-1] -ne "`n") {
                    $file.FullName
                }
            }
        )

        if ($badFiles.Count -gt 0) {
            throw "The following files do not end with a newline: `r`n`r`n$($badFiles -join "`r`n")"
        }
    }

    It "uses UTF-8 for code files" {
        $badFiles = @(
            foreach ($file in $codeFiles) {
                $encoding = Get-FileEncoding -Path $file.FullName
                if ($encoding -and $encoding.encoding -ne "UTF8") {
                    $file.FullName
                }
            }
        )

        if ($badFiles.Count -gt 0) {
            throw "The following files are not encoded with UTF-8 (no BOM): `r`n`r`n$($badFiles -join "`r`n")"
        }
    }

    It "uses UTF-8 for documentation files" {
        $badFiles = @(
            foreach ($file in $docFiles) {
                $encoding = Get-FileEncoding -Path $file.FullName
                if ($encoding -and $encoding.encoding -ne "UTF8") {
                    $file.FullName
                }
            }
        )

        if ($badFiles.Count -gt 0) {
            throw "The following files are not encoded with UTF-8 (no BOM): `r`n`r`n$($badFiles -join "`r`n")"
        }
    }

    It "uses CRLF as newline character in code files" {
        $badFiles = @(
            foreach ($file in $codeFiles) {
                $string = [System.IO.File]::ReadAllText($file.FullName)
                if ($string.Length -gt 0 -and $string -notmatch "\r\n$") {
                    $file.FullName
                }
            }
        )

        if ($badFiles.Count -gt 0) {
            throw "The following files do not use CRLF as line break: `r`n`r`n$($badFiles -join "`r`n")"
        }
    }

    It "uses LF as newline character in documentation files" {
        $badFiles = @(
            foreach ($file in $docFiles) {
                $string = [System.IO.File]::ReadAllText($file.FullName)
                if ($string.Length -gt 0 -and $string -notmatch "\n$") {
                    $file.FullName
                }
            }
        )

        if ($badFiles.Count -gt 0) {
            throw "The following files do not use CRLF as line break: `r`n`r`n$($badFiles -join "`r`n")"
        }
    }
}
