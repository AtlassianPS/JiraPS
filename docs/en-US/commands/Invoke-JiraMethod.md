---
external help file: JiraPS-help.xml
Module Name: JiraPS
online version: https://atlassianps.org/docs/JiraPS/commands/Invoke-JiraMethod/
locale: en-US
schema: 2.0.0
layout: documentation
permalink: /docs/JiraPS/commands/Invoke-JiraMethod/
---
# Invoke-JiraMethod

## SYNOPSIS

Invoke a specific call to a Jira REST Api endpoint

## SYNTAX

```powershell
Invoke-JiraMethod [-URI] <Uri> [[-Method] <WebRequestMethod>] [[-Body] <String>] [-RawBody]
 [[-Headers] <Hashtable>] [[-GetParameter] <Hashtable>] [[-Paging] <Switch>] [[-InFile] <String>]
 [[-OutFile] <String>] [-StoreSession] [[-OutputType] <String>] [[-Credential] <PSCredential>]
 [[-Cmdlet] <System.Management.Automation.PSCmdlet>] [<CommonParameters>]
```

## DESCRIPTION

Make a call to a REST Api endpoint with all the benefits of JiraPS.

This cmdlet is what the other cmdlets call under the hood.
It handles the authentication, parses the
response, handles exceptions from Jira, returns specific objects and handles the differences between
versions of Powershell and Operating Systems.

JiraPS does not support any third-party plugins on Jira.
This cmdlet can be used to interact with REST Api enpoints which are not already coverted in JiraPS.
It allows for anyone to use the same technics as JiraPS uses internally for creating their own functions
or modules.
When used by a module, the Manifest (.psd1) can define the dependency to JiraPS with the 'RequiredModules'
property.
This will import the module if not already loaded or even download it from the PSGallery.

## EXAMPLES

### Example 1

```powershell
Invoke-JiraMethod -URI "rest/api/latest/project"
```

Sends a GET request which will return all the projects on the Jira server.
This call would either be executed anonymously or require a session to be available.

### Example 2

```powershell
Invoke-JiraMethod -URI "rest/api/latest/project" -Credential (Get-Credential)
```

Prompts the user for his Jira credentials and send a GET request,
which will return all the projects on the Jira server.

### Example 3

```powershell
$parameter = @{
    URI = "rest/api/latest/project"
    Method = "POST"
    Credential = $cred
}
Invoke-JiraMethod @parameter
```

Sends a POST request to the server.

> This will example doesn't really do anything on the server, as the content API needs requires a value for the BODY.

See next example

### Example 4

```powershell
$body = '{"name": "NewGroup"}'
$params = @{
    Uri = "rest/api/latest/group"
    Method = "POST"
    Body = $body
    Credential = $cred
}
Invoke-JiraMethod @params
```

Creates a new group named "NewGroup"

### Example 5

```powershell
$params = @{
    Uri = "rest/api/latest/mypermissions"
    Method = "GET"
    Body = $body
    StoreSession = $true
    Credential = $cred
}
Invoke-JiraMethod @params
```

Executes the GET request but instead of returning the response,
it returns a `[JiraPS.Session]` which contains the `[WebRequestSession]`.

### Example 6

```powershell
$params = @{
    Uri = "rest/api/latest/issue/10000"
    Method = "POST"
    InFile = "c:\temp\20001231_Connection.log"
    Credential = $cred
}
Invoke-JiraMethod @params
```

Executes a POST request on the defined URI and uploads the InFile with a multipart/form-data request.

### Example 7

```powershell
$parameter = @{
    URI = "rest/api/latest/project"
    Method = "GET"
    OutFile = "c:\temp\jira_projects.json"
    Credential = $cred
}
Invoke-JiraMethod @parameter
```

Executes a GET request on all available projects and stores the response json in the defined file.

### Example 8

```powershell
$parameter = @{
    URI = "rest/api/latest/project"
    Method = "GET"
    Headers = @{"Accept" = "text/plain"}
    OutFile = "c:\temp\jira_projects.json"
    Credential = $cred
}
Invoke-JiraMethod @parameter
```

Executes a GET request on the defined URI and stores the output on the File System.
It also uses the Headers to define what mimeTypes are expected in the response.

## PARAMETERS

### -URI

URI address of the REST API endpoint.
Could be relative or absolute URL.
Keep in mind that mostly you should use relative path (ex. rest/api) and seek to avoid use absolute path (ex. /rest/api).

```yaml
Type: Uri, string
Parameter Sets: (All)
Aliases:

Required: True
Position: 0
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Method

Method of the HTTP request.

```yaml
Type: WebRequestMethod
Parameter Sets: (All)
Aliases:
Accepted values: Default, Get, Head, Post, Put, Delete, Trace, Options, Merge, Patch

Required: False
Position: 1
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Body

Body of the HTTP request.

By default each character of the Body is encoded to a sequence of bytes.
This enables the support of UTF8 characters.
And was first reported here:
https://stackoverflow.com/questions/15290185/invoke-webrequest-issue-with-special-characters-in-json

This behavior can be changed with -RawBody.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 2
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -RawBody

Keep the Body from being encoded.

```yaml
Type: SwitchParameter
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Headers

Define a key-value set of HTTP headers that should be used in the call.

```yaml
Type: Hashtable
Parameter Sets: (All)
Aliases:

Required: False
Position: 3
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -GetParameter

Key-Value pair of the Headers to be used.

```yaml
Type: Hashtable
Parameter Sets: (All)
Aliases:

Required: False
Position: 4
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Paging

Use paging on the results.

More about paging: <https://docs.atlassian.com/software/jira/docs/api/REST/7.6.1/#pagination>

```yaml
Type: SwitchParameter
Parameter Sets: (All)
Aliases:

Required: False
Position: 4
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -InFile

Path to a file that will be uploaded with a multipart/form-data request.

This parameter does not validate the input in any way.

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

### -OutFile

Path to the file where the response should be stored to.

This parameter does not validate the input in any way

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

### -StoreSession

Instead of returning the response, it returns a `[JiraPS.Session]` which contains the `[WebRequestSession]`.

```yaml
Type: SwitchParameter
Parameter Sets: (All)
Aliases:

Required: False
Position: 7
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -OutputType

Name of the data type that is expected to be returned.

Currently only used in combination with `-Paging`

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

### -Credential

Credentials to use for the authentication with the REST Api.

If none are provided, `Get-JiraSession` will be used for authentication.
If no sessions is available, the request will be executed anonymously.

```yaml
Type: PSCredential
Parameter Sets: (All)
Aliases:

Required: False
Position: 9
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Cmdlet

Context which will be used for throwing errors.

```yaml
Type: PSCmdlet
Parameter Sets: (All)
Aliases:

Required: False
Position: 10
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -IncludeTotalCount

Causes an extra output of the total count at the beginning.

Note this is actually a uInt64, but with a custom string representation.

```yaml
Type: SwitchParameter
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Skip

Controls how many things will be skipped before starting output.

Defaults to 0.

```yaml
Type: UInt64
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: 0
Accept pipeline input: False
Accept wildcard characters: False
```

### -First

Indicates how many items to return.

```yaml
Type: UInt64
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: 18446744073709551615
Accept pipeline input: False
Accept wildcard characters: False
```

### CommonParameters

This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable.
For more information, see about_CommonParameters (http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

## OUTPUTS

### [System.Management.Automation.PSCustomObject]

This command is designed to handle JSON responses only.
The response is convert to PSCustomObject with `ConvertFrom-Json`

## NOTES

## RELATED LINKS

[Jira Cloud API](https://developer.atlassian.com/cloud/jira/platform/rest/)

[Jira Server API](https://docs.atlassian.com/software/jira/docs/api/REST/7.6.1/)
