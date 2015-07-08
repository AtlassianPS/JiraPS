#param(
#    [Switch] $ShowMockData
#)

$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$sut = (Split-Path -Leaf $MyInvocation.MyCommand.Path).Replace(".Tests.", ".")
. "$here\$sut"

InModuleScope PSJira {
    
    # This is intended to be a parameter to the test, but Pester currently does not allow parameters to be passed to InModuleScope blocks.
    # For the time being, we'll need to hard-code this and adjust it as desired.
    $ShowMockData = $false

    $jiraServer = 'http://jiraserver.example.com'
    $issueID = 41701
    $issueKey = 'IT-3676'
    
    $projectId = 10003
    $projectName = 'Information Technology'
    $projectKey = 'IT'

    $issueTypeId = 2
    $issueTypeName = 'Desktop Support'

    $customField1Id = 'customfield_10002'
    $customField1Name = 'Issue Location';

    $customField2Id = 'customfield_10012';
    $customField2Name = 'Contact Phone';

    $testUsername = 'powershell-test'

    $restResultNew = @"
{
  "id": "$issueID",
  "key": "$issueKey",
  "self": "$jiraServer/rest/api/latest/issue/$issueID"
}
"@
    Describe "New-JiraIssue" {
        
        Mock Get-JiraConfigServer -ModuleName PSJira {
            Write-Output $jiraServer
        }

        Mock Get-JiraProject -ModuleName PSJira {
            [PSCUstomObject] @{
                'ID'   = $projectId;
                'Name' = $projectName;
                'Key'  = $projectKey;
            }
        }

        Mock Get-JiraIssueType -ModuleName PSJira {
            [PSCustomObject] @{
                'Id'   = $issueTypeId;
                'Name' = $issueTypeName;
            }
        }
        
        Mock Get-JiraIssueCreateMetadata -ModuleName PSJira {
            [PSCustomObject] @{
                'Id'       = $customField1Id;
                'Name'     = $customField1Name;
                'Required' = $true;
            }

            [PSCustomObject] @{
                'Id'       = $customField2Id;
                'Name'     = $customField2Name;
                'Required' = $true;
            }
        }

        Mock Get-JiraUser -ModuleName PSJira {
            [PSCustomObject] @{
                'Name' = $testUsername;
            }
        }

        Mock Get-JiraField -ModuleName PSJira -ParameterFilter {$Field -eq $customField1Id -or $Field -eq $customField1Name} {
            [PSCustomObject] @{
                'ID' = $customField1Id;
                'Name' = $customField1Name;
            }
        }

        Mock Get-JiraField -ModuleName PSJira -ParameterFilter {$Field -eq $customField2Id -or $Field -eq $customField2Name} {
            [PSCustomObject] @{
                'ID' = $customField2Id;
                'Name' = $customField2Name;
            }
        }

        # This should be called when actually creating the issue
        Mock Invoke-JiraMethod -ModuleName PSJira -ParameterFilter {$Method -eq 'Post' -and $URI -eq "$jiraServer/rest/api/latest/issue"} {
            if ($ShowMockData)
            {
                Write-Host "       Mocked Invoke-JiraMethod with POST method" -ForegroundColor Cyan
                Write-Host "         [Method] $Method" -ForegroundColor Cyan
                Write-Host "         [URI]    $URI" -ForegroundColor Cyan
            }
            ConvertFrom-Json $restResultNew
        }

        Mock Get-JiraIssue -ModuleName PSJira -ParameterFilter {$Key -eq $issueKey} {
            ConvertTo-JiraIssue ([PSCustomObject] @{
                ID  = $issueID;
                Key = $issueKey;
                fields = @{}
            })
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

        It "Creates an issue in JIRA and returns a result" {
            $newResult = New-JiraIssue -Project $projectKey -IssueType $issueTypeName -Priority 1 -Reporter $testUsername -Summary 'Test summary - new issue' -Description 'This is a test of creating a new Jira issue via PowerShell.' -Fields @{$customField1Name ='.'; $customField2Name = '.'}
            $newResult | Should Not BeNullOrEmpty
            $newResult.Key | Should Be $issueKey
        }

        It "Checks to make sure all reqiured custom fields are provided" {
            { $newResult = New-JiraIssue -Project $projectKey -IssueType $issueTypeName -Priority 1 -Reporter $testUsername -Summary 'Test summary - new issue' -Description 'This is a test of creating a new Jira issue without custom fields that should be required.' } | Should Throw
            { $newResult = New-JiraIssue -Project $projectKey -IssueType $issueTypeName -Priority 1 -Reporter $testUsername -Summary 'Test summary - new issue' -Description 'This is a test of creating a new Jira issue without custom fields that should be required.' -Fields @{$customField1Name = '.'} } | Should Throw
        }

        It "Sets the type name of the output object to PSJira.Issue" {
            $newResult = New-JiraIssue -Project $projectKey -IssueType $issueTypeName -Priority 1 -Reporter $testUsername -Summary 'Test summary - new issue' -Description 'This is a test of creating a new Jira issue via PowerShell.' -Fields @{$customField1Name ='.'; $customField2Name = '.'}
            (Get-Member -InputObject $newResult).TypeName | Should Be 'PSJira.Issue'
        }

        It "Accepts either the issue type ID or the issue type Name" {
            $nameResult = New-JiraIssue -Project $projectKey -IssueType $issueTypeName -Priority 1 -Reporter $testUsername -Summary 'Test summary - new issue' -Description 'This is a test of creating a new Jira issue via PowerShell.' -Fields @{$customField1Name ='.'; $customField2Name = '.'}
            $idResult = New-JiraIssue -Project $projectKey -IssueType $issueTypeId -Priority 1 -Reporter $testUsername -Summary 'Test summary - new issue' -Description 'This is a test of creating a new Jira issue via PowerShell.' -Fields @{$customField1Name ='.'; $customField2Name = '.'}
            $nameResult.Key | Should Be $idResult.Key
        }

        It "Defaults to the Credential's username if the -Reporter parameter is not specified" {
            $reporterResult = New-JiraIssue -Project 'IT' -IssueType 2 -Priority 1 -Summary 'Test summary - new issue' -Description 'This is a test of creating a new Jira issue without specifying the reporter.' -Fields @{$customField1Name ='.'; $customField2Name = '.'}
            # I'm not sure how to test this...
        }
    }
}