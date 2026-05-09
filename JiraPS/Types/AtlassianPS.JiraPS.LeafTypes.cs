// Leaf Jira domain objects: Status, Priority, IssueType, Component, Attachment, etc.
// These types are referenced by the core types but are not identity-comparable.

using System;

namespace AtlassianPS.JiraPS
{

    // StatusCategory, CreateMetaField, and EditMetaField have convenience
    // string constructors for direct PowerShell construction but are not
    // used as cmdlet parameter types, so they have no transformation attribute.
    public class StatusCategory
    {
        public long? Id { get; set; }
        public string Key { get; set; }
        public string Name { get; set; }
        public string ColorName { get; set; }
        public Uri RestUrl { get; set; }

        public StatusCategory() { }

        public StatusCategory(string name)
        {
            if (string.IsNullOrWhiteSpace(name))
            {
                throw new ArgumentException("name must not be null, empty, or whitespace.", "name");
            }
            Name = name;
        }

        public override string ToString()
        {
            return Name ?? string.Empty;
        }
    }

    public class Status
    {
        public long? Id { get; set; }
        public string Name { get; set; }
        public string Description { get; set; }
        public Uri IconUrl { get; set; }
        public Uri RestUrl { get; set; }
        public StatusCategory StatusCategory { get; set; }

        public Status() { }

        public Status(string name)
        {
            if (string.IsNullOrWhiteSpace(name))
            {
                throw new ArgumentException("name must not be null, empty, or whitespace.", "name");
            }
            Name = name;
        }

        public override string ToString()
        {
            return Name ?? string.Empty;
        }
    }

    public class Priority
    {
        public long? Id { get; set; }
        public string Name { get; set; }
        public string Description { get; set; }
        public string StatusColor { get; set; }
        public Uri IconUrl { get; set; }
        public Uri RestUrl { get; set; }

        public Priority() { }

        public Priority(string name)
        {
            if (string.IsNullOrWhiteSpace(name))
            {
                throw new ArgumentException("name must not be null, empty, or whitespace.", "name");
            }
            Name = name;
        }

        public override string ToString()
        {
            return Name ?? string.Empty;
        }
    }

    public class Resolution
    {
        public string Id { get; set; }
        public string Name { get; set; }
        public string Description { get; set; }
        public Uri RestUrl { get; set; }

        public Resolution() { }

        public Resolution(string name)
        {
            if (string.IsNullOrWhiteSpace(name))
            {
                throw new ArgumentException("name must not be null, empty, or whitespace.", "name");
            }
            Name = name;
        }

        public override string ToString()
        {
            return Name ?? string.Empty;
        }
    }

    public class IssueType
    {
        public long? Id { get; set; }
        public string Name { get; set; }
        public string Description { get; set; }
        public Uri IconUrl { get; set; }
        public Uri RestUrl { get; set; }
        public bool Subtask { get; set; }
        public long? AvatarId { get; set; }
        public int? HierarchyLevel { get; set; }
        public object Scope { get; set; }

        public IssueType() { }

        public IssueType(string name)
        {
            if (string.IsNullOrWhiteSpace(name))
            {
                throw new ArgumentException("name must not be null, empty, or whitespace.", "name");
            }
            Name = name;
        }

        public override string ToString()
        {
            return Name ?? string.Empty;
        }
    }

    public class Component
    {
        public string Id { get; set; }
        public string Name { get; set; }
        public Uri RestUrl { get; set; }
        public User Lead { get; set; }
        public string LeadDisplayName { get; set; }
        public string ProjectName { get; set; }
        public string ProjectId { get; set; }
        public string Description { get; set; }
        public string AssigneeType { get; set; }
        public string RealAssigneeType { get; set; }
        public bool? IsAssigneeTypeValid { get; set; }

        public Component() { }

        public Component(string name)
        {
            if (string.IsNullOrWhiteSpace(name))
            {
                throw new ArgumentException("name must not be null, empty, or whitespace.", "name");
            }
            Name = name;
        }

        public override string ToString()
        {
            return Name ?? string.Empty;
        }
    }

    public class Field
    {
        public string Id { get; set; }
        public string Name { get; set; }
        public bool Custom { get; set; }
        public bool Orderable { get; set; }
        public bool Navigable { get; set; }
        public bool Searchable { get; set; }
        public string[] ClauseNames { get; set; }
        public object Schema { get; set; }

        public Field() { }

        public Field(string idOrName)
        {
            if (string.IsNullOrWhiteSpace(idOrName))
            {
                throw new ArgumentException("idOrName must not be null, empty, or whitespace.", "idOrName");
            }
            Id = idOrName;
        }

        public override string ToString()
        {
            return Name ?? string.Empty;
        }
    }

    public class IssueLinkType
    {
        public string Id { get; set; }
        public string Name { get; set; }
        public string InwardText { get; set; }
        public string OutwardText { get; set; }
        public Uri RestUrl { get; set; }

        public IssueLinkType() { }

        public IssueLinkType(string name)
        {
            if (string.IsNullOrWhiteSpace(name))
            {
                throw new ArgumentException("name must not be null, empty, or whitespace.", "name");
            }
            Name = name;
        }

        public override string ToString()
        {
            return Name ?? string.Empty;
        }
    }

    public class IssueLink
    {
        public long? Id { get; set; }
        public IssueLinkType Type { get; set; }
        public Issue InwardIssue { get; set; }
        public Issue OutwardIssue { get; set; }

        public IssueLink() { }

        public IssueLink(string id)
        {
            if (string.IsNullOrWhiteSpace(id))
            {
                throw new ArgumentException("id must not be null, empty, or whitespace.", "id");
            }
            long parsed;
            if (long.TryParse(id, System.Globalization.NumberStyles.Integer, System.Globalization.CultureInfo.InvariantCulture, out parsed))
            {
                Id = parsed;
            }
        }

        public override string ToString()
        {
            return Id.HasValue ? Id.Value.ToString(System.Globalization.CultureInfo.InvariantCulture) : string.Empty;
        }
    }

    public class Attachment
    {
        public string Id { get; set; }
        public Uri Self { get; set; }
        public string FileName { get; set; }
        public User Author { get; set; }
        public DateTimeOffset? Created { get; set; }
        public long? Size { get; set; }
        public string MimeType { get; set; }
        public Uri Content { get; set; }
        public Uri Thumbnail { get; set; }

        public Attachment() { }

        public Attachment(string id)
        {
            if (string.IsNullOrWhiteSpace(id))
            {
                throw new ArgumentException("id must not be null, empty, or whitespace.", "id");
            }
            Id = id;
        }

        public override string ToString()
        {
            return FileName ?? string.Empty;
        }
    }

    public class Worklogitem
    {
        public long? Id { get; set; }
        public object Visibility { get; set; }
        public string Comment { get; set; }
        public Uri RestUrl { get; set; }
        public User Author { get; set; }
        public User UpdateAuthor { get; set; }
        public DateTimeOffset? Created { get; set; }
        public DateTimeOffset? Updated { get; set; }
        public DateTimeOffset? Started { get; set; }
        public string TimeSpent { get; set; }
        public long? TimeSpentSeconds { get; set; }

        public Worklogitem() { }

        public Worklogitem(string id)
        {
            if (string.IsNullOrWhiteSpace(id))
            {
                throw new ArgumentException("id must not be null, empty, or whitespace.", "id");
            }
            long parsed;
            if (long.TryParse(id, System.Globalization.NumberStyles.Integer, System.Globalization.CultureInfo.InvariantCulture, out parsed))
            {
                Id = parsed;
            }
        }

        public override string ToString()
        {
            return Id.HasValue ? Id.Value.ToString(System.Globalization.CultureInfo.InvariantCulture) : string.Empty;
        }
    }

    public class Transition
    {
        public long? Id { get; set; }
        public string Name { get; set; }
        public Status ResultStatus { get; set; }

        public Transition() { }

        public Transition(string nameOrId)
        {
            if (string.IsNullOrWhiteSpace(nameOrId))
            {
                throw new ArgumentException("nameOrId must not be null, empty, or whitespace.", "nameOrId");
            }
            long parsed;
            if (long.TryParse(nameOrId, System.Globalization.NumberStyles.Integer, System.Globalization.CultureInfo.InvariantCulture, out parsed))
            {
                Id = parsed;
            }
            else
            {
                Name = nameOrId;
            }
        }

        public override string ToString()
        {
            return Name ?? string.Empty;
        }
    }

    public class Link
    {
        public long? Id { get; set; }
        public Uri RestUrl { get; set; }
        public string GlobalId { get; set; }
        public object Application { get; set; }
        public string Relationship { get; set; }
        // Jira wire field `object`; renamed to avoid shadowing System.Object.
        public object RemoteObject { get; set; }

        public Link() { }

        public Link(string id)
        {
            if (string.IsNullOrWhiteSpace(id))
            {
                throw new ArgumentException("id must not be null, empty, or whitespace.", "id");
            }
            long parsed;
            if (long.TryParse(id, System.Globalization.NumberStyles.Integer, System.Globalization.CultureInfo.InvariantCulture, out parsed))
            {
                Id = parsed;
            }
        }

        public override string ToString()
        {
            return Id.HasValue ? Id.Value.ToString(System.Globalization.CultureInfo.InvariantCulture) : string.Empty;
        }
    }

    public class ProjectRole
    {
        public long? Id { get; set; }
        public string Name { get; set; }
        public string Description { get; set; }
        public object Actors { get; set; }
        public Uri RestUrl { get; set; }

        public ProjectRole() { }

        public ProjectRole(string name)
        {
            if (string.IsNullOrWhiteSpace(name))
            {
                throw new ArgumentException("name must not be null, empty, or whitespace.", "name");
            }
            long parsed;
            if (long.TryParse(name, System.Globalization.NumberStyles.Integer, System.Globalization.CultureInfo.InvariantCulture, out parsed))
            {
                Id = parsed;
            }
            else
            {
                Name = name;
            }
        }

        public override string ToString()
        {
            return Name ?? string.Empty;
        }
    }

    public class FilterPermission
    {
        public long? Id { get; set; }
        public string Type { get; set; }
        public Group Group { get; set; }
        public Project Project { get; set; }
        public ProjectRole Role { get; set; }

        public FilterPermission() { }

        public FilterPermission(string id)
        {
            if (string.IsNullOrWhiteSpace(id))
            {
                throw new ArgumentException("id must not be null, empty, or whitespace.", "id");
            }
            long parsed;
            if (long.TryParse(id, System.Globalization.NumberStyles.Integer, System.Globalization.CultureInfo.InvariantCulture, out parsed))
            {
                Id = parsed;
            }
        }

        public override string ToString()
        {
            return Type ?? string.Empty;
        }
    }

    public class CreateMetaField
    {
        public string Id { get; set; }
        public string Name { get; set; }
        public bool HasDefaultValue { get; set; }
        public bool Required { get; set; }
        public object Schema { get; set; }
        public object Operations { get; set; }
        public object AllowedValues { get; set; }
        public Uri AutoCompleteUrl { get; set; }

        public CreateMetaField() { }

        public CreateMetaField(string id)
        {
            if (string.IsNullOrWhiteSpace(id))
            {
                throw new ArgumentException("id must not be null, empty, or whitespace.", "id");
            }
            Id = id;
        }

        public override string ToString()
        {
            return Name ?? string.Empty;
        }
    }

    // Structurally identical to CreateMetaField; the subclass exists solely
    // for type discrimination so callers can distinguish create-screen vs
    // edit-screen metadata with `$field -is [EditMetaField]`.
    public class EditMetaField : CreateMetaField
    {
        public EditMetaField() { }

        public EditMetaField(string id) : base(id) { }
    }
}
