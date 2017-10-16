function ConvertTo-JiraIssueType {
    [CmdletBinding()]
    param(
        [Parameter(
            Mandatory = $true,
            Position = 0,
            ValueFromPipeline = $true
        )]
        [PSObject[]] $InputObject,

        [ValidateScript( {Test-Path $_})]
        [String] $ConfigFile,

        [Switch] $ReturnError
    )

    process {
        foreach ($i in $InputObject) {
            # Write-Debug "[ConvertTo-JiraIssueType] Processing object: '$i'"

            if ($i.errorMessages) {
                # Write-Debug "[ConvertTo-JiraIssueType] Detected an errorMessages property. This is an error result."

                if ($ReturnError) {
                    # Write-Debug "[ConvertTo-JiraIssueType] Outputting details about error message"
                    $props = @{
                        'ErrorMessages' = $i.errorMessages;
                    }

                    $result = New-Object -TypeName PSObject -Property $props
                    $result.PSObject.TypeNames.Insert(0, 'JiraPS.Error')

                    Write-Output $result
                }
            }
            else {
                # $server = ($InputObject.self -split 'rest')[0]
                # $http = "${server}browse/$($i.key)"

                # Write-Debug "[ConvertTo-JiraIssueType] Defining standard properties"
                $props = @{
                    'ID'          = $i.id;
                    'Name'        = $i.name;
                    'Description' = $i.description;
                    'IconUrl'     = $i.iconUrl;
                    'RestUrl'     = $i.self;
                    'Subtask'     = [System.Convert]::ToBoolean($i.subtask)
                }

                # Write-Debug "[ConvertTo-JiraIssueType] Creating PSObject out of properties"
                $result = New-Object -TypeName PSObject -Property $props

                # Write-Debug "[ConvertTo-JiraIssueType] Inserting type name information"
                $result.PSObject.TypeNames.Insert(0, 'JiraPS.IssueType')

                # Write-Debug "[ConvertTo-JiraIssueType] Inserting custom toString() method"
                $result | Add-Member -MemberType ScriptMethod -Name "ToString" -Force -Value {
                    Write-Output "$($this.Name)"
                }

                # Write-Debug "[ConvertTo-JiraIssueType] Outputting object"
                Write-Output $result
            }
        }
    }

    end {
        # Write-Debug "[ConvertTo-JiraIssueType] Complete"
    }
}
