---
external help file: JiraPS-help.xml
online version: 
schema: 2.0.0
---

# Get-JiraIssueCreateMetadata

## SYNOPSIS
Returns metadata required to create an issue in JIRA

## SYNTAX

```
Get-JiraIssueCreateMetadata [-Project] <String> [-IssueType] <String> [-ConfigFile <String>]
 [-Credential <PSCredential>]
```

## DESCRIPTION
This function returns metadata required to create an issue in JIRA - the fields that can be defined in the process of creating an issue. 
This can be used to identify custom fields in order to pass them to New-JiraIssue.

This function is particularly useful when your JIRA instance includes custom fields that are marked as mandatory. 
The required fields can be identified from this See the examples for more details on this approach.

## EXAMPLES

### -------------------------- EXAMPLE 1 --------------------------
```
Get-JiraIssueCreateMetadata -Project 'TEST' -IssueType 'Bug'
```

This example returns the fields available when creating an issue of type Bug under project TEST.

### -------------------------- EXAMPLE 2 --------------------------
```
Get-JiraIssueCreateMetadata -Project 'JIRA' -IssueType 'Bug' | ? {$_.Required -eq $true}
```

This example returns fields available when creating an issue of type Bug under the project Jira. 
It then uses Where-Object (aliased by the question mark) to filter only the fields that are required.

## PARAMETERS

### -Project
Project ID or key of the reference issue.

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
Issue type ID or name.

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

### -ConfigFile
Path of the file with the configuration.

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

## INPUTS

### This function does not accept pipeline input.

## OUTPUTS

### This function outputs the JiraPS.Field objects that represent JIRA's create metadata.

## NOTES
This function requires either the -Credential parameter to be passed or a persistent JIRA session.
See New-JiraSession for more details. 
If neither are supplied, this function will run with anonymous access to JIRA.

## RELATED LINKS

