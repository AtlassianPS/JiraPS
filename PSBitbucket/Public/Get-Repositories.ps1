function Get-Repositories {    
[CmdletBinding()]
param (
    [PSCredential]$credential, 
    [string]$Repo
)

    $server = Get-BitbucketConfigServer
    
    Write-Verbose "
    Getting Repos:
    RepoName: $Repo
    Server: $Server
    "

    $uri = "$server/rest/api/1.0/repos"

    Invoke-BitBucketMethod -uri $uri -credential $credential -method GET
}
