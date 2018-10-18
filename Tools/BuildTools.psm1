[CmdletBinding()]
param()

function Invoke-Init {
    [Alias("Init")]
    [CmdletBinding()]
    param()
    begin {
        Set-BuildEnvironment -BuildOutput '$ProjectPath/Release' -ErrorAction SilentlyContinue
        Add-ToModulePath -Path $env:BHBuildOutput
    }
}

function Assert-True {
    [CmdletBinding( DefaultParameterSetName = 'ByBool' )]
    param(
        [Parameter( Position = 0, Mandatory, ParameterSetName = 'ByScriptBlock' )]
        [ScriptBlock]$ScriptBlock,
        [Parameter( Position = 0, Mandatory, ParameterSetName = 'ByBool' )]
        [Bool]$Bool,
        [Parameter( Position = 1, Mandatory )]
        [String]$Message
    )

    if ($ScriptBlock) {
        $Bool = & $ScriptBlock
    }

    if (-not $Bool) {
        throw $Message
    }
}

function LogCall {
    Assert-True { Test-Path TestDrive:\ } "This function only work inside pester"

    Set-Content -Value "$($MyInvocation.Invocationname) $($MyInvocation.UnBoundArguments -join " ")" -Path "TestDrive:\FunctionCalled.$($MyInvocation.Invocationname).txt" -Force
}

function Add-ToModulePath ([String]$Path) {
    $PSModulePath = $env:PSModulePath -split ([IO.Path]::PathSeparator)
    if ($Path -notin $PSModulePath) {
        $PSModulePath += $Path
        $env:PSModulePath = $PSModulePath -join ([IO.Path]::PathSeparator)
    }
}

function Install-PSDepend {
    if (-not (Get-Module PSDepend -ListAvailable)) {
        if (Get-Module PowershellGet -ListAvailable) {
            Install-Module PSDepend -Scope CurrentUser -ErrorAction Stop -Verbose
        }
        else {
            throw "The PowershellGet module is not available."
        }
    }
}

function Get-AppVeyorBuild {
    param()

    Assert-True { $env:APPVEYOR_API_TOKEN } "missing api token for AppVeyor."
    Assert-True { $env:APPVEYOR_ACCOUNT_NAME } "not an appveyor build."

    $invokeRestMethodSplat = @{
        Uri     = "https://ci.appveyor.com/api/projects/$env:APPVEYOR_ACCOUNT_NAME/$env:APPVEYOR_PROJECT_SLUG"
        Method  = 'GET'
        Headers = @{
            "Authorization" = "Bearer $env:APPVEYOR_API_TOKEN"
            "Content-type"  = "application/json"
        }
    }
    Invoke-RestMethod @invokeRestMethodSplat
}

function Get-TravisBuild {
    param()

    Assert-True { $env:TRAVIS_API_TOKEN } "missing api token for Travis-CI."
    Assert-True { $env:APPVEYOR_ACCOUNT_NAME } "not an appveyor build."

    $invokeRestMethodSplat = @{
        Uri     = "https://api.travis-ci.org/builds?limit=10"
        Method  = 'Get'
        Headers = @{
            "Authorization"      = "token $env:TRAVIS_API_TOKEN"
            "Travis-API-Version" = "3"
        }
    }
    Invoke-RestMethod @invokeRestMethodSplat
}

function Test-IsLastJob {
    param()

    if (-not ('AppVeyor' -eq $env:BHBuildSystem)) {
        return $true
    }
    Assert-True { $env:APPVEYOR_JOB_ID } "Invalid Job identifier"

    $buildData = Get-AppVeyorBuild
    $lastJob = ($buildData.build.jobs | Select-Object -Last 1).jobId

    if ($lastJob -eq $env:APPVEYOR_JOB_ID) {
        return $true
    }
    else {
        return $false
    }
}

function Test-ShouldDeploy {
    if (-not ($env:ShouldDeploy -eq $true)) {
        return $false
    }
    # only deploy master branch
    if (-not ('master' -eq $env:BHBranchName)) {
        return $false
    }
    # it cannot be a PR
    if ($env:APPVEYOR_PULL_REQUEST_NUMBER) {
        return $false
    }
    # only deploy from AppVeyor
    if (-not ($env:APPVEYOR_JOB_ID)) {
        return $false
    }
    # must be last job of AppVeyor
    if (-not (Test-IsLastJob)) {
        return $false
    }
    # Travis-CI must be finished (if used)
    # TODO: (Test-TravisProgress) -and
    # it cannot have a commit message that contains "skip-deploy"
    if ($env:BHCommitMessage -like '*skip-deploy*') {
        return $false
    }

    return $true
}

function Publish-GithubRelease {
    param(
        [Parameter( Mandatory )]
        [ValidateNotNullOrEmpty()]
        [String]$GITHUB_ACCESS_TOKEN,
        [String]$ProjectOwner = "AtlassianPS",
        [String]$ReleaseText,
        [Object]$NextBuildVersion
    )

    Assert-True { $env:BHProjectName } "Missing AppVeyor's Repo Name"

    $body = @{
        "tag_name"         = "v$NextBuildVersion"
        "target_commitish" = "master"
        "name"             = "v$NextBuildVersion"
        "body"             = $ReleaseText
        "draft"            = $false
        "prerelease"       = $false
    } | ConvertTo-Json

    $releaseParams = @{
        Uri         = "https://api.github.com/repos/{0}/{1}/releases" -f $ProjectOwner, $env:BHProjectName
        Method      = 'POST'
        Headers     = @{
            Authorization = 'Basic ' + [Convert]::ToBase64String(
                [Text.Encoding]::ASCII.GetBytes($GITHUB_ACCESS_TOKEN + ":x-oauth-basic")
            )
        }
        ContentType = 'application/json'
        Body        = $body
        ErrorAction = "Stop"
    }
    Invoke-RestMethod @releaseParams
}

function Publish-GithubReleaseArtifact {
    param(
        [Parameter( Mandatory )]
        [ValidateNotNullOrEmpty()]
        [String]$GITHUB_ACCESS_TOKEN,
        [Uri]$Uri,
        [String]$Path
    )

    $body = [System.IO.File]::ReadAllBytes($Path)
    $assetParams = @{
        Uri         = $Uri
        Method      = 'POST'
        Headers     = @{
            Authorization = 'Basic ' + [Convert]::ToBase64String(
                [Text.Encoding]::ASCII.GetBytes($GITHUB_ACCESS_TOKEN + ":x-oauth-basic")
            )
        }
        ContentType = "application/zip"
        Body        = $body
    }
    Invoke-RestMethod @assetParams
}

function Set-AppVeyorBuildNumber {
    param()

    Assert-True { $env:APPVEYOR_REPO_NAME } "Is not an AppVeyor Job"
    Assert-True { $env:APPVEYOR_API_TOKEN } "Is missing AppVeyor's API token"

    $separator = "-"
    $headers = @{
        "Authorization" = "Bearer $env:APPVEYOR_API_TOKEN"
        "Content-type"  = "application/json"
    }
    $apiURL = "https://ci.appveyor.com/api/projects/$env:APPVEYOR_ACCOUNT_NAME/$env:APPVEYOR_PROJECT_SLUG"
    $history = Invoke-RestMethod -Uri "$apiURL/history?recordsNumber=2" -Headers $headers  -Method Get
    if ($history.builds.Count -eq 2) {
        $s = Invoke-RestMethod -Uri "$apiURL/settings" -Headers $headers  -Method Get
        $s.settings.nextBuildNumber = ($s.settings.nextBuildNumber - 1)
        Invoke-RestMethod -Uri 'https://ci.appveyor.com/api/projects' -Headers $headers  -Body ($s.settings | ConvertTo-Json -Depth 10) -Method Put
        $previousVersion = $history.builds[1].version
        if ($previousVersion.IndexOf("$separator") -ne "-1") {$previousVersion = $previousVersion.SubString(0, $previousVersion.IndexOf("$separator"))}
        Update-AppveyorBuild -Version $previousVersion$separator$((New-Guid).ToString().SubString(0,8))
    }
}

#region Old
# function allJobsFinished {
#     param()

#     if (-not ('AppVeyor' -eq $env:BHBuildSystem)) {
#         return $true
#     }
#     if (-not ($env:APPVEYOR_API_TOKEN)) {
#         Write-Warning "Missing `$env:APPVEYOR_API_TOKEN"
#         return $true
#     }
#     if (-not ($env:APPVEYOR_ACCOUNT_NAME)) {
#         Write-Warning "Missing `$env:APPVEYOR_ACCOUNT_NAME"
#         return $true
#     }

#     Test-IsLastJob

#     Write-Host "[IDLE] :: waiting for other jobs to complete"

#     [datetime]$stop = ([datetime]::Now).AddMinutes($env:TimeOutMins)

#     do {
#         $project = Get-AppVeyorBuild
#         $continue = @()
#         $project.build.jobs | Where-Object {$_.jobId -ne $env:APPVEYOR_JOB_ID} | Foreach-Object {
#             $job = $_
#             switch -regex ($job.status) {
#                 "failed" { throw "AppVeyor's Job ($($job.jobId)) failed." }
#                 "(running|success)" { $continue += $true; continue }
#                 Default { $continue += $false; Write-Host "new state: $_.status" }
#             }
#         }
#         if ($false -notin $continue) { return $true }
#         Start-sleep 5
#     } while (([datetime]::Now) -lt $stop)

#     throw "Test jobs were not finished in $env:TimeOutMins minutes"
# }
#endregion Old

function Get-FileEncoding {
    <#
    .SYNOPSIS
        Attempt to determine a file type based on a BOM or file header.
    .DESCRIPTION
        This script attempts to determine file types based on a byte sequence at the beginning of the file.

        If an identifiable byte sequence is not present the file type cannot be determined using this method.
        The order signatures appear in is critical where signatures overlap. For example, UTF32-LE must be evaluated before UTF16-LE.
    .LINK
        https://en.wikipedia.org/wiki/Byte_order_mark#cite_note-b-15
        https://filesignatures.net

    .SOURCE
        https://gist.github.com/indented-automation/8e603144167c7acca4dd8f653d47441e
    #>

    [CmdletBinding()]
    [OutputType('EncodingInfo')]
    param (
        # The path to a file to analyze.
        [Parameter(Mandatory, Position = 1, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [ValidateScript( { Test-Path $_ -PathType Leaf } )]
        [Alias('FullName')]
        [String]$Path,

        # Test the file against a small set of signature definitions for binary file types.
        #
        # Identification should be treated as tentative. Several file formats cannot be identified using the sequence at the start alone.
        [Switch]$IncludeBinary
    )

    begin {
        $signatures = [Ordered]@{
            'UTF32-LE'   = 'FF-FE-00-00'
            'UTF32-BE'   = '00-00-FE-FF'
            'UTF8-BOM'   = 'EF-BB-BF'
            'UTF16-LE'   = 'FF-FE'
            'UTF16-BE'   = 'FE-FF'
            'UTF7'       = '2B-2F-76-38', '2B-2F-76-39', '2B-2F-76-2B', '2B-2F-76-2F'
            'UTF1'       = 'F7-64-4C'
            'UTF-EBCDIC' = 'DD-73-66-73'
            'SCSU'       = '0E-FE-FF'
            'BOCU-1'     = 'FB-EE-28'
            'GB-18030'   = '84-31-95-33'
        }

        if ($IncludeBinary) {
            $signatures += [Ordered]@{
                'LNK'      = '4C-00-00-00-01-14-02-00'
                'MSEXCEL'  = '50-4B-03-04-14-00-06-00'
                'PNG'      = '89-50-4E-47-0D-0A-1A-0A'
                'MSOFFICE' = 'D0-CF-11-E0-A1-B1-1A-E1'
                '7ZIP'     = '37-7A-BC-AF-27-1C'
                'RTF'      = '7B-5C-72-74-66-31'
                'GIF'      = '47-49-46-38'
                'REGPOL'   = '50-52-65-67'
                'JPEG'     = 'FF-D8'
                'MSEXE'    = '4D-5A'
                'ZIP'      = '50-4B'
            }
        }

        # Convert sequence strings to byte arrays. Intended to simplify signature maintenance.
        [String[]]$keys = $signatures.Keys
        foreach ($name in $keys) {
            [System.Collections.Generic.List[System.Collections.Generic.List[Byte]]]$values = foreach ($value in $signatures[$name]) {
                [System.Collections.Generic.List[Byte]]$signatureBytes = foreach ($byte in $value.Split('-')) {
                    [Convert]::ToByte($byte, 16)
                }
                , $signatureBytes
            }
            $signatures[$name] = $values
        }
    }

    process {
        try {
            $Path = $pscmdlet.GetUnresolvedProviderPathFromPSPath($Path)

            $bytes = [Byte[]]::new(8)
            $stream = New-Object System.IO.StreamReader($Path)
            $null = $stream.Peek()
            $enc = $stream.CurrentEncoding
            $stream.Close()
            $stream = [System.IO.File]::OpenRead($Path)
            $null = $stream.Read($bytes, 0, $bytes.Count)
            $bytes = [System.Collections.Generic.List[Byte]]$bytes
            $stream.Close()

            if ($enc -eq [System.Text.Encoding]::UTF8) {
                $encoding = "UTF8"
            }

            foreach ($name in $signatures.Keys) {
                $sampleEncoding = foreach ($sequence in $signatures[$name]) {
                    $sample = $bytes.GetRange(0, $sequence.Count)

                    if ([System.Linq.Enumerable]::SequenceEqual($sample, $sequence)) {
                        $name
                        break
                    }
                }
                if ($sampleEncoding) {
                    $encoding = $sampleEncoding
                    break
                }
            }

            if (-not $encoding) {
                $encoding = "ASCII"
            }

            [PSCustomObject]@{
                Name      = Split-Path $Path -Leaf
                Extension = [System.IO.Path]::GetExtension($Path)
                Encoding  = $encoding
                Path      = $Path
            } | Add-Member -TypeName 'EncodingInfo' -PassThru
        }
        catch {
            $pscmdlet.WriteError($_)
        }
    }
}

function Remove-Utf8Bom {
    <#
    .SYNOPSIS
        Removes a UTF8 BOM from a file.
    .DESCRIPTION
        Removes a UTF8 BOM from a file if the BOM appears to be present.
        The UTF8 BOM is identified by the byte sequence 0xEF 0xBB 0xBF at the beginning of the file.
    .EXAMPLE
        Remove-Utf8Bom -Path c:\file.txt
        Remove a BOM from a single file.
    .EXAMPLE
        Get-ChildItem c:\folder -Recurse -File | Remove-Utf8Bom
        Remove the BOM from every file returned by Get-ChildItem.
    .LINK
        https://gist.github.com/indented-automation/5f6b87f31c438f14905f62961025758b
    #>

    [CmdletBinding()]
    param (
        # The path to a file which should be updated.
        [Parameter(Mandatory, Position = 1, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [ValidateScript( { Test-Path $_ -PathType Leaf } )]
        [Alias('FullName')]
        [String]$Path
    )

    begin {
        $encoding = [System.Text.UTF8Encoding]::new($false)
    }

    process {
        $Path = $pscmdlet.GetUnresolvedProviderPathFromPSPath($Path)

        try {
            $bom = [Byte[]]::new(3)
            $stream = [System.IO.File]::OpenRead($Path)
            $null = $stream.Read($bom, 0, 3)
            $stream.Close()

            if ([BitConverter]::ToString($bom, 0) -eq 'EF-BB-BF') {
                [System.IO.File]::WriteAllLines(
                    $Path,
                    [System.IO.File]::ReadAllLines($Path),
                    $encoding
                )
            }
            else {
                Write-Verbose ('A UTF8 BOM was not detected on the file {0}' -f $Path)
            }
        }
        catch {
            Write-Error -ErrorRecord $_
        }
    }
}

Export-ModuleMember -Function * -Alias *
