@{
    Suites = @(
        @{
            File   = 'Groups.Integration.Tests.ps1'
            Common = @(
                'Groups.Get-JiraGroup.Group Retrieval.retrieves a group by name'
                'Groups.Get-JiraGroup.Group Retrieval.returns group object with correct type'
                'Groups.Get-JiraGroup.Group Retrieval.includes group name'
                'Groups.Get-JiraGroup.Error Handling.fails for non-existent group'
                'Groups.Get-JiraGroupMember.Group Members.retrieves members of a group'
                'Groups.Get-JiraGroupMember.Group Members.returns user objects'
            )
            Cloud  = @(
                'Groups.Get-JiraGroup.Group Retrieval.exposes Id on Jira Cloud'
                'Groups.Get-JiraGroupMember.Group Members.retrieves members for a resolved group object on Jira Cloud'
            )
            Server = @(
                'Groups.Get-JiraGroupMember.Group Members.retrieves members for a resolved group object on Server'
            )
        }
    )
}
