Import-Module C:\git\JiraPS\JiraPS\JiraPS.psm1
Set-JiraConfigServer -Server https://jira.loandepot.com
If (-not $Creds) {
    $Creds = Get-Credential mdejulia
}
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
New-JiraSession -Credential $Creds -Verbose
