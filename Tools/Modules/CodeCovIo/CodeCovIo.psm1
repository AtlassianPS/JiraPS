<#
  .SYNOPSIS
  Updates a hash table with the Unique file lines
  Structure:
  RootTable.[FileKey].[SubTable].[Line]

  .PARAMETER FileLine
  The table to update

  .PARAMETER Command
  The list of Command from pester to update the table based on

  .PARAMETER RepoRoot
  The path to the root of the repo.  This part of the path will not be included in the report.  Needed to normalize all the reports.

  .PARAMETER TableName
  The path of the file to write the report to.
#>
function Add-UniqueFileLineToTable {
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        [HashTable]
        $FileLine,

        [Parameter(Mandatory = $true)]
        [Object]
        $Command,

        [Parameter(Mandatory = $true)]
        [String]
        $RepoRoot,

        [Parameter(Mandatory = $true)]
        [String]
        $TableName
    )

    # file paths need to be relative to repo root when querying GIT
    Push-Location -LiteralPath $RepoRoot
    try {
        Write-Verbose -Message "running git ls-files" -Verbose

        # Get the list of files as Git sees them
        $fileKeys = & git.exe ls-files

        # Populate the sub-table
        foreach ($command in $Command) {
            #Find the file as Git sees it
            $file = $command.File
            $fileKey = $file.replace($RepoRoot, '').TrimStart('\').replace('\', '/')
            $fileKey = $fileKeys.where{$_ -like $fileKey}

            if ($null -eq $fileKey) {
                Write-Warning -Message "Unexpected error filekey was null"
                continue
            }
            elseif ($fileKey.Count -ne 1) {
                Write-Warning -Message "Unexpected error, more than one git file matched file ($file): $($fileKey -join ', ')"
                continue
            }

            $fileKey = $fileKey | Select-Object -First 1

            if (!$FileLine.ContainsKey($fileKey)) {
                $FileLine.add($fileKey, @{ $TableName = @{}})
            }

            if (!$FileLine.$fileKey.ContainsKey($TableName)) {
                $FileLine.$fileKey.Add($TableName, @{})
            }

            $lines = $FileLine.($fileKey).$TableName
            $lineKey = $($command.line)
            if (!$lines.ContainsKey($lineKey)) {
                $lines.Add($lineKey, 1)
            }
            else {
                $lines.$lineKey ++
            }
        }
    }
    finally {
        Pop-Location
    }
}

<#
  .SYNOPSIS
  Tests if the specified property is a CodeCoverage object
  For use in a ValidateScript attribute

  .PARAMETER CodeCoverage
  The CodeCoverage property of the output of Invoke-Pester with the -PassThru and -CodeCoverage options

#>
function Test-CodeCoverage {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [Object]
        $CodeCoverage
    )

    if (!($CodeCoverage | Get-Member -Name MissedCommands)) {
        throw 'Must be a Pester CodeCoverage object'
    }

    return $true
}

<#
  .SYNOPSIS
  Exports a Pester CodeCoverage report as a CodeCov.io json report

  .PARAMETER CodeCoverage
  The CodeCoverage property of the output of Invoke-Pester with the -PassThru and -CodeCoverage options

  .PARAMETER RepoRoot
  The path to the root of the repo.  This part of the path will not be included in the report.  Needed to normalize all the reports.

  .PARAMETER Path
  The path of the file to write the report to.
#>
function Export-CodeCovIoJson {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateScript( {Test-CodeCoverage -CodeCoverage $_})]
        [Object]
        $CodeCoverage,

        [Parameter(Mandatory = $true)]
        [String]
        $RepoRoot,

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [String]
        $Path = (Join-Path -Path $env:TEMP -ChildPath 'codeCov.json')
    )

    Write-Verbose -Message "RepoRoot: $RepoRoot"

    # Get a list of all unique files
    $files = @()
    foreach ($file in ($CodeCoverage.MissedCommands | Select-Object -ExpandProperty File -Unique)) {
        if ($files -notcontains $file) {
            $files += $file
        }
    }

    foreach ($file in ($CodeCoverage.HitCommands | Select-Object -ExpandProperty File -Unique)) {
        if ($files -notcontains $file) {
            $files += $file
        }
    }

    # A table of the file key then a sub-tables of `misses` and `hits` lines.
    $FileLine = @{}

    # define common parameters
    $addUniqueFileLineParams = @{
        FileLine = $FileLine
        RepoRoo  = $RepoRoot
    }

    <#
        Basically indexing all the hit and miss lines by file and line.
        Populate the misses sub-table
    #>
    Add-UniqueFileLineToTable -Command $CodeCoverage.MissedCommands -TableName 'misses' @addUniqueFileLineParams

    # Populate the hits sub-table
    Add-UniqueFileLineToTable -Command $CodeCoverage.HitCommands -TableName 'hits' @addUniqueFileLineParams

    # Create the results structure
    $resultLineData = @{}
    $resultMessages = @{}
    $result = @{
        coverage = $resultLineData
        messages = $resultMessages
    }

    foreach ($file in $FileLine.Keys) {
        $hit = 0
        $partial = 0
        $missed = 0
        Write-Verbose -Message "summarizing for file: $file"

        # Get the hits, if they exist
        $hits = @{}
        if ($FileLine.$file.ContainsKey('hits')) {
            $hits = $FileLine.$file.hits
        }

        # Get the misses, if they exist
        $misses = @{}
        if ($FileLine.$file.ContainsKey('misses')) {
            $misses = $FileLine.$file.misses
        }

        Write-Verbose -Message "fileKeys: $($FileLine.$file.Keys)"
        $max = $hits.Keys | Sort-Object -Descending | Select-Object -First 1
        $maxMissLine = $misses.Keys | Sort-Object -Descending | Select-Object -First 1

        <#
            if max missed line is greater than maxed hit line
            used max missed line as the max line
        #>
        if ($maxMissLine -gt $max) {
            $max = $maxMissLine
        }

        $lineData = @()
        $messages = @{}

        <#
            produce the results
            start at line 0 per codecov doc
        #>
        for ($lineNumber = 0; $lineNumber -le $max; $lineNumber++) {
            $hitInfo = $null
            $missInfo = $null
            switch ($true) {
                # Hit
                ($hits.ContainsKey($lineNumber) -and ! $misses.ContainsKey($lineNumber)) {
                    Write-Verbose -Message "Got code coverage hit at $lineNumber"
                    $lineData += "$($hits.$lineNumber)"
                }

                # Miss
                ($misses.ContainsKey($lineNumber) -and ! $hits.ContainsKey($lineNumber)) {
                    Write-Verbose -Message "Got code coverage miss at $lineNumber"
                    $lineData += '0'
                }

                # Partial Hit
                ($misses.ContainsKey($lineNumber) -and $hits.ContainsKey($lineNumber)) {
                    Write-Verbose -Message "Got code coverage partial at $lineNumber"

                    $missInfo = $misses.$lineNumber
                    $hitInfo = $hits.$lineNumber
                    $lineData += "$hitInfo/$($hitInfo+$missInfo)"
                }

                # Non-Code Line
                (!$misses.ContainsKey($lineNumber) -and !$hits.ContainsKey($lineNumber)) {
                    Write-Verbose -Message "Got non-code at $lineNumber"

                    <#
                        If I put an actual null in an array ConvertTo-Json just leaves it out
                        I'll put this string in and clean it up later.
                    #>
                    $lineData += '!null!'
                }

                default {
                    throw "Unexpected error occured generating codeCov.io report for $file at line $lineNumber with hits: $($hits.ContainsKey($lineNumber)) and misses: $($misses.ContainsKey($lineNumber))"
                }
            }
        }

        $resultLineData.Add($file, $lineData)
        $resultMessages.add($file, $messages)
    }

    $commitOutput = @(&git.exe log -1 --pretty=format:%H)
    $commit = $commitOutput[0]

    Write-Verbose -Message "Branch: $Branch"

    $json = $result | ConvertTo-Json
    $json = $json.Replace('"!null!"', 'null')

    $json | Out-File -Encoding ascii -LiteralPath $Path -Force
    return $Path
}

<#
  .SYNOPSIS
  Uploads a CodeCov.io code coverage report

  .PARAMETER Path
  The path to the code coverage report (gcov not supported)
#>
function Invoke-UploadCoveCoveIoReport {
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        [String]
        $Path
    )

    $resolvedResultFile = (Resolve-Path -Path $Path).ProviderPath

    if ($env:APPVEYOR_REPO_BRANCH) {
        Push-AppVeyorArtifact $resolvedResultFile
    }

    # Set the location of Python, install the pip and get the CodeCov script, and upload the code coverage report to CodeCov
    $ENV:PATH = 'C:\\Python34;C:\\Python34\\Scripts;' + $ENV:PATH
    $null = python -m pip install --upgrade pip
    $null = pip install git+git://github.com/codecov/codecov-python.git
    $uploadResults = codecov -f $resolvedResultFile -X gcov

    if ($env:APPVEYOR_REPO_BRANCH) {
        $logPath = (Join-Path -Path $env:TEMP -ChildPath 'codeCovUpload.log')
        $uploadResults | Out-File -Encoding ascii -LiteralPath $logPath -Force
        $resolvedLogPath = (Resolve-Path -Path $logPath).ProviderPath
        Push-AppVeyorArtifact $resolvedLogPath
    }
}
