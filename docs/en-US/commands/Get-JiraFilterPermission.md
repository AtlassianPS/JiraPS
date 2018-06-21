---
external help file: JiraPS-help.xml
Module Name: JiraPS
online version: https://atlassianps.org/docs/JiraPS/commands/Get-JiraFilterPermission/
locale: en-US
schema: 2.0.0
layout: documentation
permalink: /docs/JiraPS/commands/Get-JiraFilterPermission/
---
# Get-JiraFilterPermission

## SYNOPSIS

Fetch the permissions of a specific Filter.

## SYNTAX

### ByInputObject (Default)

```powershell
Get-JiraFilterPermission [-Filter] <JiraPS.Filter> [[-Credential] <PSCredential>]
 [<CommonParameters>]
```

### ById

```powershell
Get-JiraFilterPermission [-Id] <UInt32[]> [[-Credential] <PSCredential>]
 [<CommonParameters>]
```

## DESCRIPTION

This allows the user to retrieve all the sharing permissions set for a Filter.

## EXAMPLES

### Example 1

```powershell
Get-JiraFilterPermission -Filter (Get-JiraFilter 12345)
#-------
Get-JiraFilterPermission -Id 12345
```

Two methods for retrieving the permissions set for Filter 12345.

### Example 2

```powershell
12345 | Get-JiraFilterPermission
#-------
Get-JiraFilter 12345 | Add-JiraFilterPermission
```

Two methods for retrieve the permissions set for Filter 12345 by using the pipeline.

_The Id could be read from a file._

## PARAMETERS

### -Filter

Filter object from which to retrieve the permissions

```yaml
Type: JiraPS.Filter
Parameter Sets: ByInputObject
Aliases:

Required: True
Position: 0
Default value: None
Accept pipeline input: True (ByValue)
Accept wildcard characters: False
```

### -Id

Id of the Filter from which to retrieve the permissions

```yaml
Type: UInt32[]
Parameter Sets: ById
Aliases:

Required: True
Position: 0
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
Position: 1
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### CommonParameters

This cmdlet supports the common parameters: -Debug, -ErrorAction,
-ErrorVariable, -InformationAction, -InformationVariable, -OutVariable,
-OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable.
For more information, see about_CommonParameters
(<http://go.microsoft.com/fwlink/?LinkID=113216>).

## INPUTS

### [JiraPS.Filter]

## OUTPUTS

### [JiraPS.Filter]

## NOTES

This function requires either the `-Credential` parameter to be passed or
a persistent JIRA session.
See `New-JiraSession` for more details.
If neither are supplied, this function will run with anonymous access to JIRA.

## RELATED LINKS

[Get-JiraFilter](../Get-JiraFilter/)

[Add-JiraFilterPermission](../Add-JiraFilterPermission/)

[Remove-JiraFilterPermission](../Remove-JiraFilterPermission/)
