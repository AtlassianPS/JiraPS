. $PSScriptRoot\Shared.ps1

InModuleScope JiraPS {

    [System.Diagnostics.CodeAnalysis.SuppressMessage('PSUseDeclaredVarsMoreThanAssigments', '', Scope = '*', Target = 'SuppressImportModule')]
    $SuppressImportModule = $true
    . $PSScriptRoot\Shared.ps1

    Describe "ConvertTo-JiraSession" {

        $sampleUsername = 'powershell-test'
        $sampleSession = @{}

        $r = ConvertTo-JiraSession -Session $sampleSession -Username $sampleUsername

        It "Creates a PSObject out of Web request data" {
            $r | Should Not BeNullOrEmpty
        }

        checkPsType $r 'JiraPS.Session'
        defProp $r 'Username' $sampleUsername
    }
}
