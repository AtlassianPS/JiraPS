---
external help file: JiraPS-help.xml
online version: 
schema: 2.0.0
---

# New-JiraIssue

## SYNOPSIS
Creates an issue in JIRA

## SYNTAX

```
New-JiraIssue [-Project] <String> [-IssueType] <String> [[-Priority] <Int32>] [-Summary] <String>
 [[-Description] <String>] [[-Reporter] <String>] [[-Labels] <String[]>] [[-Parent] <String>]
 [[-FixVersion] <String[]>] [[-Fields] <Hashtable>] [[-Credential] <PSCredential>] [-WhatIf] [-Confirm]
```

## DESCRIPTION
This function creates a new issue in JIRA.

Creating an issue requires a lot of data, and the exact data may be
different from one instance of JIRA to the next. 
To identify what data
is required for a given issue type and project, use the
Get-JiraIssueCreateMetadata function provided in this module.

Some JIRA instances may require additional custom fields specific to that
instance of JIRA. 
In addition to the parameterized fields provided in
this function, the Fields parameter accepts a hashtable of field names /
IDs and values. 
This allows users to provide custom field data when
creating an issue.

## EXAMPLES

### -------------------------- EXAMPLE 1 --------------------------
```
Get-JiraIssueCreateMetadata -Project TEST -IssueType Bug | ? {$_.Required -eq $true}
```

New-JiraIssue -Project TEST -IssueType Bug -Priority 1 -Summary 'Test issue from PowerShell' -Description 'This is a test issue created from the JiraPS module in PowerShell.' -Fields {'Custom Field Name 1'='foo';'customfield_10001'='bar';}
This example uses Get-JiraIssueCreateMetadata to identify fields required
to create an issue in JIRA. 
It then creates an issue with the Fields parameter
providing a field name and a field ID.

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

### -Priority
ID of the Priority the issue shall have.

```yaml
Type: Int32
Parameter Sets: (All)
Aliases: 

Required: False
Position: 3
Default value: 0
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
Position: 4
Default value: None
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
User that shall be registed as the reporter.
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
Parent issue - in case of "Sub-Tasks".

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

```yaml
Type: Hashtable
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

## INPUTS

### This function does not accept pipeline input.

## OUTPUTS

### [JiraPS.Issue] The issue created in JIRA.

## NOTES

## RELATED LINKS

