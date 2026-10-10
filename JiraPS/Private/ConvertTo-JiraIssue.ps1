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
            'Fields', 'Expand', 'Transition', 'Comment', 'History'
        )
    }

    process {
        foreach ($i in $InputObject) {
            if ($null -eq $i) { continue }
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
                HttpUrl     = [uri]$http
                RestUrl     = [uri]$i.self
                Summary     = $i.fields.summary
                Description = ConvertFrom-AtlassianDocumentFormat -InputObject $i.fields.description
            }

            if ($i.fields.status) { $hash.Status = ConvertTo-JiraStatus -InputObject $i.fields.status }

            if ($null -ne $i.fields.issuelinks) {
                $hash.IssueLinks = [AtlassianPS.JiraPS.IssueLink[]]@(ConvertTo-JiraIssueLink -InputObject $i.fields.issuelinks)
            }

            if ($null -ne $i.fields.attachment) {
                $hash.Attachment = [AtlassianPS.JiraPS.Attachment[]]@(ConvertTo-JiraAttachment $i.fields.attachment)
            }

            if ($i.fields.project) {
                $hash.Project = ConvertTo-JiraProject -InputObject $i.fields.project
            }

            if ($i.changelog) {
                $hash.History = [AtlassianPS.JiraPS.IssueHistoryEntry[]]@(
                    foreach ($entry in $i.changelog.histories) {
                        ConvertTo-JiraIssueHistoryEntry -InputObject $entry
                    }
                )
            }

            foreach ($field in @('Assignee', 'Creator', 'Reporter')) {
                if ($i.fields.$field) {
                    $hash.$field = ConvertTo-JiraUser -InputObject $i.fields.$field
                }
            }

            foreach ($field in @('Created', 'LastViewed', 'Updated')) {
                if ($i.fields.$field) {
                    $hash.$field = ConvertTo-JiraDateTimeOffsetValue $i.fields.$field
                }
            }

            if ($IncludeDebug) {
                $hash.Fields = [System.Collections.Generic.Dictionary[string, object]]::new()
                foreach ($property in $i.fields.PSObject.Properties) {
                    $hash.Fields[$property.Name] = $property.Value
                }
                $hash.Expand = $i.expand
            }

            $transitions = [System.Collections.Generic.List[AtlassianPS.JiraPS.Transition]]::new()
            foreach ($t in $i.transitions) {
                $transitions.Add((ConvertTo-JiraTransition -InputObject $t))
            }
            $hash.Transition = $transitions.ToArray()

            if ($null -ne $i.fields.comment.comments) {
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
                $value = switch ($f.Name) {
                    'issuetype' { ConvertTo-JiraIssueType -InputObject $f.Value; break }
                    'priority' { ConvertTo-JiraPriority -InputObject $f.Value; break }
                    'resolution' { if ($f.Value) { ConvertTo-JiraResolution -InputObject $f.Value } else { $null }; break }
                    'components' { , [AtlassianPS.JiraPS.Component[]]@(ConvertTo-JiraComponent -InputObject $f.Value); break }
                    'worklog' {
                        if ($f.Value.worklogs) {
                            , [AtlassianPS.JiraPS.Worklogitem[]]@(ConvertTo-JiraWorklogitem -InputObject $f.Value.worklogs)
                        }
                        else { , [AtlassianPS.JiraPS.Worklogitem[]]@() }
                        break
                    }
                    'fixVersions' { , [AtlassianPS.JiraPS.Version[]]@(ConvertTo-JiraVersion $f.Value); break }
                    'versions' { , [AtlassianPS.JiraPS.Version[]]@(ConvertTo-JiraVersion $f.Value); break }
                    'parent' { if ($f.Value) { ConvertTo-JiraIssue $f.Value }; break }
                    'subtasks' { , [AtlassianPS.JiraPS.Issue[]]@(ConvertTo-JiraIssue $f.Value); break }
                    'watches' {
                        if ($f.Value) {
                            [AtlassianPS.JiraPS.IssueWatches]@{
                                Self       = [uri]$f.Value.self
                                WatchCount = ConvertTo-JiraNullableInt64 $f.Value.watchCount
                                IsWatching = $f.Value.isWatching
                                Watchers   = [AtlassianPS.JiraPS.User[]]@(ConvertTo-JiraUser $f.Value.watchers)
                            }
                        }
                        break
                    }
                    'votes' {
                        if ($f.Value) {
                            [AtlassianPS.JiraPS.IssueVotes]@{
                                Self     = [uri]$f.Value.self
                                Votes    = ConvertTo-JiraNullableInt64 $f.Value.votes
                                HasVoted = $f.Value.hasVoted
                                Voters   = [AtlassianPS.JiraPS.User[]]@(ConvertTo-JiraUser $f.Value.voters)
                            }
                        }
                        break
                    }
                    { $_ -in 'progress', 'aggregateprogress' } {
                        if ($f.Value) {
                            [AtlassianPS.JiraPS.IssueProgress]@{
                                Progress = ConvertTo-JiraNullableInt64 $f.Value.progress
                                Total    = ConvertTo-JiraNullableInt64 $f.Value.total
                                Percent  = ConvertTo-JiraNullableInt64 $f.Value.percent
                            }
                        }
                        break
                    }
                    'timetracking' {
                        if ($f.Value) {
                            [AtlassianPS.JiraPS.IssueTimeTracking]@{
                                OriginalEstimate         = $f.Value.originalEstimate
                                RemainingEstimate        = $f.Value.remainingEstimate
                                TimeSpent                = $f.Value.timeSpent
                                OriginalEstimateSeconds  = ConvertTo-JiraNullableInt64 $f.Value.originalEstimateSeconds
                                RemainingEstimateSeconds = ConvertTo-JiraNullableInt64 $f.Value.remainingEstimateSeconds
                                TimeSpentSeconds         = ConvertTo-JiraNullableInt64 $f.Value.timeSpentSeconds
                            }
                        }
                        break
                    }
                    'security' {
                        if ($f.Value) {
                            [AtlassianPS.JiraPS.IssueSecurityLevel]@{
                                Id          = $f.Value.id
                                Name        = $f.Value.name
                                Description = $f.Value.description
                                Self        = [uri]$f.Value.self
                            }
                        }
                        break
                    }
                    default { , $f.Value }
                }

                if ($result.PSObject.Properties[$f.Name].MemberType -eq 'Property') {
                    $result.($f.Name) = $value
                }
                else {
                    $result | Add-Member -MemberType NoteProperty -Name $f.Name -Value $value -Force
                }
            }

            $result
        }
    }
}
