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
    }

    process {
        foreach ($i in $InputObject) {
            Write-Debug "[$($MyInvocation.MyCommand.Name)] Converting `$InputObject to AtlassianPS.JiraPS.Issue"

            # Derive the user-facing /browse URL from the item's own self link.
            # Previously this used $InputObject.self, which returns the entire
            # array of self URLs when more than one issue is converted in a
            # single call — producing a stringified-array prefix on every
            # HttpUrl after the first. Per-item $i.self is correct.
            $http = "{0}browse/$($i.key)" -f ($i.self -split 'rest')[0]

            $hash = @{
                ID          = $i.id
                Key         = $i.key
                HttpUrl     = $http
                RestUrl     = $i.self
                Summary     = $i.fields.summary
                Description = ConvertFrom-AtlassianDocumentFormat -InputObject $i.fields.description
                Status      = ConvertTo-JiraStatus -InputObject $i.fields.status
            }

            if ($i.fields.issuelinks) {
                $hash.IssueLinks = ConvertTo-JiraIssueLink -InputObject $i.fields.issuelinks
            }

            if ($i.fields.attachment) {
                $hash.Attachment = ConvertTo-JiraAttachment $i.fields.attachment
            }

            if ($i.fields.project) {
                $hash.Project = ConvertTo-JiraProject -InputObject $i.fields.project
            }

            foreach ($field in @('Assignee', 'Creator', 'Reporter')) {
                if ($i.fields.$field) {
                    $hash.$field = ConvertTo-JiraUser -InputObject $i.fields.$field
                }
                elseif ($field -eq 'Assignee') {
                    # Legacy sentinel. Surfaced as a string so downstream
                    # `if ($issue.Assignee -eq 'Unassigned')` checks keep working.
                    $hash.Assignee = 'Unassigned'
                }
            }

            foreach ($field in @('Created', 'LastViewed', 'Updated')) {
                if ($i.fields.$field) {
                    $hash.$field = Get-Date -Date ($i.fields.$field)
                }
            }

            if ($IncludeDebug) {
                $hash.Fields = $i.fields
                $hash.Expand = $i.expand
            }

            $transitions = @()
            foreach ($t in $i.transitions) {
                $transitions += ConvertTo-JiraTransition -InputObject $t
            }
            $hash.Transition = $transitions

            if ($i.fields.comment -and $i.fields.comment.comments) {
                $comments = foreach ($c in $i.fields.comment.comments) {
                    ConvertTo-JiraComment -InputObject $c
                }
                # Explicit cast keeps the [Comment[]] slot bound when only one
                # comment is present (PowerShell would otherwise unwrap to a scalar).
                $hash.Comment = [AtlassianPS.JiraPS.Comment[]]@($comments)
            }

            # $hash is a fresh hashtable literal — cast straight to the class.
            # ConvertTo-Hashtable is only needed when the input is already a
            # PSCustomObject (which trips PS5.1's [Class]$psobject cast); a
            # locally-built hashtable does not have that problem.
            $result = [AtlassianPS.JiraPS.Issue]$hash

            # Custom fields and any unmapped server payload keys ride along as
            # PSObject NoteProperties to preserve the historical contract that
            # every API field is accessible by name on the returned object.
            $extraFields = $i.fields.PSObject.Properties | Where-Object -FilterScript { $_.Name -notin $nativeProperties }
            foreach ($f in $extraFields) {
                $result | Add-Member -MemberType NoteProperty -Name $f.Name -Value $f.Value -Force
            }

            $result
        }
    }
}
