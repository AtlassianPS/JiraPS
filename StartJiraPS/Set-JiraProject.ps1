function Set-JiraProject {
    <#
    .Synopsis
         Modifies project properties in JIRA
    .DESCRIPTION
         This function modifies project properties in JIR
    .EXAMPLE
        Set-JiraProject -project project1
        Modifies...
    .EXAMPLE
        Set-JiraProject -project project1
        Modifies...
    .INPUTS
        [JiraPS.Project[]] The JIRA project that should be modified.
    .OUTPUTS
        [JiraPS.Project[]]
    .NOTES

    #>
    [CmdletBinding(
        DefaultParameterSetName = 'ByNamedParameters')]
    param(
        # Project Name or project object obtained from Get-JiraProject.
        [Parameter(Position = 0,
            Mandatory = $true,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true,
            ParameterSetName = 'ByObject'
        )]
        [Object[]] $Project,

        # Project Key
        [Parameter(Mandatory = $false,
            ParameterSetName = 'ByNamedParameters')]
        [String] $ProjectKey,

        # Project Type Key
        [Parameter(Mandatory = $false,
            ParameterSetName = 'ByNamedParameters')]
        [String] $ProjectTypeKey,

        # Project Template Key
        [Parameter(Mandatory = $false,
            ParameterSetName = 'ByNamedParameters')]
        [String] $ProjectTemplateKey,

        # Long description of the Project.
        [Parameter(Mandatory = $false,
            ParameterSetName = 'ByNamedParameters')]
        [String] $Description,

        # Project Lead
        [Parameter(Mandatory = $false,
            ParameterSetName = 'ByNamedParameters')]
        [String] $Lead,

        # Assignee Type
        [Parameter(Mandatory = $false,
            ParameterSetName = 'ByNamedParameters')]
        [ValidateSet('ProjectLead', 'Unassigned')]
        [String] $AssigneeType,

        # Avatar ID
        [Parameter(Mandatory = $false,
            ParameterSetName = 'ByNamedParameters')]
        [int] $AvatarId,

        # Issue Security Scheme ID
        [Parameter(Mandatory = $false,
            ParameterSetName = 'ByNamedParameters')]
        [int] $IssueSecurityScheme,

        # Permission Scheme ID
        [Parameter(Mandatory = $false,
            ParameterSetName = 'ByNamedParameters')]
        [int] $PermissionScheme,

        # Notification Scheme ID
        [Parameter(Mandatory = $false,
            ParameterSetName = 'ByNamedParameters')]
        [int] $NotificationScheme,

        # Category ID
        [Parameter(Mandatory = $false,
            ParameterSetName = 'ByNamedParameters')]
        [int] $CategoryId,

        # Credentials to use to connect to JIRA.
        # If not specified, this function will use anonymous access.
        [Parameter(Mandatory = $false)]
        [System.Management.Automation.PSCredential] $Credential
    )

    begin {
        Write-Debug "[Set-JiraProject] Reading server from config file"
        $server = Get-JiraConfigServer -ConfigFile $ConfigFile -ErrorAction Stop
    }
    process {
        foreach ($p in $project) {
            Write-Debug "[Set-JiraProject] Obtaining reference to project [$p]"

            $projectObj = Get-Jiraproject -Project $p.Key -Credential $Credential

            Write-Debug "[Set-JiraProject] Building URI for REST call"
            $projectUrl = "$server/rest/api/2/project/{0}" -f $projectObj.key

            Write-Debug "[Set-JiraIssue] ParameterSetName=$($PSCmdlet.ParameterSetName)"
            $props = @{}
            Switch ($PSCmdlet.ParameterSetName) {
                'byObject' {
                    # Validate InputObject type
                    if ($projectObj.PSObject.TypeNames[0] -ne "JiraPS.Project") {
                        $message = "Wrong object type provided for Project. Only JiraPS.Project is accepted"
                        $exception = New-Object -TypeName System.ArgumentException -ArgumentList $message
                        Throw $exception
                    }

                    # Validate mandatory properties
                    if (-not ($projectObj.Key)) {
                        $message = "The Project provided does not contain all necessary information. Mandatory properties: 'Key'"
                        $exception = New-Object -TypeName System.ArgumentException -ArgumentList $message
                        Throw $exception
                    }

                    $props["Key"] = $projectObj.Key
                    $props["Name"] = $projectObj.Name
                    $props["projectTypeKey"] = $projectObj.ProjectTypeKey
                    $props["projectTemplateKey"] = $projectObj.ProjectTemplateKey
                    $props["description"] = $projectObj.Description
                    $props["Lead"] = $projectObj.Lead
                    $props["url"] = $server
                    $props["AssigneeType"] = $projectObj.AssigneeType
                    $props["AvatarId"] = $projectObj.AvatarId
                    $props["IssueSecurityScheme"] = $projectObj.IssueSecurityScheme
                    $props["PermissionScheme"] = $projectObj.PermissionScheme
                    $props["NotificationScheme"] = $projectObj.NotificationScheme
                    $props["categoryId"] = $projectObj.CategoryId

                }
                'ByNamedParameters' {
                    # Validate Project parameter
                    if (-not(($Project.PSObject.TypeNames[0] -ne "JiraPS.Project") -or ($Project -isnot [String]))) {
                        $message = "The Project provided is invalid."
                        $exception = New-Object -TypeName System.ArgumentException -ArgumentList $message
                        Throw $exception
                    }

                    Write-Debug -Message '[Set-JiraProject] Defining properties'
                    if ($PSCmdlet.MyInvocation.BoundParameters.ContainsKey("projectTypeKey")) {
                        $props["projectTypeKey"] = $ProjectTypeKey
                    }
                    if ($PSCmdlet.MyInvocation.BoundParameters.ContainsKey("projectTemplateKey")) {
                        $props["projectTemplateKey"] = $ProjectTemplateKey
                    }
                    if ($PSCmdlet.MyInvocation.BoundParameters.ContainsKey("description")) {
                        $props["description"] = $Description
                    }
                    if ($PSCmdlet.MyInvocation.BoundParameters.ContainsKey("Lead")) {
                        $props["Lead"] = $Lead
                    }
                    if ($PSCmdlet.MyInvocation.BoundParameters.ContainsKey("AssigneeType")) {
                        $props["AssigneeType"] = $AssigneeType
                    }
                    if ($PSCmdlet.MyInvocation.BoundParameters.ContainsKey("AvatarId")) {
                        $props["AvatarId"] = $AvatarId
                    }
                    if ($PSCmdlet.MyInvocation.BoundParameters.ContainsKey("IssueSecurityScheme")) {
                        $props["IssueSecurityScheme"] = $IssueSecurityScheme
                    }
                    if ($PSCmdlet.MyInvocation.BoundParameters.ContainsKey("PermissionScheme")) {
                        $props["PermissionScheme"] = $PermissionScheme
                    }
                    if ($PSCmdlet.MyInvocation.BoundParameters.ContainsKey("description")) {
                        $props["description"] = $Description
                    }
                    if ($PSCmdlet.MyInvocation.BoundParameters.ContainsKey("NotificationScheme")) {
                        $props["NotificationScheme"] = $NotificationScheme
                    }
                    if ($PSCmdlet.MyInvocation.BoundParameters.ContainsKey("categoryId")) {
                        $props["categoryId"] = $CategoryId
                    }

                }
            }
            Write-Debug -Message '[Set-JiraProject] Converting to JSON'
            $json = ConvertTo-Json -InputObject $props

            if ($PSCmdlet.ShouldProcess($Name, "Updating Project on JIRA")) {
                Write-Debug -Message '[Set-JiraProject] Preparing for blastoff!'
                $results = Invoke-JiraMethod -Method Put -URI $projectUrl -Body $json -Credential $Credential
                If ($results) {
                    ConvertTo-JiraProject -InputObject $results
                }
                else {
                    #Remove
                    "Something Didn't Work"
                }

            }
        }
    }
    end {
        Write-Debug "[Set-JiraProject] Complete"
    }
}
