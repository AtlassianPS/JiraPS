---
external help file: JiraPS-help.xml
Module Name: JiraPS
online version: https://atlassianps.org/docs/JiraPS/commands/Invoke-JiraMethod/
locale: en-US
layout: documentation
permalink: /docs/JiraPS/commands/Invoke-JiraMethod/
document type: cmdlet
PlatyPS schema version: 2024-05-01
---
# Invoke-JiraMethod

## SYNOPSIS

Send a request to a Jira REST endpoint.

## SYNTAX

### Connection (Default)

```
Invoke-JiraMethod [-Uri] <uri> [-Method <WebRequestMethod>] [-Body <Object>] [-ContentType <string>]
 [-Headers <hashtable>] [-QueryParameter <hashtable>] [-Paging] [-PageSize <int>]
 [-OutFile <string>] [-RawResponse] [-TimeoutSec <int>] [-Connection <AtlassianPS.Connection>] [-WhatIf]
 [-Confirm] [-IncludeTotalCount] [-Skip <ulong>] [-First <ulong>]
```

### NamedConnection

```
Invoke-JiraMethod [-Uri] <uri> -ConnectionName <string> [-Method <WebRequestMethod>]
 [-Body <Object>] [-ContentType <string>] [-Headers <hashtable>] [-QueryParameter <hashtable>]
 [-Paging] [-PageSize <int>] [-OutFile <string>] [-RawResponse] [-TimeoutSec <int>] [-WhatIf]
 [-Confirm] [-IncludeTotalCount] [-Skip <ulong>] [-First <ulong>]
```

### Anonymous

```
Invoke-JiraMethod [-Uri] <uri> -BaseUri <uri> -Anonymous [-Method <WebRequestMethod>]
 [-Body <Object>] [-ContentType <string>] [-Headers <hashtable>] [-QueryParameter <hashtable>]
 [-Paging] [-PageSize <int>] [-OutFile <string>] [-RawResponse] [-TimeoutSec <int>] [-WhatIf]
 [-Confirm] [-IncludeTotalCount] [-Skip <ulong>] [-First <ulong>]
```

### PersonalAccessToken

```
Invoke-JiraMethod [-Uri] <uri> -BaseUri <uri> -PersonalAccessToken <Object>
 [-Method <WebRequestMethod>] [-Body <Object>] [-ContentType <string>] [-Headers <hashtable>]
 [-QueryParameter <hashtable>] [-Paging] [-PageSize <int>] [-OutFile <string>] [-RawResponse]
 [-TimeoutSec <int>] [-WhatIf] [-Confirm] [-IncludeTotalCount] [-Skip <ulong>] [-First <ulong>]
```

### CloudToken

```
Invoke-JiraMethod [-Uri] <uri> -BaseUri <uri> -EmailAddress <string> -ApiToken <Object>
 [-Method <WebRequestMethod>] [-Body <Object>] [-ContentType <string>] [-Headers <hashtable>]
 [-QueryParameter <hashtable>] [-Paging] [-PageSize <int>] [-OutFile <string>] [-RawResponse]
 [-TimeoutSec <int>] [-WhatIf] [-Confirm] [-IncludeTotalCount] [-Skip <ulong>] [-First <ulong>]
```

### Basic

```
Invoke-JiraMethod [-Uri] <uri> -BaseUri <uri> -Credential <pscredential>
 [-Method <WebRequestMethod>] [-Body <Object>] [-ContentType <string>] [-Headers <hashtable>]
 [-QueryParameter <hashtable>] [-Paging] [-PageSize <int>] [-OutFile <string>] [-RawResponse]
 [-TimeoutSec <int>] [-WhatIf] [-Confirm] [-IncludeTotalCount] [-Skip <ulong>] [-First <ulong>]
```

## ALIASES

This cmdlet has the following aliases,
None.

## DESCRIPTION

Use this command for Jira REST endpoints without a dedicated JiraPS command.
Omitting a connection selector uses the selected default connection.
Supply either Connection or ConnectionName to select another connection.
An existing connection keeps its authenticated identity; authentication overrides are not supported.

For a standalone request, supply BaseUri and exactly one authentication method.
Standalone authentication is validated through Jira's myself endpoint before the requested operation.
The temporary connection is disposed after the request and does not change the default or register a named connection.
Anonymous standalone access requires recognized Jira deployment metadata.

Relative resource paths must start with a single slash.
JiraPS preserves the selected connection's context or Cloud gateway prefix.
Absolute resource URLs must belong to the selected endpoint.
Matching Jira Cloud site resource URLs are mapped to the connection's gateway.
Choose the REST API version and deployment-specific payload explicitly.

Responses are parsed as JSON by default.
Paging emits individual records from supported Jira item arrays.
RawResponse returns the native web response, and OutFile saves the response bytes and returns FileInfo.
These three response modes are mutually exclusive.
Successful responses without content produce no objects.
HTTP and transport failures honor the standard ErrorAction preference.

Potentially mutating methods and file output support WhatIf and Confirm.
Automatic retries apply only to GET, HEAD and OPTIONS requests.
POST, PUT, PATCH and DELETE requests are not retried automatically.
Typed JiraPS commands share this transport and retain their own confirmation behavior.

## EXAMPLES

### Example 1: Use the selected connection

```powershell
Invoke-JiraMethod '/rest/api/2/mypermissions'
```

Returns the Jira permissions response through the selected connection.

### Example 2: Supply query parameters

```powershell
Invoke-JiraMethod '/rest/api/2/issue/PROJ-123' -ConnectionName 'work' -QueryParameter @{
    fields = 'summary,status'
    expand = 'names'
}
```

Uses the named connection and requests selected issue fields.
Supply unencoded values; JiraPS encodes them once.
Arrays produce repeated query keys, so use a comma-separated string when an endpoint expects comma-separated values.

### Example 3: Submit a structured JSON body

```powershell
Invoke-JiraMethod '/rest/api/2/group' -Method Post -Body @{
    name = 'release-reviewers'
} -Connection $connection
```

Creates a group using the supplied connection.
The nested body is serialized as JSON and encoded as UTF-8.
An already serialized JSON string is sent without additional JSON serialization.

### Example 4: Authenticate a standalone Cloud request

```powershell
Invoke-JiraMethod '/rest/api/2/mypermissions' -BaseUri 'https://example.atlassian.net' -EmailAddress $email -ApiToken $token
```

Validates the supplied Cloud identity and sends one request without registering a connection.
The normal Cloud site URL resolves to the Cloud API gateway automatically.

### Example 5: Page a Data Center search

```powershell
Invoke-JiraMethod '/rest/api/2/search' -Connection $dataCenter -QueryParameter @{
    jql = 'project = PROJ ORDER BY key'
} -Paging -PageSize 50 -Skip 10 -First 100
```

Returns at most 100 issue records after skipping the first 10.
PageSize controls the requested batch size; Jira may cap it.
Cloud enhanced search uses the GET endpoint /rest/api/3/search/jql and token pagination.
Skip is applied locally for enhanced-search tokens and as an offset for Data Center search.

### Example 6: Inspect the response

```powershell
$response = Invoke-JiraMethod '/rest/api/2/mypermissions' -RawResponse
$response.StatusCode
$response.Headers
$response.Content
```

Returns the native web response for status, headers and content inspection.
Use this mode for endpoints that return non-JSON content.

### Example 7: Save a response

```powershell
$file = Invoke-JiraMethod '/rest/api/2/project' -OutFile './jira-projects.json'
$file.FullName
```

Saves the response bytes and returns the resulting file.
A POST body may also be combined with OutFile when an endpoint returns a downloadable response.
Use Add-JiraIssueAttachment for Jira multipart attachment uploads.

## PARAMETERS

### -Anonymous

Request anonymous standalone access.
Requires BaseUri and recognized deployment metadata from serverInfo.

```yaml
Type: SwitchParameter
DefaultValue: None
SupportsWildcards: false
Aliases: []
ParameterSets:
- Name: Anonymous
  Position: Named
  IsRequired: true
  ValueFromPipeline: false
  ValueFromPipelineByPropertyName: false
  ValueFromRemainingArguments: false
DontShow: false
AcceptedValues: []
HelpMessage: ''
```

### -ApiToken

The Cloud API token as a nonempty string or SecureString.
Supply BaseUri and EmailAddress in the same call.
A normal Cloud site URL is resolved automatically.

```yaml
Type: Object
DefaultValue: None
SupportsWildcards: false
Aliases: []
ParameterSets:
- Name: CloudToken
  Position: Named
  IsRequired: true
  ValueFromPipeline: false
  ValueFromPipelineByPropertyName: false
  ValueFromRemainingArguments: false
DontShow: false
AcceptedValues: []
HelpMessage: ''
```

### -BaseUri

The product endpoint for a standalone request.
Requires exactly one authentication method: Credential, EmailAddress with ApiToken, PersonalAccessToken, or Anonymous.
Standalone requests validate authentication and do not change the selected default.

```yaml
Type: Uri
DefaultValue: None
SupportsWildcards: false
Aliases: []
ParameterSets:
- Name: Anonymous
  Position: Named
  IsRequired: true
  ValueFromPipeline: false
  ValueFromPipelineByPropertyName: false
  ValueFromRemainingArguments: false
- Name: PersonalAccessToken
  Position: Named
  IsRequired: true
  ValueFromPipeline: false
  ValueFromPipelineByPropertyName: false
  ValueFromRemainingArguments: false
- Name: CloudToken
  Position: Named
  IsRequired: true
  ValueFromPipeline: false
  ValueFromPipelineByPropertyName: false
  ValueFromRemainingArguments: false
- Name: Basic
  Position: Named
  IsRequired: true
  ValueFromPipeline: false
  ValueFromPipelineByPropertyName: false
  ValueFromRemainingArguments: false
DontShow: false
AcceptedValues: []
HelpMessage: ''
```

### -Body

The request payload.
Dictionaries, structured objects, arrays and scalar values are serialized as JSON.
Strings are encoded as UTF-8 without additional JSON serialization.
Byte arrays are sent unchanged.
Structured values require a JSON ContentType; use strings or bytes for other formats.

```yaml
Type: Object
DefaultValue: ''
SupportsWildcards: false
Aliases: []
ParameterSets:
- Name: (All)
  Position: Named
  IsRequired: false
  ValueFromPipeline: false
  ValueFromPipelineByPropertyName: false
  ValueFromRemainingArguments: false
DontShow: false
AcceptedValues: []
HelpMessage: ''
```

### -Confirm

Prompt before a potentially mutating request or file write.

```yaml
Type: SwitchParameter
DefaultValue: ''
SupportsWildcards: false
Aliases:
- cf
ParameterSets:
- Name: (All)
  Position: Named
  IsRequired: false
  ValueFromPipeline: false
  ValueFromPipelineByPropertyName: false
  ValueFromRemainingArguments: false
DontShow: false
AcceptedValues: []
HelpMessage: ''
```

### -Connection

An active Jira connection.
Omitting a selector uses the selected default connection.
Cannot be combined with ConnectionName, BaseUri or authentication inputs.

```yaml
Type: AtlassianPS.Connection
DefaultValue: None
SupportsWildcards: false
Aliases: []
ParameterSets:
- Name: Connection
  Position: Named
  IsRequired: false
  ValueFromPipeline: false
  ValueFromPipelineByPropertyName: false
  ValueFromRemainingArguments: false
DontShow: false
AcceptedValues: []
HelpMessage: ''
```

### -ConnectionName

The name of an active Jira connection.
Cannot be combined with Connection, BaseUri or authentication inputs.

```yaml
Type: String
DefaultValue: None
SupportsWildcards: false
Aliases: []
ParameterSets:
- Name: NamedConnection
  Position: Named
  IsRequired: true
  ValueFromPipeline: false
  ValueFromPipelineByPropertyName: false
  ValueFromRemainingArguments: false
DontShow: false
AcceptedValues: []
HelpMessage: ''
```

### -ContentType

The request media type.
Defaults to application/json; charset=utf-8 when Body is supplied.
Use this parameter or a Content-Type header, not both.

```yaml
Type: String
DefaultValue: ''
SupportsWildcards: false
Aliases: []
ParameterSets:
- Name: (All)
  Position: Named
  IsRequired: false
  ValueFromPipeline: false
  ValueFromPipelineByPropertyName: false
  ValueFromRemainingArguments: false
DontShow: false
AcceptedValues: []
HelpMessage: ''
```

### -Credential

The Basic authentication credential for a standalone request.
Requires BaseUri and cannot be combined with other authentication methods or a selected connection.

```yaml
Type: PSCredential
DefaultValue: None
SupportsWildcards: false
Aliases: []
ParameterSets:
- Name: Basic
  Position: Named
  IsRequired: true
  ValueFromPipeline: false
  ValueFromPipelineByPropertyName: false
  ValueFromRemainingArguments: false
DontShow: false
AcceptedValues: []
HelpMessage: ''
```

### -EmailAddress

The authentication email for a standalone Cloud API token request.
Requires BaseUri and ApiToken in the same call.

```yaml
Type: String
DefaultValue: None
SupportsWildcards: false
Aliases: []
ParameterSets:
- Name: CloudToken
  Position: Named
  IsRequired: true
  ValueFromPipeline: false
  ValueFromPipelineByPropertyName: false
  ValueFromRemainingArguments: false
DontShow: false
AcceptedValues: []
HelpMessage: ''
```

### -First

The maximum number of records to emit when Paging is enabled.
Defaults to all available records.
First 0 makes no request unless IncludeTotalCount is also supplied.

```yaml
Type: UInt64
DefaultValue: 18446744073709551615
SupportsWildcards: false
Aliases: []
ParameterSets:
- Name: (All)
  Position: Named
  IsRequired: false
  ValueFromPipeline: false
  ValueFromPipelineByPropertyName: false
  ValueFromRemainingArguments: false
DontShow: false
AcceptedValues: []
HelpMessage: ''
```

### -Headers

Ordinary request headers.
Authorization, Proxy-Authorization and Cookie headers are rejected; use a connection or standalone authentication parameters.

```yaml
Type: Hashtable
DefaultValue: None
SupportsWildcards: false
Aliases: []
ParameterSets:
- Name: (All)
  Position: Named
  IsRequired: false
  ValueFromPipeline: false
  ValueFromPipelineByPropertyName: false
  ValueFromRemainingArguments: false
DontShow: false
AcceptedValues: []
HelpMessage: ''
```

### -IncludeTotalCount

Emit the server-reported total before the records when Paging is enabled.
The total describes the result before First and Skip are applied.
When Jira omits a total, the count is marked unknown with Accuracy 0.

```yaml
Type: SwitchParameter
DefaultValue: ''
SupportsWildcards: false
Aliases: []
ParameterSets:
- Name: (All)
  Position: Named
  IsRequired: false
  ValueFromPipeline: false
  ValueFromPipelineByPropertyName: false
  ValueFromRemainingArguments: false
DontShow: false
AcceptedValues: []
HelpMessage: ''
```

### -Method

The HTTP method.
Defaults to GET.
Automatic paging supports GET requests only.

```yaml
Type: WebRequestMethod
DefaultValue: '"GET"'
SupportsWildcards: false
Aliases: []
ParameterSets:
- Name: (All)
  Position: Named
  IsRequired: false
  ValueFromPipeline: false
  ValueFromPipelineByPropertyName: false
  ValueFromRemainingArguments: false
DontShow: false
AcceptedValues: []
HelpMessage: ''
```

### -OutFile

The file-system path where response bytes should be saved.
Returns the resulting System.IO.FileInfo without parsing JSON.
An existing file is overwritten after any requested confirmation.
The parent directory must exist.
Cannot be combined with Paging or RawResponse.

```yaml
Type: String
DefaultValue: ''
SupportsWildcards: false
Aliases: []
ParameterSets:
- Name: (All)
  Position: Named
  IsRequired: false
  ValueFromPipeline: false
  ValueFromPipelineByPropertyName: false
  ValueFromRemainingArguments: false
DontShow: false
AcceptedValues: []
HelpMessage: ''
```

### -PageSize

The requested batch size when Paging is enabled.
Defaults to 25; Jira may cap the size.
Use PageSize or QueryParameter.maxResults, not both.

```yaml
Type: Int32
DefaultValue: ''
SupportsWildcards: false
Aliases: []
ParameterSets:
- Name: (All)
  Position: Named
  IsRequired: false
  ValueFromPipeline: false
  ValueFromPipelineByPropertyName: false
  ValueFromRemainingArguments: false
DontShow: false
AcceptedValues: []
HelpMessage: ''
```

### -Paging

Follow supported Jira GET pagination and emit individual records.
Supported item arrays are comments, dashboards, fields, groups, issues, values and worklogs.
Offset responses must include recognized paging metadata.
Enhanced-search GET responses use nextPageToken.
Unsupported, ambiguous or body-based pagination fails with an explanation.
Cannot be combined with RawResponse or OutFile.

```yaml
Type: SwitchParameter
DefaultValue: ''
SupportsWildcards: false
Aliases: []
ParameterSets:
- Name: (All)
  Position: Named
  IsRequired: false
  ValueFromPipeline: false
  ValueFromPipelineByPropertyName: false
  ValueFromRemainingArguments: false
DontShow: false
AcceptedValues: []
HelpMessage: ''
```

### -PersonalAccessToken

The Data Center personal access token as a nonempty string or SecureString.
Requires BaseUri and cannot be combined with another authentication method or a selected connection.

```yaml
Type: Object
DefaultValue: None
SupportsWildcards: false
Aliases:
- PAT
- BearerToken
ParameterSets:
- Name: PersonalAccessToken
  Position: Named
  IsRequired: true
  ValueFromPipeline: false
  ValueFromPipelineByPropertyName: false
  ValueFromRemainingArguments: false
DontShow: false
AcceptedValues: []
HelpMessage: ''
```

### -QueryParameter

Query keys and unencoded values to merge with the resource URL.
Supplied keys override matching keys in the URL.
Array values produce repeated query keys.
Use explicit comma-separated strings for endpoints that require that format.

```yaml
Type: Hashtable
DefaultValue: ''
SupportsWildcards: false
Aliases: []
ParameterSets:
- Name: (All)
  Position: Named
  IsRequired: false
  ValueFromPipeline: false
  ValueFromPipelineByPropertyName: false
  ValueFromRemainingArguments: false
DontShow: false
AcceptedValues: []
HelpMessage: ''
```

### -RawResponse

Return the native web response with status, headers and content instead of parsing JSON.
HTTP failures still report errors.
Cannot be combined with Paging or OutFile.

```yaml
Type: SwitchParameter
DefaultValue: ''
SupportsWildcards: false
Aliases: []
ParameterSets:
- Name: (All)
  Position: Named
  IsRequired: false
  ValueFromPipeline: false
  ValueFromPipelineByPropertyName: false
  ValueFromRemainingArguments: false
DontShow: false
AcceptedValues: []
HelpMessage: ''
```

### -Skip

The number of records to skip when Paging is enabled.
Offset paging applies this value on the server.
Enhanced-search token paging skips records locally across pages.

```yaml
Type: UInt64
DefaultValue: 0
SupportsWildcards: false
Aliases: []
ParameterSets:
- Name: (All)
  Position: Named
  IsRequired: false
  ValueFromPipeline: false
  ValueFromPipelineByPropertyName: false
  ValueFromRemainingArguments: false
DontShow: false
AcceptedValues: []
HelpMessage: ''
```

### -TimeoutSec

The request timeout in seconds.
Defaults to 100; 0 disables the timeout.
Standalone discovery and identity validation use their own bounded validation requests.

```yaml
Type: Int32
DefaultValue: 100
SupportsWildcards: false
Aliases: []
ParameterSets:
- Name: (All)
  Position: Named
  IsRequired: false
  ValueFromPipeline: false
  ValueFromPipelineByPropertyName: false
  ValueFromRemainingArguments: false
DontShow: false
AcceptedValues: []
HelpMessage: ''
```

### -Uri

The Jira REST resource to request.
Relative paths must start with a single slash and resolve against the selected connection.
Absolute URLs must belong to that connection's endpoint.

```yaml
Type: Uri
DefaultValue: ''
SupportsWildcards: false
Aliases: []
ParameterSets:
- Name: (All)
  Position: 0
  IsRequired: true
  ValueFromPipeline: false
  ValueFromPipelineByPropertyName: false
  ValueFromRemainingArguments: false
DontShow: false
AcceptedValues: []
HelpMessage: ''
```

### -WhatIf

Show the intended mutation or file write without sending the request or performing standalone discovery.

```yaml
Type: SwitchParameter
DefaultValue: ''
SupportsWildcards: false
Aliases:
- wi
ParameterSets:
- Name: (All)
  Position: Named
  IsRequired: false
  ValueFromPipeline: false
  ValueFromPipelineByPropertyName: false
  ValueFromRemainingArguments: false
DontShow: false
AcceptedValues: []
HelpMessage: ''
```

### CommonParameters

This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable,
-InformationAction, -InformationVariable, -OutBuffer, -OutVariable, -PipelineVariable,
-ProgressAction, -Verbose, -WarningAction, and -WarningVariable. For more information, see
[about_CommonParameters](https://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

### None

This command does not accept pipeline input.

## OUTPUTS

### System.Object

Parsed JSON responses or individual records when Paging is enabled.

### Microsoft.PowerShell.Commands.WebResponseObject

The native web response when RawResponse is supplied.

### System.IO.FileInfo

The saved file when OutFile is supplied.

## NOTES

This command leaves REST API versions and Cloud/Data Center payload differences to the caller.
Connection selection and authentication are described in about_JiraPS_Authentication.
Response-header logging can be enabled with Set-JiraResponseHeaderLogConfiguration.
Inspect diagnostic output before sharing it.

StoreSession, RawBody, InFile, OutputType and the public cache controls were removed in v3.
Use Connect-Jira for reusable authentication and Add-JiraIssueAttachment for uploads.
GetParameter was renamed to QueryParameter.
Only Uri supports positional binding.

## RELATED LINKS

[Connect-Jira](Connect-Jira.md)

[Add-JiraIssueAttachment](Add-JiraIssueAttachment.md)

[Authentication guide](../about_JiraPS_Authentication.md)
