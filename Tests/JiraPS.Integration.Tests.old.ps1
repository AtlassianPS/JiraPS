Describe 'Load Module' -Tag 'Integration' {
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
    . "$PSScriptRoot/Shared.ps1"

    Describe 'Authenticating' -Tag 'Integration' {

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

    Describe 'Handling of Versions' -Tag 'Integration' {
        $projectKey = "TV"

        $versionName1 = "TESTv1"
        $versionName2 = "TESTv2"
        $versionName3 = "TESTv3"

        Context 'New-JiraVersion' {
            # ARRANGE
            $versionObject = [PSCustomObject]@{
                Name        = $versionName1
                Description = "My Description"
                Project     = (Get-JiraProject -Project $projectKey)
                ReleaseDate = (Get-Date "2017-12-01")
                StartDate   = (Get-Date "2017-01-01")
            }
            $versionObject.PSObject.TypeNames.Insert(0, 'JiraPS.Version')
            $versionParameter = [PSCustomObject]@{
                Name        = $versionName2
                Project     = $projectKey
                Description = "Lorem Ipsum"
            }
            $versionSplat = @{
                Name        = $versionName3
                Description = "A Description"
                Archived    = $false
                Released    = $true
                ReleaseDate = "2017-12-01"
                StartDate   = "2017-01-01"
                Project     = (Get-JiraProject -Project $projectKey)
            }

            # ACT
            $result1 = $versionObject | New-JiraVersion -ErrorAction Stop
            $result2 = New-JiraVersion -Name $versionParameter.Name -Project $versionParameter.Project -Description $versionParameter.Description -ErrorAction Stop
            $result3 = New-JiraVersion @versionSplat -ErrorAction Stop

            # ASSERT
            It 'returns an object with specific properties' {
                checkType $result1 'JiraPS.Version'
                checkType $result2 'JiraPS.Version'
                checkType $result3 'JiraPS.Version'
            }
            defProp $result1 'Name' $versionName1
            defProp $result2 'Name' $versionName2
            defProp $result3 'Name' $versionName3
        }

        Context 'Get-JiraVersion' {
            # ARRANGE
            $versionObject = [PSCustomObject]@{
                Name = $versionName1
            }
            $versionObject.PSObject.TypeNames.Insert(0, 'JiraPS.Version')
            $versionParameter = [PSCustomObject]@{
                Name    = $versionName2
                Project = $projectKey
            }

            # ACT
            $result1 = Get-JiraVersion -Project $projectKey -ErrorAction Stop
            $result2 = Get-JiraProject $projectKey | Get-JiraVersion -ErrorAction Stop
            $result3 = Get-JiraVersion -Project $projectKey -Name $versionName1, $versionName2 -ErrorAction Stop
            $result4 = Get-JiraVersion -Id $result1.Id -ErrorAction Stop
            $result5 = $result1 | Get-JiraVersion -ErrorAction Stop

            # ASSERT
            It 'returns an object with specific properties' {
                checkType $result1 'JiraPS.Version'
                checkType $result2 'JiraPS.Version'
                checkType $result3 'JiraPS.Version'
                checkType $result4 'JiraPS.Version'
                checkType $result5 'JiraPS.Version'
            }
            It 'returns the expected objects' {
                $result1.Name -contains $versionName1 | Should Be $true
                $result1.Name -contains $versionName2 | Should Be $true
                $result1.Name -contains $versionName3 | Should Be $true
                $result2.Name -contains $versionName1 | Should Be $true
                $result2.Name -contains $versionName2 | Should Be $true
                $result2.Name -contains $versionName3 | Should Be $true
                $result1.ToString() | Should Be $result2.ToString()
                $result3.Name -contains $versionName1 | Should Be $true
                $result3.Name -contains $versionName2 | Should Be $true
                $result1.ToString() | Should Be $result4.ToString()
                $result4.ToString() | Should Be $result5.ToString()
            }
        }

        Context 'Set-JiraVersion' {
            # ARRANGE
            $now = (Get-Date)
            $oldVersion1 = Get-JiraVersion -Project $projectKey -Name $versionName1
            $versionNewName1 = "TESTv1.1"
            $oldVersion2 = Get-JiraVersion -Project $projectKey -Name $versionName2
            $oldVersion3 = Get-JiraVersion -Project $projectKey -Name $versionName3

            # ACT
            $version1 = Set-JiraVersion -Version $oldVersion1 -Name "$versionNewName1" -ErrorAction Stop
            $version2 = Set-JiraVersion -Version $oldVersion2 -Description "" -ErrorAction Stop
            $version3 = $oldVersion2, $oldVersion3 | Set-JiraVersion -ReleaseDate $now -ErrorAction Stop

            # ASSERT
            It 'returns an object with specific properties' {
                checkType $version1 'JiraPS.Version'
                checkType $version2 'JiraPS.Version'
                checkType $version3 'JiraPS.Version'
            }
            It 'changes field value by parameters' {
                $version1 = Get-JiraVersion -Id $oldVersion1.Id
                $version1.Name | Should Be $versionNewName1
                $version1.Name | Should Not Be $oldVersion1.Name
            }
            It 'clears the value of a field' {
                $oldVersion2.Description | Should Not BeNullOrEmpty
                $version2 = Get-JiraVersion -Id $oldVersion2.Id
                $version2.Description | Should BeNullOrEmpty
                $version2.Description | Should Not Be $oldVersion2.Description
            }
            It 'changes field value by the pipeline' {
                $version3 = Get-JiraVersion -Id $oldVersion2.Id, $oldVersion3.Id
                $version3.ReleaseDate[0].ToString('yyyy-MM-dd') | Should Be $now.ToString('yyyy-MM-dd')
            }
        }

        Context 'Remove-JiraVersion' {
            # ARRANGE
            $versionName1 = "TESTv1.1"
            $versionObject = Get-JiraVersion -Project $projectKey -Name $versionName2

            # ACT
            Remove-JiraVersion -Version $versionObject -Force -ErrorAction Stop
            Get-JiraVersion -Project $projectKey -Name $versionName1, $versionName3 | Remove-JiraVersion -Force -ErrorAction Stop

            # ASSERT
            It 'removes the versions' {
                Get-JiraVersion -Project $projectKey -Name $versionName1, $versionName2, $versionName3 | Should BeNullOrEmpty
            }
        }
    }

    <# Describe 'Handling of Users and Groups' -Tag 'Integration' {

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
