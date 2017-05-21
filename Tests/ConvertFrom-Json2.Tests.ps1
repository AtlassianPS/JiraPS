[System.Diagnostics.CodeAnalysis.SuppressMessage('PSUseDeclaredVarsMoreThanAssigments', '', Scope='*', Target='SuppressImportModule')]
$SuppressImportModule = $true
. $PSScriptRoot\Shared.ps1

Describe "ConvertFrom-Json2" {
	$sampleJson = '{"id":"issuetype","name":"Issue Type","custom":false,"orderable":true,"navigable":true,"searchable":true,"clauseNames":["issuetype","type"],"schema":{"type":"issuetype","system":"issuetype"}}'
    $sampleObject = ConvertFrom-Json2 -InputObject $sampleJson

	It "Creates a PSObject out of JSON input" {
        $sampleObject | Should Not BeNullOrEmpty
    }

	defProp $sampleObject 'Id' 'issuetype'
    defProp $sampleObject 'Name' 'Issue Type'
    defProp $sampleObject 'Custom' $false

    Context "Sanity checking" {
        It "Does not crash on a null or empty input" {
            { ConvertFrom-Json2 -InputObject '' } | Should Not Throw
        }

        It "Accepts pipeline input" {
            { @($sampleJson,$sampleJson) | ConvertFrom-Json2 } | Should Not Throw
        }

        It "Provides the same output as ConvertFrom-Json for JSON strings the latter can handle" {
            # Make sure we've got our head screwed on straight. If it's a short enough JSON string that ConvertFrom-Json can handle it, this function should provide identical output to the native one.

            $sampleNative = ConvertFrom-Json -InputObject $sampleJson
            foreach ($p in $sampleObject.PSObject.Properties.Name) {
                # Force converting everything to a string isn't the best test of equality, but it's good enough for what we need here.
                "$($sampleObject.$p)" | Should Be "$($sampleNative.$p)"
            }
        }
    }
}