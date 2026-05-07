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
using System.Runtime.CompilerServices;
using System.Threading;

namespace AtlassianPS.JiraPS
{
    internal static class JiraTypeIdentity
    {
        private sealed class ObjectOrderToken
        {
            public readonly int Value;

            public ObjectOrderToken(int value)
            {
                Value = value;
            }
        }

        private static readonly StringComparer Comparer = StringComparer.OrdinalIgnoreCase;
        private static readonly ConditionalWeakTable<object, ObjectOrderToken> ObjectOrder = new ConditionalWeakTable<object, ObjectOrderToken>();
        private static int NextObjectOrder;

        public static bool Equals(string left, string right)
        {
            return Comparer.Equals(Normalize(left), Normalize(right));
        }

        public static int Compare(string left, string right)
        {
            return Comparer.Compare(Normalize(left), Normalize(right));
        }

        public static int CompareObjects(string left, string right, object leftObject, object rightObject)
        {
            var normalizedLeft = Normalize(left);
            var normalizedRight = Normalize(right);
            var leftHasIdentity = normalizedLeft.Length > 0;
            var rightHasIdentity = normalizedRight.Length > 0;

            if (leftHasIdentity && rightHasIdentity)
            {
                return Comparer.Compare(normalizedLeft, normalizedRight);
            }

            if (leftHasIdentity) { return 1; }
            if (rightHasIdentity) { return -1; }
            if (ReferenceEquals(leftObject, rightObject)) { return 0; }

            return GetObjectOrder(leftObject).CompareTo(GetObjectOrder(rightObject));
        }

        public static bool IdentityEquals<T>(T leftObject, T rightObject, string leftIdentity, string rightIdentity)
            where T : class
        {
            if (ReferenceEquals(rightObject, null)) { return false; }
            if (ReferenceEquals(leftObject, rightObject)) { return true; }
            if (string.IsNullOrEmpty(leftIdentity) || string.IsNullOrEmpty(rightIdentity)) { return false; }

            return Equals(leftIdentity, rightIdentity);
        }

        public static int IdentityGetHashCode(string identity)
        {
            if (string.IsNullOrEmpty(identity)) { return 0; }
            return GetHashCode(identity);
        }

        public static int IdentityCompare<T>(T leftObject, T rightObject, string leftIdentity, string rightIdentity)
            where T : class
        {
            if (ReferenceEquals(rightObject, null)) { return 1; }
            return CompareObjects(leftIdentity, rightIdentity, leftObject, rightObject);
        }

        public static int CompareToObject<T>(object value, Func<T, int> compare, string typeName)
            where T : class
        {
            if (value == null) { return 1; }

            var other = value as T;
            if (other == null) { throw new ArgumentException("Object must be " + typeName + ".", "obj"); }

            return compare(other);
        }

        public static int GetHashCode(string value)
        {
            return Comparer.GetHashCode(Normalize(value));
        }

        private static string Normalize(string value)
        {
            return value ?? string.Empty;
        }

        private static int GetObjectOrder(object value)
        {
            return ObjectOrder.GetValue(value, CreateObjectOrderToken).Value;
        }

        private static ObjectOrderToken CreateObjectOrderToken(object value)
        {
            return new ObjectOrderToken(Interlocked.Increment(ref NextObjectOrder));
        }
    }

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
        public string RestUrl { get; set; }

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
        public object IssueTypes { get; set; }
        public object Roles { get; set; }
        public string RestUrl { get; set; }
        public object Components { get; set; }
        public string Style { get; set; }
        public object Category { get; set; }
        // Both platforms: 'software', 'business', 'service_desk', 'product_discovery'.
        public string ProjectTypeKey { get; set; }
        public string Url { get; set; }
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
        public string RestUrl { get; set; }
        public User Author { get; set; }
        public User UpdateAuthor { get; set; }
        public DateTime? Created { get; set; }
        public DateTime? Updated { get; set; }

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
        public string HttpUrl { get; set; }
        public string RestUrl { get; set; }
        public string Summary { get; set; }
        public string Description { get; set; }
        // Status is a `JiraPS.Status` PSObject (returned by ConvertTo-JiraStatus),
        // not a bare string. The PSObject's ToString() renders the status name so
        // `"$($issue.Status)"` and the default formatter still display the name.
        public object Status { get; set; }
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
        public string RestUrl { get; set; }
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
        public string BaseURL { get; set; }
        public string Version { get; set; }
        // Both platforms expose this as e.g. [9, 17, 0]; surfaced separately
        // from the Version string so callers can compare numerically.
        public int[] VersionNumbers { get; set; }
        public string DeploymentType { get; set; }
        public long? BuildNumber { get; set; }
        public DateTime? BuildDate { get; set; }
        public DateTime? ServerTime { get; set; }
        public string ScmInfo { get; set; }
        public string ServerTitle { get; set; }
        // DC-only display URL (the canonical externally-visible base URL,
        // which can differ from BaseURL behind a reverse proxy).
        public string DisplayUrl { get; set; }
        // DC-only co-located product display URLs; null on Cloud and on DC
        // instances that are not paired with Confluence / Service Desk.
        public string DisplayUrlConfluence { get; set; }
        public string DisplayUrlServicedeskHelpCenter { get; set; }
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
        public string RestUrl { get; set; }
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

    // Internal helper shared by JiraPS argument transformers that fan out
    // array arguments (e.g. [User[]], [Group[]]). IssueTransformation does
    // not use this — singular [Issue] parameters must not auto-iterate a
    // bound array; callers pipeline-iterate instead.
    //
    // Throw vs. pass-through (binder fallthrough): see AGENTS.md
    // "Argument transformation attributes". When a parameter shares
    // ValueFromPipeline with another parameter set that expects a different
    // type, TransformOne must return inputData unchanged for unrecognized
    // shapes (see VersionTransformationAttribute). Otherwise TransformOne
    // should throw ArgumentTransformationMetadataException.
    //
    // PowerShell's ArgumentTransformationAttribute is invoked once with
    // whatever the caller typed — a single value OR an enumerable bound to a
    // [T[]] parameter (e.g. -User $a, $b on Remove-JiraGroupMember). For array
    // parameters we walk the enumerable so each element is transformed in
    // isolation and element coercion sees the right runtime type.
    internal static class JiraTransform
    {
        public static bool IsJiraDomainObject(object value)
        {
            if (value == null) { return false; }

            var pso = value as System.Management.Automation.PSObject;
            if (pso != null)
            {
                if (pso.TypeNames != null)
                {
                    foreach (var typeName in pso.TypeNames)
                    {
                        if (!string.IsNullOrEmpty(typeName)
                            && (typeName.StartsWith("AtlassianPS.JiraPS.", StringComparison.Ordinal)
                                || typeName.StartsWith("JiraPS.", StringComparison.Ordinal)))
                        {
                            return true;
                        }
                    }
                }
                value = pso.BaseObject;
                if (value == null) { return false; }
            }

            var valueType = value.GetType();
            return valueType != null && string.Equals(valueType.Namespace, "AtlassianPS.JiraPS", StringComparison.Ordinal);
        }

        public static object TransformOrFanout(object inputData, Func<object, object> perItem)
        {
            if (inputData == null) return null;

            var pso = inputData as System.Management.Automation.PSObject;
            object value = pso != null ? pso.BaseObject : inputData;

            // Strings are IEnumerable<char>; treat them as scalars.
            if (value is string) { return perItem(inputData); }

            // Hashtables are IEnumerable<DictionaryEntry>; never fan-out.
            if (value is System.Collections.IDictionary) { return perItem(inputData); }

            // C# 5 compatible (PS 5.1's bundled csc.exe): use `as` + null check
            // instead of pattern-matching `is X identifier` (C# 7+).
            var enumerable = value as System.Collections.IEnumerable;
            if (enumerable != null)
            {
                var results = new System.Collections.Generic.List<object>();
                foreach (var item in enumerable) { results.Add(perItem(item)); }
                return results.ToArray();
            }

            return perItem(inputData);
        }
    }

    // ArgumentTransformationAttribute lets cmdlets type their parameters as
    // [AtlassianPS.JiraPS.Issue] while still accepting an issue-key string at
    // the call site. The attribute wraps strings in a stub Issue (Key only),
    // leaving the eventual GET to Resolve-JiraIssueObject in the cmdlet body.
    [AttributeUsage(AttributeTargets.Property | AttributeTargets.Field | AttributeTargets.Parameter, AllowMultiple = false)]
    // Accepts an existing Issue, an issue-key string, or a legacy PSCustomObject
    // decorated with the AtlassianPS.JiraPS.Issue PSTypeName (the contract several
    // test fixtures still construct). For everything else we return inputData
    // unchanged so ValueFromPipeline parameter-set fallthrough can continue.
    public sealed class IssueTransformationAttribute : System.Management.Automation.ArgumentTransformationAttribute
    {
        // No fan-out: every consumer of [IssueTransformation] declares the
        // parameter as singular [AtlassianPS.JiraPS.Issue]. Passing an array
        // directly stays a hard error (existing test contract — pipeline-iterate
        // instead). UserTransformation does fan out because Remove-JiraGroupMember
        // legitimately takes [User[]].
        public override object Transform(System.Management.Automation.EngineIntrinsics engineIntrinsics, object inputData)
        {
            return TransformOne(inputData);
        }

        private static object TransformOne(object inputData)
        {
            if (inputData == null) return null;

            var pso = inputData as System.Management.Automation.PSObject;
            object value = pso != null ? pso.BaseObject : inputData;

            if (value is Issue) return value;

            var key = value as string;
            if (key != null)
            {
                if (string.IsNullOrWhiteSpace(key))
                {
                    throw new System.Management.Automation.ArgumentTransformationMetadataException(
                        "Cannot bind an empty or whitespace string to parameter -Issue.");
                }
                return new Issue(key);
            }

            // Legacy PSCustomObject masquerading as an Issue (PSTypeName trick).
            // Map the well-known scalar slots so old call sites keep working.
            if (pso != null && pso.TypeNames != null && pso.TypeNames.Contains("AtlassianPS.JiraPS.Issue"))
            {
                var issue = new Issue();
                foreach (var prop in pso.Properties)
                {
                    switch (prop.Name)
                    {
                        case "ID": case "Id": case "id": issue.ID = prop.Value as string; break;
                        case "Key": case "key": issue.Key = prop.Value as string; break;
                        case "HttpUrl": issue.HttpUrl = prop.Value as string; break;
                        case "RestUrl": case "RestURL": issue.RestUrl = prop.Value as string; break;
                        case "Summary": issue.Summary = prop.Value as string; break;
                        case "Description": issue.Description = prop.Value as string; break;
                        case "Status": issue.Status = prop.Value as string; break;
                        case "Project": issue.Project = prop.Value as Project; break;
                    }
                }
                return issue;
            }

            if (JiraTransform.IsJiraDomainObject(inputData)) { return inputData; }

            throw new System.Management.Automation.ArgumentTransformationMetadataException(string.Format(
                "Cannot convert value of type '{0}' to AtlassianPS.JiraPS.Issue. Expected an issue-key string or an existing AtlassianPS.JiraPS.Issue object.",
                value.GetType().FullName));
        }
    }

    // Same idea as IssueTransformationAttribute, for User-typed parameters.
    // Accepts an existing User, a non-empty identifier string (a username on
    // DC, an accountId on Cloud — Resolve-JiraUser inspects the slot pattern
    // at call time and routes the GET accordingly), or a legacy PSCustomObject
    // tagged as AtlassianPS.JiraPS.User. Unrecognized values are returned
    // unchanged so competing pipeline parameter sets can still bind.
    [AttributeUsage(AttributeTargets.Property | AttributeTargets.Field | AttributeTargets.Parameter, AllowMultiple = false)]
    public sealed class UserTransformationAttribute : System.Management.Automation.ArgumentTransformationAttribute
    {
        public override object Transform(System.Management.Automation.EngineIntrinsics engineIntrinsics, object inputData)
        {
            return JiraTransform.TransformOrFanout(inputData, TransformOne);
        }

        private static object TransformOne(object inputData)
        {
            if (inputData == null) return null;

            var pso = inputData as System.Management.Automation.PSObject;
            object value = pso != null ? pso.BaseObject : inputData;

            if (value is User) return value;

            var identifier = value as string;
            if (identifier != null)
            {
                if (string.IsNullOrWhiteSpace(identifier))
                {
                    throw new System.Management.Automation.ArgumentTransformationMetadataException(
                        "Cannot bind an empty or whitespace string to a User parameter.");
                }
                // Store the raw identifier in Name; Resolve-JiraUser inspects
                // it at call time and dispatches to /accountId or /username
                // based on the detected platform — same semantics as the
                // legacy ValidateScript code path.
                return new User(identifier);
            }

            // Legacy PSCustomObject masquerading as a User (PSTypeName trick).
            if (pso != null && pso.TypeNames != null && pso.TypeNames.Contains("AtlassianPS.JiraPS.User"))
            {
                var user = new User();
                foreach (var prop in pso.Properties)
                {
                    switch (prop.Name)
                    {
                        case "Key": case "key": user.Key = prop.Value as string; break;
                        case "AccountId": case "accountId": user.AccountId = prop.Value as string; break;
                        case "AccountType": case "accountType": user.AccountType = prop.Value as string; break;
                        case "Name": case "name": user.Name = prop.Value as string; break;
                        case "DisplayName": case "displayName": user.DisplayName = prop.Value as string; break;
                        case "EmailAddress": case "emailAddress": user.EmailAddress = prop.Value as string; break;
                        case "TimeZone": case "timeZone": user.TimeZone = prop.Value as string; break;
                        case "Locale": case "locale": user.Locale = prop.Value as string; break;
                        case "RestUrl": case "RestURL":
                            user.RestUrl = prop.Value as string; break;
                    }
                }
                return user;
            }

            if (JiraTransform.IsJiraDomainObject(inputData)) { return inputData; }

            throw new System.Management.Automation.ArgumentTransformationMetadataException(string.Format(
                "Cannot convert value of type '{0}' to AtlassianPS.JiraPS.User. Expected a username/accountId string or an existing AtlassianPS.JiraPS.User object.",
                value.GetType().FullName));
        }
    }

    // Same shape as UserTransformationAttribute. -Group / -GroupName parameters
    // are typed as [Group[]] on the cmdlets that take more than one (so the
    // attribute uses TransformOrFanout), and as [Group] on the singletons.
    [AttributeUsage(AttributeTargets.Property | AttributeTargets.Field | AttributeTargets.Parameter, AllowMultiple = false)]
    public sealed class GroupTransformationAttribute : System.Management.Automation.ArgumentTransformationAttribute
    {
        public override object Transform(System.Management.Automation.EngineIntrinsics engineIntrinsics, object inputData)
        {
            return JiraTransform.TransformOrFanout(inputData, TransformOne);
        }

        private static object TransformOne(object inputData)
        {
            if (inputData == null) return null;

            var pso = inputData as System.Management.Automation.PSObject;
            object value = pso != null ? pso.BaseObject : inputData;

            if (value is Group) return value;

            var name = value as string;
            if (name != null)
            {
                if (string.IsNullOrWhiteSpace(name))
                {
                    throw new System.Management.Automation.ArgumentTransformationMetadataException(
                        "Cannot bind an empty or whitespace string to a Group parameter.");
                }
                return new Group(name);
            }

            // Legacy PSCustomObject masquerading as a Group (PSTypeName trick).
            // Map both the new "AtlassianPS.JiraPS.Group" tag and the historical
            // "JiraPS.Group" tag, the latter so test fixtures and v2 user
            // scripts that still construct PSCustomObjects bind without changes
            // until they are migrated.
            if (pso != null && pso.TypeNames != null && (pso.TypeNames.Contains("AtlassianPS.JiraPS.Group") || pso.TypeNames.Contains("JiraPS.Group")))
            {
                var group = new Group();
                foreach (var prop in pso.Properties)
                {
                    switch (prop.Name)
                    {
                        case "Name": case "name": group.Name = prop.Value as string; break;
                        case "GroupId": case "groupId": case "Id": case "id":
                            group.Id = prop.Value as string; break;
                        case "RestUrl": case "RestURL": case "self":
                            group.RestUrl = prop.Value as string; break;
                        case "Size": case "size":
                            if (prop.Value != null)
                            {
                                int size;
                                if (int.TryParse(prop.Value.ToString(), out size)) { group.Size = size; }
                            }
                            break;
                        case "Member": case "Members":
                            group.Member = prop.Value as User[]; break;
                    }
                }
                return group;
            }

            if (JiraTransform.IsJiraDomainObject(inputData)) { return inputData; }

            throw new System.Management.Automation.ArgumentTransformationMetadataException(string.Format(
                "Cannot convert value of type '{0}' to AtlassianPS.JiraPS.Group. Expected a group-name string or an existing AtlassianPS.JiraPS.Group object.",
                value.GetType().FullName));
        }
    }

    // Same idea as the other transformers, for Version-typed parameters.
    // Accepts an existing Version, a numeric value (int / long / numeric
    // string — Jira Version IDs are integers on the wire), a non-numeric
    // string (treated as a Version name, the shape New-JiraVersion's byObject
    // path used to coerce out of [Object]), or a legacy PSCustomObject tagged
    // as AtlassianPS.JiraPS.Version. The cmdlet body is responsible for
    // resolving stub Versions through Get-JiraVersion when it needs the full
    // payload (RestUrl etc.).
    [AttributeUsage(AttributeTargets.Property | AttributeTargets.Field | AttributeTargets.Parameter, AllowMultiple = false)]
    public sealed class VersionTransformationAttribute : System.Management.Automation.ArgumentTransformationAttribute
    {
        public override object Transform(System.Management.Automation.EngineIntrinsics engineIntrinsics, object inputData)
        {
            return JiraTransform.TransformOrFanout(inputData, TransformOne);
        }

        private static object TransformOne(object inputData)
        {
            if (inputData == null) return null;

            var pso = inputData as System.Management.Automation.PSObject;
            object value = pso != null ? pso.BaseObject : inputData;

            if (value is Version) return value;

            // Numeric scalars — Jira Version IDs are always integral.
            if (value is int || value is long || value is short || value is byte
                || value is uint || value is ulong || value is ushort || value is sbyte)
            {
                return new Version { ID = System.Convert.ToInt64(value).ToString(System.Globalization.CultureInfo.InvariantCulture) };
            }

            var str = value as string;
            if (str != null)
            {
                if (string.IsNullOrWhiteSpace(str))
                {
                    throw new System.Management.Automation.ArgumentTransformationMetadataException(
                        "Cannot bind an empty or whitespace string to a Version parameter.");
                }
                // Version(string) parses numeric tokens into ID and falls
                // back to Name for everything else — same routing as the
                // historic transformer body.
                return new Version(str);
            }

            // Legacy PSCustomObject masquerading as a Version (PSTypeName trick).
            if (pso != null && pso.TypeNames != null && (pso.TypeNames.Contains("AtlassianPS.JiraPS.Version") || pso.TypeNames.Contains("JiraPS.Version")))
            {
                var version = new Version();
                foreach (var prop in pso.Properties)
                {
                    switch (prop.Name)
                    {
                        case "ID": case "Id": case "id": version.ID = prop.Value as string ?? (prop.Value != null ? prop.Value.ToString() : null); break;
                        case "Name": case "name": version.Name = prop.Value as string; break;
                        case "Description": case "description": version.Description = prop.Value as string; break;
                        case "RestUrl": case "RestURL": case "self":
                            version.RestUrl = prop.Value as string; break;
                        case "Archived": case "archived":
                            if (prop.Value != null)
                            {
                                bool archived;
                                if (bool.TryParse(prop.Value.ToString(), out archived)) { version.Archived = archived; }
                            }
                            break;
                        case "Released": case "released":
                            if (prop.Value != null)
                            {
                                bool released;
                                if (bool.TryParse(prop.Value.ToString(), out released)) { version.Released = released; }
                            }
                            break;
                        case "Overdue": case "overdue":
                            if (prop.Value != null)
                            {
                                bool overdue;
                                if (bool.TryParse(prop.Value.ToString(), out overdue)) { version.Overdue = overdue; }
                            }
                            break;
                        case "Project": case "project": case "projectId":
                            if (prop.Value != null)
                            {
                                long projectId;
                                if (long.TryParse(prop.Value.ToString(), out projectId)) { version.Project = projectId; }
                            }
                            break;
                    }
                }
                return version;
            }

            // Get-JiraVersion has sister parameter sets that share ValueFromPipeline
            // (notably -InputProject [PSTypeName('AtlassianPS.JiraPS.Project')]).
            // If another JiraPS domain object is piped, we want PowerShell's
            // parameter binder to fall through to the matching alternate set
            // rather than fail here. Truly unrelated values should still produce
            // a targeted transformation error.
            if (JiraTransform.IsJiraDomainObject(inputData)) { return inputData; }

            throw new System.Management.Automation.ArgumentTransformationMetadataException(string.Format(
                "Cannot convert value of type '{0}' to AtlassianPS.JiraPS.Version. Expected a version name/ID, a numeric Jira version ID, or an existing AtlassianPS.JiraPS.Version object.",
                value.GetType().FullName));
        }
    }

    // Same shape as the other transformers, for Filter-typed parameters.
    // Accepts an existing Filter, a numeric scalar or string (treated as a
    // filter ID — Jira filter IDs are integral on the wire and the historic
    // Get-JiraFilter -InputObject [String] path always treated the string as
    // an ID via .ToString()), or a legacy PSCustomObject tagged as
    // AtlassianPS.JiraPS.Filter. The cmdlet body is responsible for resolving
    // stub Filters through Get-JiraFilter -Id when it needs the full payload
    // (SearchUrl, RestUrl, JQL, ...).
    [AttributeUsage(AttributeTargets.Property | AttributeTargets.Field | AttributeTargets.Parameter, AllowMultiple = false)]
    public sealed class FilterTransformationAttribute : System.Management.Automation.ArgumentTransformationAttribute
    {
        public override object Transform(System.Management.Automation.EngineIntrinsics engineIntrinsics, object inputData)
        {
            return JiraTransform.TransformOrFanout(inputData, TransformOne);
        }

        private static object TransformOne(object inputData)
        {
            if (inputData == null) return null;

            var pso = inputData as System.Management.Automation.PSObject;
            object value = pso != null ? pso.BaseObject : inputData;

            if (value is Filter) return value;

            if (value is int || value is long || value is short || value is byte
                || value is uint || value is ulong || value is ushort || value is sbyte)
            {
                return new Filter { ID = System.Convert.ToInt64(value).ToString(System.Globalization.CultureInfo.InvariantCulture) };
            }

            var str = value as string;
            if (str != null)
            {
                if (string.IsNullOrWhiteSpace(str))
                {
                    throw new System.Management.Automation.ArgumentTransformationMetadataException(
                        "Cannot bind an empty or whitespace string to a Filter parameter.");
                }
                // Historic behaviour: a string passed to -InputObject was always
                // treated as a filter ID (the body called ToString() on it and
                // forwarded to Get-JiraFilter -Id). Preserve that contract.
                return new Filter(str);
            }

            // Legacy PSCustomObject masquerading as a Filter (PSTypeName trick).
            if (pso != null && pso.TypeNames != null && (pso.TypeNames.Contains("AtlassianPS.JiraPS.Filter") || pso.TypeNames.Contains("JiraPS.Filter")))
            {
                var filter = new Filter();
                foreach (var prop in pso.Properties)
                {
                    switch (prop.Name)
                    {
                        case "ID": case "Id": case "id": filter.ID = prop.Value as string ?? (prop.Value != null ? prop.Value.ToString() : null); break;
                        case "Name": case "name": filter.Name = prop.Value as string; break;
                        case "JQL": case "jql": filter.JQL = prop.Value as string; break;
                        case "RestUrl": case "RestURL": case "self":
                            filter.RestUrl = prop.Value as string; break;
                        case "ViewUrl": case "viewUrl":
                            filter.ViewUrl = prop.Value as string; break;
                        case "SearchUrl": case "SearchURL": case "searchUrl":
                            filter.SearchUrl = prop.Value as string; break;
                        case "Description": case "description": filter.Description = prop.Value as string; break;
                        case "Favourite": case "Favorite": case "favourite":
                            if (prop.Value != null)
                            {
                                bool fav;
                                if (bool.TryParse(prop.Value.ToString(), out fav)) { filter.Favourite = fav; }
                            }
                            break;
                        case "Owner": case "owner":
                            filter.Owner = prop.Value as User; break;
                    }
                }
                return filter;
            }

            if (JiraTransform.IsJiraDomainObject(inputData)) { return inputData; }

            throw new System.Management.Automation.ArgumentTransformationMetadataException(string.Format(
                "Cannot convert value of type '{0}' to AtlassianPS.JiraPS.Filter. Expected a filter ID, a numeric Jira filter ID, or an existing AtlassianPS.JiraPS.Filter object.",
                value.GetType().FullName));
        }
    }

    // Same shape as the other transformers, for Project-typed parameters.
    // Accepts an existing Project, a string (treated as a project Key — every
    // -Project consumer historically forwarded the string straight to either
    // a /project/{key} URL or to Get-JiraProject -Project, both of which take
    // keys), a numeric scalar (treated as a project ID), or a legacy
    // PSCustomObject tagged as AtlassianPS.JiraPS.Project. The cmdlet body is
    // responsible for picking Key vs ID based on what the underlying REST
    // endpoint expects.
    [AttributeUsage(AttributeTargets.Property | AttributeTargets.Field | AttributeTargets.Parameter, AllowMultiple = false)]
    public sealed class ProjectTransformationAttribute : System.Management.Automation.ArgumentTransformationAttribute
    {
        public override object Transform(System.Management.Automation.EngineIntrinsics engineIntrinsics, object inputData)
        {
            return JiraTransform.TransformOrFanout(inputData, TransformOne);
        }

        private static object TransformOne(object inputData)
        {
            if (inputData == null) return null;

            var pso = inputData as System.Management.Automation.PSObject;
            object value = pso != null ? pso.BaseObject : inputData;

            if (value is Project) return value;

            // Numeric scalars are unambiguously project IDs (Jira project IDs
            // are integral on the wire; project keys are uppercase letters).
            if (value is int || value is long || value is short || value is byte
                || value is uint || value is ulong || value is ushort || value is sbyte)
            {
                return new Project { ID = System.Convert.ToInt64(value).ToString(System.Globalization.CultureInfo.InvariantCulture) };
            }

            var str = value as string;
            if (str != null)
            {
                if (string.IsNullOrWhiteSpace(str))
                {
                    throw new System.Management.Automation.ArgumentTransformationMetadataException(
                        "Cannot bind an empty or whitespace string to a Project parameter.");
                }
                // Historic behaviour: every -Project consumer forwarded the raw
                // string to either /project/{idOrKey} URLs or to Get-JiraProject
                // -Project (which is documented as taking a key). Wrap as Key so
                // the call sites continue to work without per-cmdlet branching
                // on "did the user pass an ID or a key?".
                return new Project(str);
            }

            // Legacy PSCustomObject masquerading as a Project (PSTypeName trick).
            if (pso != null && pso.TypeNames != null && (pso.TypeNames.Contains("AtlassianPS.JiraPS.Project") || pso.TypeNames.Contains("JiraPS.Project")))
            {
                var project = new Project();
                foreach (var prop in pso.Properties)
                {
                    switch (prop.Name)
                    {
                        case "ID": case "Id": case "id": project.ID = prop.Value as string ?? (prop.Value != null ? prop.Value.ToString() : null); break;
                        case "Key": case "key": project.Key = prop.Value as string; break;
                        case "Name": case "name": project.Name = prop.Value as string; break;
                        case "Description": case "description": project.Description = prop.Value as string; break;
                        case "Lead": case "lead":
                            project.Lead = prop.Value as User; break;
                        case "RestUrl": case "RestURL": case "self":
                            project.RestUrl = prop.Value as string; break;
                        case "Style": case "style":
                            project.Style = prop.Value as string; break;
                        case "ProjectTypeKey": case "projectTypeKey":
                            project.ProjectTypeKey = prop.Value as string; break;
                        case "Url": case "url":
                            project.Url = prop.Value as string; break;
                        case "Email": case "email":
                            project.Email = prop.Value as string; break;
                    }
                }
                return project;
            }

            if (JiraTransform.IsJiraDomainObject(inputData)) { return inputData; }

            throw new System.Management.Automation.ArgumentTransformationMetadataException(string.Format(
                "Cannot convert value of type '{0}' to AtlassianPS.JiraPS.Project. Expected a project-key string, a numeric Jira project ID, or an existing AtlassianPS.JiraPS.Project object.",
                value.GetType().FullName));
        }
    }
}
