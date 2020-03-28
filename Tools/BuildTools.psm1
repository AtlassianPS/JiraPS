#requires -Modules @{ModuleName='PowerShellGet';ModuleVersion='1.6.0'}

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

function Install-Dependency {
    [CmdletBinding()]
    param(
        [ValidateSet("CurrentUser", "AllUsers")]
        $Scope = "CurrentUser"
    )

    [Microsoft.PowerShell.Commands.ModuleSpecification[]]$RequiredModules = Import-LocalizedData -BaseDirectory $PSScriptRoot -FileName "build.requirements.psd1"
    $Policy = (Get-PSRepository PSGallery).InstallationPolicy
    try {
        Set-PSRepository PSGallery -InstallationPolicy Trusted
        $RequiredModules | Install-Module -Scope $Scope -Repository PSGallery -SkipPublisherCheck -AllowClobber
    }
    finally {
        Set-PSRepository PSGallery -InstallationPolicy $Policy
    }
    $RequiredModules | Import-Module
}

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
    [System.Diagnostics.CodeAnalysis.SuppressMessage('PSUseShouldProcessForStateChangingFunctions', '')]
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

function Set-GitUser {
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseShouldProcessForStateChangingFunctions", "")]
    param()
    # github's PAT is stored to ~\.git-credentials within the Release Pipeline
    # to avoid it being passed as parameter

    if (-not (git config user.email)) { git config user.email "support@atlassianps.net" }
    if (-not (git config user.name)) { git config user.name "AtlassianPS Automated User" }
    if (-not (git config credential.helper)) { git config credential.helper "store --file ~/.git-credentials" }
}

Export-ModuleMember -Function * -Alias *
