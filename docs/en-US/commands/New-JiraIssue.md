---
external help file: JiraPS-help.xml
Module Name: JiraPS
online version: https://atlassianps.org/docs/JiraPS/commands/New-JiraIssue/
locale: en-US
schema: 2.0.0
layout: documentation
permalink: /docs/JiraPS/commands/New-JiraIssue/
---
# New-JiraIssue

## SYNOPSIS

Creates a new issue in JIRA

## SYNTAX

```powershell
New-JiraIssue [-Project] <String> [-IssueType] <String> [-Summary] <String> [[-Priority] <Int32>]
 [[-Description] <String>] [[-Reporter] <String>] [[-Labels] <String[]>] [[-Parent] <String>]
 [[-FixVersion] <String[]>] [[-Fields] <PSCustomObject>] [[-Credential] <PSCredential>] [-WhatIf] [-Confirm]
 [<CommonParameters>]
```

## DESCRIPTION

This function creates a new issue in JIRA.

Creating an issue requires a lot of data, and the exact data may be
different from one instance of JIRA to the next.

To identify what data is required for a given issue type and project,
use the `Get-JiraIssueCreateMetadata` function provided in this module.

Some JIRA instances may require additional custom fields specific to that instance of JIRA.
In addition to the parameterized fields provided in this function,
the Fields parameter accepts a hashtable of field names/IDs and values.
This allows users to provide custom field data when creating an issue.
Read more about it in [about_JiraPS_CustomFields](../../about/custom-fields.html)

## EXAMPLES

### EXAMPLE 1

```powershell
New-JiraIssue -Project "TEST" -Type "Bug" -Summary "Test issue"
```

Creates a new issue in the TEST project.

This is the simplest way possible to use the command,
given the project only requires these fields as mandatory.

### EXAMPLE 2

```powershell
Get-JiraIssueCreateMetadata -Project TEST -IssueType Bug | ? {$_.Required -eq $true}
New-JiraIssue -Project TEST -IssueType Bug -Priority 1 -Summary 'Test issue from PowerShell' -Description 'This is a test issue created from the JiraPS module in PowerShell.' -Fields @{'Custom Field Name 1'=@{"foo" = "bar"};'customfield_10001'=@('baz');}
```

This example uses `Get-JiraIssueCreateMetadata` to identify fields required to create an issue in JIRA.
It then creates an issue with the Fields parameter providing a field name and a field ID.

### EXAMPLE 3

```powershell
$parameters = @{
    Project = "TEST"
    IssueType = "Bug"
    Priority = 1
    Summary = 'Test issue from PowerShell'
    Description = 'This is a test issue created from the JiraPS module in PowerShell.'
    Fields = @{
        "Custom Field Name 1" = @{"foo" = "bar"}
        customfield_10001 = @('baz')
    }
}
New-JiraIssue @parameters
```

This illustrates how to use splatting for the example above.

Read more about splatting: about_Splatting

### EXAMPLE 4

```powershell
"project,summary,assignee,IssueType,Priority,Description" > "./data.csv"
"CS,Some Title 1,admin,Minor,1,Some Description 1" >> "./data.csv"
"CS,Some Title 2,admin,Minor,1,Some Description 2" >> "./data.csv"
import-csv "./data.csv" | New-JiraIssue
```
This example illuetrates how to prepare multiple new stories and pipe them to be created all at once.

## PARAMETERS

### -Project

Project in which to create the issue.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: True
Position: 1
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -IssueType

Type of the issue.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: True
Position: 2
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Summary

Summary of the issue.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: True
Position: 3
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Priority

ID of the Priority the issue shall have.

```yaml
Type: Int32
Parameter Sets: (All)
Aliases:

Required: False
Position: 4
Default value: 0
Accept pipeline input: False
Accept wildcard characters: False
```

### -Description

Long description of the issue.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 5
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Reporter

User that shall be registered as the reporter.

If left empty, the currently authenticated user will be used.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 6
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Labels

List of labels which will be added to the issue.

```yaml
Type: String[]
Parameter Sets: (All)
Aliases:

Required: False
Position: 7
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Parent

Parent issue - in case of issues of type "Sub-Tasks".

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 8
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -FixVersion

Set the FixVersion of the issue.

```yaml
Type: String[]
Parameter Sets: (All)
Aliases: FixVersions

Required: False
Position: 9
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Fields

Any additional fields.

See: about_JiraPS_CustomFields

```yaml
Type: PSCustomObject
Parameter Sets: (All)
Aliases:

Required: False
Position: 10
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Credential

Credentials to use to connect to JIRA.  
If not specified, this function will use anonymous access.

```yaml
Type: PSCredential
Parameter Sets: (All)
Aliases:

Required: False
Position: 11
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -WhatIf

Shows what would happen if the cmdlet runs.
The cmdlet is not run.

```yaml
Type: SwitchParameter
Parameter Sets: (All)
Aliases: wi

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Confirm

Prompts you for confirmation before running the cmdlet.

```yaml
Type: SwitchParameter
Parameter Sets: (All)
Aliases: cf

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### CommonParameters

This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable.
For more information, see about_CommonParameters (http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

## OUTPUTS

### [JiraPS.Issue]

## NOTES

This function requires either the `-Credential` parameter to be passed or a persistent JIRA session.
See `New-JiraSession` for more details.
If neither are supplied, this function will run with anonymous access to JIRA.

## RELATED LINKS

[about_JiraPS_CreatingIssues](../../about/creating-issues.html)

[about_JiraPS_CustomFields](../../about/custom-fields.html)

[Get-JiraIssueCreateMetadata](../Get-JiraIssueCreateMetadata/)

[Get-JiraComponent](../Get-JiraComponent/)

[Get-JiraField](../Get-JiraField/)

[Get-JiraPriority](../Get-JiraPriority/)

[Get-JiraProject](../Get-JiraProject/)

[Get-JiraVersion](../Get-JiraVersion/)
