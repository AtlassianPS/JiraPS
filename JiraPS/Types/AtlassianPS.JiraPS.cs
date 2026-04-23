// Strongly-typed POCOs for the JiraPS module's most-used domain types.
// Loaded once at module import via Add-Type from JiraPS.psm1 (#region Dependencies).
//
// Slots typed `object` are intentional — they hold polymorphic values
// (e.g. Issue.Assignee is a User OR the string "Unassigned"), pass through
// opaque API payloads (avatar URL maps, role dictionaries, ADF Visibility),
// or — in Session.WebSession — avoid forcing a reference to
// Microsoft.PowerShell.Commands.Utility.dll, whose path differs across
// PowerShell editions.

using System;
using System.Collections.Generic;

namespace AtlassianPS.JiraPS
{
    public class User
    {
        public string Key { get; set; }
        public string AccountId { get; set; }
        public string Name { get; set; }
        public string DisplayName { get; set; }
        public string EmailAddress { get; set; }
        public bool Active { get; set; }
        public object AvatarUrl { get; set; }
        public string TimeZone { get; set; }
        public string Locale { get; set; }
        public string[] Groups { get; set; }
        public string RestUrl { get; set; }

        public override string ToString()
        {
            if (!string.IsNullOrEmpty(Name)) { return Name; }
            if (!string.IsNullOrEmpty(DisplayName)) { return DisplayName; }
            if (!string.IsNullOrEmpty(AccountId)) { return AccountId; }
            return string.Empty;
        }
    }

    public class Project
    {
        public string ID { get; set; }
        public string Key { get; set; }
        public string Name { get; set; }
        public string Description { get; set; }
        public User Lead { get; set; }
        public object IssueTypes { get; set; }
        public object Roles { get; set; }
        public string RestUrl { get; set; }
        public object Components { get; set; }
        public string Style { get; set; }
        public object Category { get; set; }

        public override string ToString()
        {
            return Name ?? string.Empty;
        }
    }

    public class Comment
    {
        public string ID { get; set; }
        public string Body { get; set; }
        public object Visibility { get; set; }
        public string RestUrl { get; set; }
        public User Author { get; set; }
        public User UpdateAuthor { get; set; }
        public DateTime? Created { get; set; }
        public DateTime? Updated { get; set; }

        public override string ToString()
        {
            return Body ?? string.Empty;
        }
    }

    public class Issue
    {
        public string ID { get; set; }
        public string Key { get; set; }
        public string HttpUrl { get; set; }
        public string RestUrl { get; set; }
        public string Summary { get; set; }
        public string Description { get; set; }
        public string Status { get; set; }
        public object IssueLinks { get; set; }
        public object Attachment { get; set; }
        public Project Project { get; set; }
        // Assignee may be a User instance OR the legacy string "Unassigned".
        public object Assignee { get; set; }
        public User Creator { get; set; }
        public User Reporter { get; set; }
        public DateTime? Created { get; set; }
        public DateTime? LastViewed { get; set; }
        public DateTime? Updated { get; set; }
        public object Fields { get; set; }
        public object Expand { get; set; }
        public object Transition { get; set; }
        public Comment[] Comment { get; set; }

        public override string ToString()
        {
            return string.Format("[{0}] {1}", Key, Summary);
        }
    }

    public class Version
    {
        public string ID { get; set; }
        // Wire field is `projectId` (a long); kept under the legacy `Project`
        // name for backward compatibility with v2 scripts.
        public long? Project { get; set; }
        public string Name { get; set; }
        public string Description { get; set; }
        public bool Archived { get; set; }
        public bool Released { get; set; }
        public bool Overdue { get; set; }
        public string RestUrl { get; set; }
        public DateTime? StartDate { get; set; }
        public DateTime? ReleaseDate { get; set; }

        public override string ToString()
        {
            return Name ?? string.Empty;
        }
    }

    public class Filter
    {
        public string ID { get; set; }
        public string Name { get; set; }
        public string JQL { get; set; }
        public string RestUrl { get; set; }
        public string ViewUrl { get; set; }
        public string SearchUrl { get; set; }
        public bool Favourite { get; set; }
        public object FilterPermissions { get; set; }
        public object SharePermission { get; set; }
        public object SharedUser { get; set; }
        public object Subscription { get; set; }
        public string Description { get; set; }
        public User Owner { get; set; }

        // The PowerShell-side AliasProperty for the American spelling (`Favorite`)
        // is added by ConvertTo-JiraFilter so historical assertions about the
        // member type continue to hold.

        public override string ToString()
        {
            return Name ?? string.Empty;
        }
    }

    public class Session
    {
        // Runtime type is Microsoft.PowerShell.Commands.WebRequestSession.
        public object WebSession { get; set; }
        public string Username { get; set; }
        public string JSessionID { get; set; }

        public override string ToString()
        {
            return string.Format("JiraSession[JSessionID={0}]", JSessionID);
        }
    }

    public class ServerInfo
    {
        public string BaseURL { get; set; }
        public string Version { get; set; }
        public string DeploymentType { get; set; }
        public long? BuildNumber { get; set; }
        public DateTime? BuildDate { get; set; }
        public DateTime? ServerTime { get; set; }
        public string ScmInfo { get; set; }
        public string ServerTitle { get; set; }

        public override string ToString()
        {
            return string.Format("[{0}] {1}", DeploymentType, Version);
        }
    }
}
