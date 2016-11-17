function Get-Branch {    
[CmdletBinding()]
param (
    [PSCredential]$credential, 
    [string]$Branch,
    [string]$Repo
)


Write-Verbose "
    Getting Branch: 
    Repo: $Repo
    Branch: $Branch
    Server: $Server
    "
$Branch = Get-BranchList -repo $Repo -credential $credential| where-object displayId -match $Branch

return $Branch

}