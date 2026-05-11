// Argument-transformation attributes for JiraPS cmdlet parameters.
// Loaded once at module import via Add-Type from JiraPS.psm1 (#region Dependencies).

using System;

namespace AtlassianPS.JiraPS
{

    [AttributeUsage(AttributeTargets.Property | AttributeTargets.Field | AttributeTargets.Parameter, AllowMultiple = false)]
    public sealed class StatusTransformationAttribute : JiraTransformationAttribute
    {
        protected override Type TargetType { get { return typeof(Status); } }
        protected override object FromString(string value) { return new Status(value); }
    }

    [AttributeUsage(AttributeTargets.Property | AttributeTargets.Field | AttributeTargets.Parameter, AllowMultiple = false)]
    public sealed class PriorityTransformationAttribute : JiraTransformationAttribute
    {
        protected override Type TargetType { get { return typeof(Priority); } }
        protected override object FromString(string value) { return new Priority(value); }
    }

    [AttributeUsage(AttributeTargets.Property | AttributeTargets.Field | AttributeTargets.Parameter, AllowMultiple = false)]
    public sealed class ResolutionTransformationAttribute : JiraTransformationAttribute
    {
        protected override Type TargetType { get { return typeof(Resolution); } }
        protected override object FromString(string value) { return new Resolution(value); }
    }

    [AttributeUsage(AttributeTargets.Property | AttributeTargets.Field | AttributeTargets.Parameter, AllowMultiple = false)]
    public sealed class IssueTypeTransformationAttribute : JiraTransformationAttribute
    {
        protected override Type TargetType { get { return typeof(IssueType); } }
        protected override object FromString(string value) { return new IssueType(value); }
    }

    [AttributeUsage(AttributeTargets.Property | AttributeTargets.Field | AttributeTargets.Parameter, AllowMultiple = false)]
    public sealed class ComponentTransformationAttribute : JiraTransformationAttribute
    {
        protected override Type TargetType { get { return typeof(Component); } }
        protected override object FromString(string value) { return new Component(value); }
    }

    [AttributeUsage(AttributeTargets.Property | AttributeTargets.Field | AttributeTargets.Parameter, AllowMultiple = false)]
    public sealed class FieldTransformationAttribute : JiraTransformationAttribute
    {
        protected override Type TargetType { get { return typeof(Field); } }
        protected override object FromString(string value) { return new Field(value); }
    }

    [AttributeUsage(AttributeTargets.Property | AttributeTargets.Field | AttributeTargets.Parameter, AllowMultiple = false)]
    public sealed class IssueLinkTypeTransformationAttribute : JiraTransformationAttribute
    {
        protected override Type TargetType { get { return typeof(IssueLinkType); } }
        protected override object FromString(string value) { return new IssueLinkType(value); }
        protected override object FromNumericScalar(long value)
        {
            return new IssueLinkType { Id = value.ToString(System.Globalization.CultureInfo.InvariantCulture) };
        }

        protected override string[] LegacyTypeNames { get { return new[] { "AtlassianPS.JiraPS.IssueLinkType", "JiraPS.IssueLinkType" }; } }

        protected override object MapLegacyObject(System.Management.Automation.PSObject pso)
        {
            var issueLinkType = new IssueLinkType();
            foreach (var prop in pso.Properties)
            {
                switch (prop.Name)
                {
                    case "ID": case "Id": case "id": issueLinkType.Id = prop.Value as string ?? (prop.Value != null ? prop.Value.ToString() : null); break;
                    case "Name": case "name": issueLinkType.Name = prop.Value as string; break;
                    case "InwardText": case "inwardText": issueLinkType.InwardText = prop.Value as string; break;
                    case "OutwardText": case "outwardText": issueLinkType.OutwardText = prop.Value as string; break;
                    case "RestUrl": case "RestURL": case "self":
                        issueLinkType.RestUrl = JiraTransform.ToUri(prop.Value); break;
                }
            }
            return issueLinkType;
        }
    }

    [AttributeUsage(AttributeTargets.Property | AttributeTargets.Field | AttributeTargets.Parameter, AllowMultiple = false)]
    public sealed class IssueLinkTransformationAttribute : JiraTransformationAttribute
    {
        protected override Type TargetType { get { return typeof(IssueLink); } }
        protected override object FromString(string value) { return new IssueLink(value); }

        protected override string[] LegacyTypeNames { get { return new[] { "AtlassianPS.JiraPS.IssueLink", "JiraPS.IssueLink" }; } }

        protected override bool ShouldMapLegacyObject(System.Management.Automation.PSObject pso)
        {
            if (base.ShouldMapLegacyObject(pso)) { return true; }
            if (pso == null || pso.Properties == null) { return false; }

            return HasProperty(pso, "type")
                || HasProperty(pso, "inwardIssue")
                || HasProperty(pso, "outwardIssue");
        }

        protected override object MapLegacyObject(System.Management.Automation.PSObject pso)
        {
            var issueLink = new IssueLink();
            var hasKnownShape = false;

            foreach (var prop in pso.Properties)
            {
                switch (prop.Name)
                {
                    case "ID":
                    case "Id":
                    case "id":
                        if (prop.Value != null)
                        {
                            long parsedId;
                            if (long.TryParse(prop.Value.ToString(), out parsedId)) { issueLink.Id = parsedId; }
                        }
                        hasKnownShape = true;
                        break;
                    case "Type":
                    case "type":
                        issueLink.Type = MapIssueLinkType(prop.Value, prop.Name);
                        hasKnownShape = true;
                        break;
                    case "InwardIssue":
                    case "inwardIssue":
                        issueLink.InwardIssue = MapIssue(prop.Value, prop.Name);
                        hasKnownShape = true;
                        break;
                    case "OutwardIssue":
                    case "outwardIssue":
                        issueLink.OutwardIssue = MapIssue(prop.Value, prop.Name);
                        hasKnownShape = true;
                        break;
                }
            }

            if (!hasKnownShape)
            {
                throw new System.Management.Automation.ArgumentTransformationMetadataException(
                    "Cannot convert value to AtlassianPS.JiraPS.IssueLink. Expected an issue-link object shape with id, type, inwardIssue, or outwardIssue properties.");
            }

            return issueLink;
        }

        private static bool HasProperty(System.Management.Automation.PSObject pso, string name)
        {
            foreach (var prop in pso.Properties)
            {
                if (string.Equals(prop.Name, name, StringComparison.OrdinalIgnoreCase)) { return true; }
            }
            return false;
        }

        private static IssueLinkType MapIssueLinkType(object value, string propertyName)
        {
            if (value == null)
            {
                throw new System.Management.Automation.ArgumentTransformationMetadataException(
                    "IssueLink property '" + propertyName + "' must not be null.");
            }

            var typed = value as IssueLinkType;
            if (typed != null) { return typed; }

            var text = value as string;
            if (!string.IsNullOrWhiteSpace(text))
            {
                return new IssueLinkType(text);
            }
            if (text != null)
            {
                throw new System.Management.Automation.ArgumentTransformationMetadataException(
                    "IssueLink property '" + propertyName + "' cannot be empty or whitespace.");
            }

            var pso = value as System.Management.Automation.PSObject;
            if (pso != null)
            {
                var mapped = new IssueLinkType();
                var hasName = false;
                var hasId = false;
                foreach (var prop in pso.Properties)
                {
                    switch (prop.Name)
                    {
                        case "ID":
                        case "Id":
                        case "id":
                            mapped.Id = prop.Value != null ? prop.Value.ToString() : null;
                            hasId = !string.IsNullOrWhiteSpace(mapped.Id);
                            break;
                        case "Name":
                        case "name":
                            mapped.Name = prop.Value as string;
                            hasName = !string.IsNullOrWhiteSpace(mapped.Name);
                            break;
                        case "InwardText":
                        case "inwardText":
                            mapped.InwardText = prop.Value as string;
                            break;
                        case "OutwardText":
                        case "outwardText":
                            mapped.OutwardText = prop.Value as string;
                            break;
                    }
                }

                if (!hasName && !hasId)
                {
                    throw new System.Management.Automation.ArgumentTransformationMetadataException(
                        "IssueLink property '" + propertyName + "' must include either a non-empty 'name' or 'id'.");
                }
                return mapped;
            }

            throw new System.Management.Automation.ArgumentTransformationMetadataException(
                "IssueLink property '" + propertyName + "' must be a string, AtlassianPS.JiraPS.IssueLinkType, or object with 'name'/'id'.");
        }

        private static Issue MapIssue(object value, string propertyName)
        {
            if (value == null)
            {
                throw new System.Management.Automation.ArgumentTransformationMetadataException(
                    "IssueLink property '" + propertyName + "' must not be null.");
            }

            var typed = value as Issue;
            if (typed != null) { return typed; }

            var text = value as string;
            if (!string.IsNullOrWhiteSpace(text))
            {
                return new Issue(text);
            }
            if (text != null)
            {
                throw new System.Management.Automation.ArgumentTransformationMetadataException(
                    "IssueLink property '" + propertyName + "' cannot be empty or whitespace.");
            }

            var pso = value as System.Management.Automation.PSObject;
            if (pso != null)
            {
                var mapped = new Issue();
                var hasKey = false;
                var hasId = false;
                foreach (var prop in pso.Properties)
                {
                    switch (prop.Name)
                    {
                        case "ID":
                        case "Id":
                        case "id":
                            mapped.Id = prop.Value != null ? prop.Value.ToString() : null;
                            hasId = !string.IsNullOrWhiteSpace(mapped.Id);
                            break;
                        case "Key":
                        case "key":
                            mapped.Key = prop.Value as string;
                            hasKey = !string.IsNullOrWhiteSpace(mapped.Key);
                            break;
                    }
                }

                if (!hasKey && !hasId)
                {
                    throw new System.Management.Automation.ArgumentTransformationMetadataException(
                        "IssueLink property '" + propertyName + "' must include either a non-empty 'key' or 'id'.");
                }
                return mapped;
            }

            throw new System.Management.Automation.ArgumentTransformationMetadataException(
                "IssueLink property '" + propertyName + "' must be a string, AtlassianPS.JiraPS.Issue, or object with 'key'/'id'.");
        }
    }

    [AttributeUsage(AttributeTargets.Property | AttributeTargets.Field | AttributeTargets.Parameter, AllowMultiple = false)]
    public sealed class IssueLinkCreateRequestTransformationAttribute : JiraTransformationAttribute
    {
        protected override Type TargetType { get { return typeof(IssueLinkCreateRequest); } }

        protected override object FromString(string value)
        {
            throw new System.Management.Automation.ArgumentTransformationMetadataException(
                "Cannot convert a string to AtlassianPS.JiraPS.IssueLinkCreateRequest. Supply an AtlassianPS.JiraPS.IssueLinkCreateRequest object or an object with 'type', 'inwardIssue', or 'outwardIssue' properties.");
        }

        protected override string[] LegacyTypeNames { get { return new[] { "AtlassianPS.JiraPS.IssueLinkCreateRequest" }; } }

        protected override bool ShouldMapLegacyObject(System.Management.Automation.PSObject pso)
        {
            if (base.ShouldMapLegacyObject(pso)) { return true; }
            if (pso == null || pso.Properties == null) { return false; }

            return HasProperty(pso, "type")
                || HasProperty(pso, "inwardIssue")
                || HasProperty(pso, "outwardIssue");
        }

        protected override object MapLegacyObject(System.Management.Automation.PSObject pso)
        {
            var request = new IssueLinkCreateRequest();
            var hasKnownShape = false;

            foreach (var prop in pso.Properties)
            {
                switch (prop.Name)
                {
                    case "Type":
                    case "type":
                        request.Type = MapIssueLinkTypeRef(prop.Value, prop.Name);
                        hasKnownShape = true;
                        break;
                    case "InwardIssue":
                    case "inwardIssue":
                        request.InwardIssue = MapLinkedIssueRef(prop.Value, prop.Name);
                        hasKnownShape = true;
                        break;
                    case "OutwardIssue":
                    case "outwardIssue":
                        request.OutwardIssue = MapLinkedIssueRef(prop.Value, prop.Name);
                        hasKnownShape = true;
                        break;
                }
            }

            if (!hasKnownShape)
            {
                throw new System.Management.Automation.ArgumentTransformationMetadataException(
                    "Cannot convert value to AtlassianPS.JiraPS.IssueLinkCreateRequest. Expected an issue-link create object shape with type, inwardIssue, or outwardIssue properties.");
            }

            return request;
        }

        private static bool HasProperty(System.Management.Automation.PSObject pso, string name)
        {
            foreach (var prop in pso.Properties)
            {
                if (string.Equals(prop.Name, name, StringComparison.OrdinalIgnoreCase)) { return true; }
            }
            return false;
        }

        private static IssueLinkTypeRef MapIssueLinkTypeRef(object value, string propertyName)
        {
            if (value == null)
            {
                throw new System.Management.Automation.ArgumentTransformationMetadataException(
                    "IssueLinkCreateRequest property '" + propertyName + "' must not be null.");
            }

            var typed = value as IssueLinkTypeRef;
            if (typed != null) { return typed; }

            var legacyTyped = value as IssueLinkType;
            if (legacyTyped != null)
            {
                return new IssueLinkTypeRef { Id = legacyTyped.Id, Name = legacyTyped.Name };
            }

            var text = value as string;
            if (!string.IsNullOrWhiteSpace(text))
            {
                return new IssueLinkTypeRef { Name = text };
            }
            if (text != null)
            {
                throw new System.Management.Automation.ArgumentTransformationMetadataException(
                    "IssueLinkCreateRequest property '" + propertyName + "' cannot be empty or whitespace.");
            }

            var pso = value as System.Management.Automation.PSObject;
            if (pso != null)
            {
                var mapped = new IssueLinkTypeRef();
                var hasName = false;
                var hasId = false;
                foreach (var prop in pso.Properties)
                {
                    switch (prop.Name)
                    {
                        case "ID":
                        case "Id":
                        case "id":
                            mapped.Id = prop.Value != null ? prop.Value.ToString() : null;
                            hasId = !string.IsNullOrWhiteSpace(mapped.Id);
                            break;
                        case "Name":
                        case "name":
                            mapped.Name = prop.Value as string;
                            hasName = !string.IsNullOrWhiteSpace(mapped.Name);
                            break;
                    }
                }

                if (!hasName && !hasId)
                {
                    throw new System.Management.Automation.ArgumentTransformationMetadataException(
                        "IssueLinkCreateRequest property '" + propertyName + "' must include either a non-empty 'name' or 'id'.");
                }
                return mapped;
            }

            var dict = value as System.Collections.IDictionary;
            if (dict != null)
            {
                var mapped = new IssueLinkTypeRef();
                var hasName = false;
                var hasId = false;
                foreach (System.Collections.DictionaryEntry entry in dict)
                {
                    var key = entry.Key != null ? entry.Key.ToString() : string.Empty;
                    switch (key)
                    {
                        case "ID":
                        case "Id":
                        case "id":
                            mapped.Id = entry.Value != null ? entry.Value.ToString() : null;
                            hasId = !string.IsNullOrWhiteSpace(mapped.Id);
                            break;
                        case "Name":
                        case "name":
                            mapped.Name = entry.Value != null ? entry.Value.ToString() : null;
                            hasName = !string.IsNullOrWhiteSpace(mapped.Name);
                            break;
                    }
                }

                if (!hasName && !hasId)
                {
                    throw new System.Management.Automation.ArgumentTransformationMetadataException(
                        "IssueLinkCreateRequest property '" + propertyName + "' must include either a non-empty 'name' or 'id'.");
                }
                return mapped;
            }

            throw new System.Management.Automation.ArgumentTransformationMetadataException(
                "IssueLinkCreateRequest property '" + propertyName + "' must be a string, AtlassianPS.JiraPS.IssueLinkTypeRef, or object with 'name'/'id'.");
        }

        private static LinkedIssueRef MapLinkedIssueRef(object value, string propertyName)
        {
            if (value == null)
            {
                throw new System.Management.Automation.ArgumentTransformationMetadataException(
                    "IssueLinkCreateRequest property '" + propertyName + "' must not be null.");
            }

            var typed = value as LinkedIssueRef;
            if (typed != null) { return typed; }

            var legacyIssue = value as Issue;
            if (legacyIssue != null)
            {
                return new LinkedIssueRef { Id = legacyIssue.Id, Key = legacyIssue.Key };
            }

            var legacyIssueRef = value as IssueLink;
            if (legacyIssueRef != null)
            {
                if (legacyIssueRef.OutwardIssue != null)
                {
                    return new LinkedIssueRef { Id = legacyIssueRef.OutwardIssue.Id, Key = legacyIssueRef.OutwardIssue.Key };
                }
                if (legacyIssueRef.InwardIssue != null)
                {
                    return new LinkedIssueRef { Id = legacyIssueRef.InwardIssue.Id, Key = legacyIssueRef.InwardIssue.Key };
                }
            }

            var text = value as string;
            if (!string.IsNullOrWhiteSpace(text))
            {
                return new LinkedIssueRef { Key = text };
            }
            if (text != null)
            {
                throw new System.Management.Automation.ArgumentTransformationMetadataException(
                    "IssueLinkCreateRequest property '" + propertyName + "' cannot be empty or whitespace.");
            }

            var pso = value as System.Management.Automation.PSObject;
            if (pso != null)
            {
                var mapped = new LinkedIssueRef();
                var hasKey = false;
                var hasId = false;
                foreach (var prop in pso.Properties)
                {
                    switch (prop.Name)
                    {
                        case "ID":
                        case "Id":
                        case "id":
                            mapped.Id = prop.Value != null ? prop.Value.ToString() : null;
                            hasId = !string.IsNullOrWhiteSpace(mapped.Id);
                            break;
                        case "Key":
                        case "key":
                            mapped.Key = prop.Value as string;
                            hasKey = !string.IsNullOrWhiteSpace(mapped.Key);
                            break;
                    }
                }

                if (!hasKey && !hasId)
                {
                    throw new System.Management.Automation.ArgumentTransformationMetadataException(
                        "IssueLinkCreateRequest property '" + propertyName + "' must include either a non-empty 'key' or 'id'.");
                }
                return mapped;
            }

            var dict = value as System.Collections.IDictionary;
            if (dict != null)
            {
                var mapped = new LinkedIssueRef();
                var hasKey = false;
                var hasId = false;
                foreach (System.Collections.DictionaryEntry entry in dict)
                {
                    var key = entry.Key != null ? entry.Key.ToString() : string.Empty;
                    switch (key)
                    {
                        case "ID":
                        case "Id":
                        case "id":
                            mapped.Id = entry.Value != null ? entry.Value.ToString() : null;
                            hasId = !string.IsNullOrWhiteSpace(mapped.Id);
                            break;
                        case "Key":
                        case "key":
                            mapped.Key = entry.Value != null ? entry.Value.ToString() : null;
                            hasKey = !string.IsNullOrWhiteSpace(mapped.Key);
                            break;
                    }
                }

                if (!hasKey && !hasId)
                {
                    throw new System.Management.Automation.ArgumentTransformationMetadataException(
                        "IssueLinkCreateRequest property '" + propertyName + "' must include either a non-empty 'key' or 'id'.");
                }
                return mapped;
            }

            throw new System.Management.Automation.ArgumentTransformationMetadataException(
                "IssueLinkCreateRequest property '" + propertyName + "' must be a string, AtlassianPS.JiraPS.LinkedIssueRef, or object with 'key'/'id'.");
        }
    }

    [AttributeUsage(AttributeTargets.Property | AttributeTargets.Field | AttributeTargets.Parameter, AllowMultiple = false)]
    public sealed class AttachmentTransformationAttribute : JiraTransformationAttribute
    {
        protected override Type TargetType { get { return typeof(Attachment); } }
        protected override object FromString(string value) { return new Attachment(value); }
    }

    [AttributeUsage(AttributeTargets.Property | AttributeTargets.Field | AttributeTargets.Parameter, AllowMultiple = false)]
    public sealed class WorklogitemTransformationAttribute : JiraTransformationAttribute
    {
        protected override Type TargetType { get { return typeof(Worklogitem); } }
        protected override object FromString(string value) { return new Worklogitem(value); }
    }

    [AttributeUsage(AttributeTargets.Property | AttributeTargets.Field | AttributeTargets.Parameter, AllowMultiple = false)]
    public sealed class TransitionTransformationAttribute : JiraTransformationAttribute
    {
        protected override Type TargetType { get { return typeof(Transition); } }
        protected override object FromString(string value) { return new Transition(value); }
    }

    [AttributeUsage(AttributeTargets.Property | AttributeTargets.Field | AttributeTargets.Parameter, AllowMultiple = false)]
    public sealed class LinkTransformationAttribute : JiraTransformationAttribute
    {
        protected override Type TargetType { get { return typeof(Link); } }
        protected override object FromString(string value) { return new Link(value); }
    }

    [AttributeUsage(AttributeTargets.Property | AttributeTargets.Field | AttributeTargets.Parameter, AllowMultiple = false)]
    public sealed class ProjectRoleTransformationAttribute : JiraTransformationAttribute
    {
        protected override Type TargetType { get { return typeof(ProjectRole); } }
        protected override object FromString(string value) { return new ProjectRole(value); }
    }

    [AttributeUsage(AttributeTargets.Property | AttributeTargets.Field | AttributeTargets.Parameter, AllowMultiple = false)]
    public sealed class FilterPermissionTransformationAttribute : JiraTransformationAttribute
    {
        protected override Type TargetType { get { return typeof(FilterPermission); } }
        protected override object FromString(string value) { return new FilterPermission(value); }
    }

    // Singular [Issue] parameters must not auto-iterate arrays; callers
    // pipeline-iterate instead. All other core transformers fan out.
    [AttributeUsage(AttributeTargets.Property | AttributeTargets.Field | AttributeTargets.Parameter, AllowMultiple = false)]
    public sealed class IssueTransformationAttribute : JiraTransformationAttribute
    {
        protected override Type TargetType { get { return typeof(Issue); } }
        protected override bool UseFanOut { get { return false; } }
        protected override object FromString(string value) { return new Issue(value); }

        protected override string[] LegacyTypeNames { get { return new[] { "AtlassianPS.JiraPS.Issue" }; } }

        protected override object MapLegacyObject(System.Management.Automation.PSObject pso)
        {
            var issue = new Issue();
            foreach (var prop in pso.Properties)
            {
                switch (prop.Name)
                {
                    case "ID": case "Id": case "id": issue.Id = prop.Value as string; break;
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
    }

    [AttributeUsage(AttributeTargets.Property | AttributeTargets.Field | AttributeTargets.Parameter, AllowMultiple = false)]
    public sealed class UserTransformationAttribute : JiraTransformationAttribute
    {
        protected override Type TargetType { get { return typeof(User); } }
        protected override object FromString(string value) { return new User(value); }

        protected override string[] LegacyTypeNames { get { return new[] { "AtlassianPS.JiraPS.User" }; } }

        protected override object MapLegacyObject(System.Management.Automation.PSObject pso)
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
    }

    [AttributeUsage(AttributeTargets.Property | AttributeTargets.Field | AttributeTargets.Parameter, AllowMultiple = false)]
    public sealed class GroupTransformationAttribute : JiraTransformationAttribute
    {
        protected override Type TargetType { get { return typeof(Group); } }
        protected override object FromString(string value) { return new Group(value); }

        protected override string[] LegacyTypeNames { get { return new[] { "AtlassianPS.JiraPS.Group", "JiraPS.Group" }; } }

        protected override object MapLegacyObject(System.Management.Automation.PSObject pso)
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
    }

    [AttributeUsage(AttributeTargets.Property | AttributeTargets.Field | AttributeTargets.Parameter, AllowMultiple = false)]
    public sealed class VersionTransformationAttribute : JiraTransformationAttribute
    {
        protected override Type TargetType { get { return typeof(Version); } }
        protected override object FromString(string value) { return new Version(value); }

        protected override object FromNumericScalar(long value)
        {
            return new Version { Id = value.ToString(System.Globalization.CultureInfo.InvariantCulture) };
        }

        protected override string[] LegacyTypeNames { get { return new[] { "AtlassianPS.JiraPS.Version", "JiraPS.Version" }; } }

        protected override object MapLegacyObject(System.Management.Automation.PSObject pso)
        {
            var version = new Version();
            foreach (var prop in pso.Properties)
            {
                switch (prop.Name)
                {
                    case "ID": case "Id": case "id": version.Id = prop.Value as string ?? (prop.Value != null ? prop.Value.ToString() : null); break;
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
    }

    [AttributeUsage(AttributeTargets.Property | AttributeTargets.Field | AttributeTargets.Parameter, AllowMultiple = false)]
    public sealed class FilterTransformationAttribute : JiraTransformationAttribute
    {
        protected override Type TargetType { get { return typeof(Filter); } }
        protected override object FromString(string value) { return new Filter(value); }

        protected override object FromNumericScalar(long value)
        {
            return new Filter { Id = value.ToString(System.Globalization.CultureInfo.InvariantCulture) };
        }

        protected override string[] LegacyTypeNames { get { return new[] { "AtlassianPS.JiraPS.Filter", "JiraPS.Filter" }; } }

        protected override object MapLegacyObject(System.Management.Automation.PSObject pso)
        {
            var filter = new Filter();
            foreach (var prop in pso.Properties)
            {
                switch (prop.Name)
                {
                    case "ID": case "Id": case "id": filter.Id = prop.Value as string ?? (prop.Value != null ? prop.Value.ToString() : null); break;
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
    }

    [AttributeUsage(AttributeTargets.Property | AttributeTargets.Field | AttributeTargets.Parameter, AllowMultiple = false)]
    public sealed class ProjectTransformationAttribute : JiraTransformationAttribute
    {
        protected override Type TargetType { get { return typeof(Project); } }
        protected override object FromString(string value) { return new Project(value); }

        protected override object FromNumericScalar(long value)
        {
            return new Project { Id = value.ToString(System.Globalization.CultureInfo.InvariantCulture) };
        }

        protected override string[] LegacyTypeNames { get { return new[] { "AtlassianPS.JiraPS.Project", "JiraPS.Project" }; } }

        protected override object MapLegacyObject(System.Management.Automation.PSObject pso)
        {
            var project = new Project();
            foreach (var prop in pso.Properties)
            {
                switch (prop.Name)
                {
                    case "ID": case "Id": case "id": project.Id = prop.Value as string ?? (prop.Value != null ? prop.Value.ToString() : null); break;
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
    }
}
