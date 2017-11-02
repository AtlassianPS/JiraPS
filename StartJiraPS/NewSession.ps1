Import-Module C:\git\JiraPS\JiraPS\JiraPS\JiraPS.psd1
Set-JiraConfigServer -Server https://powershell.atlassian.net
If (-not $Creds) {
    $Creds = Get-Credential Michael.dejulia@gmail.com
}
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
New-JiraSession -Credential $Creds -Verbose
