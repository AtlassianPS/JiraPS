#requires -modules @{ ModuleName = "Pester"; ModuleVersion = "5.7"; MaximumVersion = "5.999" }

BeforeDiscovery {
    . "$PSScriptRoot/../../Helpers/TestTools.ps1"

    $script:moduleToTest = Initialize-TestEnvironment
}

InModuleScope JiraPS {
    Describe "New-JiraIssueLinkRequest" -Tag 'Unit' {
        Describe "Signature" {
            BeforeAll {
                $script:command = Get-Command -Name "New-JiraIssueLinkRequest"
            }

            Context "Parameter Types" {
                It "has a parameter '<parameter>' of type '<type>'" -TestCases @(
                    @{ parameter = "LinkType"; type = "AtlassianPS.JiraPS.IssueLinkType" }
                    @{ parameter = "FromIssue"; type = "AtlassianPS.JiraPS.Issue" }
                    @{ parameter = "ToIssue"; type = "AtlassianPS.JiraPS.Issue" }
                ) {
                    $command | Should -HaveParameter $parameter -Type $type
                }
            }

            Context "Aliases" {
                It "supports alias '<alias>' for parameter '<parameter>'" -TestCases @(
                    @{ parameter = "LinkType"; alias = "Type" }
                    @{ parameter = "FromIssue"; alias = "InwardIssue" }
                    @{ parameter = "ToIssue"; alias = "OutwardIssue" }
                ) {
                    $command.Parameters[$parameter].Aliases | Should -Contain $alias
                }
            }

            Context "Mandatory Parameters" {
                It "parameter '<parameter>' is mandatory" -TestCases @(
                    @{ parameter = "LinkType" }
                    @{ parameter = "FromIssue" }
                    @{ parameter = "ToIssue" }
                ) {
                    $command | Should -HaveParameter $parameter -Mandatory
                }
            }
        }

        Describe "Behavior" {
            It "returns a typed issue-link create request" {
                $result = New-JiraIssueLinkRequest -LinkType "Blocks" -FromIssue "TEST-01" -ToIssue "TEST-02"

                $result | Should -BeOfType "AtlassianPS.JiraPS.IssueLinkCreateRequest"
                $result.Type.Name | Should -Be "Blocks"
                $result.InwardIssue.Key | Should -Be "TEST-01"
                $result.OutwardIssue.Key | Should -Be "TEST-02"
            }

            It "supports id-based refs for type and issue refs" {
                $type = [AtlassianPS.JiraPS.IssueLinkType]@{ Id = "10000" }
                $from = [AtlassianPS.JiraPS.Issue]@{ Id = "10001" }
                $to = [AtlassianPS.JiraPS.Issue]@{ Id = "10002" }

                $result = New-JiraIssueLinkRequest -LinkType $type -FromIssue $from -ToIssue $to

                $result.Type.Id | Should -Be "10000"
                $result.InwardIssue.Id | Should -Be "10001"
                $result.OutwardIssue.Id | Should -Be "10002"
            }
        }
    }
}
