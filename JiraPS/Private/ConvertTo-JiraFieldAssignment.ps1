function ConvertTo-JiraFieldAssignment {
    <#
    .SYNOPSIS
        Converts a -Fields hashtable into resolved Jira field assignments.
    .DESCRIPTION
        Reuses scoped metadata first, then lazily fetches the global field
        catalogue only if at least one key is absent from the scoped metadata.
        Returns normalized assignment objects so callers can keep their own
        payload-writing logic.
    #>
    [CmdletBinding()]
    [OutputType([PSObject[]])]
    param(
        [Parameter(Mandatory)]
        [object]$Fields,

        [AllowNull()]
        [object[]]$ScopedMeta = @(),

        [Parameter(Mandatory)]
        [bool]$IsCloud,

        [string]$ScopedContext = 'scoped metadata',

        [string]$CallerName = $MyInvocation.MyCommand.Name,

        [scriptblock]$FallbackFieldFetcher
    )

    $scopedFieldsById = if ($ScopedMeta) {
        $ScopedMeta | Group-Object -Property Id -AsHashTable -AsString
    }
    else {
        @{}
    }
    $scopedFieldsByName = if ($ScopedMeta) {
        $ScopedMeta | Group-Object -Property Name -AsHashTable -AsString
    }
    else {
        @{}
    }

    $fallbackFieldsById = $null
    $fallbackFieldsByName = $null

    Write-Debug "[$CallerName] Resolving `$Fields"

    foreach ($_key in $Fields.Keys) {
        $name = $_key
        $value = $Fields.$_key
        Write-DebugMessage "[$CallerName] Attempting to identify field (name=[$name], value=[$value])"

        if (
            -not $scopedFieldsById.ContainsKey($name) -and
            -not $scopedFieldsById.ContainsKey("customfield_$name") -and
            -not $scopedFieldsByName.ContainsKey($name) -and
            $null -eq $fallbackFieldsById
        ) {
            Write-Debug "[$CallerName] [$name] not in $ScopedContext; fetching global field list as fallback"
            $fb = if ($FallbackFieldFetcher) { & $FallbackFieldFetcher } else { @() }
            $fallbackFieldsById = if ($fb) { $fb | Group-Object -Property Id -AsHashTable -AsString } else { @{} }
            $fallbackFieldsByName = if ($fb) { $fb | Group-Object -Property Name -AsHashTable -AsString } else { @{} }
        }

        $fallbackByIdForResolve = @{}
        $fallbackByNameForResolve = @{}
        if ($null -ne $fallbackFieldsById) {
            $fallbackByIdForResolve = $fallbackFieldsById
            $fallbackByNameForResolve = $fallbackFieldsByName
        }

        $field = Resolve-JiraField `
            -Name $name `
            -ScopedById $scopedFieldsById `
            -ScopedByName $scopedFieldsByName `
            -FallbackById $fallbackByIdForResolve `
            -FallbackByName $fallbackByNameForResolve `
            -CallerName $CallerName

        if ($IsCloud -and ($value -is [string]) -and (Test-JiraRichTextField -Field $field)) {
            $value = Resolve-JiraTextFieldPayload -Text $value -IsCloud $true
        }

        [PSCustomObject]@{
            InputName = $name
            Field     = $field
            Id        = [string]$field.Id
            Value     = $value
        }
    }
}
