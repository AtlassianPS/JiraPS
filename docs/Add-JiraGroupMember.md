---
external help file: JiraPS-help.xml
online version: 
schema: 2.0.0
---

# Add-JiraGroupMember

## SYNOPSIS
Adds a user to a JIRA group

## SYNTAX

```
Add-JiraGroupMember [-Group] <Object[]> -User <Object[]> [-Credential <PSCredential>] [-PassThru]
```

## DESCRIPTION
This function adds a JIRA user to a JIRA group.

## EXAMPLES

### -------------------------- EXAMPLE 1 --------------------------
```
Add-JiraGroupMember -Group testUsers -User jsmith
```

This example adds the user jsmith to the group testUsers

### -------------------------- EXAMPLE 2 --------------------------
```
Get-JiraGroup 'Project Admins' | Add-JiraGroupMember -User jsmith
```

This example illustrates the use of the pipeline to add jsmith to the
"Project Admins" group in JIRA.

## PARAMETERS

### -Group
Group (or list of groups) to which the user(s) will be added.

```yaml
Type: Object[]
Parameter Sets: (All)
Aliases: GroupName

Required: True
Position: 1
Default value: None
Accept pipeline input: True (ByValue)
Accept wildcard characters: False
```

### -User
Username or user object obtained from Get-JiraUser.

```yaml
Type: Object[]
Parameter Sets: (All)
Aliases: UserName

Required: True
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

## INPUTS

### [JiraPS.Group[]] Group(s) to which users should be added

## OUTPUTS

### If the -PassThru parameter is provided, this function will provide a
reference to the JIRA group modified.  Otherwise, this function does not
provide output.

## NOTES
This REST method is still marked Experimental in JIRA's REST API.
That
means that there is a high probability this will break in future
versions of JIRA.
The function will need to be re-written at that time.

## RELATED LINKS

