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
        [Parameter(Mandatory = $FALSE)]
        [String] $Key,

        # Name of the Project
        [Parameter(Mandatory = $FALSE)]
        [String] $Name,

        # Project Type Key
        [Parameter(Mandatory = $false)]
        [String] $ProjectTypeKey,

        # Project Template Key
        [Parameter(Mandatory = $false)]
        [String] $ProjectTemplateKey,

        # Long description of the Project.
        [Parameter(Mandatory = $FALSE)]
        [String] $Description,

        # Project Lead
        [Parameter(Mandatory = $FALSE)]
        [String] $Lead,

        # Assignee Type
        [Parameter(Mandatory = $FALSE)]
        [ValidateSet('ProjectLead', 'Unassigned')]
        [String] $AssigneeType,

        # Avatar ID
        [Parameter(Mandatory = $false)]
        [int] $AvatarId,

        # Issue Security Scheme ID
        [Parameter(Mandatory = $FALSE)]
        [int] $IssueSecurityScheme,

        # Permission Scheme ID
        [Parameter(Mandatory = $FALSE)]
        [int] $PermissionScheme,

        # Notification Scheme ID
        [Parameter(Mandatory = $FALSE)]
        [int] $NotificationScheme,

        # Category ID
        [Parameter(Mandatory = $FALSE)]
        [int] $categoryId,

        # Credentials to use to connect to JIRA.
        # If not specified, this function will use anonymous access.
        [Parameter(Mandatory = $false)]
        [PSCredential] $Credential
    )
    begin {
        Write-Debug -Message '[New-JiraProject] Reading information from config file'
        $server = Get-JiraConfigServer -ConfigFile $ConfigFile -ErrorAction Stop

        $restUrl = "$server/rest/api/2/project"
    }

    process {
        enum assigneeType {
            PROJECT_LEAD
            UNASSIGNED
        }
        Switch($AssigneeType)
        {
            'ProjectLead'
            {
                $AssigneeTypeEnum = [assigneeType]::PROJECT_LEAD
            }
            'Unassigned'
            {
                $AssigneeType = [assigneeType]::UNASSIGNED
            }
        }

        $iwrSplat = @{
            key                 = $Key
            name                = $Name
            projectTypeKey      = $ProjectTypeKey
            projectTemplateKey  = $ProjectTemplateKey
            description         = $Description
            lead                = $lead
            url                 = $server
            assigneeType        = $AssigneeTypeEnum
            avatarId            = $AvatarId
            issueSecurityScheme = $IssueSecurityScheme
            permissionScheme    = $PermissionScheme
            notificationScheme  = $NotificationScheme
            categoryId          = $categoryId

        }
        Write-Debug -Message '[New-JiraProject] Converting to JSON'
        $json = ConvertTo-Json -InputObject $iwrSplat

        if ($PSCmdlet.ShouldProcess($Name, "Creating new Project in JIRA")) {
            Write-Debug -Message '[New-JiraProject] Preparing for blastoff!'
            $result = Invoke-JiraMethod -Method Post -URI $restUrl -Body $json -Credential $Credential
        }
        $result
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
