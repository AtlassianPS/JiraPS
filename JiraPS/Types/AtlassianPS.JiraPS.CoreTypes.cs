// Strongly-typed POCOs and argument transformers for JiraPS.
// Loaded once at module import via Add-Type from JiraPS.psm1 (#region Dependencies).

using System;
using System.Collections.Generic;
using System.Runtime.CompilerServices;
using System.Threading;

namespace AtlassianPS.JiraPS
{
    // Slots typed `object` are intentional: they hold polymorphic values, opaque API payloads,
    // or runtime-specific objects whose concrete types differ across PowerShell editions.

    public class User : IEquatable<User>, IComparable<User>, IComparable
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

        // Parameterless ctor preserved explicitly: declaring the
        // string-arg overload below removes C#'s implicit parameterless
        // ctor, which the [Class]@{ ... } hashtable-cast pattern requires.
        public User() { }

        // Convenience ctor for the common stub-from-an-identifier case.
        // Matches UserTransformationAttribute's wire contract: the raw
        // identifier lands in Name and Resolve-JiraUser routes to
        // /accountId or /username at call time based on shape.
        public User(string identifier)
        {
            if (string.IsNullOrWhiteSpace(identifier))
            {
                throw new ArgumentException("identifier must not be null, empty, or whitespace.", "identifier");
            }
            Name = identifier;
        }

        private string GetIdentity()
        {
            if (!string.IsNullOrEmpty(AccountId)) { return AccountId; }
            if (!string.IsNullOrEmpty(Name)) { return Name; }
            return string.Empty;
        }

        public bool Equals(User other)
        {
            return JiraTypeIdentity.IdentityEquals(this, other, GetIdentity(), other != null ? other.GetIdentity() : string.Empty);
        }

        public override bool Equals(object obj)
        {
            return Equals(obj as User);
        }

        public override int GetHashCode()
        {
            return JiraTypeIdentity.IdentityGetHashCode(GetIdentity());
        }

        public int CompareTo(User other)
        {
            return JiraTypeIdentity.IdentityCompare(this, other, GetIdentity(), other != null ? other.GetIdentity() : string.Empty);
        }

        int IComparable.CompareTo(object obj)
        {
            return JiraTypeIdentity.CompareToObject<User>(obj, CompareTo, "AtlassianPS.JiraPS.User");
        }

        public override string ToString()
        {
            if (!string.IsNullOrEmpty(Name)) { return Name; }
            if (!string.IsNullOrEmpty(DisplayName)) { return DisplayName; }
            if (!string.IsNullOrEmpty(AccountId)) { return AccountId; }
            return string.Empty;
        }
    }

    public class Project : IEquatable<Project>, IComparable<Project>, IComparable
    {
        public string ID { get; set; }
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

        // Stub-from-key ctor; matches ProjectTransformationAttribute's
        // string-input contract (alphanumeric tokens are project keys).
        public Project(string key)
        {
            if (string.IsNullOrWhiteSpace(key))
            {
                throw new ArgumentException("key must not be null, empty, or whitespace.", "key");
            }
            Key = key;
        }

        private string GetIdentity()
        {
            return Key ?? string.Empty;
        }

        public bool Equals(Project other)
        {
            return JiraTypeIdentity.IdentityEquals(this, other, GetIdentity(), other != null ? other.GetIdentity() : string.Empty);
        }

        public override bool Equals(object obj)
        {
            return Equals(obj as Project);
        }

        public override int GetHashCode()
        {
            return JiraTypeIdentity.IdentityGetHashCode(GetIdentity());
        }

        public int CompareTo(Project other)
        {
            return JiraTypeIdentity.IdentityCompare(this, other, GetIdentity(), other != null ? other.GetIdentity() : string.Empty);
        }

        int IComparable.CompareTo(object obj)
        {
            return JiraTypeIdentity.CompareToObject<Project>(obj, CompareTo, "AtlassianPS.JiraPS.Project");
        }

        public override string ToString()
        {
            return Name ?? string.Empty;
        }
    }

    public class Comment
    {
        public string ID { get; set; }
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

    public class Issue : IEquatable<Issue>, IComparable<Issue>, IComparable
    {
        public string ID { get; set; }
        public string Key { get; set; }
        public Uri HttpUrl { get; set; }
        public Uri RestUrl { get; set; }
        public string Summary { get; set; }
        public string Description { get; set; }
        // Status is a `JiraPS.Status` PSObject (returned by ConvertTo-JiraStatus),
        // not a bare string. The PSObject's ToString() renders the status name so
        // `"$($issue.Status)"` and the default formatter still display the name.
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

        // Stub-from-key ctor; matches IssueTransformationAttribute's
        // string-input contract.
        public Issue(string key)
        {
            if (string.IsNullOrWhiteSpace(key))
            {
                throw new ArgumentException("key must not be null, empty, or whitespace.", "key");
            }
            Key = key;
        }

        private string GetIdentity()
        {
            return Key ?? string.Empty;
        }

        public bool Equals(Issue other)
        {
            return JiraTypeIdentity.IdentityEquals(this, other, GetIdentity(), other != null ? other.GetIdentity() : string.Empty);
        }

        public override bool Equals(object obj)
        {
            return Equals(obj as Issue);
        }

        public override int GetHashCode()
        {
            return JiraTypeIdentity.IdentityGetHashCode(GetIdentity());
        }

        public int CompareTo(Issue other)
        {
            return JiraTypeIdentity.IdentityCompare(this, other, GetIdentity(), other != null ? other.GetIdentity() : string.Empty);
        }

        int IComparable.CompareTo(object obj)
        {
            return JiraTypeIdentity.CompareToObject<Issue>(obj, CompareTo, "AtlassianPS.JiraPS.Issue");
        }

        public override string ToString()
        {
            return string.Format("[{0}] {1}", Key, Summary);
        }
    }

    public class Version : IEquatable<Version>, IComparable<Version>, IComparable
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
        public Uri RestUrl { get; set; }
        public DateTime? StartDate { get; set; }
        public DateTime? ReleaseDate { get; set; }

        public Version() { }

        // Stub-from-identifier ctor; matches VersionTransformationAttribute's
        // string-input contract: a numeric token is the integer ID, anything
        // else is the human-readable Name.
        public Version(string nameOrId)
        {
            if (string.IsNullOrWhiteSpace(nameOrId))
            {
                throw new ArgumentException("nameOrId must not be null, empty, or whitespace.", "nameOrId");
            }
            long parsed;
            if (long.TryParse(nameOrId, System.Globalization.NumberStyles.Integer, System.Globalization.CultureInfo.InvariantCulture, out parsed))
            {
                ID = parsed.ToString(System.Globalization.CultureInfo.InvariantCulture);
            }
            else
            {
                Name = nameOrId;
            }
        }

        private string GetIdentity()
        {
            if (!string.IsNullOrEmpty(ID)) { return ID; }
            if (!string.IsNullOrEmpty(Name)) { return Name; }
            return string.Empty;
        }

        public bool Equals(Version other)
        {
            return JiraTypeIdentity.IdentityEquals(this, other, GetIdentity(), other != null ? other.GetIdentity() : string.Empty);
        }

        public override bool Equals(object obj)
        {
            return Equals(obj as Version);
        }

        public override int GetHashCode()
        {
            return JiraTypeIdentity.IdentityGetHashCode(GetIdentity());
        }

        public int CompareTo(Version other)
        {
            return JiraTypeIdentity.IdentityCompare(this, other, GetIdentity(), other != null ? other.GetIdentity() : string.Empty);
        }

        int IComparable.CompareTo(object obj)
        {
            return JiraTypeIdentity.CompareToObject<Version>(obj, CompareTo, "AtlassianPS.JiraPS.Version");
        }

        public override string ToString()
        {
            return Name ?? string.Empty;
        }
    }

    public class Filter : IEquatable<Filter>, IComparable<Filter>, IComparable
    {
        public string ID { get; set; }
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

        // The PowerShell-side AliasProperty for the American spelling (`Favorite`)
        // is added by ConvertTo-JiraFilter so historical assertions about the
        // member type continue to hold.

        public Filter() { }

        // Stub-from-id ctor; matches FilterTransformationAttribute's
        // string-input contract (the historic Get-JiraFilter -InputObject
        // [String] path always treated the value as an ID).
        public Filter(string id)
        {
            if (string.IsNullOrWhiteSpace(id))
            {
                throw new ArgumentException("id must not be null, empty, or whitespace.", "id");
            }
            ID = id;
        }

        private string GetIdentity()
        {
            return ID ?? string.Empty;
        }

        public bool Equals(Filter other)
        {
            return JiraTypeIdentity.IdentityEquals(this, other, GetIdentity(), other != null ? other.GetIdentity() : string.Empty);
        }

        public override bool Equals(object obj)
        {
            return Equals(obj as Filter);
        }

        public override int GetHashCode()
        {
            return JiraTypeIdentity.IdentityGetHashCode(GetIdentity());
        }

        public int CompareTo(Filter other)
        {
            return JiraTypeIdentity.IdentityCompare(this, other, GetIdentity(), other != null ? other.GetIdentity() : string.Empty);
        }

        int IComparable.CompareTo(object obj)
        {
            return JiraTypeIdentity.CompareToObject<Filter>(obj, CompareTo, "AtlassianPS.JiraPS.Filter");
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
    public class Group : IEquatable<Group>, IComparable<Group>, IComparable
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

        // Stub-from-name ctor; matches GroupTransformationAttribute's
        // string-input contract.
        public Group(string name)
        {
            if (string.IsNullOrWhiteSpace(name))
            {
                throw new ArgumentException("name must not be null, empty, or whitespace.", "name");
            }
            Name = name;
        }

        private string GetIdentity()
        {
            return Name ?? string.Empty;
        }

        public bool Equals(Group other)
        {
            return JiraTypeIdentity.IdentityEquals(this, other, GetIdentity(), other != null ? other.GetIdentity() : string.Empty);
        }

        public override bool Equals(object obj)
        {
            return Equals(obj as Group);
        }

        public override int GetHashCode()
        {
            return JiraTypeIdentity.IdentityGetHashCode(GetIdentity());
        }

        public int CompareTo(Group other)
        {
            return JiraTypeIdentity.IdentityCompare(this, other, GetIdentity(), other != null ? other.GetIdentity() : string.Empty);
        }

        int IComparable.CompareTo(object obj)
        {
            return JiraTypeIdentity.CompareToObject<Group>(obj, CompareTo, "AtlassianPS.JiraPS.Group");
        }

        public override string ToString()
        {
            return Name ?? string.Empty;
        }
    }
}
