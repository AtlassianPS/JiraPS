---
external help file: JiraPS-help.xml
Module Name: JiraPS
online version: https://atlassianps.org/docs/JiraPS/commands/Get-JiraIssueAttachmentFile/
locale: en-US
layout: documentation
permalink: /docs/JiraPS/commands/Get-JiraIssueAttachmentFile/
---
# Get-JiraIssueAttachmentFile

## SYNOPSIS

Save an attachment to disk.

## SYNTAX

```powershell
Get-JiraIssueAttachmentFile -Attachment <AtlassianPS.JiraPS.Attachment[]> [-Path <String>] [-Credential <PSCredential>] [-Connection <AtlassianPS.Connection>] [-ConnectionName <String>] [-Uri <Uri>] [-EmailAddress <String>] [-ApiToken <Object>] [-PersonalAccessToken <Object>] [-Anonymous] [<CommonParameters>]
```

## DESCRIPTION

This function downloads an attachment of an issue to the local disk.

## EXAMPLES

### Example 1

```powershell
Get-JiraIssueAttachmentFile (Get-JiraIssueAttachment -Issue TEST-001)
```

This example downloads all attachments from issue TEST-001 to the current working directory.

### Example 2

```powershell
Get-JiraIssue TEST-002 | Get-JiraIssueAttachment | Get-JiraIssueAttachmentFile
```

This example illustrates use of the pipeline to download all attachments from issue TEST-002.

### Example 3

```powershell
Get-JiraIssue TEST-002 |
    Get-JiraIssueAttachment -FileName '*.png' |
    Get-JiraIssueAttachmentFile -Path 'C:\temp'
```

Download all attachments of issue TEST-002 where the filename ends in `.png` to a specific location.

## PARAMETERS

### -Attachment

Attachment which will be downloaded.

```yaml
Type: AtlassianPS.JiraPS.Attachment[]
DefaultValue: ''
SupportsWildcards: false
Aliases: []
ParameterSets:
- Name: (All)
  Position: 0
  IsRequired: true
  ValueFromPipeline: true
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

### -Path

Path in which to store to attachment.

The name of the file will be appended to the Path provided.

```yaml
Type: String
DefaultValue: ''
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

### -Uri

Standalone Jira product endpoint for this logical operation. Cannot be combined with Connection or ConnectionName. Supply one explicit authentication mode; use Anonymous for anonymous access. Normal HTTPS commercial Atlassian site URLs resolve cloudId and the API gateway automatically for ApiToken authentication.

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

This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutBuffer, -OutVariable, -PipelineVariable, -ProgressAction, -Verbose, -WarningAction, and -WarningVariable.
For more information, see [about_CommonParameters](https://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

### AtlassianPS.JiraPS.Attachment

## OUTPUTS

### Bool


### System.Boolean

## NOTES

This function requires either the `-Credential` parameter to be passed or a persistent Jira session.
See `New-JiraSession` for more details.
If neither are supplied, this function will run with anonymous access to Jira.

## RELATED LINKS

[Get-JiraAttachment](../Get-JiraIssueAttachmentFile/)

[Add-JiraIssueAttachmentFile](../Add-JiraIssueAttachment/)

[Get-JiraIssue](../Get-JiraIssue/)

[Remove-JiraIssueAttachmentFile](../Remove-JiraIssueAttachment/)
