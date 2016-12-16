function ConvertTo-JiraIssue
{
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true,
                   Position = 0,
                   ValueFromPipeline = $true)]
        [PSObject[]] $InputObject,

        [Switch] $IncludeDebug,

        [Switch] $ReturnError
    )

    begin
    {
        $userFields = @('Assignee','Creator','Reporter')
        $dateFields = @('Created','LastViewed','Updated')

        $transitions = New-Object -TypeName System.Collections.ArrayList
        $comments = New-Object -TypeName System.Collections.ArrayList
    }

    process
    {
        foreach ($i in $InputObject)
        {
            [void] $transitions.Clear()
            [void] $comments.Clear()

#            Write-Debug "[ConvertTo-JiraIssue] Processing object: '$i'"

            if ($i.errorMessages)
            {
#                Write-Debug "[ConvertTo-JiraIssue] Detected an errorMessages property. This is an error result."

                if ($ReturnError)
                {
#                    Write-Debug "[ConvertTo-JiraIssue] Outputting details about error message"
                    $props = @{
                        'ErrorMessages' = $i.errorMessages;
                    }

                    $result = New-Object -TypeName PSObject -Property $props
                    $result.PSObject.TypeNames.Insert(0, 'PSJira.Error')

                    Write-Output $result
                }
            } else {
                $server = ($InputObject.self -split 'rest')[0]
                $http = "${server}browse/$($i.key)"

#                Write-Debug "[ConvertTo-JiraIssue] Defining standard properties"
                $props = @{
                    'Key' = $i.key;
                    'ID' = $i.id;
                    'RestUrl' = $i.self;
                    'HttpUrl' = $http;
                    'Summary' = $i.fields.summary;
                    'Description' = $i.fields.description;
                    'Status' = $i.fields.status.name;
                }

                if ($i.fields.project)
                {
#                    Write-Debug "[ConvertTo-JiraIssue] Obtaining reference to project"
                    $props.Project = ConvertTo-JiraProject -InputObject $i.fields.project
                }

                foreach ($field in $userFields)
                {
#                    Write-Debug "[ConvertTo-JiraIssue] Checking for user field [$field]"
                    if ($i.fields.$field)
                    {
#                        Write-Debug "[ConvertTo-JiraIssue] Adding user field $field"
                        $props.$field = ConvertTo-JiraUser -InputObject $i.fields.$field
                    } elseif ($field -eq 'Assignee') {
#                        Write-Debug "[ConvertTo-JiraIssue] Adding 'Unassigned' assignee field"
                        $props.Assignee = 'Unassigned'
                    } else {
#                        Write-Debug "[ConvertTo-JiraIssue] Object does not appear to contain property [$field]"
                    }
                }

                foreach ($field in $dateFields)
                {
                    if ($i.fields.$field)
                    {
#                        Write-Debug "[ConvertTo-JiraIssue] Adding date field $field"
                        $props.$field = Get-Date -Date ($i.fields.$field)
                    }
                }

                if ($IncludeDebug)
                {
#                    Write-Debug "[ConvertTo-JiraIssue] Defining debug properties"
                    $props.Fields = $i.fields
                    $props.Expand = $i.expand
                }

#                Write-Debug "[ConvertTo-JiraIssue] Adding transitions"
                [void] $transitions.Clear()
                foreach ($t in $i.transitions)
                {
                    [void] $transitions.Add((ConvertTo-JiraTransition -InputObject $t))
                }
                $props.Transition = ($transitions.ToArray())

#                Write-Debug "[ConvertTo-JiraIssue] Adding comments"
                [void] $comments.Clear()
                if ($i.fields.comment)
                {
                    if ($i.fields.comment.comments)
                    {
                        foreach ($c in $i.fields.comment.comments)
                        {
                            [void] $comments.Add((ConvertTo-JiraComment -InputObject $c))
                        }
                        $props.Comment = ($comments.ToArray())
                    }
                }

               Write-Debug "[ConvertTo-JiraIssue] Checking for any additional fields"
                $extraFields = $i.fields.PSObject.Properties | Where-Object -FilterScript { $_.Name -notin $props.Keys }
                foreach ($f in $extraFields)
                {
                    $name = $f.Name
#                    Write-Debug "[ConvertTo-JiraIssue] Adding property [$name] with value [$($f.Value)]"
                    $props[$name] = $f.Value
                }

#                Write-Debug "[ConvertTo-JiraIssue] Creating PSObject out of properties"
                $result = New-Object -TypeName PSObject -Property $props

#                Write-Debug "[ConvertTo-JiraIssue] Inserting type name information"
                $result.PSObject.TypeNames.Insert(0, 'PSJira.Issue')

#                Write-Debug "[ConvertTo-JiraProject] Inserting custom toString() method"
                $result | Add-Member -MemberType ScriptMethod -Name "ToString" -Force -Value {
                    Write-Output "[$($this.Key)] $($this.Summary)"
                }

#                Write-Debug "[ConvertTo-JiraIssue] Outputting object"
                Write-Output $result
            }
        }
    }

    end
    {
#        Write-Debug "[ConvertTo-JiraIssue] Complete"
    }
}
