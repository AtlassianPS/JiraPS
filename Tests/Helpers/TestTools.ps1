# function Get-TestNameFromCaller {
#     $callerPath = (Get-PSCallStack)[1].ScriptName
#     $fileName = [System.IO.Path]::GetFileNameWithoutExtension($callerPath)
#     return $fileName -replace '\.Unit\.Tests$', ''
# }

function Initialize-TestEnvironment {
    <#
    .SYNOPSIS
        Cleans up previously loaded JiraPS modules to ensure a clean test state.

    .DESCRIPTION
        This helper function performs module cleanup for JiraPS unit tests by:
        - Finding any modules that depend on JiraPS
        - Removing dependent modules and JiraPS itself
        - Ensuring a clean slate for module import in tests

        This function should be called in BeforeDiscovery blocks before importing
        the module under test.

    .OUTPUTS
        None. This function works via side effects (module cleanup).

    .EXAMPLE
        # Standard usage in function tests
        BeforeDiscovery {
            . "$PSScriptRoot/../Helpers/TestTools.ps1"

            Initialize-TestEnvironment
            $script:moduleToTest = Resolve-ModuleSource

            Import-Module $script:moduleToTest -Force -ErrorAction Stop
        }

    .EXAMPLE
        # Usage in project-level tests
        BeforeAll {
            . "$PSScriptRoot/Helpers/TestTools.ps1"

            Initialize-TestEnvironment
            $script:moduleToTest = Resolve-ModuleSource
        }

    .NOTES
        This function should be called before importing the JiraPS module in tests
        to prevent conflicts with previously loaded versions.

    .LINK
        Resolve-ModuleSource

    .LINK
        Resolve-ProjectRoot
    #>
    [CmdletBinding()]
    [OutputType([void])]
    param()

    $dependentModules = Get-Module | Where-Object { $_.RequiredModules.Name -eq 'JiraPS' }
    $dependentModules, "JiraPS" | Remove-Module -Force -ErrorAction SilentlyContinue
}

function Resolve-ModuleSource {
    <#
    .SYNOPSIS
        Resolves the path to the JiraPS module manifest for testing.

    .DESCRIPTION
        This lightweight helper function replaces the BuildHelpers dependency for
        Pester v5 tests. It determines whether tests are running against the source
        module in the JiraPS/ directory or a built Release module and returns the
        appropriate manifest path.

        The function checks:
        1. If running from a Release build context
        2. The source module location (JiraPS/JiraPS.psd1)
        3. Validates the module file exists

    .OUTPUTS
        [string] Path to the JiraPS module manifest (.psd1)

    .EXAMPLE
        # Standard usage in test files
        BeforeDiscovery {
            . "$PSScriptRoot/../Helpers/TestTools.ps1"

            Initialize-TestEnvironment
            $script:moduleToTest = Resolve-ModuleSource

            Import-Module $script:moduleToTest -Force -ErrorAction Stop
        }

    .EXAMPLE
        # With verbose output
        BeforeAll {
            . "$PSScriptRoot/Helpers/TestTools.ps1"
            $VerbosePreference = 'Continue'
            $moduleToTest = Resolve-ModuleSource
            # Outputs: "Using module at: /path/to/JiraPS/JiraPS.psd1"
        }

    .NOTES
        This function uses Resolve-ProjectRoot internally to find the repository root
        before locating the module manifest.

    .LINK
        Initialize-TestEnvironment

    .LINK
        Resolve-ProjectRoot
    #>
    [CmdletBinding()]
    [OutputType([string])]
    param()

    $projectRoot = Resolve-ProjectRoot
    ${/} = [System.IO.Path]::DirectorySeparatorChar

    if ($PSScriptRoot -like "*${/}Release${/}*") {
        $projectRoot = (Resolve-Path "$projectRoot/Release").Path
    }

    $moduleManifest = Join-Path $projectRoot "JiraPS/JiraPS.psd1"

    if (-not (Test-Path $moduleManifest)) {
        throw "Could not find JiraPS module at: $moduleManifest"
    }

    Write-Verbose "Using module at: $moduleManifest"
    return $moduleManifest
}


function Resolve-ProjectRoot {
    <#
    .SYNOPSIS
        Resolves the root directory of the JiraPS project.

    .DESCRIPTION
        This helper function locates the JiraPS project root directory by navigating
        up from the Tests/Helpers directory and validating the location by checking
        for the LICENSE file.

        This is used internally by other TestTools functions to find the module
        source and other project files.

    .OUTPUTS
        [string] Fully qualified path to the project root directory

    .EXAMPLE
        # Direct usage (uncommon - typically called by other TestTools functions)
        BeforeAll {
            . "$PSScriptRoot/Helpers/TestTools.ps1"
            $projectRoot = Resolve-ProjectRoot
            $changelogPath = Join-Path $projectRoot "CHANGELOG.md"
        }

    .NOTES
        This function is primarily used internally by Resolve-ModuleSource.
        The LICENSE file is used as a marker to confirm the project root.

    .LINK
        Resolve-ModuleSource
    #>
    [CmdletBinding()]
    [OutputType([string])]
    param()

    $projectRoot = Join-Path -Path $PSScriptRoot -ChildPath "../.."

    if (-not (Test-Path "$projectRoot/LICENSE")) {
        $projectRoot = Join-Path -Path $projectRoot -ChildPath ".."
    }

    return (Resolve-Path $projectRoot)
}

function Write-MockDebugInfo {
    <#
    .SYNOPSIS
        Displays debug information about mock function calls during tests.

    .DESCRIPTION
        When $VerbosePreference = 'Continue' is set in the test's BeforeAll block,
        this function displays the mocked function name and parameter values from
        the caller's scope for debugging mock behavior.

        The function formats output with color coding:
        - Mock name in cyan
        - Parameter names in yellow
        - Array/hashtable counts in magenta
        - Null/empty values in dark gray

        Arrays with 5 or fewer items display all elements. Larger collections show
        only the count. Long strings are truncated to 100 characters.

    .PARAMETER FunctionName
        The name of the mocked function being called. This is displayed as the
        mock identifier.

    .PARAMETER Params
        Array of parameter names to display values for. The function will retrieve
        the values of these parameters from the caller's scope.

    .OUTPUTS
        None. This function writes directly to the host with Write-Host for
        formatted color output.

    .EXAMPLE
        # Basic usage in a mock
        Mock Get-JiraFilter -ModuleName JiraPS {
            Write-MockDebugInfo 'Get-JiraFilter' 'Id', 'Name'
            return @{ Id = $Id; Name = $Name }
        }

        # With verbose output enabled
        BeforeAll {
            . "$PSScriptRoot/../Helpers/TestTools.ps1"
            $VerbosePreference = 'Continue'  # Enable mock debugging
        }

    .EXAMPLE
        # In Invoke-JiraMethod mock
        Mock Invoke-JiraMethod -ModuleName JiraPS {
            Write-MockDebugInfo 'Invoke-JiraMethod' 'Method', 'Uri', 'Body'
            # ... mock implementation
        }

        # Output when called:
        # 🔷 Mock: Invoke-JiraMethod
        #   [Method] = "GET"
        #   [Uri] = "https://jira.example.com/rest/api/2/filter/12345"
        #   [Body] = <null>

    .NOTES
        - This function only produces output when $VerbosePreference = 'Continue'
        - Must be called from within a Mock scriptblock to access parameter values
        - Requires the TestTools.ps1 module to be dot-sourced inside InModuleScope
        - Uses Write-Host for colored output (suppresses PSScriptAnalyzer warning)

    .LINK
        Initialize-TestEnvironment

    .LINK
        about_Preference_Variables
    #>
    [CmdletBinding()]
    [System.Diagnostics.CodeAnalysis.SuppressMessage('PSAvoidUsingWriteHost', '')]
    param(
        [Parameter(Mandatory)]
        [string]$FunctionName,

        [Parameter()]
        [string[]]$Params,

        $BoundParameters
    )

    if ($VerbosePreference -eq 'SilentlyContinue') { return }

    Write-Host "     🔷 Mock: $FunctionName" -ForegroundColor Cyan

    if ($Params) {
        foreach ($paramName in $Params) {
            $value = Get-Variable -Name $paramName -ValueOnly -ErrorAction SilentlyContinue

            if ($null -eq $value) {
                Write-Host "         [$paramName] = <null>" -ForegroundColor DarkGray
            }
            elseif ($value -is [string] -and [string]::IsNullOrEmpty($value)) {
                Write-Host "         [$paramName] = <empty string>" -ForegroundColor DarkGray
            }
            elseif ($value -is [array]) {
                Write-Host "         [$paramName] = @(" -ForegroundColor Yellow -NoNewline
                Write-Host "$($value.Count) items" -ForegroundColor Magenta -NoNewline
                Write-Host ")" -ForegroundColor Yellow
                if ($value.Count -le 5) {
                    foreach ($item in $value) {
                        Write-Host "           - $item" -ForegroundColor DarkYellow
                    }
                }
            }
            elseif ($value -is [hashtable] -or $value -is [System.Collections.IDictionary]) {
                Write-Host "         [$paramName] = @{" -ForegroundColor Yellow -NoNewline
                Write-Host "$($value.Count) keys" -ForegroundColor Magenta -NoNewline
                Write-Host "}" -ForegroundColor Yellow
            }
            else {
                $displayValue = if ($value.ToString().Length -gt 100) {
                    "$($value.ToString().Substring(0, 97))..."
                }
                else {
                    $value.ToString()
                }
                Write-Host "         [$paramName] = $displayValue" -ForegroundColor Yellow
            }
        }
    }
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
        # Identification Should be treated as tentative. Several file formats cannot be identified using the sequence at the start alone.
        [Switch]$IncludeBinary
    )

    begin {
        $signatures = [Ordered]@{
            'UTF32-LE'   = 'FF-FE-00-00'
            'UTF32be'    = '00-00-FE-FF'
            'UTF8-BOM'   = 'EF-BB-BF'
            'UTF16-LE'   = 'FF-FE'
            'UTF16be'    = 'FE-FF'
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
