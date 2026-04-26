---
external help file: JiraPS-help.xml
Module Name: JiraPS
online version: https://atlassianps.org/docs/JiraPS/commands/Set-JiraResponseHeaderLogConfiguration/
locale: en-US
layout: documentation
permalink: /docs/JiraPS/commands/Set-JiraResponseHeaderLogConfiguration/
---
# Set-JiraResponseHeaderLogConfiguration

## SYNOPSIS

Configures Jira response headers that `Invoke-JiraMethod` writes to the debug stream.

## SYNTAX

```powershell
Set-JiraResponseHeaderLogConfiguration -Include <string[]> [-Exclude <string[]>] [<CommonParameters>]
```

```powershell
Set-JiraResponseHeaderLogConfiguration -Pattern <regex> [<CommonParameters>]
```

```powershell
Set-JiraResponseHeaderLogConfiguration -Disable [<CommonParameters>]
```

## DESCRIPTION

`Set-JiraResponseHeaderLogConfiguration` configures which HTTP response headers JiraPS logs when `Invoke-JiraMethod` receives a response from Jira.
The configuration is disabled by default.
After you configure it, matching headers are written to the debug stream when callers use `-Debug`.

The configuration is stored in module-scoped memory, like the JiraPS response cache.
It survives normal cmdlet calls in the current module instance and is cleared when the module is forcefully reloaded.
It is not written to disk or user profile storage.

`Set-Cookie`, `Set-Cookie2`, `Authorization`, and `Proxy-Authorization` response headers are always suppressed even when patterns would match them.
Debug output can still include diagnostic metadata such as Jira usernames, request IDs, node IDs, or session IDs, so review logs before sharing them.

## EXAMPLES

### EXAMPLE 1

```powershell
Set-JiraResponseHeaderLogConfiguration -Include 'X-A*'
Invoke-JiraMethod -Uri '/rest/api/2/serverInfo' -Debug
```

Logs Jira Data Center diagnostic response headers such as `X-AREQUESTID`, `X-ANODEID`, `X-ASESSIONID`, and `X-AUSERNAME` to the debug stream.
`Authorization` and cookie response headers are always suppressed regardless of the `-Include` pattern.

### EXAMPLE 2

```powershell
Set-JiraResponseHeaderLogConfiguration -Include 'X-A*', 'X-Trace-*' -Exclude 'X-Auth*'
```

Logs response headers matching either `X-A*` or `X-Trace-*` and excludes any header matching `X-Auth*` (for example, custom `X-Auth-Token` headers).
The `-Include` and `-Exclude` parameters accept an array of wildcard patterns.

### EXAMPLE 3

```powershell
Set-JiraResponseHeaderLogConfiguration -Pattern '^X-A(?!uth)'
Invoke-JiraMethod -Uri '/rest/api/2/serverInfo' -Debug
```

Uses a regular expression to log `X-A*` response headers while avoiding any `X-Auth*` headers.
Regex matching is case-insensitive.

### EXAMPLE 4

```powershell
Set-JiraResponseHeaderLogConfiguration -Disable
```

Disables response-header logging for the current module instance.

## PARAMETERS

### -Disable

Disables response-header logging by clearing the module-scoped configuration.

```yaml
Type: SwitchParameter
DefaultValue: False
SupportsWildcards: false
Aliases: []
ParameterSets:
- Name: Disabled
  Position: Named
  IsRequired: true
  ValueFromPipeline: false
  ValueFromPipelineByPropertyName: false
  ValueFromRemainingArguments: false
DontShow: false
AcceptedValues: []
HelpMessage: ''
```

### -Exclude

Wildcard patterns for response header names to exclude after `-Include` has matched.
Matching is case-insensitive.

```yaml
Type: String[]
DefaultValue: ''
SupportsWildcards: true
Aliases: []
ParameterSets:
- Name: Wildcard
  Position: Named
  IsRequired: false
  ValueFromPipeline: false
  ValueFromPipelineByPropertyName: false
  ValueFromRemainingArguments: false
DontShow: false
AcceptedValues: []
HelpMessage: ''
```

### -Include

Wildcard patterns for response header names to log.
Matching is case-insensitive.

```yaml
Type: String[]
DefaultValue: ''
SupportsWildcards: true
Aliases: []
ParameterSets:
- Name: Wildcard
  Position: Named
  IsRequired: true
  ValueFromPipeline: false
  ValueFromPipelineByPropertyName: false
  ValueFromRemainingArguments: false
DontShow: false
AcceptedValues: []
HelpMessage: ''
```

### -Pattern

Regular expression used to select response header names to log.
Regex matching is case-insensitive.

```yaml
Type: Regex
DefaultValue: ''
SupportsWildcards: false
Aliases: []
ParameterSets:
- Name: Regex
  Position: Named
  IsRequired: true
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

## OUTPUTS

## NOTES

The configuration affects only the current module instance.
Forcefully reloading the module clears the setting.

## RELATED LINKS

[Invoke-JiraMethod](../Invoke-JiraMethod/)
