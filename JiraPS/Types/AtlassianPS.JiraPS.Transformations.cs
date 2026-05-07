// Strongly-typed POCOs and argument transformers for JiraPS.
// Loaded once at module import via Add-Type from JiraPS.psm1 (#region Dependencies).

using System;
using System.Collections.Generic;
using System.Runtime.CompilerServices;
using System.Threading;

namespace AtlassianPS.JiraPS
{

    [AttributeUsage(AttributeTargets.Property | AttributeTargets.Field | AttributeTargets.Parameter, AllowMultiple = false)]
    public sealed class StatusTransformationAttribute : JiraLeafTransformationAttribute<Status>
    {
        protected override Status FromString(string value) { return new Status(value); }
    }

    [AttributeUsage(AttributeTargets.Property | AttributeTargets.Field | AttributeTargets.Parameter, AllowMultiple = false)]
    public sealed class PriorityTransformationAttribute : JiraLeafTransformationAttribute<Priority>
    {
        protected override Priority FromString(string value) { return new Priority(value); }
    }

    [AttributeUsage(AttributeTargets.Property | AttributeTargets.Field | AttributeTargets.Parameter, AllowMultiple = false)]
    public sealed class ResolutionTransformationAttribute : JiraLeafTransformationAttribute<Resolution>
    {
        protected override Resolution FromString(string value) { return new Resolution(value); }
    }

    [AttributeUsage(AttributeTargets.Property | AttributeTargets.Field | AttributeTargets.Parameter, AllowMultiple = false)]
    public sealed class IssueTypeTransformationAttribute : JiraLeafTransformationAttribute<IssueType>
    {
        protected override IssueType FromString(string value) { return new IssueType(value); }
    }

    [AttributeUsage(AttributeTargets.Property | AttributeTargets.Field | AttributeTargets.Parameter, AllowMultiple = false)]
    public sealed class ComponentTransformationAttribute : JiraLeafTransformationAttribute<Component>
    {
        protected override Component FromString(string value) { return new Component(value); }
    }

    [AttributeUsage(AttributeTargets.Property | AttributeTargets.Field | AttributeTargets.Parameter, AllowMultiple = false)]
    public sealed class FieldTransformationAttribute : JiraLeafTransformationAttribute<Field>
    {
        protected override Field FromString(string value) { return new Field(value); }
    }

    [AttributeUsage(AttributeTargets.Property | AttributeTargets.Field | AttributeTargets.Parameter, AllowMultiple = false)]
    public sealed class IssueLinkTypeTransformationAttribute : JiraLeafTransformationAttribute<IssueLinkType>
    {
        protected override IssueLinkType FromString(string value) { return new IssueLinkType(value); }
    }

    [AttributeUsage(AttributeTargets.Property | AttributeTargets.Field | AttributeTargets.Parameter, AllowMultiple = false)]
    public sealed class IssueLinkTransformationAttribute : JiraLeafTransformationAttribute<IssueLink>
    {
        protected override IssueLink FromString(string value) { return new IssueLink(value); }
    }

    [AttributeUsage(AttributeTargets.Property | AttributeTargets.Field | AttributeTargets.Parameter, AllowMultiple = false)]
    public sealed class AttachmentTransformationAttribute : JiraLeafTransformationAttribute<Attachment>
    {
        protected override Attachment FromString(string value) { return new Attachment(value); }
    }

    [AttributeUsage(AttributeTargets.Property | AttributeTargets.Field | AttributeTargets.Parameter, AllowMultiple = false)]
    public sealed class WorklogitemTransformationAttribute : JiraLeafTransformationAttribute<Worklogitem>
    {
        protected override Worklogitem FromString(string value) { return new Worklogitem(value); }
    }

    [AttributeUsage(AttributeTargets.Property | AttributeTargets.Field | AttributeTargets.Parameter, AllowMultiple = false)]
    public sealed class TransitionTransformationAttribute : JiraLeafTransformationAttribute<Transition>
    {
        protected override Transition FromString(string value) { return new Transition(value); }
    }

    [AttributeUsage(AttributeTargets.Property | AttributeTargets.Field | AttributeTargets.Parameter, AllowMultiple = false)]
    public sealed class LinkTransformationAttribute : JiraLeafTransformationAttribute<Link>
    {
        protected override Link FromString(string value) { return new Link(value); }
    }

    [AttributeUsage(AttributeTargets.Property | AttributeTargets.Field | AttributeTargets.Parameter, AllowMultiple = false)]
    public sealed class ProjectRoleTransformationAttribute : JiraLeafTransformationAttribute<ProjectRole>
    {
        protected override ProjectRole FromString(string value) { return new ProjectRole(value); }
    }

    [AttributeUsage(AttributeTargets.Property | AttributeTargets.Field | AttributeTargets.Parameter, AllowMultiple = false)]
    public sealed class FilterPermissionTransformationAttribute : JiraLeafTransformationAttribute<FilterPermission>
    {
        protected override FilterPermission FromString(string value) { return new FilterPermission(value); }
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
                        case "HttpUrl": issue.HttpUrl = JiraTransform.ToUri(prop.Value); break;
                        case "RestUrl": case "RestURL": issue.RestUrl = JiraTransform.ToUri(prop.Value); break;
                        case "Summary": issue.Summary = prop.Value as string; break;
                        case "Description": issue.Description = prop.Value as string; break;
                        case "Status": issue.Status = prop.Value as Status ?? (prop.Value != null ? new Status(prop.Value.ToString()) : null); break;
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
                            user.RestUrl = JiraTransform.ToUri(prop.Value); break;
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
                            group.RestUrl = JiraTransform.ToUri(prop.Value); break;
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
                            version.RestUrl = JiraTransform.ToUri(prop.Value); break;
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
                            filter.RestUrl = JiraTransform.ToUri(prop.Value); break;
                        case "ViewUrl": case "viewUrl":
                            filter.ViewUrl = JiraTransform.ToUri(prop.Value); break;
                        case "SearchUrl": case "SearchURL": case "searchUrl":
                            filter.SearchUrl = JiraTransform.ToUri(prop.Value); break;
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
                            project.RestUrl = JiraTransform.ToUri(prop.Value); break;
                        case "Style": case "style":
                            project.Style = prop.Value as string; break;
                        case "ProjectTypeKey": case "projectTypeKey":
                            project.ProjectTypeKey = prop.Value as string; break;
                        case "Url": case "url":
                            project.Url = JiraTransform.ToUri(prop.Value); break;
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
