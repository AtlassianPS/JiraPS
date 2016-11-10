function Get-CommitMessage {    
[CmdletBinding()]
param (
    [PSCredential]$credential, 
    [string]$ProjectKey,
    [string]$Repo
)


Write-Verbose "
    Getting Commit Messages:
    RepoName: $Repo
    ProjectKey: $ProjectKey
    Server: $Server
    "
(Get-Commits -credential $Credential -ProjectKey $ProjectKey -Repo $Repo).values | ft @{Name="commitId";expression={$_.displayID}},@{Name="Author";expression={$_.author.displayName}},message -Wrap

}