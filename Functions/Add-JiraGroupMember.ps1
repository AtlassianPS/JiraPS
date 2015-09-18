function Add-JiraGroupMember
{
    <#
    .Synopsis
       Adds a user to a JIRA group
    .DESCRIPTION
       This function adds a JIRA user to a JIRA group.
    .EXAMPLE
       Add-JiraGroupMember -Group testUsers -User jsmith
       This example adds the user jsmith to the group testUsers
    .EXAMPLE
       Get-JiraGroup 'Project Admins' | Add-JiraGroupMember -User jsmith
       This example illustrates the use of the pipeline to add jsmith to the
       "Project Admins" group in JIRA.
    .INPUTS
       [PSJira.Group[]] Group(s) to which users should be added
    .OUTPUTS
       If the -PassThru parameter is provided, this function will provide a
       reference to the JIRA group modified.  Otherwise, this function does not
       provide output.
    .NOTES
       This REST method is still marked Experimental in JIRA's REST API. That
       means that there is a high probability this will break in future
       versions of JIRA. The function will need to be re-written at that time.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true,
                   Position = 0,
                   ValueFromPipeline = $true)]
        [Alias('GroupName')]
        [Object[]] $Group,

        # Username or user object obtained from Get-JiraUser
        [Parameter(Mandatory = $true)]
        [Alias('UserName')]
        [Object[]] $User,

        [Parameter(Mandatory = $false)]
        [PSCredential] $Credential,

        # Whether output should be provided after invoking this function
        [Switch] $PassThru
    )

    begin
    {
        Write-Debug "[Add-JiraGroupMember] Reading information from config file"
        try
        {
            Write-Debug "[Add-JiraGroupMember] Reading Jira server from config file"
            $server = Get-JiraConfigServer -ConfigFile $ConfigFile -ErrorAction Stop
        } catch {
            $err = $_
            Write-Debug "[Add-JiraGroupMember] Encountered an error reading configuration data."
            throw $err
        }

        # At present, it looks like this REST method doesn't support arrays in the Name property...
        # in other words, a single REST call can only add a single group member to a single group.

        # That's kind of annoying.

        # Anyway, this builds a bunch of individual JSON strings with each username in its own Web
        # request, which we'll loop through again in the Process block.

        $userAL = New-Object -TypeName System.Collections.ArrayList
        foreach ($u in $User)
        {
            Write-Debug "[Add-JiraGroupMember] Obtaining reference to user [$u]"
            $userObj = Get-JiraUser -InputObject $u -Credential $Credential

            if ($userObj)
            {
                Write-Debug "[Add-JiraGroupMember] Retrieved user reference [$userObj]"
#                $thisUserJson = ConvertTo-Json -InputObject @{
#                    'name' = $userObj.Name;
#                }
#                [void] $userAL.Add($thisUserJson)
                [void] $userAL.Add($userObj.Name)
            } else {
                Write-Debug "[Add-JiraGroupMember] Could not identify user [$u]. Writing error message."
                Write-Error "Unable to identify user [$u]. Check the spelling of this user and ensure that you can access it via Get-JiraUser."
            }
        }

#        $userJsons = $userAL.ToArray()
        $userNames = $userAL.ToArray()

        $restUrl = "$server/rest/api/latest/group/user?groupname={0}"
    }

    process
    {
        foreach ($g in $Group)
        {
            Write-Debug "[Add-JiraGroupMember] Obtaining reference to group [$g]"
            $groupObj = Get-JiraGroup -InputObject $g -Credential $Credential

            if ($groupObj)
            {
                Write-Debug "[Add-JiraGroupMember] Obtaining members of group [$g]"
                $groupMembers = Get-JiraGroupMember -Group $g -Credential $Credential | Select-Object -ExpandProperty Name

                $thisRestUrl = $restUrl -f $groupObj.Name
                Write-Debug "[Add-JiraGroupMember] Group URL: [$thisRestUrl]"
#                foreach ($json in $userJsons)
#                {
#                    Write-Debug "[Add-JiraGroupMember] Preparing for blastoff!"
#                    $result = Invoke-JiraMethod -Method Post -URI $thisRestUrl -Body $json -Credential $Credential
#                }
                foreach ($u in $userNames)
                {
                    if ($groupMembers -notcontains $u)
                    {
                        Write-Debug "[Add-JiraGroupMember] User [$u] is not already in group [$g]. Adding user."
                        $userJson = ConvertTo-Json -InputObject @{
                            'name' = $u;
                        }
                        Write-Debug "[Add-JiraGroupMember] Preparing for blastoff!"
                        $result = Invoke-JiraMethod -Method Post -URI $thisRestUrl -Body $userJson -Credential $Credential
                    } else {
                        Write-Debug "[Add-JiraGroupMember] User [$u] is already a member of group [$g]"
                        Write-Verbose "User [$u] is already a member of group [$g]"
                    }
                }

                if ($PassThru)
                {
                    Write-Debug "[Add-JiraGroupMember] -PassThru specified. Obtaining a final reference to group [$g]"
                    $groupObjNew = Get-JiraGroup -InputObject $g -Credential $Credential
                    Write-Debug "[Add-JiraGroupMember] Outputting group [$groupObjNew]"
                    Write-Output $groupObjNew
                }
            } else {
                Write-Debug "[Add-JiraGroupMember] Could not identify group [$g]"
                Write-Error "Unable to identify group [$g]. Check the spelling of this group and ensure that you can access it via Get-JiraGroup."
            }
        }
    }

    end
    {
        Write-Debug "[Add-JiraGroupMember] Complete"
    }
}




