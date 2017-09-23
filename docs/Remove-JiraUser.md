---
external help file: JiraPS-help.xml
online version: 
schema: 2.0.0
---

# Remove-JiraUser

## SYNOPSIS
Removes an existing user from JIRA

## SYNTAX

```
Remove-JiraUser [-User] <Object[]> [-Credential <PSCredential>] [-Force] [-WhatIf] [-Confirm]
```

## DESCRIPTION
This function removes an existing user from JIRA.

WARNING: Deleting a JIRA user may cause database integrity problems.
See this article for
details:

https://confluence.atlassian.com/jira/how-do-i-delete-a-user-account-192519.html

## EXAMPLES

### -------------------------- EXAMPLE 1 --------------------------
```
Remove-JiraUser -UserName testUser
```

Removes the JIRA user TestUser

## PARAMETERS

### -User
User Object or ID to delete.

```yaml
Type: Object[]
Parameter Sets: (All)
Aliases: UserName

Required: True
Position: 1
Default value: None
Accept pipeline input: True (ByValue)
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

### -Force
Suppress user confirmation.

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

### [JiraPS.User[]] The JIRA users to delete

## OUTPUTS

### This function returns no output.

## NOTES

## RELATED LINKS

