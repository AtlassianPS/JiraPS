---
external help file: JiraPS-help.xml
online version: 
schema: 2.0.0
---

# Add-JiraIssueLink

## SYNOPSIS
Adds a link between two Issues on Jira

## SYNTAX

```
Add-JiraIssueLink [-Issue] <Object[]> -IssueLink <Object[]> [-Comment <String>] [-Credential <PSCredential>]
```

## DESCRIPTION
Creates a new link of the specified type between two Issue.

## EXAMPLES

### -------------------------- EXAMPLE 1 --------------------------
```
$link = [PSCustomObject]@{
```

outwardIssue = \[PSCustomObject\]@{key = "TEST-10"}
    type = \[PSCustomObject\]@{name = "Composition"}
}
Add-JiraIssueLink -Issue TEST-01 -IssueLink $link
Creates a link "is part of" between TEST-01 and TEST-10

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

### -IssueLink
Issue Link to be created.

```yaml
Type: Object[]
Parameter Sets: (All)
Aliases: 

Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Comment
Write a comment to the issue

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
Credentials to use to connect to Jira
,

       \[Switch\] $PassThru

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

### [JiraPS.Issue[]] The JIRA issue that should be linked
[JiraPS.IssueLink[]] The JIRA issue link that should be used

## OUTPUTS

## NOTES

## RELATED LINKS

