#requires -modules @{ ModuleName = "Pester"; ModuleVersion = "6.2.0"; MaximumVersion = "6.999" }

BeforeDiscovery {
    . "$PSScriptRoot/../../Helpers/TestTools.ps1"

    $script:moduleToTest = Initialize-TestEnvironment
    $script:requestCommands = @(
        'Add-JiraFilterPermission'
        'Add-JiraGroupMember'
        'Add-JiraIssueAttachment'
        'Add-JiraIssueComment'
        'Add-JiraIssueLink'
        'Add-JiraIssueWatcher'
        'Add-JiraIssueWorklog'
        'Find-JiraFilter'
        'Get-JiraComponent'
        'Get-JiraField'
        'Get-JiraFilter'
        'Get-JiraFilterPermission'
        'Get-JiraGroup'
        'Get-JiraGroupMember'
        'Get-JiraIssue'
        'Get-JiraIssueAttachment'
        'Get-JiraIssueAttachmentFile'
        'Get-JiraIssueComment'
        'Get-JiraIssueCreateMetadata'
        'Get-JiraIssueEditMetadata'
        'Get-JiraIssueLink'
        'Get-JiraIssueLinkType'
        'Get-JiraIssueType'
        'Get-JiraIssueWatcher'
        'Get-JiraIssueWorklog'
        'Get-JiraPriority'
        'Get-JiraProject'
        'Get-JiraRemoteLink'
        'Get-JiraServerInformation'
        'Get-JiraStatus'
        'Get-JiraUser'
        'Get-JiraVersion'
        'Invoke-JiraIssueTransition'
        'Move-JiraVersion'
        'New-JiraFilter'
        'New-JiraGroup'
        'New-JiraIssue'
        'New-JiraUser'
        'New-JiraVersion'
        'Remove-JiraFilter'
        'Remove-JiraFilterPermission'
        'Remove-JiraGroup'
        'Remove-JiraGroupMember'
        'Remove-JiraIssue'
        'Remove-JiraIssueAttachment'
        'Remove-JiraIssueLink'
        'Remove-JiraIssueWatcher'
        'Remove-JiraRemoteLink'
        'Remove-JiraUser'
        'Remove-JiraVersion'
        'Set-JiraFilter'
        'Set-JiraIssue'
        'Set-JiraIssueLabel'
        'Set-JiraUser'
        'Set-JiraVersion'
    ) | ForEach-Object { @{ Name = $_ } }
}

Describe 'Jira request connection parameters' -Tag Unit {
    It 'keeps only connection and legacy credential inputs on <Name>' -ForEach $requestCommands {
        $command = Get-Command -Name $Name -Module JiraPS

        $command.Parameters['Connection'].ParameterType | Should -Be ([AtlassianPS.Connection])
        $command.Parameters['Connection'].Aliases | Should -Contain 'Session'
        $command.Parameters['Credential'].ParameterType | Should -Be ([PSCredential])

        foreach ($parameter in @('ConnectionName', 'Uri', 'ApiToken', 'PersonalAccessToken', 'Anonymous', 'AuthenticationEmailAddress')) {
            $command.Parameters.ContainsKey($parameter) | Should -BeFalse -Because "$Name uses a connection created by Connect-Jira"
        }

        if ($Name -notin @('New-JiraUser', 'Set-JiraUser')) {
            $command.Parameters.ContainsKey('EmailAddress') | Should -BeFalse
        }
    }

    It 'keeps the email user field on New-JiraUser and Set-JiraUser' {
        foreach ($name in @('New-JiraUser', 'Set-JiraUser')) {
            (Get-Command -Name $name -Module JiraPS).Parameters['EmailAddress'].ParameterType | Should -Be ([String])
        }
    }
}
