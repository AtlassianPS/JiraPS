---
external help file: JiraPS-help.xml
online version: 
schema: 2.0.0
---

# New-JiraUser

## SYNOPSIS
Creates a new user in JIRA

## SYNTAX

```
New-JiraUser [-UserName] <String> [-EmailAddress] <String> [[-DisplayName] <String>] [[-Notify] <Boolean>]
 [[-Credential] <PSCredential>] [-WhatIf] [-Confirm]
```

## DESCRIPTION
This function creates a new user in JIRA. 
By default, the new user
will be notified via e-mail.

The new user's password is also randomly generated.

## EXAMPLES

### -------------------------- EXAMPLE 1 --------------------------
```
New-JiraUser -UserName testUser -EmailAddress testUser@example.com
```

This example creates a new JIRA user named testUser, and sends a
notification e-mail. 
The user's DisplayName will be set to
"testUser" since it is not specified.

### -------------------------- EXAMPLE 2 --------------------------
```
New-JiraUser -UserName testUser2 -EmailAddress testUser2@example.com -DisplayName "Test User 2"
```

This example illustrates setting a user's display name during
user creation.

## PARAMETERS

### -UserName
Name of user.

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

### -EmailAddress
E-mail address of the user.

```yaml
Type: String
Parameter Sets: (All)
Aliases: Email

Required: True
Position: 2
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -DisplayName
Display name of the user.

```yaml
Type: String
Parameter Sets: (All)
Aliases: 

Required: False
Position: 3
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Notify
Should the user receive a notification e-mail?

```yaml
Type: Boolean
Parameter Sets: (All)
Aliases: 

Required: False
Position: 4
Default value: True
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
Position: 5
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

### [JiraPS.User] The user object created

## NOTES

## RELATED LINKS

