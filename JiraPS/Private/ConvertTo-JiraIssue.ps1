function ConvertTo-JiraIssue {
    [CmdletBinding()]
    [OutputType([AtlassianPS.JiraPS.Issue])]
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

        # Property names native to AtlassianPS.JiraPS.Issue. Anything outside
        # this set (notably `customfield_*` keys) is attached afterwards as a
        # PSObject NoteProperty so we keep the historical "every field is
        # accessible by name" contract intact.
        $nativeProperties = @(
            'ID', 'Key', 'HttpUrl', 'RestUrl', 'Summary', 'Description',
            'Status', 'IssueLinks', 'Attachment', 'Project',
            'Assignee', 'Creator', 'Reporter',
            'Created', 'LastViewed', 'Updated',
            'Fields', 'Expand', 'Transition', 'Comment'
        )

        $transitions = New-Object -TypeName System.Collections.ArrayList
        $comments = New-Object -TypeName System.Collections.ArrayList
    }

    process {
        foreach ($i in $InputObject) {
            Write-Debug "[$($MyInvocation.MyCommand.Name)] Converting `$InputObject to custom object"

            [void] $transitions.Clear()
            [void] $comments.Clear()

            $http = "{0}browse/$($i.key)" -f ($InputObject.self -split 'rest')[0]

            $result = [AtlassianPS.JiraPS.Issue]@{
                ID          = $i.id
                Key         = $i.key
                HttpUrl     = $http
                RestUrl     = $i.self
                Summary     = $i.fields.summary
                Description = ConvertFrom-AtlassianDocumentFormat -InputObject $i.fields.description
                Status      = $i.fields.status.name
            }

            if ($i.fields.issuelinks) {
                $result.IssueLinks = ConvertTo-JiraIssueLink -InputObject $i.fields.issuelinks
            }

            if ($i.fields.attachment) {
                $result.Attachment = ConvertTo-JiraAttachment $i.fields.attachment
            }

            if ($i.fields.project) {
                $result.Project = ConvertTo-JiraProject -InputObject $i.fields.project
            }

            foreach ($field in $userFields) {
                if ($i.fields.$field) {
                    $result.$field = ConvertTo-JiraUser -InputObject $i.fields.$field
                }
                elseif ($field -eq 'Assignee') {
                    # Legacy sentinel. Surface as a string so downstream
                    # `if ($issue.Assignee -eq 'Unassigned')` checks keep working.
                    $result.Assignee = 'Unassigned'
                }
            }

            foreach ($field in $dateFields) {
                if ($i.fields.$field) {
                    $result.$field = Get-Date -Date ($i.fields.$field)
                }
            }

            if ($IncludeDebug) {
                $result.Fields = $i.fields
                $result.Expand = $i.expand
            }

            [void] $transitions.Clear()
            foreach ($t in $i.transitions) {
                [void] $transitions.Add( (ConvertTo-JiraTransition -InputObject $t) )
            }
            $result.Transition = $transitions.ToArray()

            [void] $comments.Clear()
            if ($i.fields.comment) {
                if ($i.fields.comment.comments) {
                    foreach ($c in $i.fields.comment.comments) {
                        [void] $comments.Add( (ConvertTo-JiraComment -InputObject $c) )
                    }
                    $result.Comment = $comments.ToArray()
                }
            }

            # Custom fields and any unmapped server payload keys ride along as
            # PSObject NoteProperties to preserve the historical contract that
            # every API field is accessible by name on the returned object.
            $extraFields = $i.fields.PSObject.Properties | Where-Object -FilterScript { $_.Name -notin $nativeProperties }
            foreach ($f in $extraFields) {
                $result | Add-Member -MemberType NoteProperty -Name $f.Name -Value $f.Value -Force
            }

            Add-LegacyTypeAlias -InputObject $result -LegacyName 'JiraPS.Issue'
        }
    }
}
