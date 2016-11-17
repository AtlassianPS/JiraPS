function Get-BranchList {    
[CmdletBinding()]
param (
    [PSCredential]$credential, 
    [string]$Repo
)

    $server = Get-BitbucketConfigServer
    $ProjectKey = Get-ProjectKey -repo $Repo -credential $credential

    Write-Verbose "
    Getting Branches:
    RepoName: $Repo
    ProjectKey: $ProjectKey
    Server: $Server
    "

    $uri = "$server/rest/api/1.0/projects/$ProjectKey/repos/$Repo/branches"

    $Branches = Invoke-BitBucketMethod -uri $uri -credential $credential -method GET
    
    return $Branches.values
}
