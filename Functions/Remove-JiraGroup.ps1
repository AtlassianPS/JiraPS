function Remove-JiraGroup
{
    <#
    .Synopsis
       Removes an existing group from JIRA
    .DESCRIPTION
       This function removes an existing group from JIRA.

       Deleting a group does not delete users from JIRA.
    .EXAMPLE
       Remove-JiraGroup -GroupName testGroup
       Removes the JIRA group testGroup
    .INPUTS
       [PSJira.Group[]] The JIRA groups to delete
    .OUTPUTS
       This function returns no output.
    #>
    [CmdletBinding(SupportsShouldProcess = $true,
                   ConfirmImpact = 'High')]
    param(
        [Parameter(Mandatory = $true,
                   Position = 0,
                   ValueFromPipeline = $true)]
        [Alias('GroupName')]
        [Object[]] $Group,

        [Parameter(Mandatory = $false)]
        [PSCredential] $Credential,

        [Switch] $Force
    )

    begin
    {
        Write-Debug "[Remove-JiraGroup] Reading information from config file"
        try
        {
            Write-Debug "[Remove-JiraGroup] Reading Jira server from config file"
            $server = Get-JiraConfigServer -ConfigFile $ConfigFile -ErrorAction Stop
        } catch {
            $err = $_
            Write-Debug "[Remove-JiraGroup] Encountered an error reading configuration data."
            throw $err
        }

        $restUrl = "$server/rest/api/latest/group?groupname={0}"
    }

    process
    {
        foreach ($g in $Group)
        {
            Write-Debug "[Remove-JiraGroup] Obtaining reference to group [$g]"
            $groupObj = Get-JiraGroup -InputObject $g -Credential $Credential

            if ($groupObj)
            {
                $thisUrl = $restUrl -f $groupObj.Name
                Write-Debug "[Remove-JiraGroup] Group URL: [$thisUrl]"

                Write-Debug "[Remove-JiraGroup] Checking for -WhatIf"
                if (-not $WhatIfPreference)
                {
                    Write-Debug "[Remove-JiraGroup] Checking for -Force or Confirm"
                    if ($Force -or $PSCmdlet.ShouldProcess($groupObj.Name, "Remove group [$groupObj] from JIRA"))
                    {
                        Write-Debug "[Remove-JiraGroup] Preparing for blastoff!"
                        Invoke-JiraMethod -Method Delete -URI $thisUrl -Credential $Credential
                    } else {
                        Write-Debug "[Remove-JiraGroup] User denied the confirmation prompt; no operation will be performed"
                    }
                } else {
                    Write-Debug "[Remove-JiraGroup] Runnning in WhatIf mode; no operation will be performed"
                }
            }
        }
    }

    end
    {
        Write-Debug "[Remove-JiraGroup] Complete"
    }
}