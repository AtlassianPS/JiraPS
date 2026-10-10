#requires -modules @{ ModuleName = "Pester"; ModuleVersion = "6.2.0"; MaximumVersion = "6.999" }

Describe 'Required integration coverage' -Tag Unit -ForEach @(
    @{ Track = 'Cloud'; OtherTrack = 'Server' }
    @{ Track = 'Server'; OtherTrack = 'Cloud' }
) {
    BeforeAll {
        . "$PSScriptRoot/../Helpers/TestTools.ps1"
        $script:projectRoot = Resolve-ProjectRoot
        $script:assertScript = Join-Path $projectRoot 'Tools/Assert-IntegrationCoverage.ps1'
        $script:manifestPath = Join-Path $projectRoot 'Tests/Integration/RequiredSuites.psd1'
        $script:requiredSuites = (Import-PowerShellDataFile $manifestPath).Suites
        $script:suite = $requiredSuites[0]
    }

    BeforeEach {
        $script:resultPath = Join-Path $TestDrive 'integration.xml'
        $script:report = [xml] '<test-results><test-suite type="Assembly"><results><test-suite type="TestFixture"><results /></test-suite></results></test-suite></test-results>'
        foreach ($requiredSuite in $requiredSuites | Select-Object -Skip 1) {
            $fixture = $report.SelectSingleNode('//test-suite[@type="TestFixture"]').CloneNode($true)
            $fixture.SetAttribute('name', "/home/runner/Tests/Integration/$($requiredSuite.File)")
            foreach ($name in (@($requiredSuite.Common) + @($requiredSuite.Cloud) + @($requiredSuite.Server))) {
                $test = $report.CreateElement('test-case')
                $test.SetAttribute('name', $name)
                $isOtherTrack = $name -in $requiredSuite[$OtherTrack]
                $test.SetAttribute('result', $(if ($isOtherTrack) { 'Ignored' } else { 'Success' }))
                $test.SetAttribute('executed', $(if ($isOtherTrack) { 'False' } else { 'True' }))
                $null = $fixture.SelectSingleNode('results').AppendChild($test)
            }
            $null = $report.SelectSingleNode('//test-suite[@type="Assembly"]/results').AppendChild($fixture)
        }
        $script:fileFixture = $report.SelectSingleNode('//test-suite[@type="TestFixture"]')
        $fileFixture.SetAttribute('name', "/home/runner/Tests/Integration/$($suite.File)")
        foreach ($name in (@($suite.Common) + @($suite.Cloud) + @($suite.Server))) {
            $test = $report.CreateElement('test-case')
            $test.SetAttribute('name', $name)
            $isOtherTrack = $name -in $suite[$OtherTrack]
            $test.SetAttribute('result', $(if ($isOtherTrack) { 'Ignored' } else { 'Success' }))
            $test.SetAttribute('executed', $(if ($isOtherTrack) { 'False' } else { 'True' }))
            $null = $fileFixture.SelectSingleNode('results').AppendChild($test)
        }
    }

    It 'accepts all required tests passing with only deployment-specific skips' {
        $report.Save($resultPath)
        { & $assertScript -Track $Track -ResultPath $resultPath } | Should -Not -Throw
    }

    It 'accepts Windows fixture paths' {
        $fileFixture.SetAttribute('name', "C:\runner\Tests\Integration\$($suite.File)")
        $report.Save($resultPath)
        { & $assertScript -Track $Track -ResultPath $resultPath } | Should -Not -Throw
    }

    It 'rejects a missing result file' {
        { & $assertScript -Track $Track -ResultPath "$TestDrive/missing.xml" } |
            Should -Throw -ExpectedMessage '*result file*is missing*'
    }

    It 'rejects malformed results' {
        Set-Content -LiteralPath $resultPath -Value '<test-results>'
        { & $assertScript -Track $Track -ResultPath $resultPath } |
            Should -Throw -ExpectedMessage '*Cannot read NUnit*'
    }

    It 'rejects an absent required suite even when unrelated tests pass' {
        $fileFixture.SetAttribute('name', '/Tests/Integration/Unrelated.Integration.Tests.ps1')
        $report.Save($resultPath)
        { & $assertScript -Track $Track -ResultPath $resultPath } |
            Should -Throw -ExpectedMessage '*Groups.Integration.Tests.ps1*expected one file fixture, found 0*'
    }

    It 'rejects an empty required suite' {
        $fileFixture.SelectSingleNode('results').RemoveAll()
        $report.Save($resultPath)
        { & $assertScript -Track $Track -ResultPath $resultPath } |
            Should -Throw -ExpectedMessage '*required test*is absent*'
    }

    It 'rejects a filtered-out deployment-specific required test' {
        $test = $fileFixture.SelectNodes('.//test-case') | Where-Object { $_.name -eq $suite[$Track][0] }
        $null = $test.ParentNode.RemoveChild($test)
        $report.Save($resultPath)
        { & $assertScript -Track $Track -ResultPath $resultPath } |
            Should -Throw -ExpectedMessage "*$($suite[$Track][0])*is absent*"
    }

    It 'rejects a required test with result <Result> and executed <Executed>' -ForEach @(
        @{ Result = 'Ignored'; Executed = 'False' }
        @{ Result = 'Inconclusive'; Executed = 'True' }
        @{ Result = 'Failure'; Executed = 'True' }
        @{ Result = 'Success'; Executed = 'False' }
    ) {
        $test = $fileFixture.SelectSingleNode('.//test-case')
        $test.SetAttribute('result', $Result)
        $test.SetAttribute('executed', $Executed)
        $report.Save($resultPath)
        { & $assertScript -Track $Track -ResultPath $resultPath } |
            Should -Throw -ExpectedMessage "*did not pass (result='$Result', executed='$Executed')*"
    }

    It 'rejects a wholly skipped required suite' {
        foreach ($test in $fileFixture.SelectNodes('.//test-case')) {
            $test.SetAttribute('result', 'Ignored')
            $test.SetAttribute('executed', 'False')
        }
        $report.Save($resultPath)
        { & $assertScript -Track $Track -ResultPath $resultPath } |
            Should -Throw -ExpectedMessage '*Required integration coverage failed*did not pass*'
    }

    It 'rejects an unexpected skip in a newly added test' {
        $test = $report.CreateElement('test-case')
        $test.SetAttribute('name', 'Groups.new group test')
        $test.SetAttribute('result', 'Ignored')
        $test.SetAttribute('executed', 'False')
        $null = $fileFixture.SelectSingleNode('results').AppendChild($test)
        $report.Save($resultPath)
        { & $assertScript -Track $Track -ResultPath $resultPath } |
            Should -Throw -ExpectedMessage '*Groups.new group test*did not pass*'
    }

    It 'verifies every configured suite' {
        $requirementsPath = Join-Path $TestDrive 'required.psd1'
        Set-Content -LiteralPath $requirementsPath -Value @'
@{
    Suites = @(
        @{ File = 'Groups.Integration.Tests.ps1'; Common = @('Groups.Get-JiraGroup.Group Retrieval.retrieves a group by name') }
        @{ File = 'Other.Integration.Tests.ps1'; Common = @('Other.required test') }
    )
}
'@
        $report.Save($resultPath)
        { & $assertScript -Track $Track -ResultPath $resultPath -RequiredSuitesPath $requirementsPath } |
            Should -Throw -ExpectedMessage '*Other.Integration.Tests.ps1*expected one file fixture, found 0*'
    }

    It 'rejects an empty required-suite list' {
        $requirementsPath = Join-Path $TestDrive 'empty.psd1'
        Set-Content -LiteralPath $requirementsPath -Value '@{ Suites = @() }'
        $report.Save($resultPath)
        { & $assertScript -Track $Track -ResultPath $resultPath -RequiredSuitesPath $requirementsPath } |
            Should -Throw -ExpectedMessage '*No required integration suites configured*'
    }
}
