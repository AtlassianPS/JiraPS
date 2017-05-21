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

function defProp($obj, $propName, $propValue)
{
    It "Defines the '$propName' property" {
        $obj.$propName | Should Be $propValue
    }
}