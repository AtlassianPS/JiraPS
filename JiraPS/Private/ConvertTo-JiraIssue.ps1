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

    process {
        foreach ($i in $InputObject) {
            if ($null -eq $i) { continue }
            Write-Debug "[$($MyInvocation.MyCommand.Name)] Converting `$InputObject to AtlassianPS.JiraPS.Issue"

            $http = "{0}browse/$($i.key)" -f ($i.self -split 'rest')[0]
            $hash = @{
                ID          = $i.id
                Key         = $i.key
                HttpUrl     = [uri]$http
                RestUrl     = [uri]$i.self
                Summary     = $i.fields.summary
                Description = ConvertFrom-AtlassianDocumentFormat -InputObject $i.fields.description
                Transition  = [AtlassianPS.JiraPS.Transition[]]@(ConvertTo-JiraTransition -InputObject $i.transitions)
            }

            if ($i.changelog) {
                $hash.History = [AtlassianPS.JiraPS.IssueHistoryEntry[]]@(ConvertTo-JiraIssueHistoryEntry -InputObject $i.changelog.histories)
            }

            foreach ($field in $i.fields.PSObject.Properties) {
                switch ($field.Name) {
                    'status' {
                        if ($field.Value) {
                            $hash.Status = ConvertTo-JiraStatus -InputObject $field.Value
                        }
                        break
                    }
                    'issuelinks' {
                        if ($null -ne $field.Value) {
                            $hash.IssueLinks = [AtlassianPS.JiraPS.IssueLink[]]@(ConvertTo-JiraIssueLink -InputObject $field.Value)
                        }
                        break
                    }
                    'attachment' {
                        if ($null -ne $field.Value) {
                            $hash.Attachment = [AtlassianPS.JiraPS.Attachment[]]@(ConvertTo-JiraAttachment -InputObject $field.Value)
                        }
                        break
                    }
                    'project' {
                        if ($field.Value) {
                            $hash.Project = ConvertTo-JiraProject -InputObject $field.Value
                        }
                        break
                    }
                    { $_ -in 'assignee', 'creator', 'reporter' } {
                        if ($field.Value) {
                            $hash[$field.Name] = ConvertTo-JiraUser -InputObject $field.Value
                        }
                        break
                    }
                    { $_ -in 'created', 'lastViewed', 'updated' } {
                        if ($field.Value) {
                            $hash[$field.Name] = ConvertTo-JiraDateTimeOffsetValue $field.Value
                        }
                        break
                    }
                    'comment' {
                        if ($null -ne $field.Value.comments) {
                            $hash.Comment = [AtlassianPS.JiraPS.Comment[]]@(ConvertTo-JiraComment -InputObject $field.Value.comments)
                        }
                        break
                    }
                    'issuetype' {
                        $hash.IssueType = ConvertTo-JiraIssueType -InputObject $field.Value
                        break
                    }
                    'priority' {
                        $hash.Priority = ConvertTo-JiraPriority -InputObject $field.Value
                        break
                    }
                    'resolution' {
                        if ($field.Value) {
                            $hash.Resolution = ConvertTo-JiraResolution -InputObject $field.Value
                        }
                        break
                    }
                    'components' {
                        $hash.Components = [AtlassianPS.JiraPS.Component[]]@(ConvertTo-JiraComponent -InputObject $field.Value)
                        break
                    }
                    'worklog' {
                        $hash.Worklog = [AtlassianPS.JiraPS.Worklogitem[]]@(ConvertTo-JiraWorklogitem -InputObject $field.Value.worklogs)
                        break
                    }
                    'fixVersions' {
                        $hash.FixVersions = [AtlassianPS.JiraPS.Version[]]@(ConvertTo-JiraVersion -InputObject $field.Value)
                        break
                    }
                    'versions' {
                        $hash.Versions = [AtlassianPS.JiraPS.Version[]]@(ConvertTo-JiraVersion -InputObject $field.Value)
                        break
                    }
                    'parent' {
                        if ($field.Value) {
                            $hash.Parent = ConvertTo-JiraIssue -InputObject $field.Value
                        }
                        break
                    }
                    'subtasks' {
                        $hash.Subtasks = [AtlassianPS.JiraPS.Issue[]]@(ConvertTo-JiraIssue -InputObject $field.Value)
                        break
                    }
                    'watches' {
                        $hash.Watches = ConvertTo-JiraIssueWatch -InputObject $field.Value
                        break
                    }
                    'votes' {
                        $hash.Votes = ConvertTo-JiraIssueVote -InputObject $field.Value
                        break
                    }
                    'progress' {
                        $hash.Progress = ConvertTo-JiraIssueProgress -InputObject $field.Value
                        break
                    }
                    'aggregateprogress' {
                        $hash.AggregateProgress = ConvertTo-JiraIssueProgress -InputObject $field.Value
                        break
                    }
                    'timetracking' {
                        $hash.TimeTracking = ConvertTo-JiraIssueTimeTracking -InputObject $field.Value
                        break
                    }
                    'security' {
                        $hash.Security = ConvertTo-JiraIssueSecurityLevel -InputObject $field.Value
                        break
                    }
                }
            }

            if ($IncludeDebug) {
                $hash.Fields = [System.Collections.Generic.Dictionary[string, object]]::new()
                foreach ($property in $i.fields.PSObject.Properties) {
                    $hash.Fields[$property.Name] = $property.Value
                }
                $hash.Expand = $i.expand
            }

            $result = [AtlassianPS.JiraPS.Issue]$hash
            foreach ($field in $i.fields.PSObject.Properties) {
                if ($null -eq $result.PSObject.Properties[$field.Name]) {
                    $result | Add-Member -MemberType NoteProperty -Name $field.Name -Value $field.Value
                }
            }

            $result
        }
    }
}
