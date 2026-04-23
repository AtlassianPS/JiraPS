// Strongly-typed POCOs for the JiraPS module's most-used domain types.
//
// Loaded once at module import via Add-Type from JiraPS.psm1 (#region Dependencies).
//
// Design notes:
//   * Properties whose values can legitimately be either a strong type *or* a
//     legacy sentinel (e.g. Issue.Assignee may be a User OR the literal string
//     "Unassigned") are typed as `object` to preserve backward compatibility.
//   * Properties that pass through raw API payloads (custom fields, ADF bodies,
//     avatar URL maps) are typed as `object` for the same reason.
//   * `WebSession` on Session is `object` so this assembly does not have to
//     reference Microsoft.PowerShell.Commands.Utility.dll, which lives in
//     different paths on Desktop vs Core.
//   * Date columns that can be missing in the API stay nullable (`DateTime?`).
//   * Issue keeps `Project`, `Comment[]` strong-typed; arbitrary custom fields
//     and ADF descriptions are attached as PSObject NoteProperties from the
//     converter, not modelled here.

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
        public object Groups { get; set; }
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
        // Lead's runtime value is an AtlassianPS.JiraPS.User produced by
        // ConvertTo-JiraUser, but the slot is typed as `object` so the
        // hashtable-cast `[Project]@{ Lead = ConvertTo-JiraUser $x }` does
        // not have to unwrap a PSObject (which silently works on PS7 but
        // throws PSInvalidCastException on Windows PowerShell 5.1 once
        // Add-LegacyTypeAlias has touched the value's PSObject.TypeNames).
        public object Lead { get; set; }
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
        public object Body { get; set; }
        public object Visibility { get; set; }
        public string RestUrl { get; set; }
        // Author / UpdateAuthor are AtlassianPS.JiraPS.User at runtime; see the
        // note on Project.Lead for why the storage slot is `object`.
        public object Author { get; set; }
        public object UpdateAuthor { get; set; }
        public DateTime? Created { get; set; }
        public DateTime? Updated { get; set; }

        public override string ToString()
        {
            return Body == null ? string.Empty : Body.ToString();
        }
    }

    public class Issue
    {
        public string ID { get; set; }
        public string Key { get; set; }
        public string HttpUrl { get; set; }
        public string RestUrl { get; set; }
        public string Summary { get; set; }
        public object Description { get; set; }
        public string Status { get; set; }
        public object IssueLinks { get; set; }
        public object Attachment { get; set; }
        // Project's runtime value is AtlassianPS.JiraPS.Project; the slot is
        // `object` for the same PS5.1 hashtable-cast reason as Project.Lead.
        public object Project { get; set; }
        // Assignee may be a User instance OR the legacy string "Unassigned".
        public object Assignee { get; set; }
        public object Creator { get; set; }
        public object Reporter { get; set; }
        public DateTime? Created { get; set; }
        public DateTime? LastViewed { get; set; }
        public DateTime? Updated { get; set; }
        public object Fields { get; set; }
        public object Expand { get; set; }
        public object Transition { get; set; }
        public object Comment { get; set; }

        public override string ToString()
        {
            return string.Format("[{0}] {1}", Key, Summary);
        }
    }

    public class Version
    {
        public string ID { get; set; }
        // Project here is the source projectId from the wire payload (numeric or
        // string), not a Project instance. Typed as object to preserve.
        public object Project { get; set; }
        public string Name { get; set; }
        public string Description { get; set; }
        public object Archived { get; set; }
        public object Released { get; set; }
        public object Overdue { get; set; }
        public string RestUrl { get; set; }
        // StartDate / ReleaseDate are DateTime when set, empty string when not
        // (legacy converter behavior). Typed as object to preserve.
        public object StartDate { get; set; }
        public object ReleaseDate { get; set; }

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
        public object Favourite { get; set; }
        public object FilterPermissions { get; set; }
        public object SharePermission { get; set; }
        public object SharedUser { get; set; }
        public object Subscription { get; set; }
        public string Description { get; set; }
        // Owner is AtlassianPS.JiraPS.User at runtime; see the note on
        // Project.Lead for why the storage slot is `object`.
        public object Owner { get; set; }

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
        // Typed as object so this assembly does not need to reference
        // Microsoft.PowerShell.Commands.Utility (whose path differs across editions).
        // The runtime value is a Microsoft.PowerShell.Commands.WebRequestSession.
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
        public object BuildNumber { get; set; }
        public DateTime? BuildDate { get; set; }
        public DateTime? ServerTime { get; set; }
        public object ScmInfo { get; set; }
        public string ServerTitle { get; set; }

        public override string ToString()
        {
            return string.Format("[{0}] {1}", DeploymentType, Version);
        }
    }
}
