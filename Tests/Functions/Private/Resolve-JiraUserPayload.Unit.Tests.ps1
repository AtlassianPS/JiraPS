#requires -modules @{ ModuleName = "Pester"; ModuleVersion = "5.7"; MaximumVersion = "5.999" }

BeforeDiscovery {
    . "$PSScriptRoot/../../Helpers/TestTools.ps1"

    $script:moduleToTest = Initialize-TestEnvironment
}

InModuleScope JiraPS {
    Describe "Resolve-JiraUserPayload" -Tag 'Unit' {

        BeforeAll {
            $script:serverUser = [PSCustomObject]@{ Name = 'alice' }
            $script:cloudUser = [PSCustomObject]@{ Name = 'alice'; AccountId = '5b10a2844c20165700ede21a' }
        }

        Context "Jira Cloud" {
            It "returns accountId when a Cloud user is provided" {
                $result = Resolve-JiraUserPayload -UserObject $cloudUser -IsCloud $true
                $result.Keys | Should -HaveCount 1
                $result.accountId | Should -Be '5b10a2844c20165700ede21a'
            }

            It "returns accountId:`$null when unassigning (no user)" {
                $result = Resolve-JiraUserPayload -UserObject $null -IsCloud $true
                $result.Keys | Should -HaveCount 1
                $result.ContainsKey('accountId') | Should -BeTrue
                $result.accountId | Should -BeNullOrEmpty
            }

            It "returns accountId:`$null even when a default ('-1') string is passed" {
                # Cloud does not support the project-default mechanic via 'name: -1';
                # falling through to accountId:null is the safe, predictable behavior.
                $result = Resolve-JiraUserPayload -UserObject $null -UserString '-1' -IsCloud $true
                $result.ContainsKey('accountId') | Should -BeTrue
                $result.accountId | Should -BeNullOrEmpty
            }

            It "ignores UserString when a user is provided on Cloud" {
                $result = Resolve-JiraUserPayload -UserObject $cloudUser -UserString 'should-be-ignored' -IsCloud $true
                $result.accountId | Should -Be '5b10a2844c20165700ede21a'
                $result.ContainsKey('name') | Should -BeFalse
            }

            It "throws when the Cloud user object has a `$null AccountId" {
                # Guard against silent unassign caused by a partial / mis-resolved
                # user object — the caller's intent here is to point at a user, not clear.
                $brokenUser = [PSCustomObject]@{ Name = 'alice'; AccountId = $null }
                { Resolve-JiraUserPayload -UserObject $brokenUser -IsCloud $true } |
                    Should -Throw -ExpectedMessage "*no AccountId*"
            }

            It "throws when the Cloud user object has an empty AccountId" {
                $brokenUser = [PSCustomObject]@{ Name = 'alice'; AccountId = '' }
                { Resolve-JiraUserPayload -UserObject $brokenUser -IsCloud $true } |
                    Should -Throw -ExpectedMessage "*no AccountId*"
            }
        }

        Context "Jira Server / Data Center" {
            It "returns the user's Name when a user is provided" {
                $result = Resolve-JiraUserPayload -UserObject $serverUser -IsCloud $false
                $result.Keys | Should -HaveCount 1
                $result.name | Should -Be 'alice'
            }

            It "returns name:`$null when unassigning with `$null UserString" {
                $result = Resolve-JiraUserPayload -UserObject $null -UserString $null -IsCloud $false
                $result.ContainsKey('name') | Should -BeTrue
                $result.name | Should -BeNullOrEmpty
            }

            It "returns name:'' when unassigning with empty UserString" {
                # Distinct from $null so callers can opt into either JSON shape.
                $result = Resolve-JiraUserPayload -UserObject $null -UserString '' -IsCloud $false
                $result.ContainsKey('name') | Should -BeTrue
                $result.name | Should -Be ''
            }

            It "returns name:'-1' when requesting the project default" {
                $result = Resolve-JiraUserPayload -UserObject $null -UserString '-1' -IsCloud $false
                $result.name | Should -Be '-1'
            }

            It "prefers the user object over UserString when both are provided" {
                $result = Resolve-JiraUserPayload -UserObject $serverUser -UserString '-1' -IsCloud $false
                $result.name | Should -Be 'alice'
            }
        }
    }
}
