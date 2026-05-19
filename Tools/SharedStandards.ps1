#requires -Module PowerShellGet

function Get-AtlassianPSStandardsRequiredVersion {
    [CmdletBinding()]
    [OutputType([String])]
    param(
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [String]$BuildRequirementsPath
    )

    if (-not (Test-Path -LiteralPath $BuildRequirementsPath -PathType Leaf)) {
        throw "Build requirements file was not found at '$BuildRequirementsPath'."
    }

    $tokens = $null
    $parseErrors = $null
    $ast = [System.Management.Automation.Language.Parser]::ParseFile($BuildRequirementsPath, [ref]$tokens, [ref]$parseErrors)
    if ($parseErrors -and $parseErrors.Count -gt 0) {
        throw "Unable to parse build requirements file '$BuildRequirementsPath': $($parseErrors[0].Message)"
    }

    if (-not $ast.EndBlock -or $ast.EndBlock.Statements.Count -eq 0) {
        throw "Build requirements file '$BuildRequirementsPath' does not contain a supported data expression."
    }

    $statement = $ast.EndBlock.Statements[0]
    if ($statement -isnot [System.Management.Automation.Language.PipelineAst]) {
        throw "Build requirements file '$BuildRequirementsPath' does not contain a supported data expression."
    }

    $pipelineElement = $statement.PipelineElements[0]
    if ($pipelineElement -isnot [System.Management.Automation.Language.CommandExpressionAst]) {
        throw "Build requirements file '$BuildRequirementsPath' does not contain a supported data expression."
    }

    $requirements = @($pipelineElement.Expression.SafeGetValue())
    foreach ($requirement in $requirements) {
        $moduleName = $null
        $requiredVersion = $null

        if ($requirement -is [System.Collections.IDictionary]) {
            if ($requirement.Contains('ModuleName')) {
                $moduleName = [String]$requirement['ModuleName']
            }
            if ($requirement.Contains('RequiredVersion')) {
                $requiredVersion = [String]$requirement['RequiredVersion']
            }
            elseif ($requirement.Contains('ModuleVersion')) {
                $requiredVersion = [String]$requirement['ModuleVersion']
            }
        }
        elseif ($requirement) {
            if ($requirement.PSObject.Properties.Name -contains 'ModuleName') {
                $moduleName = [String]$requirement.ModuleName
            }
            if ($requirement.PSObject.Properties.Name -contains 'RequiredVersion') {
                $requiredVersion = [String]$requirement.RequiredVersion
            }
            elseif ($requirement.PSObject.Properties.Name -contains 'ModuleVersion') {
                $requiredVersion = [String]$requirement.ModuleVersion
            }
        }

        if ($moduleName -ne 'AtlassianPS.Standards') {
            continue
        }

        if (-not $requiredVersion) {
            throw "Module requirement 'AtlassianPS.Standards' in '$BuildRequirementsPath' must specify RequiredVersion or ModuleVersion."
        }

        return $requiredVersion
    }

    throw "Module requirement 'AtlassianPS.Standards' was not found in '$BuildRequirementsPath'."
}

function Import-AtlassianPSStandardsModule {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [String]$RequiredVersion
    )

    if (-not (Get-PSRepository -Name 'PSGallery' -ErrorAction SilentlyContinue)) {
        Register-PSRepository -Default -ErrorAction Stop
    }

    $installedVersion = Get-Module -Name 'AtlassianPS.Standards' -ListAvailable |
        Where-Object { $_.Version.ToString() -eq $RequiredVersion } |
        Select-Object -First 1

    if (-not $installedVersion) {
        Install-Module -Name 'AtlassianPS.Standards' `
            -RequiredVersion $RequiredVersion `
            -Scope CurrentUser `
            -Repository 'PSGallery' `
            -AllowClobber `
            -Force `
            -ErrorAction Stop
    }

    Import-Module -Name 'AtlassianPS.Standards' -RequiredVersion $RequiredVersion -Force -ErrorAction Stop
}
