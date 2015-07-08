function Get-JiraField
{
    [CmdletBinding()]
    param(
        # The Field name or ID to search
        [Parameter(Mandatory = $false,
                   Position = 0,
                   ValueFromRemainingArguments = $true)]
        [String[]] $Field,

        # Credentials to use to connect to Jira
        [Parameter(Mandatory = $false)]
        [System.Management.Automation.PSCredential] $Credential
    )

    begin
    {
        Write-Debug "[Get-JiraField] Reading server from config file"
        try
        {
            $server = Get-JiraConfigServer -ConfigFile $ConfigFile -ErrorAction Stop
        } catch {
            $err = $_
            Write-Debug "[Get-JiraField] Encountered an error reading the Jira server."
            throw $err
        }

        $uri = "$server/rest/api/latest/field"
        Write-Debug "[Get-JiraField] Obtaining all fields from Jira"
        $allFields = ConvertTo-JiraField -InputObject (Invoke-JiraMethod -Method Get -URI $uri -Credential $Credential)
    }

    process
    {
        if ($Field)
        {
            foreach ($f in $Field)
            {
                Write-Debug "[Get-JiraField] Processing field [$f]"
                Write-Debug "[Get-JiraField] Searching for field (name=[$f])"
                $thisField = $allFields | Where-Object -FilterScript {$_.Name -eq $f}
                if ($thisField)
                {
                    Write-Debug "[Get-JiraField] Found results; outputting"
                    Write-Output $thisField
                } else {
                    Write-Debug "[Get-JiraField] No results were found for issue type by name. Searching for issue type (id=[$i])"
                    $thisField = $allFields | Where-Object -FilterScript {$_.Id -eq $f}
                    if ($thisField)
                    {
                        Write-Debug "[Get-JiraField] Found results; outputting"
                        Write-Output $thisField
                    } else {
                        Write-Debug "[Get-JiraField] No results were found for issue type by ID. This issue type appears to be unknown."
                        Write-Verbose "Unable to identify Jira field [$f]"
                    }
                }
            }
        } else {
            Write-Debug "[Get-JiraField] No Field was supplied. Outputting all fields."
            Write-Output $allFields
        }
    }

    end
    {
        Write-Debug "[Get-JiraField] Complete"
    }
}