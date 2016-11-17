function Get-CommitMessage {    
[CmdletBinding()]
param (
    [PSCredential]$credential, 
    [string]$Repo
)


Write-Verbose "
    Getting Commit Messages:
    RepoName: $Repo
    Server: $Server
    "
Get-Commits -credential $Credential -Repo $Repo | ft @{Name="commitId";expression={$_.displayID}},@{Name="Author";expression={$_.author.displayName}},message -Wrap

}