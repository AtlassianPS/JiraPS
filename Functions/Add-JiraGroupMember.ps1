function Add-JiraGroupMember
{
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
            Write-Debug "[Set-JiraUser] Obtaining reference to user [$u]"
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
                Write-Debug "[Remove-JiraGroupMember] Obtaining members of group [$g]"
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
                        $userJson = ConvertTo-Json -InputObject @{
                            'Name' = $u;
                        }
                        Write-Debug "[Add-JiraGroupMember] Preparing for blastoff!"
                        $result = Invoke-JiraMethod -Method Post -URI $thisRestUrl -Body $userJson -Credential $Credential
                    } else {
                        Write-Debug "[Remove-JiraGroupMember] User [$u] is already a member of group [$g]"
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