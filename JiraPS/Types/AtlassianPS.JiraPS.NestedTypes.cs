using System;
using System.Collections.Generic;

namespace AtlassianPS.JiraPS
{
    public enum DeploymentType
    {
        Cloud,
        Server,
        DataCenter
    }

    public enum AccountType
    {
        atlassian,
        app,
        customer
    }

    public enum AssigneeType
    {
        PROJECT_DEFAULT,
        COMPONENT_LEAD,
        PROJECT_LEAD,
        UNASSIGNED
    }

    public enum FilterShareType
    {
        GLOBAL,
        LOGGEDIN,
        PROJECT,
        GROUP,
        ROLE,
        AUTHENTICATED,
        USER
    }

    public enum ActorType
    {
        AtlassianUserRoleActor,
        AtlassianGroupRoleActor
    }

    public class IssueHistoryEntry
    {
        public string Id { get; set; }
        public User Author { get; set; }
        public DateTimeOffset? Created { get; set; }
        public IssueHistoryItem[] Items { get; set; }

        public override string ToString()
        {
            return Id ?? string.Empty;
        }
    }

    public class IssueHistoryItem
    {
        public string Field { get; set; }
        public string FieldType { get; set; }
        public string FieldId { get; set; }
        public string From { get; set; }
        public string FromString { get; set; }
        public string To { get; set; }
        // Jira uses toString as a data field; preserve its wire name.
        public new string ToString { get; set; }
    }

    public class LinkApplication
    {
        public string Type { get; set; }
        public string Name { get; set; }
    }

    public class RemoteLinkObject
    {
        public Uri Url { get; set; }
        public string Title { get; set; }
        public string Summary { get; set; }
        public RemoteLinkIcon Icon { get; set; }
        public RemoteLinkStatus Status { get; set; }
    }

    public class RemoteLinkIcon
    {
        public Uri Url16x16 { get; set; }
        public string Title { get; set; }
        public Uri Link { get; set; }
    }

    public class RemoteLinkStatus
    {
        public bool? Resolved { get; set; }
        public RemoteLinkIcon Icon { get; set; }
    }

    public class Visibility
    {
        public string Type { get; set; }
        public string Value { get; set; }
        public string Identifier { get; set; }
    }

    public class EntityProperty
    {
        public string Key { get; set; }
        public object Value { get; set; }
    }

    public class ProjectCategory
    {
        public string Id { get; set; }
        public string Name { get; set; }
        public string Description { get; set; }
        public Uri RestUrl { get; set; }
    }

    public class RoleActor
    {
        public long? Id { get; set; }
        public string Name { get; set; }
        public string DisplayName { get; set; }
        public ActorType? Type { get; set; }
        public Uri AvatarUrl { get; set; }
        public User ActorUser { get; set; }
        public Group ActorGroup { get; set; }
    }

    public class FieldSchema
    {
        public string Type { get; set; }
        public string Items { get; set; }
        public string System { get; set; }
        public string Custom { get; set; }
        public long? CustomId { get; set; }
        public IDictionary<string, object> Configuration { get; set; }
    }

    public class IssueTypeScope
    {
        public string Type { get; set; }
        public Project Project { get; set; }
    }

    public class FilterSubscription
    {
        public long? Id { get; set; }
        public User User { get; set; }
        public Group Group { get; set; }
    }

    public class FilterSubscriptionList
    {
        public int? Size { get; set; }
        public int? MaxResults { get; set; }
        public int? StartIndex { get; set; }
        public int? EndIndex { get; set; }
        public FilterSubscription[] Items { get; set; }
    }

    public class UserList
    {
        public int? Size { get; set; }
        public int? MaxResults { get; set; }
        public int? StartIndex { get; set; }
        public int? EndIndex { get; set; }
        public User[] Items { get; set; }
    }

    public class ServerTimeZone
    {
        public string Id { get; set; }
        public string DisplayName { get; set; }
    }

    public class ServerLocale
    {
        public string Locale { get; set; }
    }

    public class IssueWatches
    {
        public Uri Self { get; set; }
        public long? WatchCount { get; set; }
        public bool? IsWatching { get; set; }
        public User[] Watchers { get; set; }
    }

    public class IssueVotes
    {
        public Uri Self { get; set; }
        public long? Votes { get; set; }
        public bool? HasVoted { get; set; }
        public User[] Voters { get; set; }
    }

    public class IssueProgress
    {
        public long? Progress { get; set; }
        public long? Total { get; set; }
        public long? Percent { get; set; }
    }

    public class IssueTimeTracking
    {
        public string OriginalEstimate { get; set; }
        public string RemainingEstimate { get; set; }
        public string TimeSpent { get; set; }
        public long? OriginalEstimateSeconds { get; set; }
        public long? RemainingEstimateSeconds { get; set; }
        public long? TimeSpentSeconds { get; set; }
    }

    public class IssueSecurityLevel
    {
        public string Id { get; set; }
        public string Name { get; set; }
        public string Description { get; set; }
        public Uri Self { get; set; }
    }

}
