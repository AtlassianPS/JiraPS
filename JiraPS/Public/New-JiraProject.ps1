function New-JiraProject {
    <#
    .Synopsis
        Creates a new Project in JIRA
    .DESCRIPTION
         This function creates a new project in JIRA.
    .EXAMPLE
        New-JiraProject
        Description
        -----------
        Create a
    .EXAMPLE
       New-JiraProject
        Description
        -----------
        Create a
    .EXAMPLE
       New-JiraProject
        Description
        -----------
        Create a
    .OUTPUTS
        [JiraPS.Project]
    .LINK
        ConvertTo-JiraProject
        Invoke-JiraMethod
    .NOTES
        This function requires either the -Credential parameter to be passed or a persistent JIRA session. See New-JiraSession for more details.  If neither are supplied, this function will run with anonymous access to JIRA.
    #>
    [CmdletBinding(SupportsShouldProcess = $true)]
    param(
        # Project Key
        [Parameter(Mandatory = $true)]
        [String] $Key,

        # Name of the Project
        [Parameter(Mandatory = $true)]
        [String] $Name,

        # Project Type Key
        [Parameter(Mandatory = $true)]
        [String] $ProjectTypeKey,

        # Project Template Key
        [Parameter(Mandatory = $false)]
        [String] $ProjectTemplateKey,

        # Long description of the Project.
        [Parameter(Mandatory = $false)]
        [String] $Description,

        # Project Lead
        [Parameter(Mandatory = $true)]
        [String] $Lead,

        # Assignee Type
        [Parameter(Mandatory = $false)]
        [JiraPS.AssigneeType] $AssigneeType,

        # Avatar ID
        [Parameter(Mandatory = $false)]
        [Int] $AvatarId,

        # Issue Security Scheme ID
        [Parameter(Mandatory = $false)]
        [Int] $IssueSecurityScheme,

        # Permission Scheme ID
        [Parameter(Mandatory = $false)]
        [Int] $PermissionScheme,

        # Notification Scheme ID
        [Parameter(Mandatory = $false)]
        [Int] $NotificationScheme,

        # Category ID
        [Parameter(Mandatory = $false)]
        [Int] $CategoryId,

        # Category ID
        [Parameter(Mandatory = $false)]
        [string] $Url,

        # Credentials to use to connect to JIRA.
        # If not specified, this function will use anonymous access.
        [Parameter(Mandatory = $false)]
        [PSCredential] $Credential
    )
    begin {
        Write-Debug -Message '[New-JiraProject] Reading information from config file'
        $server = Get-JiraConfigServer -ConfigFile $ConfigFile -ErrorAction Stop

        $uri = "$server/rest/api/2/project"
    }

    process {
        $parameters = @{
            key            = $Key
            name           = $Name
            lead           = $Lead
            projectTypeKey = $ProjectTypeKey
        }

        if ($ProjectTemplateKey) { $parameters["projectTemplateKey"] = $ProjectTemplateKey }
        if ($Description) { $parameters["description"] = $Description }
        if ($Url) { $parameters["url"] = $Url }
        if ($AssigneeTypeEnum) { $parameters["assigneeType"] = $AssigneeTypeEnum }
        if ($AvatarId) { $parameters["avatarId"] = $AvatarId }
        if ($IssueSecurityScheme) { $parameters["issueSecurityScheme"] = $IssueSecurityScheme }
        if ($PermissionScheme) { $parameters["permissionScheme"] = $PermissionScheme }
        if ($NotificationScheme) { $parameters["notificationScheme"] = $NotificationScheme }
        if ($categoryId) { $parameters["categoryId"] = $categoryId }

        Write-Debug -Message '[New-JiraProject] Converting to JSON'
        $json = ConvertTo-Json -InputObject $parameters

        if ($PSCmdlet.ShouldProcess($Name, "Creating new Project in JIRA")) {
            Write-Debug -Message '[New-JiraProject] Preparing for blastoff!'
            $result = Invoke-JiraMethod -Method Post -URI $uri -RawBody -Body $json -Credential $Credential
        }
        If ($result) {
            $result | ConvertTo-JiraProject
        }
        Else {
            Write-Debug -Message '[New-JiraProject] Jira returned no results to output.'
        }
    }

    end {
        Write-Debug "[New-JiraProject] Complete"
    }
}
