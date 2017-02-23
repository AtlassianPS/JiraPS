function ConvertTo-JiraWorklogitem
{
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true,
                   Position = 0,
                   ValueFromPipeline = $true)]
        [PSObject[]] $InputObject
    )

    process
    {
        foreach ($i in $InputObject)
        {
#            Write-Debug "[ConvertTo-JiraWorklogitem] Processing object: '$i'"

#            Write-Debug "[ConvertTo-JiraWorklogitem] Defining standard properties"
            $props = @{
                'ID' = $i.id;
                'Visibility' = $i.visibility;
                'Comment' = $i.comment;
                'RestUrl' = $i.self;
            }

            # These fields should typically exist on an object returned from Jira,
            # but this provides a bit of extra error checking and safety

#            Write-Debug "[ConvertTo-JiraWorklogitem] Checking for author"
            if ($i.author)
            {
                $props.Author = ConvertTo-JiraUser -InputObject $i.author
            }

#            Write-Debug "[ConvertTo-JiraWorklogitem] Checking for update author"
            if ($i.updateAuthor)
            {
                $props.UpdateAuthor = ConvertTo-JiraUser -InputObject $i.updateAuthor
            }

#            Write-Debug "[ConvertTo-JiraWorklogitem] Checking for created date"
            if ($i.created)
            {
                $props.Created = (Get-Date ($i.created))
            }

#            Write-Debug "[ConvertTo-JiraWorklogitem] Checking for updated date"
            if ($i.updated)
            {
                $props.Updated = (Get-Date ($i.updated))
            }

#            Write-Debug "[ConvertTo-JiraWorklogitem] Checking for started date"
            if ($i.started)
            {
                $props.Started = (Get-Date ($i.started))
            }

#            Write-Debug "[ConvertTo-JiraWorklogitem] Checking for time spent"
            if ($i.timeSpent)
            {
                $props.TimeSpent = $i.timeSpent
            }

#            Write-Debug "[ConvertTo-JiraWorklogitem] Checking for time spent in seconds"
            if ($i.timeSpentSeconds)
            {
                $props.TimeSpentSeconds = $i.timeSpentSeconds
            }            

#            Write-Debug "[ConvertTo-JiraWorklogitem] Creating PSObject out of properties"
            $result = New-Object -TypeName PSObject -Property $props

#            Write-Debug "[ConvertTo-JiraWorklogitem] Inserting type name information"
            $result.PSObject.TypeNames.Insert(0, 'PSJira.Worklogitem')

#            Write-Debug "[ConvertTo-JiraWorklogitem] Inserting custom toString() method"
            $result | Add-Member -MemberType ScriptMethod -Name "ToString" -Force -Value {
                Write-Output "$($this.Body)"
            }

#            Write-Debug "[ConvertTo-JiraWorklogitem] Outputting object"
            Write-Output $result
        }
    }

    end
    {
#        Write-Debug "[ConvertTo-JiraWorklogitem] Complete"
    }
}


