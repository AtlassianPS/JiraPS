function ConvertTo-JiraAttachment
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
#            Write-Debug "Processing object: '$i'"

#            Write-Debug "Defining standard properties"
            $props = @{
                'ID' = $i.id;
                'self' = $i.self;
                'fileName' = $i.FileName;
                'author' = (ConvertTo-JiraUser -InputObject $i.Author);
                'created' = Get-Date -Date ($i.created);
                'size' = ([int]$i.size);
                'mimeType' = $i.mimeType;
                'content' = $i.content;
                'thumbnail' = $i.thumbnail
            }

#            Write-Debug "Creating PSObject out of properties"
            $result = New-Object -TypeName PSObject -Property $props

#            Write-Debug "Inserting type name information"
            $result.PSObject.TypeNames.Insert(0, 'PSJira.Attachment')

#            Write-Debug "[ConvertTo-JiraProject] Inserting custom toString() method"
            $result | Add-Member -MemberType ScriptMethod -Name "ToString" -Force -Value {
                Write-Output "$($this.Name)"
            }

#            Write-Debug "Outputting object"
            Write-Output $result
        }
    }

    end
    {
#        Write-Debug "Complete"
    }
}


