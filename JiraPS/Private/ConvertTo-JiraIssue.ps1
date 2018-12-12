function ConvertTo-JiraIssue {
    [CmdletBinding()]
    param(
        [Parameter( ValueFromPipeline )]
        [PSObject[]]
        $InputObject,

        [Switch]
        $IncludeDebug
    )

    begin {
        $userFields = @('Assignee', 'Creator', 'Reporter')
        $dateFields = @('Created', 'LastViewed', 'Updated')

        $transitions = New-Object -TypeName System.Collections.ArrayList
        $comments = New-Object -TypeName System.Collections.ArrayList
    }

    process {
        foreach ($i in $InputObject) {
            Write-Debug "[$($MyInvocation.MyCommand.Name)] Converting `$InputObject to custom object"

            [void] $transitions.Clear()
            [void] $comments.Clear()

            $http = "{0}browse/$($i.key)" -f ($InputObject.self -split 'rest')[0]

            $props = @{
                'ID'          = $i.id
                'Key'         = $i.key
                'HttpUrl'     = $http
                'RestUrl'     = $i.self
                'Summary'     = $i.fields.summary
                'Description' = $i.fields.description
                'Status'      = $i.fields.status.name
            }

            if ($i.fields.issuelinks) {
                $props['IssueLinks'] = ConvertTo-JiraIssueLink -InputObject $i.fields.issuelinks
            }

            if ($i.fields.attachment) {
                $props["Attachment"] = ConvertTo-JiraAttachment $i.fields.attachment
            }

            if ($i.fields.project) {
                $props["Project"] = ConvertTo-JiraProject -InputObject $i.fields.project
            }

            if ($i.changelog) {
                $props["History"] = foreach ($entry in $i.changelog.histories) {
                    ConvertTo-JiraIssueHistoryEntry -InputObject $entry
                }
            }

            foreach ($field in $userFields) {
                if ($i.fields.$field) {
                    $props.$field = ConvertTo-JiraUser -InputObject $i.fields.$field
                }
                elseif ($field -eq 'Assignee') {
                    $props.Assignee = 'Unassigned'
                }
                else {
                }
            }

            foreach ($field in $dateFields) {
                if ($i.fields.$field) {
                    $props.$field = Get-Date -Date ($i.fields.$field)
                }
            }

            if ($IncludeDebug) {
                $props.Fields = $i.fields
                $props.Expand = $i.expand
            }

            [void] $transitions.Clear()
            foreach ($t in $i.transitions) {
                [void] $transitions.Add( (ConvertTo-JiraTransition -InputObject $t) )
            }
            $props.Transition = $transitions.ToArray()

            [void] $comments.Clear()
            if ($i.fields.comment) {
                if ($i.fields.comment.comments) {
                    foreach ($c in $i.fields.comment.comments) {
                        [void] $comments.Add( (ConvertTo-JiraComment -InputObject $c) )
                    }
                    $props.Comment = $comments.ToArray()
                }
            }

            $extraFields = $i.fields.PSObject.Properties | Where-Object -FilterScript { $_.Name -notin $props.Keys }
            foreach ($f in $extraFields) {
                $name = $f.Name
                $props[$name] = $f.Value
            }

            $result = New-Object -TypeName PSObject -Property $props
            $result.PSObject.TypeNames.Insert(0, 'JiraPS.Issue')
            $result | Add-Member -MemberType ScriptMethod -Name "ToString" -Force -Value {
                Write-Output "[$($this.Key)] $($this.Summary)"
            }

            Write-Output $result
        }
    }
}
