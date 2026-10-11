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
        @{
            File   = 'Status.Integration.Tests.ps1'
            Common = @(
                'Status name encoding.retrieves a status whose name contains spaces'
            )
            Cloud  = @()
            Server = @()
        }
        @{
            File   = 'HttpErrors.Integration.Tests.ps1'
            Common = @(
                "HTTP Errors.preserves Jira's message for a missing issue"
                'HTTP Errors.captures a real empty HEAD error response'
                'HTTP Errors.reports the HTTP status for an empty HEAD error response'
                'HTTP Errors.emits a non-terminating HTTP error for an empty HEAD response'
            )
            Cloud  = @()
            Server = @()
        }
        @{
            File   = 'EnumContracts.Integration.Tests.ps1'
            Common = @(
                'Enum Contracts.converts a live user role actor'
                'Enum Contracts.converts a live group role actor'
                'Enum Contracts.converts a live project-role filter share'
            )
            Cloud  = @()
            Server = @()
        }
        @{
            File   = 'Visibility.Integration.Tests.ps1'
            Common = @(
                'Comment and worklog visibility.persists unrestricted comment for omitted visibility'
                'Comment and worklog visibility.persists unrestricted comment for All Users'
                'Comment and worklog visibility.persists unrestricted comment for VisibleRole alias'
                'Comment and worklog visibility.persists unrestricted comment for typed All Users role'
                'Comment and worklog visibility.persists unrestricted worklog for omitted visibility'
                'Comment and worklog visibility.persists unrestricted worklog for All Users'
                'Comment and worklog visibility.persists unrestricted worklog for VisibleRole alias'
                'Comment and worklog visibility.persists unrestricted worklog for typed All Users role'
                'Comment and worklog visibility.persists a role restriction on a comment'
                'Comment and worklog visibility.persists a group restriction on a comment'
                'Comment and worklog visibility.persists a role restriction on a worklog'
                'Comment and worklog visibility.persists a group restriction on a worklog'
            )
            Cloud  = @(
                'Comment and worklog visibility.persists a Cloud group identifier restriction on a comment'
                'Comment and worklog visibility.persists a Cloud group identifier restriction on a worklog'
            )
            Server = @()
        }
    )
}
