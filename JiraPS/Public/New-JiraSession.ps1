function New-JiraSession {
    # .ExternalHelp ..\JiraPS-help.xml
    [CmdletBinding(DefaultParameterSetName = 'Credential')]
    [System.Diagnostics.CodeAnalysis.SuppressMessage('PSUseShouldProcessForStateChangingFunctions', '')]
    param(
        [Parameter(ParameterSetName = 'Credential')]
        [System.Management.Automation.PSCredential]
        [System.Management.Automation.Credential()]
        $Credential,

        [Parameter(Mandatory, ParameterSetName = 'PersonalAccessToken')]
        [Alias('BearerToken', 'PAT')]
        [SecureString]
        $PersonalAccessToken,

        [Parameter(Mandatory, ParameterSetName = 'ApiToken')]
        [SecureString]
        $ApiToken,

        [Parameter(Mandatory, ParameterSetName = 'ApiToken')]
        [string]
        $EmailAddress,

        [Hashtable]
        $Headers = @{ }
    )

    begin {
        Write-Verbose "[$($MyInvocation.MyCommand.Name)] Function started"

        $resourceURi = "/rest/api/2/myself"
    }

    process {
        Write-DebugMessage "[$($MyInvocation.MyCommand.Name)] ParameterSetName: $($PsCmdlet.ParameterSetName)"
        Write-DebugMessage "[$($MyInvocation.MyCommand.Name)] PSBoundParameters: $($PSBoundParameters | Out-String)"

        switch ($PSCmdlet.ParameterSetName) {
            'PersonalAccessToken' {
                $tokenPlain = [System.Net.NetworkCredential]::new('', $PersonalAccessToken).Password
                $Headers['Authorization'] = "Bearer $tokenPlain"
                Write-Verbose "[$($MyInvocation.MyCommand.Name)] Using Personal Access Token (PAT) authentication"
            }
            'ApiToken' {
                $tokenPlain = [System.Net.NetworkCredential]::new('', $ApiToken).Password
                $authString = "${EmailAddress}:${tokenPlain}"
                $base64Auth = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes($authString))
                $Headers['Authorization'] = "Basic $base64Auth"
                Write-Verbose "[$($MyInvocation.MyCommand.Name)] Using API token authentication (Cloud)"
            }
        }

        $parameter = @{
            URI          = $resourceURi
            Method       = "GET"
            Headers      = $Headers
            StoreSession = $true
        }
        if ($Credential) { $parameter.Add('Credential', $Credential) }
        Write-Debug "[$($MyInvocation.MyCommand.Name)] Invoking JiraMethod with `$parameter"
        $result = Invoke-JiraMethod @parameter

        if ($MyInvocation.MyCommand.Module.PrivateData) {
            Write-DebugMessage "[$($MyInvocation.MyCommand.Name)] Adding session result to existing module PrivateData"
            $MyInvocation.MyCommand.Module.PrivateData.Session = $result
        }
        else {
            Write-DebugMessage "[$($MyInvocation.MyCommand.Name)] Creating module PrivateData"
            $MyInvocation.MyCommand.Module.PrivateData = @{
                'Session' = $result
            }
        }

        Write-Output $result
    }

    end {
        Write-Verbose "[$($MyInvocation.MyCommand.Name)] Complete"
    }
}
