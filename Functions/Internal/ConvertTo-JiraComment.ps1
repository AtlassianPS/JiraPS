function ConvertTo-JiraComment
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
#            Write-Debug "[ConvertTo-JiraComment] Processing object: '$i'"

#            Write-Debug "[ConvertTo-JiraComment] Defining standard properties"
            $props = @{
                'ID' = $i.id;
                'Body' = $i.body;
                'Visibility' = $i.visibility;
                'RestUrl' = $i.self;
            }

            # These fields should typically exist on an object returned from Jira,
            # but this provides a bit of extra error checking and safety

#            Write-Debug "[ConvertTo-JiraComment] Checking for author"
            if ($i.author)
            {
                $props.Author = ConvertTo-JiraUser -InputObject $i.author
            }

#            Write-Debug "[ConvertTo-JiraComment] Checking for update author"
            if ($i.updateAuthor)
            {
                $props.UpdateAuthor = ConvertTo-JiraUser -InputObject $i.updateAuthor
            }

#            Write-Debug "[ConvertTo-JiraComment] Checking for created date"
            if ($i.created)
            {
                $props.Created = (Get-Date ($i.created))
            }

#            Write-Debug "[ConvertTo-JiraComment] Checking for updated date"
            if ($i.updated)
            {
                $props.Updated = (Get-Date ($i.updated))
            }

#            Write-Debug "[ConvertTo-JiraComment] Creating PSObject out of properties"
            $result = New-Object -TypeName PSObject -Property $props

#            Write-Debug "[ConvertTo-JiraComment] Inserting type name information"
            $result.PSObject.TypeNames.Insert(0, 'PSJira.Comment')

#            Write-Debug "[ConvertTo-JiraComment] Inserting custom toString() method"
            $result | Add-Member -MemberType ScriptMethod -Name "ToString" -Force -Value {
                Write-Output "$($this.Body)"
            }

#            Write-Debug "[ConvertTo-JiraComment] Outputting object"
            Write-Output $result
        }
    }

    end
    {
#        Write-Debug "[ConvertTo-JiraComment] Complete"
    }
}


