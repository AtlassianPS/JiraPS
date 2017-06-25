
# Dot source this script in any Pester test script that requires the module to be imported.

$ModuleName = 'JiraPS'
$ModuleManifestPath = "$PSScriptRoot\..\$ModuleName\$ModuleManifestName.psd1"
$RootModule = "$PSScriptRoot\..\$ModuleName\$ModuleName.psm1"

# The first time this is called, the module will be forcibly (re-)imported.
# After importing it once, the $SuppressImportModule flag should prevent
# the module from being imported again for each test file.

if (-not (Get-Module -Name $ModuleName -ErrorAction SilentlyContinue) -or (!$SuppressImportModule)) {
    # If we import the .psd1 file, Pester has issues where it detects multiple
    # modules named JiraPS. Importing the .psm1 file seems to correct this.

    # -Scope Global is needed when running tests from within a CI environment
    Import-Module $RootModule -Scope Global -Force

    # Set to true so we don't need to import it again for the next test
    $SuppressImportModule = $true
}

[System.Diagnostics.CodeAnalysis.SuppressMessage('PSUseDeclaredVarsMoreThanAssigments', '', Scope='*', Target='ShowMockData')]
$ShowMockData = $false

[System.Diagnostics.CodeAnalysis.SuppressMessage('PSUseDeclaredVarsMoreThanAssigments', '', Scope='*', Target='ShowDebugText')]
$ShowDebugText = $false

function defProp($obj, $propName, $propValue)
{
    It "Defines the '$propName' property" {
        $obj.$propName | Should Be $propValue
    }
}

function defParam($command, $name)
{
    It "Has a -$name parameter" {
        $command.Parameters.Item($name) | Should Not BeNullOrEmpty
    }
}

# This function must be used from within an It block
function checkType($obj, $typeName) {
    if ($obj -is [System.Array]) {
        $o = $obj[0]
    }
    else {
        $o = $obj
    }

    $o.PSObject.TypeNames[0] | Should Be $typeName
}

function checkPsType($obj, $typeName) {
    It "Uses output type of '$typeName'" {
        checkType $obj $typeName
    }
}

function ShowMockInfo($functionName, [String[]] $params)
{
    if ($ShowMockData)
    {
        Write-Host "       Mocked $functionName" -ForegroundColor Cyan
        foreach ($p in $params) {
            Write-Host "         [$p]  $(Get-Variable -Name $p -ValueOnly)" -ForegroundColor Cyan
        }
    }
}
