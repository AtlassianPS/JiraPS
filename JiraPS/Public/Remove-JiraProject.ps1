function Remove-JiraProject {
    <#
    .Synopsis
       Removes an existing project from JIRA
    .DESCRIPTION
       This function removes an existing poject from JIRA.
    .EXAMPLE
       Remove-JiraProject -Project $project
    .INPUTS
       [JiraPS.Project[]] The JIRA projects to delete
    .OUTPUTS
       This function returns no output.
    #>
    [CmdletBinding(SupportsShouldProcess = $true,
        ConfirmImpact = 'High')]
    param(
        # Project Key
        [Parameter(
            Mandatory = $true,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true
        )]
        [String] $Key,

        # Credentials to use to connect to JIRA.
        # If not specified, this function will use anonymous access.
        [Parameter(Mandatory = $false)]
        [PSCredential] $Credential,

        # Suppress user confirmation.
        [Switch] $Force
    )

    begin {
        Write-Debug "[Remove-JiraProject] Reading information from config file"
        try {
            Write-Debug "[Remove-JiraProject] Reading Jira server from config file"
            $server = Get-JiraConfigServer -ConfigFile $ConfigFile -ErrorAction Stop
        }
        catch {
            $err = $_
            Write-Debug "[Remove-JiraProject] Encountered an error reading configuration data."
            throw $err
        }

        $restUrl = "$server/rest/api/latest/project/{0}"

        if ($Force) {
            Write-Debug "[Remove-JiraProject] -Force was passed. Backing up current ConfirmPreference [$ConfirmPreference] and setting to None"
            $oldConfirmPreference = $ConfirmPreference
            $ConfirmPreference = 'None'
        }
    }

    process {
        foreach ($p in $Key) {
            Write-Debug "[Remove-JiraProject] Obtaining reference to project [$p]"
            $projectObj = Get-JiraProject -Project $p -Credential $Credential

            if ($projectObj) {
                $thisUrl = $restUrl -f $projectObj.Key
                Write-Debug "[Remove-JiraProject] Project URL: [$thisUrl]"

                Write-Debug "[Remove-JiraProject] Checking for -WhatIf and Confirm"
                if ($PSCmdlet.ShouldProcess($projectObj.Name, "Remove project [$projectObj] from JIRA")) {
                    Write-Debug "[Remove-JiraProject] Preparing for blastoff!"
                    Invoke-JiraMethod -Method Delete -URI $thisUrl -Credential $Credential
                }
                else {
                    Write-Debug "[Remove-JiraProject] Runnning in WhatIf mode or user denied the Confirm prompt; no operation will be performed"
                }
            }
        }
    }
    end {
        if ($Force) {
            Write-Debug "[Remove-JiraProjectMember] Restoring ConfirmPreference to [$oldConfirmPreference]"
            $ConfirmPreference = $oldConfirmPreference
        }

        Write-Debug "[Remove-JiraProject] Complete"
    }
}
