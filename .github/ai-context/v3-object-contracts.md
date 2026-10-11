# JiraPS v3 object model: maintainer reference

This reference is for contributors reviewing or changing the JiraPS object model.
It maps domain properties to converters, public command parameters and regression tests, and records implementation decisions and related work.
User-facing construction and usage examples are in [about_JiraPS_Classes](../../docs/en-US/about_JiraPS_Classes.md).
Migration guidance is in [about_JiraPS_MigrationV3](../../docs/en-US/about_JiraPS_MigrationV3.md).

All domain types below use the `AtlassianPS.JiraPS` namespace.
`T[]` means a CLR array even when a response contains one item.
A missing optional nested value is `$null`; a present empty collection is an empty typed array.
Issue history is `$null` without a changelog expansion and an `IssueHistoryEntry[]` when expanded.
Issue `Assignee` is `User` or `$null`; the string `Unassigned` is no longer returned.
URI fields use `System.Uri` and timestamps use the nullable date type shown below.

## Contract inventory

This inventory includes every property declared on each public domain or request class.
`EditMetaField` also inherits the `CreateMetaField` properties.
Each type lists the converters that construct it, directly or within a containing object.
Producing commands return the class directly or within a declared containing object.
`Set-JiraIssue`, `Set-JiraIssueLabel` and `Invoke-JiraIssueTransition` return an issue when `PassThru` is requested.
Commands using transport `OutputType` conversion are included.
A command that only resolves an object internally is not listed as a producer.
The tests are under `Tests/Functions/Private`, `Tests/Functions/Public`, and `Tests/Functions/Classes`.
`V3CollectionContracts.Unit.Tests.ps1` covers empty collections, raw custom arrays and duplicate-name selectors.
`V3ReturnContracts.Unit.Tests.ps1` verifies the nested types and collections.
`V3ParameterContracts.Unit.Tests.ps1` verifies cross-cmdlet binding, request bodies and regression cases.
The existing `AtlassianPS.JiraPS.Types.Unit.Tests.ps1` and `ConvertTo-Jira.Roundtrip.Unit.Tests.ps1` cover core types and transformer fallthrough.

### `Attachment`

| Property | CLR type |
| --- | --- |
| `Id` | `string` |
| `Self` | `Uri` |
| `FileName` | `string` |
| `Author` | `User` |
| `Created` | `DateTimeOffset?` |
| `Size` | `long?` |
| `MimeType` | `string` |
| `Content` | `Uri` |
| `Thumbnail` | `Uri` |

Converters: `ConvertTo-JiraIssue`, `ConvertTo-JiraAttachment`.

Producing commands: `Add-JiraIssueAttachment`, `Get-JiraIssue`, `Get-JiraIssueAttachment`, `Get-JiraIssueLink`, `Invoke-JiraIssueTransition`, `New-JiraIssue`, `Set-JiraIssue`, `Set-JiraIssueLabel`.

Consuming parameters: `Get-JiraIssueAttachmentFile -Attachment`.

Tests: `ConvertTo-JiraIssue.Unit.Tests.ps1`, `ConvertTo-JiraAttachment.Unit.Tests.ps1`, `AtlassianPS.JiraPS.Types.Unit.Tests.ps1`, `V3ReturnContracts.Unit.Tests.ps1`.

### `Comment`

| Property | CLR type |
| --- | --- |
| `Id` | `string` |
| `Body` | `string` |
| `RenderedBody` | `string` |
| `Visibility` | `Visibility` |
| `Properties` | `EntityProperty[]` |
| `RestUrl` | `Uri` |
| `Author` | `User` |
| `UpdateAuthor` | `User` |
| `Created` | `DateTimeOffset?` |
| `Updated` | `DateTimeOffset?` |

Converters: `ConvertTo-JiraIssue`, `ConvertTo-JiraComment`.

Producing commands: `Add-JiraIssueComment`, `Get-JiraIssue`, `Get-JiraIssueComment`, `Get-JiraIssueLink`, `Invoke-JiraIssueTransition`, `New-JiraIssue`, `Set-JiraIssue`, `Set-JiraIssueLabel`.

No public parameter consumes this record directly.

Tests: `ConvertTo-JiraIssue.Unit.Tests.ps1`, `ConvertTo-JiraComment.Unit.Tests.ps1`, `AtlassianPS.JiraPS.Types.Unit.Tests.ps1`, `V3ReturnContracts.Unit.Tests.ps1`.

### `Component`

| Property | CLR type |
| --- | --- |
| `Id` | `string` |
| `Name` | `string` |
| `RestUrl` | `Uri` |
| `Lead` | `User` |
| `LeadDisplayName` | `string` |
| `ProjectName` | `string` |
| `ProjectId` | `string` |
| `Description` | `string` |
| `AssigneeType` | `AssigneeType?` |
| `RealAssigneeType` | `AssigneeType?` |
| `IsAssigneeTypeValid` | `bool?` |

Converters: `ConvertTo-JiraIssue`, `ConvertTo-JiraComponent`, `ConvertTo-JiraProject`.

Producing commands: `Add-JiraFilterPermission`, `Find-JiraFilter`, `Get-JiraComponent`, `Get-JiraFilter`, `Get-JiraFilterPermission`, `Get-JiraIssue`, `Get-JiraIssueLink`, `Get-JiraIssueType`, `Get-JiraProject`, `Invoke-JiraIssueTransition`, `New-JiraFilter`, `New-JiraIssue`, `Set-JiraFilter`, `Set-JiraIssue`, `Set-JiraIssueLabel`.

Consuming parameters: `New-JiraIssue -Components`.

Tests: `ConvertTo-JiraIssue.Unit.Tests.ps1`, `ConvertTo-JiraComponent.Unit.Tests.ps1`, `ConvertTo-JiraProject.Unit.Tests.ps1`, `AtlassianPS.JiraPS.Types.Unit.Tests.ps1`, `V3ReturnContracts.Unit.Tests.ps1`.

### `CreateMetaField`

| Property | CLR type |
| --- | --- |
| `Id` | `string` |
| `Name` | `string` |
| `HasDefaultValue` | `bool` |
| `Required` | `bool` |
| `Schema` | `FieldSchema` |
| `Operations` | `string[]` |
| `AllowedValues` | `object[]` |
| `AutoCompleteUrl` | `Uri` |

Converters: `ConvertTo-JiraCreateMetaField`.

Producing commands: `Get-JiraIssueCreateMetadata`, `Get-JiraIssueEditMetadata`.

No public parameter consumes this record directly.

Tests: `ConvertTo-JiraCreateMetaField.Unit.Tests.ps1`, `AtlassianPS.JiraPS.Types.Unit.Tests.ps1`, `V3ReturnContracts.Unit.Tests.ps1`.

### `EditMetaField`

Inherits `CreateMetaField`.

Converters: `ConvertTo-JiraEditMetaField`.

Producing commands: `Get-JiraIssueEditMetadata`.

No public parameter consumes this record directly.

Tests: `ConvertTo-JiraEditMetaField.Unit.Tests.ps1`, `AtlassianPS.JiraPS.Types.Unit.Tests.ps1`, `V3ReturnContracts.Unit.Tests.ps1`.

### `EntityProperty`

| Property | CLR type |
| --- | --- |
| `Key` | `string` |
| `Value` | `object` |

Converters: `ConvertTo-JiraComment`.

Producing commands: `Add-JiraIssueComment`, `Get-JiraIssue`, `Get-JiraIssueComment`, `Get-JiraIssueLink`, `Invoke-JiraIssueTransition`, `New-JiraIssue`, `Set-JiraIssue`, `Set-JiraIssueLabel`.

No public parameter consumes this record directly.

Tests: `ConvertTo-JiraComment.Unit.Tests.ps1`, `AtlassianPS.JiraPS.Types.Unit.Tests.ps1`, `V3ReturnContracts.Unit.Tests.ps1`.

### `Field`

| Property | CLR type |
| --- | --- |
| `Id` | `string` |
| `Name` | `string` |
| `Custom` | `bool` |
| `Orderable` | `bool` |
| `Navigable` | `bool` |
| `Searchable` | `bool` |
| `ClauseNames` | `string[]` |
| `Schema` | `FieldSchema` |

Converters: `ConvertTo-JiraField`.

Producing commands: `Get-JiraField`.

Consuming parameters: `Get-JiraField -Field`.

Tests: `ConvertTo-JiraField.Unit.Tests.ps1`, `AtlassianPS.JiraPS.Types.Unit.Tests.ps1`, `V3ReturnContracts.Unit.Tests.ps1`, `V3ParameterContracts.Unit.Tests.ps1`.

### `FieldSchema`

| Property | CLR type |
| --- | --- |
| `Type` | `string` |
| `Items` | `string` |
| `System` | `string` |
| `Custom` | `string` |
| `CustomId` | `long?` |
| `Configuration` | `IDictionary<string, object>` |

Converters: `ConvertTo-JiraFieldSchema`.

Producing commands: `Get-JiraField`, `Get-JiraIssueCreateMetadata`, `Get-JiraIssueEditMetadata`.

No public parameter consumes this record directly.

Tests: `ConvertTo-JiraFieldSchema.Unit.Tests.ps1`, `AtlassianPS.JiraPS.Types.Unit.Tests.ps1`, `V3ReturnContracts.Unit.Tests.ps1`.

### `Filter`

| Property | CLR type |
| --- | --- |
| `Id` | `string` |
| `Name` | `string` |
| `JQL` | `string` |
| `RestUrl` | `Uri` |
| `ViewUrl` | `Uri` |
| `SearchUrl` | `Uri` |
| `Favourite` | `bool` |
| `FilterPermissions` | `FilterPermission[]` |
| `SharePermission` | `FilterPermission[]` |
| `SharedUser` | `UserList` |
| `Subscription` | `FilterSubscriptionList` |
| `Description` | `string` |
| `Owner` | `User` |

Converters: `ConvertTo-JiraFilter`.

Producing commands: `Add-JiraFilterPermission`, `Find-JiraFilter`, `Get-JiraFilter`, `Get-JiraFilterPermission`, `New-JiraFilter`, `Set-JiraFilter`.

Consuming parameters: `Add-JiraFilterPermission -Filter`, `Get-JiraFilterPermission -Filter`, `Remove-JiraFilter -InputObject`, `Remove-JiraFilterPermission -Filter`, `Set-JiraFilter -InputObject`, `Get-JiraFilter -InputObject`, `Get-JiraIssue -Filter`.

Tests: `ConvertTo-JiraFilter.Unit.Tests.ps1`, `AtlassianPS.JiraPS.Types.Unit.Tests.ps1`, `V3ReturnContracts.Unit.Tests.ps1`, `V3ParameterContracts.Unit.Tests.ps1`.

### `FilterPermission`

| Property | CLR type |
| --- | --- |
| `Id` | `long?` |
| `Type` | `FilterShareType?` |
| `User` | `User` |
| `Group` | `Group` |
| `Project` | `Project` |
| `Role` | `ProjectRole` |

Converters: `ConvertTo-JiraFilterPermission`, `ConvertTo-JiraFilter`.

Producing commands: `Add-JiraFilterPermission`, `Find-JiraFilter`, `Get-JiraFilter`, `Get-JiraFilterPermission`, `New-JiraFilter`, `Set-JiraFilter`.

Consuming parameters: `Remove-JiraFilterPermission -Permission`.

Tests: `ConvertTo-JiraFilterPermission.Unit.Tests.ps1`, `ConvertTo-JiraFilter.Unit.Tests.ps1`, `AtlassianPS.JiraPS.Types.Unit.Tests.ps1`, `V3ReturnContracts.Unit.Tests.ps1`, `V3ParameterContracts.Unit.Tests.ps1`.

### `FilterSubscription`

| Property | CLR type |
| --- | --- |
| `Id` | `long?` |
| `User` | `User` |
| `Group` | `Group` |

Converters: `ConvertTo-JiraFilterSubscription`, `ConvertTo-JiraFilter`.

Producing commands: `Add-JiraFilterPermission`, `Find-JiraFilter`, `Get-JiraFilter`, `Get-JiraFilterPermission`, `New-JiraFilter`, `Set-JiraFilter`.

No public parameter consumes this record directly.

Tests: `ConvertTo-JiraFilter.Unit.Tests.ps1`, `AtlassianPS.JiraPS.Types.Unit.Tests.ps1`, `V3ReturnContracts.Unit.Tests.ps1`.

### `FilterSubscriptionList`

| Property | CLR type |
| --- | --- |
| `Size` | `int?` |
| `MaxResults` | `int?` |
| `StartIndex` | `int?` |
| `EndIndex` | `int?` |
| `Items` | `FilterSubscription[]` |

Converters: `ConvertTo-JiraFilter`.

Producing commands: `Add-JiraFilterPermission`, `Find-JiraFilter`, `Get-JiraFilter`, `Get-JiraFilterPermission`, `New-JiraFilter`, `Set-JiraFilter`.

No public parameter consumes this record directly.

Tests: `ConvertTo-JiraFilter.Unit.Tests.ps1`, `AtlassianPS.JiraPS.Types.Unit.Tests.ps1`, `V3ReturnContracts.Unit.Tests.ps1`.

### `Group`

| Property | CLR type |
| --- | --- |
| `Name` | `string` |
| `Id` | `string` |
| `GroupId` | `string` |
| `RestUrl` | `Uri` |
| `Size` | `int?` |
| `Member` | `User[]` |

Converters: `ConvertTo-JiraGroup`.

Producing commands: `Add-JiraFilterPermission`, `Add-JiraGroupMember`, `Find-JiraFilter`, `Get-JiraFilter`, `Get-JiraFilterPermission`, `Get-JiraGroup`, `New-JiraFilter`, `New-JiraGroup`, `Set-JiraFilter`.

Consuming parameters: `Add-JiraGroupMember -Group`, `Get-JiraGroupMember -Group`, `Remove-JiraGroup -Group`, `Remove-JiraGroupMember -Group`.

Tests: `ConvertTo-JiraGroup.Unit.Tests.ps1`, `AtlassianPS.JiraPS.Types.Unit.Tests.ps1`, `V3ReturnContracts.Unit.Tests.ps1`.

### `Issue`

| Property | CLR type |
| --- | --- |
| `Id` | `string` |
| `Key` | `string` |
| `HttpUrl` | `Uri` |
| `RestUrl` | `Uri` |
| `Summary` | `string` |
| `Description` | `string` |
| `Status` | `Status` |
| `IssueLinks` | `IssueLink[]` |
| `Attachment` | `Attachment[]` |
| `Project` | `Project` |
| `Assignee` | `User` |
| `Creator` | `User` |
| `Reporter` | `User` |
| `Created` | `DateTimeOffset?` |
| `LastViewed` | `DateTimeOffset?` |
| `Updated` | `DateTimeOffset?` |
| `Fields` | `IDictionary<string, object>` |
| `Expand` | `string` |
| `Transition` | `Transition[]` |
| `Comment` | `Comment[]` |
| `History` | `IssueHistoryEntry[]` |
| `IssueType` | `IssueType` |
| `Priority` | `Priority` |
| `Resolution` | `Resolution` |
| `Components` | `Component[]` |
| `Worklog` | `Worklogitem[]` |
| `FixVersions` | `Version[]` |
| `Versions` | `Version[]` |
| `Parent` | `Issue` |
| `Subtasks` | `Issue[]` |
| `Watches` | `IssueWatches` |
| `Votes` | `IssueVotes` |
| `Progress` | `IssueProgress` |
| `AggregateProgress` | `IssueProgress` |
| `TimeTracking` | `IssueTimeTracking` |
| `Security` | `IssueSecurityLevel` |

Converters: `Resolve-JiraIssueObject`, `ConvertTo-JiraIssue`.

Producing commands: `Get-JiraIssue`, `Get-JiraIssueLink`, `Invoke-JiraIssueTransition`, `New-JiraIssue`, `Set-JiraIssue`, `Set-JiraIssueLabel`.

Consuming parameters: `Add-JiraIssueComment -Issue`, `Add-JiraIssueWorklog -Issue`, `Invoke-JiraIssueTransition -Issue`, `Remove-JiraIssueLink -Issue`, `Remove-JiraRemoteLink -Issue`, `Add-JiraIssueAttachment -Issue`, `Add-JiraIssueWatcher -Issue`, `Get-JiraIssue -InputObject`, `Get-JiraIssueAttachment -Issue`, `Get-JiraIssueComment -Issue`, `Get-JiraIssueWatcher -Issue`, `Get-JiraIssueWorklog -Issue`, `Get-JiraRemoteLink -Issue`, `New-JiraIssueLinkRequest -FromIssue`, `New-JiraIssueLinkRequest -ToIssue`, `Remove-JiraIssue -InputObject`, `Remove-JiraIssueAttachment -Issue`, `Remove-JiraIssueWatcher -Issue`, `Set-JiraIssue -Issue`, `Set-JiraIssueLabel -Issue`.

Tests: `ConvertTo-JiraIssue.Unit.Tests.ps1`, `AtlassianPS.JiraPS.Types.Unit.Tests.ps1`, `V3ReturnContracts.Unit.Tests.ps1`, `V3ParameterContracts.Unit.Tests.ps1`.

### `IssueHistoryEntry`

| Property | CLR type |
| --- | --- |
| `Id` | `string` |
| `Author` | `User` |
| `Created` | `DateTimeOffset?` |
| `Items` | `IssueHistoryItem[]` |

Converters: `ConvertTo-JiraIssue`, `ConvertTo-JiraIssueHistoryEntry`.

Producing commands: `Get-JiraIssue`, `Get-JiraIssueLink`, `Invoke-JiraIssueTransition`, `New-JiraIssue`, `Set-JiraIssue`, `Set-JiraIssueLabel`.

No public parameter consumes this record directly.

Tests: `ConvertTo-JiraIssue.Unit.Tests.ps1`, `ConvertTo-JiraIssueHistoryEntry.Unit.Tests.ps1`, `AtlassianPS.JiraPS.Types.Unit.Tests.ps1`, `V3ReturnContracts.Unit.Tests.ps1`.

### `IssueHistoryItem`

| Property | CLR type |
| --- | --- |
| `Field` | `string` |
| `FieldType` | `string` |
| `FieldId` | `string` |
| `From` | `string` |
| `FromString` | `string` |
| `To` | `string` |
| `ToString` | `string` |

Converters: `ConvertTo-JiraIssueHistoryEntry`.

Producing commands: `Get-JiraIssue`, `Get-JiraIssueLink`, `Invoke-JiraIssueTransition`, `New-JiraIssue`, `Set-JiraIssue`, `Set-JiraIssueLabel`.

No public parameter consumes this record directly.

Tests: `ConvertTo-JiraIssueHistoryEntry.Unit.Tests.ps1`, `AtlassianPS.JiraPS.Types.Unit.Tests.ps1`, `V3ReturnContracts.Unit.Tests.ps1`.

### `IssueLink`

| Property | CLR type |
| --- | --- |
| `Id` | `long?` |
| `Type` | `IssueLinkType` |
| `InwardIssue` | `Issue` |
| `OutwardIssue` | `Issue` |

Converters: `ConvertTo-JiraIssue`, `ConvertTo-JiraIssueLink`.

Producing commands: `Get-JiraIssue`, `Get-JiraIssueLink`, `Invoke-JiraIssueTransition`, `New-JiraIssue`, `Set-JiraIssue`, `Set-JiraIssueLabel`.

Consuming parameters: `Remove-JiraIssueLink -IssueLink`.

Tests: `ConvertTo-JiraIssue.Unit.Tests.ps1`, `ConvertTo-JiraIssueLink.Unit.Tests.ps1`, `AtlassianPS.JiraPS.Types.Unit.Tests.ps1`, `V3ReturnContracts.Unit.Tests.ps1`.

### `IssueLinkCreateRequest`

| Property | CLR type |
| --- | --- |
| `Type` | `IssueLinkTypeRef` |
| `InwardIssue` | `LinkedIssueRef` |
| `OutwardIssue` | `LinkedIssueRef` |

Converters: Constructed by `New-JiraIssueLinkRequest`.

Producing commands: `New-JiraIssueLinkRequest`.

Consuming parameters: `Add-JiraIssueLink -IssueLink`.

Tests: `New-JiraIssueLinkRequest.Unit.Tests.ps1`.

### `IssueLinkType`

| Property | CLR type |
| --- | --- |
| `Id` | `string` |
| `Name` | `string` |
| `InwardText` | `string` |
| `OutwardText` | `string` |
| `RestUrl` | `Uri` |

Converters: `ConvertTo-JiraIssueLinkType`.

Producing commands: `Get-JiraIssue`, `Get-JiraIssueLink`, `Get-JiraIssueLinkType`, `Invoke-JiraIssueTransition`, `New-JiraIssue`, `Set-JiraIssue`, `Set-JiraIssueLabel`.

Consuming parameters: `Get-JiraIssueLinkType -LinkType`, `New-JiraIssueLinkRequest -LinkType`.

Tests: `ConvertTo-JiraIssueLinkType.Unit.Tests.ps1`, `AtlassianPS.JiraPS.Types.Unit.Tests.ps1`, `V3ReturnContracts.Unit.Tests.ps1`.

### `IssueLinkTypeRef`

| Property | CLR type |
| --- | --- |
| `Id` | `string` |
| `Name` | `string` |

Converters: Constructed by `New-JiraIssueLinkRequest`.

Producing commands: `New-JiraIssueLinkRequest`.

No public parameter consumes this record directly.

Tests: `New-JiraIssueLinkRequest.Unit.Tests.ps1`.

### `IssueProgress`

| Property | CLR type |
| --- | --- |
| `Progress` | `long?` |
| `Total` | `long?` |
| `Percent` | `long?` |

Converters: `ConvertTo-JiraIssue`, `ConvertTo-JiraIssueProgress`.

Producing commands: `Get-JiraIssue`, `Get-JiraIssueLink`, `Invoke-JiraIssueTransition`, `New-JiraIssue`, `Set-JiraIssue`, `Set-JiraIssueLabel`.

No public parameter consumes this record directly.

Tests: `ConvertTo-JiraIssue.Unit.Tests.ps1`, `AtlassianPS.JiraPS.Types.Unit.Tests.ps1`, `V3ReturnContracts.Unit.Tests.ps1`, `ConvertTo-JiraIssueProgress.Unit.Tests.ps1`.

### `IssueSecurityLevel`

| Property | CLR type |
| --- | --- |
| `Id` | `string` |
| `Name` | `string` |
| `Description` | `string` |
| `Self` | `Uri` |

Converters: `ConvertTo-JiraIssue`, `ConvertTo-JiraIssueSecurityLevel`.

Producing commands: `Get-JiraIssue`, `Get-JiraIssueLink`, `Invoke-JiraIssueTransition`, `New-JiraIssue`, `Set-JiraIssue`, `Set-JiraIssueLabel`.

No public parameter consumes this record directly.

Tests: `ConvertTo-JiraIssue.Unit.Tests.ps1`, `AtlassianPS.JiraPS.Types.Unit.Tests.ps1`, `V3ReturnContracts.Unit.Tests.ps1`, `ConvertTo-JiraIssueSecurityLevel.Unit.Tests.ps1`.

### `IssueTimeTracking`

| Property | CLR type |
| --- | --- |
| `OriginalEstimate` | `string` |
| `RemainingEstimate` | `string` |
| `TimeSpent` | `string` |
| `OriginalEstimateSeconds` | `long?` |
| `RemainingEstimateSeconds` | `long?` |
| `TimeSpentSeconds` | `long?` |

Converters: `ConvertTo-JiraIssue`, `ConvertTo-JiraIssueTimeTracking`.

Producing commands: `Get-JiraIssue`, `Get-JiraIssueLink`, `Invoke-JiraIssueTransition`, `New-JiraIssue`, `Set-JiraIssue`, `Set-JiraIssueLabel`.

No public parameter consumes this record directly.

Tests: `ConvertTo-JiraIssue.Unit.Tests.ps1`, `AtlassianPS.JiraPS.Types.Unit.Tests.ps1`, `V3ReturnContracts.Unit.Tests.ps1`, `ConvertTo-JiraIssueTimeTracking.Unit.Tests.ps1`.

### `IssueType`

| Property | CLR type |
| --- | --- |
| `Id` | `long?` |
| `Name` | `string` |
| `Description` | `string` |
| `IconUrl` | `Uri` |
| `RestUrl` | `Uri` |
| `Subtask` | `bool` |
| `AvatarId` | `long?` |
| `HierarchyLevel` | `int?` |
| `Scope` | `IssueTypeScope` |

Converters: `ConvertTo-JiraProject`, `ConvertTo-JiraIssueType`.

Producing commands: `Add-JiraFilterPermission`, `Find-JiraFilter`, `Get-JiraFilter`, `Get-JiraFilterPermission`, `Get-JiraIssue`, `Get-JiraIssueLink`, `Get-JiraIssueType`, `Get-JiraProject`, `Invoke-JiraIssueTransition`, `New-JiraFilter`, `New-JiraIssue`, `Set-JiraFilter`, `Set-JiraIssue`, `Set-JiraIssueLabel`.

Consuming parameters: `Get-JiraIssueCreateMetadata -IssueType`, `Get-JiraIssueType -IssueType`, `New-JiraIssue -IssueType`.

Tests: `ConvertTo-JiraProject.Unit.Tests.ps1`, `ConvertTo-JiraIssueType.Unit.Tests.ps1`, `AtlassianPS.JiraPS.Types.Unit.Tests.ps1`, `V3ReturnContracts.Unit.Tests.ps1`, `V3ParameterContracts.Unit.Tests.ps1`.

### `IssueTypeScope`

| Property | CLR type |
| --- | --- |
| `Type` | `string` |
| `Project` | `Project` |

Converters: `ConvertTo-JiraIssueType`.

Producing commands: `Add-JiraFilterPermission`, `Find-JiraFilter`, `Get-JiraFilter`, `Get-JiraFilterPermission`, `Get-JiraIssue`, `Get-JiraIssueLink`, `Get-JiraIssueType`, `Get-JiraProject`, `Invoke-JiraIssueTransition`, `New-JiraFilter`, `New-JiraIssue`, `Set-JiraFilter`, `Set-JiraIssue`, `Set-JiraIssueLabel`.

No public parameter consumes this record directly.

Tests: `ConvertTo-JiraIssueType.Unit.Tests.ps1`, `AtlassianPS.JiraPS.Types.Unit.Tests.ps1`, `V3ReturnContracts.Unit.Tests.ps1`.

### `IssueVotes`

| Property | CLR type |
| --- | --- |
| `Self` | `Uri` |
| `Votes` | `long?` |
| `HasVoted` | `bool?` |
| `Voters` | `User[]` |

Converters: `ConvertTo-JiraIssue`, `ConvertTo-JiraIssueVote`.

Producing commands: `Get-JiraIssue`, `Get-JiraIssueLink`, `Invoke-JiraIssueTransition`, `New-JiraIssue`, `Set-JiraIssue`, `Set-JiraIssueLabel`.

No public parameter consumes this record directly.

Tests: `ConvertTo-JiraIssue.Unit.Tests.ps1`, `AtlassianPS.JiraPS.Types.Unit.Tests.ps1`, `V3ReturnContracts.Unit.Tests.ps1`, `ConvertTo-JiraIssueVote.Unit.Tests.ps1`.

### `IssueWatches`

| Property | CLR type |
| --- | --- |
| `Self` | `Uri` |
| `WatchCount` | `long?` |
| `IsWatching` | `bool?` |
| `Watchers` | `User[]` |

Converters: `ConvertTo-JiraIssue`, `ConvertTo-JiraIssueWatch`.

Producing commands: `Get-JiraIssue`, `Get-JiraIssueLink`, `Invoke-JiraIssueTransition`, `New-JiraIssue`, `Set-JiraIssue`, `Set-JiraIssueLabel`.

No public parameter consumes this record directly.

Tests: `ConvertTo-JiraIssue.Unit.Tests.ps1`, `AtlassianPS.JiraPS.Types.Unit.Tests.ps1`, `V3ReturnContracts.Unit.Tests.ps1`, `ConvertTo-JiraIssueWatch.Unit.Tests.ps1`.

### `Link`

| Property | CLR type |
| --- | --- |
| `Id` | `long?` |
| `RestUrl` | `Uri` |
| `GlobalId` | `string` |
| `Application` | `LinkApplication` |
| `Relationship` | `string` |
| `RemoteObject` | `RemoteLinkObject` |

Converters: `ConvertTo-JiraLink`.

Producing commands: `Get-JiraRemoteLink`.

Consuming parameters: `Remove-JiraRemoteLink -LinkId`.

Tests: `ConvertTo-JiraLink.Unit.Tests.ps1`, `AtlassianPS.JiraPS.Types.Unit.Tests.ps1`, `V3ReturnContracts.Unit.Tests.ps1`, `V3ParameterContracts.Unit.Tests.ps1`.

### `LinkApplication`

| Property | CLR type |
| --- | --- |
| `Type` | `string` |
| `Name` | `string` |

Converters: `ConvertTo-JiraLink`.

Producing commands: `Get-JiraRemoteLink`.

No public parameter consumes this record directly.

Tests: `ConvertTo-JiraLink.Unit.Tests.ps1`, `AtlassianPS.JiraPS.Types.Unit.Tests.ps1`, `V3ReturnContracts.Unit.Tests.ps1`.

### `LinkedIssueRef`

| Property | CLR type |
| --- | --- |
| `Id` | `string` |
| `Key` | `string` |

Converters: Constructed by `New-JiraIssueLinkRequest`.

Producing commands: `New-JiraIssueLinkRequest`.

No public parameter consumes this record directly.

Tests: `New-JiraIssueLinkRequest.Unit.Tests.ps1`.

### `Priority`

| Property | CLR type |
| --- | --- |
| `Id` | `long?` |
| `Name` | `string` |
| `Description` | `string` |
| `StatusColor` | `string` |
| `IconUrl` | `Uri` |
| `RestUrl` | `Uri` |

Converters: `ConvertTo-JiraPriority`.

Producing commands: `Get-JiraIssue`, `Get-JiraIssueLink`, `Get-JiraPriority`, `Invoke-JiraIssueTransition`, `New-JiraIssue`, `Set-JiraIssue`, `Set-JiraIssueLabel`.

Consuming parameters: `New-JiraIssue -Priority`.

Tests: `ConvertTo-JiraPriority.Unit.Tests.ps1`, `AtlassianPS.JiraPS.Types.Unit.Tests.ps1`, `V3ReturnContracts.Unit.Tests.ps1`.

### `Project`

| Property | CLR type |
| --- | --- |
| `Id` | `string` |
| `Key` | `string` |
| `Name` | `string` |
| `Description` | `string` |
| `Lead` | `User` |
| `IssueTypes` | `IssueType[]` |
| `Roles` | `IDictionary<string, Uri>` |
| `RestUrl` | `Uri` |
| `Components` | `Component[]` |
| `AssigneeType` | `AssigneeType?` |
| `Versions` | `Version[]` |
| `Style` | `string` |
| `Category` | `ProjectCategory` |
| `ProjectTypeKey` | `string` |
| `Url` | `Uri` |
| `Email` | `string` |
| `Archived` | `bool?` |
| `Simplified` | `bool?` |
| `IsPrivate` | `bool?` |

Converters: `ConvertTo-JiraProject`.

Producing commands: `Add-JiraFilterPermission`, `Find-JiraFilter`, `Get-JiraFilter`, `Get-JiraFilterPermission`, `Get-JiraIssue`, `Get-JiraIssueLink`, `Get-JiraIssueType`, `Get-JiraProject`, `Invoke-JiraIssueTransition`, `New-JiraFilter`, `New-JiraIssue`, `Set-JiraFilter`, `Set-JiraIssue`, `Set-JiraIssueLabel`.

Consuming parameters: `Get-JiraIssueCreateMetadata -Project`, `Get-JiraProject -Project`, `Get-JiraVersion -InputProject`, `New-JiraIssue -Project`, `Find-JiraFilter -Project`, `Get-JiraComponent -Project`, `New-JiraVersion -Project`, `Set-JiraVersion -Project`.

Tests: `ConvertTo-JiraProject.Unit.Tests.ps1`, `AtlassianPS.JiraPS.Types.Unit.Tests.ps1`, `V3ReturnContracts.Unit.Tests.ps1`, `V3ParameterContracts.Unit.Tests.ps1`.

### `ProjectCategory`

| Property | CLR type |
| --- | --- |
| `Id` | `string` |
| `Name` | `string` |
| `Description` | `string` |
| `RestUrl` | `Uri` |

Converters: `ConvertTo-JiraProject`.

Producing commands: `Add-JiraFilterPermission`, `Find-JiraFilter`, `Get-JiraFilter`, `Get-JiraFilterPermission`, `Get-JiraIssue`, `Get-JiraIssueLink`, `Get-JiraIssueType`, `Get-JiraProject`, `Invoke-JiraIssueTransition`, `New-JiraFilter`, `New-JiraIssue`, `Set-JiraFilter`, `Set-JiraIssue`, `Set-JiraIssueLabel`.

No public parameter consumes this record directly.

Tests: `ConvertTo-JiraProject.Unit.Tests.ps1`, `AtlassianPS.JiraPS.Types.Unit.Tests.ps1`, `V3ReturnContracts.Unit.Tests.ps1`.

### `ProjectRole`

| Property | CLR type |
| --- | --- |
| `Id` | `long?` |
| `Name` | `string` |
| `Description` | `string` |
| `Actors` | `RoleActor[]` |
| `RestUrl` | `Uri` |

Converters: `ConvertTo-JiraProjectRole`.

Producing commands: `Add-JiraFilterPermission`, `Find-JiraFilter`, `Get-JiraFilter`, `Get-JiraFilterPermission`, `New-JiraFilter`, `Set-JiraFilter`.

No public parameter consumes this record directly.

Tests: `ConvertTo-JiraProjectRole.Unit.Tests.ps1`, `AtlassianPS.JiraPS.Types.Unit.Tests.ps1`, `V3ReturnContracts.Unit.Tests.ps1`.

### `RemoteLinkIcon`

| Property | CLR type |
| --- | --- |
| `Url16x16` | `Uri` |
| `Title` | `string` |
| `Link` | `Uri` |

Converters: `ConvertTo-JiraLink`.

Producing commands: `Get-JiraRemoteLink`.

No public parameter consumes this record directly.

Tests: `ConvertTo-JiraLink.Unit.Tests.ps1`, `AtlassianPS.JiraPS.Types.Unit.Tests.ps1`, `V3ReturnContracts.Unit.Tests.ps1`.

### `RemoteLinkObject`

| Property | CLR type |
| --- | --- |
| `Url` | `Uri` |
| `Title` | `string` |
| `Summary` | `string` |
| `Icon` | `RemoteLinkIcon` |
| `Status` | `RemoteLinkStatus` |

Converters: `ConvertTo-JiraLink`.

Producing commands: `Get-JiraRemoteLink`.

No public parameter consumes this record directly.

Tests: `ConvertTo-JiraLink.Unit.Tests.ps1`, `AtlassianPS.JiraPS.Types.Unit.Tests.ps1`, `V3ReturnContracts.Unit.Tests.ps1`.

### `RemoteLinkStatus`

| Property | CLR type |
| --- | --- |
| `Resolved` | `bool?` |
| `Icon` | `RemoteLinkIcon` |

Converters: `ConvertTo-JiraLink`.

Producing commands: `Get-JiraRemoteLink`.

No public parameter consumes this record directly.

Tests: `ConvertTo-JiraLink.Unit.Tests.ps1`, `AtlassianPS.JiraPS.Types.Unit.Tests.ps1`, `V3ReturnContracts.Unit.Tests.ps1`.

### `Resolution`

| Property | CLR type |
| --- | --- |
| `Id` | `string` |
| `Name` | `string` |
| `Description` | `string` |
| `RestUrl` | `Uri` |

Converters: `ConvertTo-JiraResolution`.

Producing commands: `Get-JiraIssue`, `Get-JiraIssueLink`, `Invoke-JiraIssueTransition`, `New-JiraIssue`, `Set-JiraIssue`, `Set-JiraIssueLabel`.

No public parameter consumes this record directly.

Tests: `AtlassianPS.JiraPS.Types.Unit.Tests.ps1`, `V3ReturnContracts.Unit.Tests.ps1`.

### `RoleActor`

| Property | CLR type |
| --- | --- |
| `Id` | `long?` |
| `Name` | `string` |
| `DisplayName` | `string` |
| `Type` | `ActorType?` |
| `AvatarUrl` | `Uri` |
| `ActorUser` | `User` |
| `ActorGroup` | `Group` |

Converters: `ConvertTo-JiraRoleActor`, `ConvertTo-JiraProjectRole`.

Producing commands: `Add-JiraFilterPermission`, `Find-JiraFilter`, `Get-JiraFilter`, `Get-JiraFilterPermission`, `New-JiraFilter`, `Set-JiraFilter`.

No public parameter consumes this record directly.

Tests: `ConvertTo-JiraProjectRole.Unit.Tests.ps1`, `AtlassianPS.JiraPS.Types.Unit.Tests.ps1`, `V3ReturnContracts.Unit.Tests.ps1`.

### `ServerInfo`

| Property | CLR type |
| --- | --- |
| `BaseURL` | `Uri` |
| `Version` | `string` |
| `VersionNumbers` | `int[]` |
| `DeploymentType` | `DeploymentType?` |
| `BuildNumber` | `long?` |
| `BuildDate` | `DateTimeOffset?` |
| `ServerTime` | `DateTimeOffset?` |
| `ScmInfo` | `string` |
| `ServerTitle` | `string` |
| `DisplayUrl` | `Uri` |
| `DisplayUrlConfluence` | `Uri` |
| `DisplayUrlServicedeskHelpCenter` | `Uri` |
| `BuildPartnerName` | `string` |
| `ServerTimeZone` | `ServerTimeZone` |
| `DefaultLocale` | `ServerLocale` |

Converters: `ConvertTo-JiraServerInfo`.

Producing commands: `Get-JiraServerInformation`.

No public parameter consumes this record directly.

Tests: `ConvertTo-JiraServerInfo.Unit.Tests.ps1`, `AtlassianPS.JiraPS.Types.Unit.Tests.ps1`, `V3ReturnContracts.Unit.Tests.ps1`.

### `ServerLocale`

| Property | CLR type |
| --- | --- |
| `Locale` | `string` |

Converters: `ConvertTo-JiraServerInfo`.

Producing commands: `Get-JiraServerInformation`.

No public parameter consumes this record directly.

Tests: `ConvertTo-JiraServerInfo.Unit.Tests.ps1`, `AtlassianPS.JiraPS.Types.Unit.Tests.ps1`, `V3ReturnContracts.Unit.Tests.ps1`.

### `ServerTimeZone`

| Property | CLR type |
| --- | --- |
| `Id` | `string` |
| `DisplayName` | `string` |

Converters: `ConvertTo-JiraServerInfo`.

Producing commands: `Get-JiraServerInformation`.

No public parameter consumes this record directly.

Tests: `ConvertTo-JiraServerInfo.Unit.Tests.ps1`, `AtlassianPS.JiraPS.Types.Unit.Tests.ps1`, `V3ReturnContracts.Unit.Tests.ps1`.

### `Session`

| Property | CLR type |
| --- | --- |
| `WebSession` | `object` |
| `Username` | `string` |
| `JSessionID` | `string` |

Converters: `ConvertTo-JiraSession`.

Producing commands: `Get-JiraSession`, `New-JiraSession`.

No public parameter consumes this record directly.

Tests: `ConvertTo-JiraSession.Unit.Tests.ps1`.

### `Status`

| Property | CLR type |
| --- | --- |
| `Id` | `long?` |
| `Name` | `string` |
| `Description` | `string` |
| `IconUrl` | `Uri` |
| `RestUrl` | `Uri` |
| `StatusCategory` | `StatusCategory` |

Converters: `ConvertTo-JiraStatus`.

Producing commands: `Get-JiraIssue`, `Get-JiraIssueLink`, `Get-JiraStatus`, `Invoke-JiraIssueTransition`, `New-JiraIssue`, `Set-JiraIssue`, `Set-JiraIssueLabel`.

Consuming parameters: `Get-JiraStatus -Status`.

Tests: `ConvertTo-JiraStatus.Unit.Tests.ps1`, `AtlassianPS.JiraPS.Types.Unit.Tests.ps1`, `V3ReturnContracts.Unit.Tests.ps1`.

### `StatusCategory`

| Property | CLR type |
| --- | --- |
| `Id` | `long?` |
| `Key` | `string` |
| `Name` | `string` |
| `ColorName` | `string` |
| `RestUrl` | `Uri` |

Converters: `ConvertTo-JiraStatus`.

Producing commands: `Get-JiraIssue`, `Get-JiraIssueLink`, `Get-JiraStatus`, `Invoke-JiraIssueTransition`, `New-JiraIssue`, `Set-JiraIssue`, `Set-JiraIssueLabel`.

No public parameter consumes this record directly.

Tests: `ConvertTo-JiraStatus.Unit.Tests.ps1`, `AtlassianPS.JiraPS.Types.Unit.Tests.ps1`, `V3ReturnContracts.Unit.Tests.ps1`.

### `Transition`

| Property | CLR type |
| --- | --- |
| `Id` | `long?` |
| `Name` | `string` |
| `ResultStatus` | `Status` |

Converters: `ConvertTo-JiraIssue`, `ConvertTo-JiraTransition`.

Producing commands: `Get-JiraIssue`, `Get-JiraIssueLink`, `Invoke-JiraIssueTransition`, `New-JiraIssue`, `Set-JiraIssue`, `Set-JiraIssueLabel`.

Consuming parameters: `Invoke-JiraIssueTransition -Transition`.

Tests: `ConvertTo-JiraIssue.Unit.Tests.ps1`, `ConvertTo-JiraTransition.Unit.Tests.ps1`, `AtlassianPS.JiraPS.Types.Unit.Tests.ps1`, `V3ReturnContracts.Unit.Tests.ps1`, `V3ParameterContracts.Unit.Tests.ps1`.

### `User`

| Property | CLR type |
| --- | --- |
| `Key` | `string` |
| `AccountId` | `string` |
| `AccountType` | `AccountType?` |
| `Name` | `string` |
| `DisplayName` | `string` |
| `EmailAddress` | `string` |
| `Active` | `bool` |
| `Deleted` | `bool?` |
| `AvatarUrl` | `IDictionary<string, Uri>` |
| `TimeZone` | `string` |
| `Locale` | `string` |
| `Groups` | `string[]` |
| `LastLoginTime` | `DateTime?` |
| `RestUrl` | `Uri` |

Converters: `ConvertTo-JiraGroup`, `ConvertTo-JiraUser`, `Resolve-JiraUser`, `ConvertTo-JiraIssue`, `ConvertTo-JiraFilter`.

Producing commands: `Add-JiraFilterPermission`, `Add-JiraGroupMember`, `Add-JiraIssueAttachment`, `Add-JiraIssueComment`, `Add-JiraIssueWorklog`, `Find-JiraFilter`, `Get-JiraComponent`, `Get-JiraFilter`, `Get-JiraFilterPermission`, `Get-JiraGroup`, `Get-JiraGroupMember`, `Get-JiraIssue`, `Get-JiraIssueAttachment`, `Get-JiraIssueComment`, `Get-JiraIssueLink`, `Get-JiraIssueType`, `Get-JiraIssueWatcher`, `Get-JiraIssueWorklog`, `Get-JiraProject`, `Get-JiraUser`, `Invoke-JiraIssueTransition`, `New-JiraFilter`, `New-JiraGroup`, `New-JiraIssue`, `New-JiraUser`, `Set-JiraFilter`, `Set-JiraIssue`, `Set-JiraIssueLabel`, `Set-JiraUser`.

Consuming parameters: `Invoke-JiraIssueTransition -Assignee`, `New-JiraIssue -Reporter`, `New-JiraIssue -Assignee`, `Add-JiraGroupMember -UserName`, `Find-JiraFilter -Owner`, `Get-JiraUser -InputObject`, `Remove-JiraGroupMember -User`, `Remove-JiraUser -User`, `Set-JiraIssue -Assignee`, `Set-JiraUser -User`.

Tests: `ConvertTo-JiraGroup.Unit.Tests.ps1`, `ConvertTo-JiraUser.Unit.Tests.ps1`, `ConvertTo-JiraIssue.Unit.Tests.ps1`, `ConvertTo-JiraFilter.Unit.Tests.ps1`, `AtlassianPS.JiraPS.Types.Unit.Tests.ps1`, `V3ReturnContracts.Unit.Tests.ps1`, `V3ParameterContracts.Unit.Tests.ps1`.

### `UserList`

| Property | CLR type |
| --- | --- |
| `Size` | `int?` |
| `MaxResults` | `int?` |
| `StartIndex` | `int?` |
| `EndIndex` | `int?` |
| `Items` | `User[]` |

Converters: `ConvertTo-JiraFilter`.

Producing commands: `Add-JiraFilterPermission`, `Find-JiraFilter`, `Get-JiraFilter`, `Get-JiraFilterPermission`, `New-JiraFilter`, `Set-JiraFilter`.

No public parameter consumes this record directly.

Tests: `ConvertTo-JiraFilter.Unit.Tests.ps1`, `AtlassianPS.JiraPS.Types.Unit.Tests.ps1`, `V3ReturnContracts.Unit.Tests.ps1`.

### `Version`

| Property | CLR type |
| --- | --- |
| `Id` | `string` |
| `Project` | `long?` |
| `Name` | `string` |
| `Description` | `string` |
| `Archived` | `bool` |
| `Released` | `bool` |
| `Overdue` | `bool` |
| `RestUrl` | `Uri` |
| `StartDate` | `DateTime?` |
| `ReleaseDate` | `DateTime?` |

Converters: `ConvertTo-JiraIssue`, `ConvertTo-JiraProject`, `ConvertTo-JiraVersion`.

Producing commands: `Add-JiraFilterPermission`, `Find-JiraFilter`, `Get-JiraFilter`, `Get-JiraFilterPermission`, `Get-JiraIssue`, `Get-JiraIssueLink`, `Get-JiraIssueType`, `Get-JiraProject`, `Get-JiraVersion`, `Invoke-JiraIssueTransition`, `New-JiraFilter`, `New-JiraIssue`, `New-JiraVersion`, `Set-JiraFilter`, `Set-JiraIssue`, `Set-JiraIssueLabel`, `Set-JiraVersion`.

Consuming parameters: `Get-JiraVersion -InputVersion`, `New-JiraIssue -FixVersion`, `Move-JiraVersion -Version`, `Move-JiraVersion -After`, `New-JiraVersion -InputObject`, `Remove-JiraVersion -Version`, `Set-JiraVersion -Version`.

Tests: `ConvertTo-JiraIssue.Unit.Tests.ps1`, `ConvertTo-JiraProject.Unit.Tests.ps1`, `ConvertTo-JiraVersion.Unit.Tests.ps1`, `AtlassianPS.JiraPS.Types.Unit.Tests.ps1`, `V3ReturnContracts.Unit.Tests.ps1`.

### `Visibility`

| Property | CLR type |
| --- | --- |
| `Type` | `string` |
| `Value` | `string` |
| `Identifier` | `string` |

Converters: `ConvertTo-JiraVisibility`.

Producing commands: `Add-JiraIssueComment`, `Add-JiraIssueWorklog`, `Get-JiraIssue`, `Get-JiraIssueComment`, `Get-JiraIssueLink`, `Get-JiraIssueWorklog`, `Invoke-JiraIssueTransition`, `New-JiraIssue`, `Set-JiraIssue`, `Set-JiraIssueLabel`.

Consuming parameters: `Add-JiraIssueComment -Visibility`, `Add-JiraIssueWorklog -Visibility`.

Tests: `AtlassianPS.JiraPS.Types.Unit.Tests.ps1`, `V3ReturnContracts.Unit.Tests.ps1`, `V3ParameterContracts.Unit.Tests.ps1`.

### `Worklogitem`

| Property | CLR type |
| --- | --- |
| `Id` | `long?` |
| `Visibility` | `Visibility` |
| `Comment` | `string` |
| `RestUrl` | `Uri` |
| `Author` | `User` |
| `UpdateAuthor` | `User` |
| `Created` | `DateTimeOffset?` |
| `Updated` | `DateTimeOffset?` |
| `Started` | `DateTimeOffset?` |
| `TimeSpent` | `string` |
| `TimeSpentSeconds` | `long?` |

Converters: `ConvertTo-JiraWorklogitem`, `ConvertTo-JiraIssue`.

Producing commands: `Add-JiraIssueWorklog`, `Get-JiraIssue`, `Get-JiraIssueLink`, `Get-JiraIssueWorklog`, `Invoke-JiraIssueTransition`, `New-JiraIssue`, `Set-JiraIssue`, `Set-JiraIssueLabel`.

No public parameter consumes this record directly.

Tests: `ConvertTo-JiraWorklogitem.Unit.Tests.ps1`, `ConvertTo-JiraIssue.Unit.Tests.ps1`, `AtlassianPS.JiraPS.Types.Unit.Tests.ps1`, `V3ReturnContracts.Unit.Tests.ps1`.

## Deliberately extensible values

| Property or result | CLR type | Reason |
| --- | --- | --- |
| `Issue.Fields` and additional issue field note properties | `IDictionary<string, object>` and arbitrary values | Custom fields and plugins define their own payload shapes; debug data retains the raw field values. |
| `EntityProperty.Value` | `object` | Jira entity properties accept arbitrary JSON values. The property envelope itself is typed. |
| `CreateMetaField.AllowedValues`, inherited by `EditMetaField` | `object[]` | Values vary by field schema and plugin, including users, options, components and plugin records. |
| `FieldSchema.Configuration` | `IDictionary<string, object>` | App-defined field configuration has arbitrary keys and values. |
| `Session.WebSession` | `object` | Holds the live `Microsoft.PowerShell.Commands.WebRequestSession` from the current PowerShell edition. The C# assembly does not reference the edition-specific Utility assembly. It is runtime state, not a Jira domain record or export format. |
| `Invoke-JiraMethod` results, issue debug fields, ADF documents and extra metadata keys | Native REST/PowerShell JSON shapes | These explicitly raw or extensible results are not domain models. Internal HTTP/request objects follow their existing transport contract. |

## Enumerated properties

| Property | Nullable CLR enum | Known values |
| --- | --- | --- |
| `ServerInfo.DeploymentType` | `DeploymentType?` | `Cloud`, `Server`, `DataCenter` |
| `User.AccountType` | `AccountType?` | `atlassian`, `app`, `customer` |
| `Project.AssigneeType`, `Component.AssigneeType`, `Component.RealAssigneeType` | `AssigneeType?` | `PROJECT_DEFAULT`, `COMPONENT_LEAD`, `PROJECT_LEAD`, `UNASSIGNED` |
| `FilterPermission.Type` | `FilterShareType?` | `GLOBAL`, `LOGGEDIN`, `PROJECT`, `GROUP`, `ROLE`, `AUTHENTICATED`, `USER` |
| `RoleActor.Type` | `ActorType?` | `AtlassianUserRoleActor`, `AtlassianGroupRoleActor` |

Unknown wire values become `$null`, including Cloud's `accountType: unknown` sentinel.
Missing enum values are `$null`, except the existing `ServerInfo.DeploymentType` fallback to `Server` for older responses without deployment information.
The converters map Jira's hyphenated actor strings and `projectRole` share type to their enum names.
Request construction uses Jira wire values explicitly; it does not serialize a domain object as a REST request.
PowerShell `ConvertTo-Json` serializes enums as numbers by default; cast enum properties to `[string]` when a textual JSON representation is needed on both PS5.1 and PS7.

## Leaf transformation decisions

The following attributes have public consumers: `Status`, `Priority`, `IssueType`, `Component`, `Field`, `IssueLinkType`, `IssueLink`, `Transition`, `Link` and `FilterPermission` transformations.
`Resolution`, `Attachment`, `Worklogitem` and `ProjectRole` transformations are removed because no public operation consumes their identifier stubs.
Attachment downloads still require a complete typed `Attachment` with `FileName` and `Content`, rather than accepting an ID that cannot be downloaded without another lookup.
Output-only records such as `StatusCategory`, history records and metadata records have no transformer.

Transformers reject unrelated domain objects unless the parameter explicitly enables fallthrough for competing pipeline parameter sets.
`Get-JiraVersion` enables it for version/project input; `Remove-JiraIssueLink` enables it for issue/link input.
Strings remain identifier or name shorthand where documented.
Filters, remote links and filter permissions require numeric IDs; transitions accept either an ID or an unambiguous available transition name.
Numeric selectors such as `Get-JiraPriority -Id` intentionally remain scalar API identifiers; use the returned object's `.Id` when supplying those selectors.
Wildcard search parameters remain search strings where they do not consume a domain object.

## Related v3 work and release gate

This change implements the enum property choices tracked by #613 and the visibility parameter/model contract tracked by #174.
It does not change `User(string)` classification or Cloud/DC identity dispatch; #614 owns that additive constructor/helper work.
The current constructor keeps its documented `Name` stub behavior and `Resolve-JiraUser` resolves Cloud identifiers at runtime.
Assignment intent continues to use `-Unassign` and `-UseDefaultAssignee` rather than magic user values.

#194 owns named connections, server-bound session state, configuration import/export and final connection propagation.
`Session` and `ServerInfo` are inventoried here, but the session contract cannot be frozen until #194 lands.
Completion of #681 depends on #194/#614 coordination and PS5.1/PS7 CI verification.

## Wire-contract references

- [Cloud filter sharing and role actor payloads](https://developer.atlassian.com/cloud/jira/platform/rest/v3/api-group-filter-sharing/)
- [Cloud filters and subscriptions](https://developer.atlassian.com/cloud/jira/platform/rest/v3/api-group-filters/)
- [Cloud issues and changelogs](https://developer.atlassian.com/cloud/jira/platform/rest/v3/api-group-issues/)
- [Jira Data Center REST reference](https://docs.atlassian.com/software/jira/docs/api/REST/latest/)
