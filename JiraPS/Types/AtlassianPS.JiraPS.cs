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
        // Both platforms: 'software', 'business', 'service_desk', 'product_discovery'.
        public string ProjectTypeKey { get; set; }
        public string Url { get; set; }
        public string Email { get; set; }
        // Optional flags returned only by newer instances; nullable so callers
        // can tell "field absent" apart from "explicitly false".
        public bool? Archived { get; set; }
        public bool? Simplified { get; set; }
        public bool? IsPrivate { get; set; }

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

        public override string ToString()
        {
            return string.Format("[{0}] {1}", DeploymentType, Version);
        }
    }

    // Internal helper shared by every JiraPS argument transformer. PowerShell's
    // ArgumentTransformationAttribute is invoked once with whatever the caller
    // typed at the call site — that may be a single value OR an enumerable
    // bound to a [Type[]] parameter (e.g. -User $a, $b on Remove-JiraGroupMember).
    // For singular parameters the per-element transform is enough; for array
    // parameters we walk the enumerable so each element is transformed in
    // isolation and PowerShell's element coercion sees the right runtime type.
    internal static class JiraTransform
    {
        public static object TransformOrFanout(object inputData, Func<object, object> perItem)
        {
            if (inputData == null) return null;

            var pso = inputData as System.Management.Automation.PSObject;
            object value = pso != null ? pso.BaseObject : inputData;

            // Strings are IEnumerable<char>; treat them as scalars.
            if (value is string) { return perItem(inputData); }

            // Hashtables are IEnumerable<DictionaryEntry>; never fan-out.
            if (value is System.Collections.IDictionary) { return perItem(inputData); }

            if (value is System.Collections.IEnumerable enumerable)
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
    // test fixtures still construct). For everything else we throw a clear
    // transformation error rather than letting PowerShell's stock coercion
    // produce a less helpful "Cannot convert" message.
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

            if (value is string key)
            {
                if (string.IsNullOrWhiteSpace(key))
                {
                    throw new System.Management.Automation.ArgumentTransformationMetadataException(
                        "Cannot bind an empty or whitespace string to parameter -Issue.");
                }
                return new Issue { Key = key };
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

            throw new System.Management.Automation.ArgumentTransformationMetadataException(string.Format(
                "Cannot convert value of type '{0}' to AtlassianPS.JiraPS.Issue. Expected an issue-key string or an existing AtlassianPS.JiraPS.Issue object.",
                value.GetType().FullName));
        }
    }

    // Same idea as IssueTransformationAttribute, for User-typed parameters.
    // Accepts an existing User, a non-empty identifier string (a username on
    // DC, an accountId on Cloud — Resolve-JiraUser inspects the slot pattern
    // at call time and routes the GET accordingly), or a legacy PSCustomObject
    // tagged as AtlassianPS.JiraPS.User. Anything else throws a transformer
    // error so the caller sees an actionable message at parameter binding.
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

            if (value is string identifier)
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
                return new User { Name = identifier };
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

            throw new System.Management.Automation.ArgumentTransformationMetadataException(string.Format(
                "Cannot convert value of type '{0}' to AtlassianPS.JiraPS.User. Expected a username/accountId string or an existing AtlassianPS.JiraPS.User object.",
                value.GetType().FullName));
        }
    }
}
