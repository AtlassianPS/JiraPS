#requires -modules @{ ModuleName = "Pester"; ModuleVersion = "6.2.0"; MaximumVersion = "6.999" }

BeforeDiscovery {
    . "$PSScriptRoot/../../Helpers/TestTools.ps1"
    $script:moduleToTest = Initialize-TestEnvironment
}

InModuleScope JiraPS {
    Describe 'Save-JiraIssueAttachment file contract' -Tag Unit {
        BeforeEach {
            $script:attachment = [AtlassianPS.JiraPS.Attachment]@{ Id = '123'; FileName = 'report.txt'; Content = 'https://jira.example.com/secure/attachment/123/report.txt' }
            Mock Invoke-JiraRequest { [IO.File]::WriteAllBytes($OutFile, [byte[]]@(0, 1, 255)) }
        }

        It 'saves into an existing directory and returns FileInfo' {
            $result = $attachment | Save-JiraIssueAttachment -Path $TestDrive
            $result | Should -BeOfType ([IO.FileInfo])
            [IO.File]::ReadAllBytes($result.FullName) -join ',' | Should -Be '0,1,255'
        }

        It 'accepts an explicit destination file name' {
            $destination = Join-Path $TestDrive 'chosen-name.bin'
            $result = Save-JiraIssueAttachment -Attachment $attachment -Path $destination
            $result.FullName | Should -Be $destination
        }

        It 'requires Force to overwrite an existing file' {
            $destination = Join-Path $TestDrive 'existing.bin'
            [IO.File]::WriteAllText($destination, 'previous')
            { Save-JiraIssueAttachment -Attachment $attachment -Path $destination } | Should -Throw '*Use -Force*'
            [IO.File]::ReadAllText($destination) | Should -Be 'previous'
            Save-JiraIssueAttachment -Attachment $attachment -Path $destination -Force
            [IO.File]::ReadAllBytes($destination) -join ',' | Should -Be '0,1,255'
        }

        It 'does not write or download under WhatIf' {
            Save-JiraIssueAttachment -Attachment $attachment -Path (Join-Path $TestDrive 'whatif.bin') -WhatIf
            Should -Invoke Invoke-JiraRequest -Exactly 0
        }

        It 'rejects multiple attachments for one destination file' {
            { Save-JiraIssueAttachment -Attachment @($attachment, $attachment) -Path (Join-Path $TestDrive 'one.bin') } | Should -Throw '*directory destination*'
            Should -Invoke Invoke-JiraRequest -Exactly 0
        }

        It 'rejects server-provided path traversal names before downloading' {
            $attachment.FileName = '../escape.bin'
            { Save-JiraIssueAttachment -Attachment $attachment -Path $TestDrive } | Should -Throw '*path separators*'
            Should -Invoke Invoke-JiraRequest -Exactly 0
        }
    }
}
