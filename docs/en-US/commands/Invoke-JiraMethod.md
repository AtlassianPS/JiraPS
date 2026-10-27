---
external help file: JiraPS-help.xml
Module Name: JiraPS
online version: https://atlassianps.org/docs/JiraPS/commands/Invoke-JiraMethod/
locale: en-US
layout: documentation
permalink: /docs/JiraPS/commands/Invoke-JiraMethod/
---
# Invoke-JiraMethod

## SYNOPSIS

Invoke a specific call to a Jira REST Api endpoint

## SYNTAX

```powershell
Invoke-JiraMethod -URI <Uri> [-Method <WebRequestMethod>] [-Body <String>] [-RawBody] [-Headers <Hashtable>] [-GetParameter <Hashtable>] [-Paging] [-InFile <String>] [-OutFile <String>] [-StoreSession] [-OutputType <String>] [-Credential <PSCredential>] [-CacheKey <String>] [-CacheExpiry <TimeSpan>] [-BypassCache] [-TimeoutSec <Int32>] [-Connection <AtlassianPS.Connection>] [-ConnectionName <String>] [-BaseUri <Uri>] [-EmailAddress <String>] [-ApiToken <Object>] [-PersonalAccessToken <Object>] [-Anonymous] [-IncludeTotalCount] [-Skip <UInt64>] [-First <UInt64>] [<CommonParameters>]
```

## DESCRIPTION

Make a call to a REST Api endpoint with all the benefits of JiraPS.

This cmdlet is what the other cmdlets call under the hood.
It handles the authentication, parses the response, handles exceptions from Jira, returns specific objects and handles the differences between versions of Powershell and Operating Systems.
When you pass a relative URI path, it must start with `/` and JiraPS resolves it against `Get-JiraConfigServer`.
Absolute URIs are also accepted for compatibility with object properties like `RestURL`.

Use `Set-JiraResponseHeaderLogConfiguration` to opt into response-header logging on the debug stream.
This is useful when troubleshooting Jira Data Center diagnostic headers such as `X-AREQUESTID`, `X-ANODEID`, `X-ASESSIONID`, and `X-AUSERNAME`.
Debug output can include diagnostic metadata such as Jira usernames, so review logs before sharing them.

JiraPS does not support any third-party plugins on Jira.
This cmdlet can be used to interact with REST Api enpoints which are not already coverted in JiraPS.
It allows for anyone to use the same technics as JiraPS uses internally for creating their own functions or modules.
When used by a module, the Manifest (.psd1) can define the dependency to JiraPS with the 'RequiredModules' property.
This will import the module if not already loaded or even download it from the PSGallery.

## EXAMPLES

### Example 1

```powershell
Invoke-JiraMethod -URI "/rest/api/latest/project"
```

Sends a GET request which will return all the projects on the Jira server.
This call would either be executed anonymously or require a session to be available.

### Example 2

```powershell
Invoke-JiraMethod -URI "/rest/api/latest/project" -Credential (Get-Credential)
```

Prompts the user for his Jira credentials and send a GET request,
which will return all the projects on the Jira server.

### Example 3

```powershell
$parameter = @{
    URI = "/rest/api/latest/project"
    Method = "POST"
    Credential = $cred
}
Invoke-JiraMethod @parameter
```

Sends a POST request to the server.

> This will example doesn't really do anything on the server, as the content API needs requires a value for the BODY.

See next example

### Example 4

```powershell
$body = '{"name": "NewGroup"}'
$params = @{
    Uri = "/rest/api/latest/group"
    Method = "POST"
    Body = $body
    Credential = $cred
}
Invoke-JiraMethod @params
```

Creates a new group named "NewGroup"

### Example 5

```powershell
$params = @{
    Uri = "/rest/api/latest/mypermissions"
    Method = "GET"
    Body = $body
    StoreSession = $true
    Credential = $cred
}
Invoke-JiraMethod @params
```

Executes the GET request but instead of returning the response,
it returns a `[AtlassianPS.JiraPS.Session]` which contains the `[WebRequestSession]`.

### Example 6

```powershell
$params = @{
    Uri = "/rest/api/latest/issue/10000"
    Method = "POST"
    InFile = "c:\temp\20001231_Connection.log"
    Credential = $cred
}
Invoke-JiraMethod @params
```

Executes a POST request on the defined URI and uploads the InFile with a multipart/form-data request.

### Example 7

```powershell
$parameter = @{
    URI = "/rest/api/latest/project"
    Method = "GET"
    OutFile = "c:\temp\jira_projects.json"
    Credential = $cred
}
Invoke-JiraMethod @parameter
```

Executes a GET request on all available projects and stores the response json in the defined file.

### Example 8

```powershell
$parameter = @{
    URI = "/rest/api/latest/project"
    Method = "GET"
    Headers = @{"Accept" = "text/plain"}
    OutFile = "c:\temp\jira_projects.json"
    Credential = $cred
}
Invoke-JiraMethod @parameter
```

Executes a GET request on the defined URI and stores the output on the File System.
It also uses the Headers to define what mimeTypes are expected in the response.

### Example 9

```powershell
$parameter = @{
    URI = "/rest/api/latest/field"
    Method = "GET"
    CacheKey = "Fields"
    CacheExpiry = [TimeSpan]::FromHours(1)
}
Invoke-JiraMethod @parameter
```

Fetches all fields from Jira and caches the response for 1 hour.
Subsequent calls with the same CacheKey will return the cached data without making an API call.

### Example 10

```powershell
# 30 seconds — short-lived data
Invoke-JiraMethod -URI $uri -CacheKey "Status" -CacheExpiry ([TimeSpan]::FromSeconds(30))

# 15 minutes — moderately static data
Invoke-JiraMethod -URI $uri -CacheKey "Priorities" -CacheExpiry ([TimeSpan]::FromMinutes(15))

# 2 hours — rarely changing reference data
Invoke-JiraMethod -URI $uri -CacheKey "IssueTypes" -CacheExpiry ([TimeSpan]::FromHours(2))

# 1 day — essentially static configuration
Invoke-JiraMethod -URI $uri -CacheKey "ServerInfo" -CacheExpiry ([TimeSpan]::FromDays(1))

# Using New-TimeSpan cmdlet — combines multiple units
Invoke-JiraMethod -URI $uri -CacheKey "Custom" -CacheExpiry (New-TimeSpan -Hours 1 -Minutes 30)

# Using string literal — PowerShell auto-converts "hh:mm:ss" to TimeSpan
Invoke-JiraMethod -URI $uri -CacheKey "Custom" -CacheExpiry "00:45:00"

```

Demonstrates various ways to construct a `[TimeSpan]` value for `-CacheExpiry`.
Use the form that best communicates the intended duration.

### Example 11

```powershell
$parameter = @{
    URI = "/rest/api/latest/field"
    CacheKey = "Fields"
    BypassCache = $true
}
Invoke-JiraMethod @parameter
```

Forces a fresh API call, ignoring any cached data.
The fresh response will be stored in the cache.

## PARAMETERS

### -Body

Body of the HTTP request.

By default each character of the Body is encoded to a sequence of bytes.
This enables the support of UTF8 characters.
And was first reported here:
https://stackoverflow.com/questions/15290185/invoke-webrequest-issue-with-special-characters-in-json

This behavior can be changed with -RawBody.

```yaml
Type: String
DefaultValue: ''
SupportsWildcards: false
Aliases: []
ParameterSets:
- Name: (All)
  Position: 2
  IsRequired: false
  ValueFromPipeline: false
  ValueFromPipelineByPropertyName: false
  ValueFromRemainingArguments: false
DontShow: false
AcceptedValues: []
HelpMessage: ''
```

### -BypassCache

When specified, ignores any cached response and makes a fresh API call.
The fresh response will still be stored in the cache.
Only applies when `-CacheKey` is specified.

```yaml
Type: SwitchParameter
DefaultValue: False
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

### -CacheExpiry

Specifies how long cached responses should be valid, as a `[TimeSpan]`.
Only applies when `-CacheKey` is specified.

Common ways to construct a TimeSpan:

| Duration    | Using static methods                | Using New-TimeSpan              | String literal |
| ----------- | ----------------------------------- | ------------------------------- | -------------- |
| 30 seconds  | `[TimeSpan]::FromSeconds(30)`       | `New-TimeSpan -Seconds 30`      | `"00:00:30"`   |
| 5 minutes   | `[TimeSpan]::FromMinutes(5)`        | `New-TimeSpan -Minutes 5`       | `"00:05:00"`   |
| 1 hour      | `[TimeSpan]::FromHours(1)`          | `New-TimeSpan -Hours 1`         | `"01:00:00"`   |
| 1.5 hours   | `[TimeSpan]::FromMinutes(90)`       | `New-TimeSpan -Hours 1 -Minutes 30` | `"01:30:00"` |
| 1 day       | `[TimeSpan]::FromDays(1)`           | `New-TimeSpan -Days 1`          | `"1.00:00:00"` |

```yaml
Type: TimeSpan
DefaultValue: '[TimeSpan]::FromHours(1)'
SupportsWildcards: false
Aliases: []
ParameterSets:
- Name: (All)
  Position: 12
  IsRequired: false
  ValueFromPipeline: false
  ValueFromPipelineByPropertyName: false
  ValueFromRemainingArguments: false
DontShow: false
AcceptedValues: []
HelpMessage: ''
```

### -CacheKey

When specified, enables caching for this GET request.
The response will be stored in a module-level cache and returned on subsequent calls with the same CacheKey until the cache expires or is cleared.

Only applies to GET requests.
POST, PUT, DELETE requests are never cached.

```yaml
Type: String
DefaultValue: ''
SupportsWildcards: false
Aliases: []
ParameterSets:
- Name: (All)
  Position: 11
  IsRequired: false
  ValueFromPipeline: false
  ValueFromPipelineByPropertyName: false
  ValueFromRemainingArguments: false
DontShow: false
AcceptedValues: []
HelpMessage: ''
```

### -Cmdlet

Context which will be used for throwing errors.

```yaml
Type: PSCmdlet
DefaultValue: 'PSCmdlet'
SupportsWildcards: false
Aliases: []
ParameterSets:
- Name: (All)
  Position: 9
  IsRequired: false
  ValueFromPipeline: false
  ValueFromPipelineByPropertyName: false
  ValueFromRemainingArguments: false
DontShow: false
AcceptedValues: []
HelpMessage: ''
```

### -Credential

Username/password or compatible Cloud email/token as PSCredential. Explicit input temporarily overrides the selected identity without inheriting cookies or changing the stored connection. An empty credential fails; omitted input uses the selected connection.

```yaml
Type: PSCredential
Parameter Sets: (All)
Aliases: None

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -First

Indicates how many items to return.

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

### -GetParameter

Key-Value pair of the Headers to be used.

```yaml
Type: Hashtable
DefaultValue: '@{}'
SupportsWildcards: false
Aliases: []
ParameterSets:
- Name: (All)
  Position: 4
  IsRequired: false
  ValueFromPipeline: false
  ValueFromPipelineByPropertyName: false
  ValueFromRemainingArguments: false
DontShow: false
AcceptedValues: []
HelpMessage: ''
```

### -Headers

Ordinary request headers. Authorization and Cookie headers are rejected; supply authentication through the supported parameters.

```yaml
Type: Hashtable
Parameter Sets: (All)
Aliases: None

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -IncludeTotalCount

Causes an extra output of the total count at the beginning.
The count uses Jira's reported total before `-First` and `-Skip` are applied.
If Jira does not report a total, the count is marked as unknown with `Accuracy` set to `0`.

Note this is actually a uInt64, but with a custom string representation.

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

### -InFile

Path to a file that will be uploaded with a multipart/form-data request.

This parameter does not validate the input in any way.

```yaml
Type: String
DefaultValue: ''
SupportsWildcards: false
Aliases: []
ParameterSets:
- Name: (All)
  Position: 5
  IsRequired: false
  ValueFromPipeline: false
  ValueFromPipelineByPropertyName: false
  ValueFromRemainingArguments: false
DontShow: false
AcceptedValues: []
HelpMessage: ''
```

### -Method

Method of the HTTP request.

```yaml
Type: WebRequestMethod
DefaultValue: '"GET"'
SupportsWildcards: false
Aliases: []
ParameterSets:
- Name: (All)
  Position: 1
  IsRequired: false
  ValueFromPipeline: false
  ValueFromPipelineByPropertyName: false
  ValueFromRemainingArguments: false
DontShow: false
AcceptedValues: []
HelpMessage: ''
```

### -OutFile

Path to the file where the response should be stored to.

This parameter does not validate the input in any way

```yaml
Type: String
DefaultValue: ''
SupportsWildcards: false
Aliases: []
ParameterSets:
- Name: (All)
  Position: 6
  IsRequired: false
  ValueFromPipeline: false
  ValueFromPipelineByPropertyName: false
  ValueFromRemainingArguments: false
DontShow: false
AcceptedValues: []
HelpMessage: ''
```

### -OutputType

Name of the data type that is expected to be returned.

Currently only used in combination with `-Paging`

```yaml
Type: String
DefaultValue: ''
SupportsWildcards: false
Aliases: []
ParameterSets:
- Name: (All)
  Position: 7
  IsRequired: false
  ValueFromPipeline: false
  ValueFromPipelineByPropertyName: false
  ValueFromRemainingArguments: false
DontShow: false
AcceptedValues:
- JiraComment
- JiraIssue
- JiraUser
- JiraVersion
- JiraWorklogItem
HelpMessage: ''
```

### -Paging

Use paging on the results.

More about paging: <https://docs.atlassian.com/software/jira/docs/api/REST/7.6.1/#pagination>

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

### -RawBody

Keep the Body from being encoded.

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

Controls how many things will be skipped before starting output.

Defaults to 0.

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

### -StoreSession

Obsolete in this connection API. Use Connect-Jira rather than transport session capture.

```yaml
Type: SwitchParameter
Parameter Sets: (All)
Aliases: None

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -TimeoutSec

Per-request HTTP timeout, in seconds.
Defaults to `100` (matches the historical .NET `HttpClient` default).

The previous behaviour was to omit the parameter entirely, which inherits `Invoke-WebRequest`'s per-host default — `Infinite` on PowerShell 7+ — and lets a hung Jira instance block the calling pipeline indefinitely.
Bounding the request at 100 seconds surfaces a `WebException` that callers can retry or report instead of waiting forever.

Set to `0` to disable the timeout (use sparingly; reserved for caller-driven long uploads such as large attachments).

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

### -URI

URI address of the REST API endpoint.
Relative paths must start with `/`.
When a relative path is used, JiraPS prefixes it with the configured Jira server URL.
Absolute URLs are still supported.

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

### -Connection

Live shared connection for this operation. Session is a compatibility alias. The object must be active in this runspace and belong to Jira.

```yaml
Type: AtlassianPS.Connection
Parameter Sets: (All)
Aliases: Session

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -ConnectionName

Case-insensitive name of an active Jira connection. Server and ServerName are compatibility aliases. This parameter is mutually exclusive with Connection and a standalone endpoint.

```yaml
Type: String
Parameter Sets: (All)
Aliases: Server, ServerName

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -BaseUri

Standalone Jira product endpoint. Uri remains the REST resource. Cannot be combined with Connection or ConnectionName. Normal HTTPS Cloud site URLs discover their gateway for ApiToken authentication.

```yaml
Type: Uri
Parameter Sets: (All)
Aliases: None

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -EmailAddress

Cloud authentication email for ApiToken. Email is an alias. An override must supply both its own email and token.

```yaml
Type: String
Parameter Sets: (All)
Aliases: Email

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -ApiToken

Cloud API token as a nonempty string or SecureString. Supply the authentication email in the same call. The module normalizes the secret and resolves a normal Cloud site URL automatically.

```yaml
Type: Object
Parameter Sets: (All)
Aliases: None

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -PersonalAccessToken

Data Center PAT as a nonempty string or SecureString. PAT and BearerToken are aliases. No dummy username is required.

```yaml
Type: Object
Parameter Sets: (All)
Aliases: PAT, BearerToken

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Anonymous

Explicit anonymous authentication when the Jira endpoint permits it. Never borrows the default connection identity.

```yaml
Type: SwitchParameter
Parameter Sets: (All)
Aliases: None

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### CommonParameters

This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable,
-InformationAction, -InformationVariable, -OutBuffer, -OutVariable, -PipelineVariable,
-ProgressAction, -Verbose, -WarningAction, and -WarningVariable. For more information, see
[about_CommonParameters](https://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

## OUTPUTS

### System.Management.Automation.PSCustomObject

This command is designed to handle JSON responses only.
The response is convert to PSCustomObject with `ConvertFrom-Json`

## NOTES

Uri is a REST resource and retains that meaning.
Use BaseUri to supply a standalone product endpoint.
Relative resources preserve application and gateway context paths.
Absolute URLs must match the selected endpoint; matching Cloud site REST URLs are mapped to its resolved gateway.
Foreign origins, redirects and escaped context paths fail before a second authenticated request.
When no connection is selected, supply BaseUri rather than relying on an arbitrary absolute resource URL.

Uri is a REST resource and retains that meaning.
Use BaseUri to supply a standalone product endpoint.
Relative resources preserve application and gateway context paths.
Absolute URLs must match the selected endpoint; matching Cloud site REST URLs are mapped to its resolved gateway.
Foreign origins, redirects and escaped context paths fail before a second authenticated request.
When no connection is selected, supply BaseUri rather than relying on an arbitrary absolute resource URL.

## RELATED LINKS

[about_JiraPS_Authentication](../../about/authentication.html)

[Jira Cloud API](https://developer.atlassian.com/cloud/jira/platform/rest/)

[Jira Server API](https://docs.atlassian.com/software/jira/docs/api/REST/7.6.1/)
