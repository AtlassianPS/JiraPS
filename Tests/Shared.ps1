
# Dot source this script in any Pester test script that requires the module to be imported.

$ModuleName = 'PSJira'
$ModuleManifestPath = "$PSScriptRoot\..\$ModuleName\$ModuleManifestName.psd1"
$RootModule = "$PSScriptRoot\..\$ModuleName\$ModuleName.psm1"

# The first time this is called, the module will be forcibly (re-)imported.
# After importing it once, the $SuppressImportModule flag should prevent
# the module from being imported again for each test file.

if (-not (Get-Module -Name $ModuleName -ErrorAction SilentlyContinue) -or (!$SuppressImportModule)) {
    # If we import the .psd1 file, Pester has issues where it detects multiple
    # modules named PSJira. Importing the .psm1 file seems to correct this.

    # -Scope Global is needed when running tests from within a CI environment
    Import-Module $RootModule -Scope Global -Force

    # Set to true so we don't need to import it again for the next test
    $SuppressImportModule = $true
}

[System.Diagnostics.CodeAnalysis.SuppressMessage('PSUseDeclaredVarsMoreThanAssigments', '', Scope='*', Target='ShowMockData')]
$ShowMockData = $true

[System.Diagnostics.CodeAnalysis.SuppressMessage('PSUseDeclaredVarsMoreThanAssigments', '', Scope='*', Target='ShowDebugText')]
$ShowDebugText = $true

function defProp($obj, $propName, $propValue)
{
    It "Defines the '$propName' property" {
        $obj.$propName | Should Be $propValue
    }
}

function checkPsType($obj, $typeName) {
    It "Uses output type of '$typeName'" {
        # If $obj is an array, newer versions of PowerShell can return
        # the typenames in a row - "PSJira.Issue PSJira.Issue PSJira.Issue"
        @($obj)[0].PSObject.TypeNames[0] | Should Be $typeName
    }
}
