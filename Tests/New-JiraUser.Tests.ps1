. $PSScriptRoot\Shared.ps1

InModuleScope PSJira {

    [System.Diagnostics.CodeAnalysis.SuppressMessage('PSUseDeclaredVarsMoreThanAssigments', '', Scope='*', Target='SuppressImportModule')]
    $SuppressImportModule = $true
    . $PSScriptRoot\Shared.ps1

    $jiraServer = 'http://jiraserver.example.com'

    $testUsername = 'powershell-test'
    $testEmail = "$testUsername@example.com"
    $testDisplayName = 'Test User'

    # Trimmed from this example JSON: expand, groups, avatarURL
    $testJson = @"
{
    "self": "$jiraServer/rest/api/2/user?username=testUser",
    "key": "$testUsername",
    "name": "$testUsername",
    "emailAddress": "$testEmail",
    "displayName": "$testDisplayName",
    "active": true
}
"@

    Describe "New-JiraUser" {

        Mock Write-Debug {
            if ($ShowDebugData)
            {
                Write-Host -Object "[DEBUG] $Message" -ForegroundColor Yellow
            }
        }

        Mock Get-JiraConfigServer -ModuleName PSJira {
            Write-Output $jiraServer
        }

        Mock Invoke-JiraMethod -ModuleName PSJira -ParameterFilter {$Method -eq 'POST' -and $URI -eq "$jiraServer/rest/api/latest/user"} {
            if ($ShowMockData)
            {
                Write-Host "       Mocked Invoke-JiraMethod with POST method" -ForegroundColor Cyan
                Write-Host "         [Method]         $Method" -ForegroundColor Cyan
                Write-Host "         [URI]            $URI" -ForegroundColor Cyan
            }
            ConvertFrom-Json2 $testJson
        }

        # Generic catch-all. This will throw an exception if we forgot to mock something.
        Mock Invoke-JiraMethod -ModuleName PSJira {
            Write-Host "       Mocked Invoke-JiraMethod with no parameter filter." -ForegroundColor DarkRed
            Write-Host "         [Method]         $Method" -ForegroundColor DarkRed
            Write-Host "         [URI]            $URI" -ForegroundColor DarkRed
            throw "Unidentified call to Invoke-JiraMethod"
        }

        #############
        # Tests
        #############

        It "Creates a user in JIRA and returns a result" {
            $newResult = New-JiraUser -UserName $testUsername -EmailAddress $testEmail -DisplayName $testDisplayName
            $newResult | Should Not BeNullOrEmpty
        }

        It "Outputs a PSJira.User object" {
            $newResult = New-JiraUser -UserName $testUsername -EmailAddress $testEmail -DisplayName $testDisplayName
            checkType $newResult 'PSJira.User' 
            $newResult.Name | Should Be $testUsername
            $newResult.EmailAddress | Should Be $testEmail
            $newResult.DisplayName | Should Be $testDisplayName
        }

        Context "Output checking" {
            Mock ConvertTo-JiraUser {}
            New-JiraUser -UserName $testUsername -EmailAddress $testEmail -DisplayName $testDisplayName

            It "Uses ConvertTo-JiraUser to beautify output" {
                Assert-MockCalled 'ConvertTo-JiraUser'
            }
        }
    }
}


