function New-JiraGroup {
    <#
    .Synopsis
       Creates a new group in JIRA
    .DESCRIPTION
       This function creates a new group in JIRA.
    .EXAMPLE
       New-JiraGroup -GroupName testGroup
       This example creates a new JIRA group named testGroup.
    .INPUTS
       This function does not accept pipeline input.
    .OUTPUTS
       [JiraPS.Group] The user object created
    #>
    [CmdletBinding(SupportsShouldProcess = $true)]
    param(
        # Name for the new group.
        [Parameter(
            Position = 0,
            Mandatory = $true
        )]
        [Alias('Name')]
        [String] $GroupName,

        # Credentials to use to connect to JIRA.
        # If not specified, this function will use anonymous access.
        [PSCredential] $Credential
    )

    begin {
        Write-Verbose "[$($MyInvocation.MyCommand.Name)] Function started"

        $server = Get-JiraConfigServer -ConfigFile $ConfigFile -ErrorAction Stop

        $restUrl = "$server/rest/api/latest/group"
    }

    process {
        Write-DebugMessage "[$($MyInvocation.MyCommand.Name)] ParameterSetName: $($PsCmdlet.ParameterSetName)"
        Write-DebugMessage "[$($MyInvocation.MyCommand.Name)] PSBoundParameters: $($PSBoundParameters | Out-String)"

        Write-Debug "[New-JiraGroup] Defining properties"
        $props = @{
            "name" = $GroupName;
        }

        Write-Debug "[New-JiraGroup] Converting to JSON"
        $json = ConvertTo-Json -InputObject $props

        Write-Debug "[New-JiraGroup] Checking for -WhatIf and Confirm"
        if ($PSCmdlet.ShouldProcess($GroupName, "Creating group [$GroupName] to JIRA")) {
            Write-Debug "[$($MyInvocation.MyCommand.Name)] Invoking JiraMethod with `$parameter"
            $result = Invoke-JiraMethod -Method Post -URI $restUrl -Body $json -Credential $Credential
        }
        if ($result) {
            Write-Debug "[New-JiraGroup] Converting output object into a Jira user and outputting"
            ConvertTo-JiraGroup -InputObject $result
        }
        else {
            Write-Debug "[New-JiraGroup] Jira returned no results to output."
        }
    }

    end {
        Write-Verbose "[$($MyInvocation.MyCommand.Name)] Complete"
    }
}
