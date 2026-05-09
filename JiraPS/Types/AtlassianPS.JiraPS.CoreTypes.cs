// Core Jira domain objects: Issue, Project, User, Version, Filter, Group, etc.
// These are the primary types exchanged between PowerShell cmdlets and the REST API.

using System;
using System.Collections.Generic;

namespace AtlassianPS.JiraPS
{
    // Slots typed `object` are intentional: they hold polymorphic values, opaque API payloads,
    // or runtime-specific objects whose concrete types differ across PowerShell editions.
    //
    // Id storage type convention:
    //   string — when the PowerShell converters (ConvertTo-Jira*) and existing scripts
    //            historically treated the Id as a string (e.g. $issue.Id was always a
    //            string in v2). Keeps backward compat with user scripts that concatenate
    //            or compare without casting.
    //   long?  — when the Id is exclusively numeric on the wire AND no v2 script
    //            compatibility constraint exists (e.g. leaf types introduced in v3).
    //   Both forms are valid Jira IDs; prefer string for new core types unless there
    //   is a compelling numeric-comparison need.

    public class User : JiraIdentityObject<User>
    {
        public string Key { get; set; }
        public string AccountId { get; set; }
        // Cloud-only field documented in REST v3: 'atlassian', 'app', 'customer', 'unknown'.
        public string AccountType { get; set; }
        public string Name { get; set; }
        public string DisplayName { get; set; }
        public string EmailAddress { get; set; }
        public bool Active { get; set; }
        // DC-only "right-to-be-forgotten" flag; nullable so callers can tell
        // "field missing" (legacy instances) apart from "explicitly false".
        public bool? Deleted { get; set; }
        public object AvatarUrl { get; set; }
        public string TimeZone { get; set; }
        public string Locale { get; set; }
        public string[] Groups { get; set; }
        public DateTime? LastLoginTime { get; set; }
        public Uri RestUrl { get; set; }

        public User() { }

        public User(string identifier)
        {
            if (string.IsNullOrWhiteSpace(identifier))
            {
                throw new ArgumentException("identifier must not be null, empty, or whitespace.", "identifier");
            }
            Name = identifier;
        }

        protected override string GetIdentity()
        {
            if (!string.IsNullOrEmpty(AccountId)) { return AccountId; }
            if (!string.IsNullOrEmpty(Name)) { return Name; }
            return string.Empty;
        }

        public override string ToString()
        {
            if (!string.IsNullOrEmpty(Name)) { return Name; }
            if (!string.IsNullOrEmpty(DisplayName)) { return DisplayName; }
            if (!string.IsNullOrEmpty(AccountId)) { return AccountId; }
            return string.Empty;
        }
    }

    public class Project : JiraIdentityObject<Project>
    {
        public string Id { get; set; }
        public string Key { get; set; }
        public string Name { get; set; }
        public string Description { get; set; }
        public User Lead { get; set; }
        public IssueType[] IssueTypes { get; set; }
        public object Roles { get; set; }
        public Uri RestUrl { get; set; }
        public Component[] Components { get; set; }
        public string Style { get; set; }
        public object Category { get; set; }
        // Both platforms: 'software', 'business', 'service_desk', 'product_discovery'.
        public string ProjectTypeKey { get; set; }
        public Uri Url { get; set; }
        public string Email { get; set; }
        // Optional flags returned only by newer instances; nullable so callers
        // can tell "field absent" apart from "explicitly false".
        public bool? Archived { get; set; }
        public bool? Simplified { get; set; }
        public bool? IsPrivate { get; set; }

        public Project() { }

        public Project(string key)
        {
            if (string.IsNullOrWhiteSpace(key))
            {
                throw new ArgumentException("key must not be null, empty, or whitespace.", "key");
            }
            Key = key;
        }

        protected override string GetIdentity()
        {
            return Key ?? string.Empty;
        }

        public override string ToString()
        {
            return Name ?? string.Empty;
        }
    }

    public class Comment
    {
        public string Id { get; set; }
        public string Body { get; set; }
        // Server-side rendered HTML body; only populated when the request
        // included expand=renderedBody (DC v2; not available on Cloud v3).
        public string RenderedBody { get; set; }
        public object Visibility { get; set; }
        // Cloud-only entity-properties array (each item is { key, value }).
        public object[] Properties { get; set; }
        public Uri RestUrl { get; set; }
        public User Author { get; set; }
        public User UpdateAuthor { get; set; }
        public DateTimeOffset? Created { get; set; }
        public DateTimeOffset? Updated { get; set; }

        public Comment() { }

        public override string ToString()
        {
            return Body ?? string.Empty;
        }
    }

    public class Issue : JiraIdentityObject<Issue>
    {
        public string Id { get; set; }
        public string Key { get; set; }
        public Uri HttpUrl { get; set; }
        public Uri RestUrl { get; set; }
        public string Summary { get; set; }
        public string Description { get; set; }
        public Status Status { get; set; }
        public IssueLink[] IssueLinks { get; set; }
        public Attachment[] Attachment { get; set; }
        public Project Project { get; set; }
        // Assignee may be a User instance OR the legacy string "Unassigned".
        public object Assignee { get; set; }
        public User Creator { get; set; }
        public User Reporter { get; set; }
        public DateTimeOffset? Created { get; set; }
        public DateTimeOffset? LastViewed { get; set; }
        public DateTimeOffset? Updated { get; set; }
        public IDictionary<string, object> Fields { get; set; }
        public object Expand { get; set; }
        public Transition[] Transition { get; set; }
        public Comment[] Comment { get; set; }

        public Issue() { }

        public Issue(string key)
        {
            if (string.IsNullOrWhiteSpace(key))
            {
                throw new ArgumentException("key must not be null, empty, or whitespace.", "key");
            }
            Key = key;
        }

        protected override string GetIdentity()
        {
            return Key ?? string.Empty;
        }

        public override string ToString()
        {
            return string.Format("[{0}] {1}", Key, Summary);
        }
    }

    public class Version : JiraIdentityObject<Version>
    {
        public string Id { get; set; }
        // Wire field is `projectId` (a long); kept under the legacy `Project`
        // name for backward compatibility with v2 scripts.
        public long? Project { get; set; }
        public string Name { get; set; }
        public string Description { get; set; }
        public bool Archived { get; set; }
        public bool Released { get; set; }
        public bool Overdue { get; set; }
        public Uri RestUrl { get; set; }
        public DateTime? StartDate { get; set; }
        public DateTime? ReleaseDate { get; set; }

        public Version() { }

        public Version(string nameOrId)
        {
            if (string.IsNullOrWhiteSpace(nameOrId))
            {
                throw new ArgumentException("nameOrId must not be null, empty, or whitespace.", "nameOrId");
            }
            long parsed;
            if (long.TryParse(nameOrId, System.Globalization.NumberStyles.Integer, System.Globalization.CultureInfo.InvariantCulture, out parsed))
            {
                Id = parsed.ToString(System.Globalization.CultureInfo.InvariantCulture);
            }
            else
            {
                Name = nameOrId;
            }
        }

        protected override string GetIdentity()
        {
            if (!string.IsNullOrEmpty(Id)) { return Id; }
            if (!string.IsNullOrEmpty(Name)) { return Name; }
            return string.Empty;
        }

        public override string ToString()
        {
            return Name ?? string.Empty;
        }
    }

    public class Filter : JiraIdentityObject<Filter>
    {
        public string Id { get; set; }
        public string Name { get; set; }
        public string JQL { get; set; }
        public Uri RestUrl { get; set; }
        public Uri ViewUrl { get; set; }
        public Uri SearchUrl { get; set; }
        public bool Favourite { get; set; }
        public FilterPermission[] FilterPermissions { get; set; }
        public object SharePermission { get; set; }
        public object SharedUser { get; set; }
        public object Subscription { get; set; }
        public string Description { get; set; }
        public User Owner { get; set; }

        public Filter() { }

        public Filter(string id)
        {
            if (string.IsNullOrWhiteSpace(id))
            {
                throw new ArgumentException("id must not be null, empty, or whitespace.", "id");
            }
            Id = id;
        }

        protected override string GetIdentity()
        {
            return Id ?? string.Empty;
        }

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

        public Session() { }

        public override string ToString()
        {
            if (string.IsNullOrEmpty(JSessionID)) { return "JiraSession"; }
            return string.Format("JiraSession[JSessionID={0}]", JSessionID);
        }
    }

    public class ServerInfo
    {
        public Uri BaseURL { get; set; }
        public string Version { get; set; }
        // Both platforms expose this as e.g. [9, 17, 0]; surfaced separately
        // from the Version string so callers can compare numerically.
        public int[] VersionNumbers { get; set; }
        public string DeploymentType { get; set; }
        public long? BuildNumber { get; set; }
        public DateTimeOffset? BuildDate { get; set; }
        public DateTimeOffset? ServerTime { get; set; }
        public string ScmInfo { get; set; }
        public string ServerTitle { get; set; }
        // DC-only display URL (the canonical externally-visible base URL,
        // which can differ from BaseURL behind a reverse proxy).
        public Uri DisplayUrl { get; set; }
        // DC-only co-located product display URLs; null on Cloud and on DC
        // instances that are not paired with Confluence / Service Desk.
        public Uri DisplayUrlConfluence { get; set; }
        public Uri DisplayUrlServicedeskHelpCenter { get; set; }
        // DC-only OEM partner attribution (e.g. "Marketplace App Vendor").
        public string BuildPartnerName { get; set; }
        // DC-only complex shapes: { id, displayName } and { locale }.
        // Kept as object so this assembly does not have to model side-band
        // helper structs that no other class consumes.
        public object ServerTimeZone { get; set; }
        public object DefaultLocale { get; set; }

        public ServerInfo() { }

        public override string ToString()
        {
            if (!string.IsNullOrEmpty(DeploymentType) && !string.IsNullOrEmpty(Version))
            {
                return string.Format("[{0}] {1}", DeploymentType, Version);
            }
            if (!string.IsNullOrEmpty(Version)) { return Version; }
            if (!string.IsNullOrEmpty(DeploymentType)) { return DeploymentType; }
            return string.Empty;
        }
    }

    // JiraPS treats Group as a narrow canonical domain object: a stable name,
    // an optional Cloud-capable identifier, an optional REST URL, and optional
    // member-expansion data. The underlying wire shapes now differ by product:
    // Cloud canonical resolution comes from /group/bulk, while Data Center
    // canonical resolution is adapted from /group/member.
    public class Group : JiraIdentityObject<Group>
    {
        public string Name { get; set; }
        public string Id { get; set; }
        public string GroupId { get { return Id; } set { Id = value; } }
        public Uri RestUrl { get; set; }
        // Null means "size not supplied by this payload shape"; 0 means the
        // group is known to have zero members.
        public int? Size { get; set; }
        public User[] Member { get; set; }

        public Group() { }

        public Group(string name)
        {
            if (string.IsNullOrWhiteSpace(name))
            {
                throw new ArgumentException("name must not be null, empty, or whitespace.", "name");
            }
            Name = name;
        }

        protected override string GetIdentity()
        {
            return Name ?? string.Empty;
        }

        public override string ToString()
        {
            return Name ?? string.Empty;
        }
    }
}
