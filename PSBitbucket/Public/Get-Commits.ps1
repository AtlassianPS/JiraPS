function Get-Commits {    
[CmdletBinding()]
param (
    [PSCredential]$credential, 
    [string]$ProjectKey,
    [string]$Repo
)

    $server = Get-BitbucketConfigServer
    
    Write-Verbose "
    Getting Commits:
    RepoName: $Repo
    ProjectKey: $ProjectKey
    Server: $Server
    "

    $uri = "$server/rest/api/1.0/projects/$ProjectKey/repos/$Repo/commits"

    Invoke-BitBucketMethod -uri $uri -credential $credential -method GET
}
