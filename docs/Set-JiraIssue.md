---
external help file: JiraPS-help.xml
online version: 
schema: 2.0.0
---

# Set-JiraIssue

## SYNOPSIS
Modifies an existing issue in JIRA

## SYNTAX

```
Set-JiraIssue [-Issue] <Object[]> [-Summary <String>] [-Description <String>] [-FixVersion <String[]>]
 [-Assignee <Object>] [-Label <String[]>] [-Fields <Hashtable>] [-ConfigFile <String>]
 [-Credential <PSCredential>] [-PassThru] [-WhatIf] [-Confirm]
```

## DESCRIPTION
This function modifies an existing isue in JIRA. 
This can include changing
the issue's summary or description, or assigning the issue.

## EXAMPLES

### -------------------------- EXAMPLE 1 --------------------------
```
Set-JiraIssue -Issue TEST-01 -Summary 'Modified issue summary' -Description 'This issue has been modified by PowerShell'
```

This example changes the summary and description of the JIRA issue TEST-01.

### -------------------------- EXAMPLE 2 --------------------------
```
$issue = Get-JiraIssue TEST-01
```

$issue | Set-JiraIssue -Description "$($issue.Description)\`n\`nEdit: Also foo."
This example appends text to the end of an existing issue description by using
Get-JiraIssue to obtain a reference to the current issue and description.

### -------------------------- EXAMPLE 3 --------------------------
```
Set-JiraIssue -Issue TEST-01 -Assignee 'Unassigned'
```

This example removes the assignee from JIRA issue TEST-01.

## PARAMETERS

### -Issue
Issue key or JiraPS.Issue object returned from Get-JiraIssue

```yaml
Type: Object[]
Parameter Sets: (All)
Aliases: Key

Required: True
Position: 1
Default value: None
Accept pipeline input: True (ByPropertyName, ByValue)
Accept wildcard characters: False
```

### -Summary
New summary of the issue.

```yaml
Type: String
Parameter Sets: (All)
Aliases: 

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Description
New description of the issue.

```yaml
Type: String
Parameter Sets: (All)
Aliases: 

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -FixVersion
Set the FixVersion of the issue, this will overwrite any present FixVersions

```yaml
Type: String[]
Parameter Sets: (All)
Aliases: FixVersions

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Assignee
New assignee of the issue.
Enter 'Unassigned' to unassign the issue.

```yaml
Type: Object
Parameter Sets: (All)
Aliases: 

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Label
Labels to be set on the issue.
These wil overwrite any existing
labels on the issue.
For more granular control over issue labels,
use Set-JiraIssueLabel.

```yaml
Type: String[]
Parameter Sets: (All)
Aliases: 

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Fields
Any additional fields that should be updated.

```yaml
Type: Hashtable
Parameter Sets: (All)
Aliases: 

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -ConfigFile
Path of the file where the configuration is stored.

```yaml
Type: String
Parameter Sets: (All)
Aliases: 

Required: False
Position: Named
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
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -PassThru
Whether output should be provided after invoking this function.

```yaml
Type: SwitchParameter
Parameter Sets: (All)
Aliases: 

Required: False
Position: Named
Default value: False
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

### [JiraPS.Issue[]] The JIRA issue that should be modified

## OUTPUTS

### If the -PassThru parameter is provided, this function will provide a reference
to the JIRA issue modified.  Otherwise, this function does not provide output.

## NOTES

## RELATED LINKS

