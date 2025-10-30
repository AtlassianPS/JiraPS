#requires -modules BuildHelpers
#requires -modules @{ ModuleName = "Pester"; ModuleVersion = "5.7.1" }

Describe "New-JiraIssue" -Tag 'Unit' {

    BeforeAll {
        Remove-Item -Path Env:\BH*
        $projectRoot = (Resolve-Path "$PSScriptRoot/../..").Path
        if ($projectRoot -like "*Release") {
            $projectRoot = (Resolve-Path "$projectRoot/..").Path
        }

        Import-Module BuildHelpers
        Set-BuildEnvironment -BuildOutput '$ProjectPath/Release' -Path $projectRoot -ErrorAction SilentlyContinue

        $env:BHManifestToTest = $env:BHPSModuleManifest
        $script:isBuild = $PSScriptRoot -like "$env:BHBuildOutput*"
        if ($script:isBuild) {
            $Pattern = [regex]::Escape($env:BHProjectPath)

            $env:BHBuildModuleManifest = $env:BHPSModuleManifest -replace $Pattern, $env:BHBuildOutput
            $env:BHManifestToTest = $env:BHBuildModuleManifest
        }

        Import-Module "$env:BHProjectPath/Tools/BuildTools.psm1"

        Remove-Module $env:BHProjectName -ErrorAction SilentlyContinue
        Import-Module $env:BHManifestToTest

        . "$PSScriptRoot/../Shared.ps1"  # helpers used by tests (defParam / ShowMockInfo)

        $jiraServer = 'https://jira.example.com'
        $issueTypeTest = 1

        Mock Get-JiraConfigServer -ModuleName JiraPS {
            $jiraServer
        }

        # If we don't override this in a context or test, we don't want it to
        # actually try to query a JIRA instance
        Mock Invoke-JiraMethod -ModuleName JiraPS {
            ShowMockInfo 'Invoke-JiraMethod' 'Method', 'Uri'
            @{ Key = "TEST-01" }
        }

        Mock Get-JiraIssue -ModuleName JiraPS {
            [PSCustomObject] @{ Key = "TEST-01" }
        }

        Mock Get-JiraProject -ModuleName JiraPS {
            $issueObject = [PSCustomObject] @{
                ID   = $issueTypeTest
                Name = 'Test Issue Type'
            }
            $issueObject.PSObject.TypeNames.Insert(0, 'JiraPS.IssueType')
            $object = [PSCustomObject] @{
                'ID'  = $Project
                'Key' = "TEST"
            }
            Add-Member -InputObject $object -MemberType NoteProperty -Name "IssueTypes" -Value $issueObject
            $object.PSObject.TypeNames.Insert(0, 'JiraPS.Project')
            return $object
        }

        Mock Get-JiraUser -ModuleName JiraPS {
            $object = [PSCustomObject] @{
                'Name' = $UserName;
            }
            $object.PSObject.TypeNames.Insert(0, 'JiraPS.User')
            return $object
        }

        # This one needs to be able to output multiple objects
        Mock Get-JiraField -ModuleName JiraPS {

            (If ($null -eq $Field) {
                @(
                    'Project'
                    'IssueType'
                    'Priority'
                    'Summary'
                    'Description'
                    'Reporter'
                    'CustomField'
                )
            } Else {
                $Field
            }) | ForEach-Object {
                $object = [PSCustomObject] @{
                    'Id' = $_
                }
                $object.PSObject.TypeNames.Insert(0, 'JiraPS.Field')
                $object
            }
        }

        Mock Get-JiraIssueCreateMetadata -ModuleName JiraPS {
            @(
                @{Name = 'Project'; ID = 'Project'; Required = $true }
                @{Name = 'IssueType'; ID = 'IssueType'; Required = $true }
                @{Name = 'Priority'; ID = 'Priority'; Required = $true }
                @{Name = 'Summary'; ID = 'Summary'; Required = $true }
                @{Name = 'Description'; ID = 'Description'; Required = $true }
                @{Name = 'Reporter'; ID = 'Reporter'; Required = $true }
            )
        }

        $newParams = @{
            'Project'     = 'TEST';
            'IssueType'   = 1;
            'Priority'    = 1;
            'Reporter'    = 'testUsername';
            'Summary'     = 'Test summary';
            'Description' = 'Test description';
        }

        $pipelineParams = New-Object -TypeName PSCustomObject -Property $newParams
    }

    Context "Sanity checking" {
        It "Has expected parameters" {
            $command = Get-Command -Name New-JiraIssue

            defParam $command 'Project'
            defParam $command 'IssueType'
            defParam $command 'Priority'
            defParam $command 'Summary'
            defParam $command 'Description'
            defParam $command 'Reporter'
            defParam $command 'Label'
            defParam $command 'Fields'
            defParam $command 'Credential'
        }
    }

    Context "Behavior testing" {
        It "Creates an issue in JIRA" {
            { New-JiraIssue @newParams } | Should -Not -Throw
            # The String in the ParameterFilter is made from the keywords
            # we should expect to see in the JSON that should be sent,
            # including the summary provided in the test call above.
            Should -Invoke 'Invoke-JiraMethod' -ModuleName JiraPS -Exactly -Times 1 -ParameterFilter { $Method -eq 'Post' -and $URI -like "$jiraServer/rest/api/*/issue" }
        }

        It "Creates an issue in JIRA from pipeline" {
            { $pipelineParams | New-JiraIssue } | Should -Not -Throw
            # The String in the ParameterFilter is made from the keywords
            # we should expect to see in the JSON that should be sent,
            # including the summary provided in the test call above.
            Should -Invoke 'Invoke-JiraMethod' -ModuleName JiraPS -Exactly -Times 1 -ParameterFilter { $Method -eq 'Post' -and $URI -like "$jiraServer/rest/api/*/issue" }
        }
    }

    Context "New-JiraIssue handles duplicate fields" {
        BeforeAll {
            # Intentionally output multiple objects of different IDs but with the same name
            Mock Get-JiraField -ModuleName JiraPS {
                $Field | ForEach-Object {
                    $name = $_
                    if ($name -eq 'Reporter') {
                        'Reporter', 'Reporter_mismatched' | ForEach-Object {
                            $fieldname = $_
                            $object = [PSCustomObject] @{
                                'Id' = "$fieldname"
                            }
                            $object.PSObject.TypeNames.Insert(0, 'JiraPS.Field')
                            $object
                        }
                    }
                    else {
                        $object = [PSCustomObject] @{
                            'Id' = "$name"
                        }
                        $object.PSObject.TypeNames.Insert(0, 'JiraPS.Field')
                        $object
                    }
                }
            }
        }

        It "finds the right field which has a matching name and id" {
            Mock Get-JiraIssueCreateMetadata -ModuleName JiraPS {
                @(
                    @{Name = 'Project'; ID = 'Project'; Required = $true }
                    @{Name = 'IssueType'; ID = 'IssueType'; Required = $true }
                    @{Name = 'Priority'; ID = 'Priority'; Required = $true }
                    @{Name = 'Summary'; ID = 'Summary'; Required = $true }
                    @{Name = 'Description'; ID = 'Description'; Required = $true }
                    @{Name = 'Reporter'; ID = 'Reporter'; Required = $true }
                    @{Name = 'Reporter'; ID = 'Reporter_mismatch'; Required = $false }
                )
            }

            { New-JiraIssue @newParams } | Should -Not -Throw
        }

        It "throws when a field name return multiple fields without a field has matching name and id" {
            Mock Get-JiraIssueCreateMetadata -ModuleName JiraPS {
                @(
                    @{Name = 'Project'; ID = 'Project'; Required = $true }
                    @{Name = 'IssueType'; ID = 'IssueType'; Required = $true }
                    @{Name = 'Priority'; ID = 'Priority'; Required = $true }
                    @{Name = 'Summary'; ID = 'Summary'; Required = $true }
                    @{Name = 'Description'; ID = 'Description'; Required = $true }
                    @{Name = 'Reporter'; ID = 'Reporter_mismatch1'; Required = $true }
                    @{Name = 'Reporter'; ID = 'Reporter_mismatch2'; Required = $false }
                )
            }

            { New-JiraIssue @newParams } | Should -Throw
        }
    }

    Context "Input testing" {
        It "Checks to make sure all required fields are provided" {
            # We'll create a custom field that's required, then see what happens when we don't provide it
            Mock Get-JiraIssueCreateMetadata -ModuleName JiraPS {
                @(
                    @{Name = 'Project'; ID = 'Project'; Required = $true }
                    @{Name = 'IssueType'; ID = 'IssueType'; Required = $true }
                    @{Name = 'Priority'; ID = 'Priority'; Required = $true }
                    @{Name = 'Summary'; ID = 'Summary'; Required = $true }
                    @{Name = 'Description'; ID = 'Description'; Required = $true }
                    @{Name = 'Reporter'; ID = 'Reporter'; Required = $true }
                    @{Name = 'CustomField'; ID = 'CustomField'; Required = $true }
                )
            }

            { New-JiraIssue @newParams } | Should -Throw
            { New-JiraIssue @newParams -Fields @{'CustomField' = '.' } } | Should -Not -Throw
        }
    }

    AfterAll {
        Remove-Module $env:BHProjectName -ErrorAction SilentlyContinue
        Remove-Module BuildHelpers -ErrorAction SilentlyContinue
        Remove-Item -Path Env:\BH*
    }
}
