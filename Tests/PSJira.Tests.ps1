$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$projectRoot = Split-Path -Parent $here
$moduleRoot = "$projectRoot\PSJira"

$manifestFile = "$moduleRoot\PSJira.psd1"
$changelogFile = "$projectRoot\CHANGELOG.md"
$appveyorFile = "$projectRoot\appveyor.yml"
$functions = "$moduleRoot\Functions"

Describe "PSJira" {
    Context "All required tests are present" {
        # We want to make sure that every .ps1 file in the Functions directory that isn't a Pester test has an associated Pester test.
        # This helps keep me honest and makes sure I'm testing my code appropriately.
        It "Includes a test for each PowerShell function in the module" {
            Get-ChildItem -Path $functions -Filter "*.ps1" -Recurse | Where-Object -FilterScript {$_.Name -notlike '*.Tests.ps1'} | % {
                $_.FullName -replace '.ps1','.Tests.ps1' | Should Exist
            }
        }
    }

    Context "Manifest, changelog, and AppVeyor" {

        # These tests are...erm, borrowed...from the module tests from the Pester module.
        # I think they are excellent for sanity checking, and all credit for the following
        # tests goes to Dave Wyatt, the genius behind Pester.  I've just adapted them
        # slightly to match PSJira.

        $script:manifest = $null
        It "Includes a valid manifest file" {
            {
                $script:manifest = Test-ModuleManifest -Path $manifestFile -ErrorAction Stop -WarningAction SilentlyContinue
            } | Should Not Throw
        }

        It "Manifest file includes the correct name" {
            $script:manifest.Name | Should Be PSJira
        }

        It "Manifest file includes the correct guid" {
            $script:manifest.Guid | Should Be '4bf3eb15-037e-43b7-9e47-20a30436324f'
        }

        It "Manifest file includes a valid version" {
            $script:manifest.Version -as [Version] | Should Not BeNullOrEmpty
        }

        It "Includes a changelog file" {
            $changelogFile | Should Exist
        }

        $script:changelogVersion = $null
        It "Changelog includes a valid version number" {

            foreach ($line in (Get-Content $changelogFile))
            {
                if ($line -match "^\D*(?<Version>(\d+\.){1,3}\d+)")
                {
                    $script:changelogVersion = $matches.Version
                    break
                }
            }
            $script:changelogVersion                | Should Not BeNullOrEmpty
            $script:changelogVersion -as [Version]  | Should Not BeNullOrEmpty
        }

        It "Changelog version matches manifest version" {
            $script:changelogVersion -as [Version] | Should Be ( $script:manifest.Version -as [Version] )
        }

        # Back to me! Pester doesn't use AppVeyor, as far as I know, and I do.

        It "Includes an appveyor.yml file" {
            $appveyorFile | Should Exist
        }

        It "Appveyor.yml file includes the module version" {
            foreach ($line in (Get-Content $appveyorFile))
            {
                # (?<Version>()) - non-capturing group, but named Version. This makes it
                # easy to reference the inside group later.

                if ($line -match '^\D*(?<Version>(\d+\.){1,3}\d+).\{build\}')
                {
                    $script:appveyorVersion = $matches.Version
                    break
                }
            }
            $script:appveyorVersion               | Should Not BeNullOrEmpty
            $script:appveyorVersion -as [Version] | Should Not BeNullOrEmpty
        }

        It "Appveyor version matches manifest version" {
            $script:appveyorVersion -as [Version] | Should Be ( $script:manifest.Version -as [Version] )
        }
    }

    Context "Style checking" {

        # This section is again from the mastermind, Dave Wyatt. Again, credit
        # goes to him for these tests.

        $files = @(
            Get-ChildItem $here -Include *.ps1,*.psm1
            Get-ChildItem $functions -Include *.ps1,*.psm1 -Recurse
        )

        It 'Source files contain no trailing whitespace' {
            $badLines = @(
                foreach ($file in $files)
                {
                    $lines = [System.IO.File]::ReadAllLines($file.FullName)
                    $lineCount = $lines.Count

                    for ($i = 0; $i -lt $lineCount; $i++)
                    {
                        if ($lines[$i] -match '\s+$')
                        {
                            'File: {0}, Line: {1}' -f $file.FullName, ($i + 1)
                        }
                    }
                }
            )

            if ($badLines.Count -gt 0)
            {
                throw "The following $($badLines.Count) lines contain trailing whitespace: `r`n`r`n$($badLines -join "`r`n")"
            }
        }

        It 'Source files all end with a newline' {
            $badFiles = @(
                foreach ($file in $files)
                {
                    $string = [System.IO.File]::ReadAllText($file.FullName)
                    if ($string.Length -gt 0 -and $string[-1] -ne "`n")
                    {
                        $file.FullName
                    }
                }
            )

            if ($badFiles.Count -gt 0)
            {
                throw "The following files do not end with a newline: `r`n`r`n$($badFiles -join "`r`n")"
            }
        }
    }
}


