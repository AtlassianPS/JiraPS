function Get-ProjectKey {    
[CmdletBinding()]
param (
    [PSCredential]$credential, 
    [string]$Repo
)


Write-Verbose "
    Getting Project Key of:
    RepoName: $Repo
    Server: $Server
    "
$RepoObj = Get-Repositories -credential $credential| where-object slug -match $Repo

$RepoObj.project.key

}