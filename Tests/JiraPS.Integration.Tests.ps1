Describe 'Load Module' {
    # ARRANGE
    Remove-Module JiraPS -Force -ErrorAction SilentlyContinue

    # ACT
    Import-Module "$PSScriptRoot\..\JiraPS" -Force -ErrorAction Stop

    #ASSERT
    It "imports the module" {
        Get-Module JiraPS | Should BeOfType [PSModuleInfo]
    }
}

InModuleScope JiraPS {

    . $PSScriptRoot\Shared.ps1

    Describe 'Authenticating' {

        # ARRANGE
        $Pass = ConvertTo-SecureString -AsPlainText -Force -String $env:JiraPass
        $Cred = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList ($env:JiraUser, $Pass)

        Context 'Storing Server Data' {
            # ACT
            Set-JiraConfigServer $env:JiraURI

            # ASSERT
            It 'stores the server address' {
                Get-JiraConfigServer | Should Be $env:JiraURI
            }
        }

        Context 'Basic Authentication' {
            # ACT
            $myUser = Get-JiraUser -UserName $env:JiraUser -Credential $cred

            # ASSERT
            It 'can authenticate with the API' {
                $myUser | Should Not BeNullOrEmpty
                checkType $myUser 'JiraPS.User'
            }
        }

        Context 'Session Authentication' {
            # ACT
            $null = New-JiraSession -Credential $cred
            $myUser = Get-JiraUser -UserName $env:JiraUser
            $session = Get-JiraSession

            # ASSERT
            It 'stored the session' {
                $session | Should Not BeNullOrEmpty
            }
            checkPsType $session 'JiraPS.Session'
            It 'can authenticate with the API' {
                $myUser | Should Not BeNullOrEmpty
                checkType $myUser 'JiraPS.User'
            }
        }

    }

    <# Describe 'Handling of Users and Groups' {

        Context 'New-JiraGroup' {
            # ARRANGE
            $groupName = "TGroup1"
            $collectionOfGroups = @('TGroup2', 'TGroup3')

            # ACT
            $groupObj = New-JiraGroup -GroupName $groupName -ErrorAction Stop
            $groupObjs = $collectionOfGroups | ForEach-Object { New-JiraGroup $_ -ErrorAction Stop }

            # ASSERT
            It 'returns an object with specific properties' {
                checkType $groupObj 'JiraPS.Group'
                checkType $groupObjs 'JiraPS.Group'
            }
        }

        Context 'Get-JiraGroup' {
            # ARRANGE
            $groupName = "TGroup1"
            $collectionOfGroups = @('TGroup2', 'TGroup3')

            # ACT
            $groupObj = Get-JiraGroup -GroupName $groupName
            $groupObjs = Get-JiraGroup $collectionOfGroups

            # ASSERT
            It 'returns an object with specific properties' {
                checkType $groupObj 'JiraPS.Group'
                checkType $groupObjs 'JiraPS.Group'
            }
            defProp $groupObj 'Name' $groupName
            defProp $groupObjs[0] 'Name' $collectionOfGroups[0]
            defProp $groupObjs[1] 'Name' $collectionOfGroups[1]
            hasProp $groupObj 'RestUrl'
            hasProp $groupObjs[0] 'RestUrl'
            hasProp $groupObjs[1] 'RestUrl'
            defProp $groupObj 'Size' 0
            defProp $groupObjs[0] 'Size' 0
            defProp $groupObjs[1] 'Size' 0
            hasNotProp $groupObj 'Member'
            hasNotProp $groupObjs[0] 'Member'
            hasNotProp $groupObjs[1] 'Member'
        }

        Context 'New-JiraUser' {
            # ARRANGE
            $user1 = @{
                UserName     = "TUser1"
                EmailAddress = "TUser1@JiraPS.com"
                DisplayName  = "Test User #1"
            }
            $userName2 = "TUser2"
            $userName3 = "TUser3"

            # ACT
            $userObj1 = New-JiraUser @user1 -Notify $false -ErrorAction Stop
            $userObj2 = New-JiraUser -UserName $userName2 -EmailAddress "$userName2@JiraPS.com" -DisplayName "Test User from Collection" -Notify $false -ErrorAction Stop
            $userObj3 = New-JiraUser -UserName $userName3 -EmailAddress "$userName3@JiraPS.com" -DisplayName "Test User from Collection" -Notify $false -ErrorAction Stop

            # ASSERT
            It 'returns an object with specific properties' {
                checkType $userObj1 'JiraPS.User'
                checkType $userObj2 'JiraPS.User'
                checkType $userObj3 'JiraPS.User'
            }
        }

        Context 'Get-JiraUser' {
            # ARRANGE
            $user1 = @{
                UserName     = "TUser1"
                EmailAddress = "TUser1@JiraPS.com"
                DisplayName  = "Test User #1"
            }
            $userName2 = "TUser2"
            $userName3 = "TUser3"

            # ACT
            $userObj = Get-JiraUser -UserName $user1["UserName"]
            $userObjs = Get-JiraUser @($userName2, $userName3)

            # ASSERT
            It 'returns an object with specific properties' {
                checkType $userObj 'JiraPS.User'
                checkType $userObjs 'JiraPS.User'
            }
            defProp $userObj 'Name' $user["UserName"]
            defProp $userObjs[0] 'Name' $collectionOfUsers[0]
            defProp $userObjs[1] 'Name' $collectionOfUsers[1]
            defProp $userObj 'DisplayName' $user["DisplayName"]
            defProp $userObjs[0] 'DisplayName' "Test User from Collection"
            defProp $userObjs[1] 'DisplayName' "Test User from Collection"
            defProp $userObj 'EmailAddress' $user["EmailAddress"]
            defProp $userObjs[0] 'EmailAddress' "$($collectionOfUsers[0])@JiraPS.com"
            defProp $userObjs[1] 'EmailAddress' "$($collectionOfUsers[1])@JiraPS.com"
            defProp $userObjs[1] 'Name' $collectionOfUsers[1]
            defProp $userObj 'Active' $true
            defProp $userObjs[0] 'Active' $true
            defProp $userObjs[1] 'Active' $true
            hasProp $userObj 'RestUrl'
            hasProp $userObjs[0] 'RestUrl'
            hasProp $userObjs[1] 'RestUrl'
            hasProp $userObj 'AvatarUrl'
            hasProp $userObjs[0] 'AvatarUrl'
            hasProp $userObjs[1] 'AvatarUrl'
            hasProp $userObj 'TimeZone'
            hasProp $userObjs[0] 'TimeZone'
            hasProp $userObjs[1] 'TimeZone'
            hasNotProp $userObj 'Group'
            hasNotProp $userObjs[0] 'Group'
            hasNotProp $userObjs[1] 'Group'
        }

        Context 'Add-JiraGroupMember' {
            # ARRANGE
            $user1 = Get-JiraUser "TUser1" -ErrorAction Stop
            $userName2 = "TUser2"
            $group1 = Get-JiraGroup "TGroup1" -ErrorAction Stop
            $groupName2 = "TGroup2"

            # ACT
            $result1 = Add-JiraGroupMember -Group $group1 -User @($user1, $userName2) -PassThru -ErrorAction Stop
            $result2 = Get-JiraGroup $groupName2 | Add-JiraGroupMember -User $user1 -ErrorAction Stop

            # ASSERT
            It 'returns an object with specific properties' {
                checkType $result1 'JiraPS.Group'
                $result2 | Should BeNullOrEmpty
            }

            It 'adds a user as member of the group' {
                $result1.Size | Should Be 2
                (Get-JiraGroupMember -Group $group1 | Measure-Object).Count | Should Be 2
                (Get-JiraGroupMember -Group $groupName2 | Measure-Object).Count | Should Be 1
            }

            It 'shows the group membership in all relevant objects' {
                $resultUser1 = Get-JiraUser $user1 -ErrorAction Stop
                $resultUser2 = Get-JiraUser $userName2 -ErrorAction Stop
                $resultGroup1 = Get-JiraGroup $group1
                $resultGroup2 = Get-JiraGroup $groupName2
                checkType $resultUser1 'JiraPS.User'
                checkType $resultUser2 'JiraPS.User'
                checkType $resultGroup1 'JiraPS.Group'
                checkType $resultGroup2 'JiraPS.Group'
                hasNotProp $resultUser1 'Group'
                hasNotProp $resultUser2 'Group'
                defProp $resultGroup1 'Size' 2
                defProp $resultGroup2 'Size' 1
                hasNotProp $resultGroup1 'Member'
                hasNotProp $resultGroup2 'Member'
            }
        }

        Context 'Get-JiraGroupMember' {
            # ARRANGE
            # ACT
            # ASSERT
        }

        Context 'Remove-JiraGroupMember' {
            # ARRANGE
            $user1 = Get-JiraUser "TUser1" -ErrorAction Stop
            $userName2 = "TUser2"
            $group1 = Get-JiraGroup "TGroup1" -ErrorAction Stop
            $groupName2 = "TGroup2"

            # ACT
            $result1 = Remove-JiraGroupMember -Group $group1 -User @($user1, $userName2) -PassThru -Force
            $result2 = $groupName2 | Remove-JiraGroupMember -User $user1 -Force

            # ASSERT
            Get-JiraGroupMember -Group $group1 | Should BeNullOrEmpty
            Get-JiraGroupMember -Group $groupName2 | Should BeNullOrEmpty
        }

        Context 'Remove-JiraUser' {
            # ARRANGE
            $userName = "TUser1"
            $collectionOfUsers = @("TUser2", "TUser3")

            # ACT
            Remove-JiraUser -User $userName -Force -ErrorAction SilentlyContinue
            Get-JiraUser $collectionOfUsers | Remove-JiraUser -Force -ErrorAction SilentlyContinue

            # ASSERT
            Get-JiraUser -User $userName | Should BeNullOrEmpty
            Get-JiraUser $collectionOfUsers | Should BeNullOrEmpty
        }

        Context 'Remove-JiraGroup' {
            # ARRANGE
            $WarningPreference = "SilentlyContinue"
            $groupName = "TGroup1"
            $groups = Get-JiraGroup @('TGroup2', 'TGroup3')

            # ACT
            Remove-JiraGroup -Group $groupName -Force -ErrorAction Stop
            Get-JiraGroup $groups | Remove-JiraGroup -Force -ErrorAction Stop

            # ASSERT
            { Get-JiraGroup -GroupName $groupName -ErrorAction Stop } | Should Throw
            { Get-JiraGroup $groups -ErrorAction Stop } | Should Throw
        }

    } #>

}
