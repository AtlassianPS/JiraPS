# Parameter help description
param(

    [Parameter()]
    [Switch] $ImportModule,

    [Parameter(Mandatory)]
    [ValidateSet('My','JiraPS')]
    [String] $Company
)

If($ImportModule.ispresent)
{
    Import-Module C:\git\JiraPS\JiraPS\JiraPS\JiraPS.psd1
}

Switch($Company)
{
    'JiraPS'
    {
        Set-JiraConfigServer -Server https://powershell.atlassian.net
        $Creds = Get-Credential Michael.dejulia@gmail.com
    }
    'My'
    {

    }
}


[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
New-JiraSession -Credential $Creds -Verbose
