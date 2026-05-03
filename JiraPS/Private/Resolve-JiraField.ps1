function Resolve-JiraField {
    <#
    .SYNOPSIS
        Resolves a field key from a -Fields hashtable to a JiraPS field object.
    .DESCRIPTION
        Checks scoped metadata first (create/edit/transition screen), then falls
        back to the global field catalogue provided by the caller. Throws a
        terminating error when the key is ambiguous or not found. This function
        does NOT call Get-JiraField; the caller is responsible for fetching and
        passing the fallback hashtables.
    #>
    [CmdletBinding()]
    [OutputType([PSObject])]
    param(
        # The key from the -Fields hashtable (a field ID or display name).
        [Parameter(Mandatory)]
        [string]$Name,

        # Hashtables from scoped metadata (create/edit/transition screen).
        # Pass empty @{} if scoped metadata is unavailable.
        [Parameter(Mandatory)]
        [hashtable]$ScopedById,

        [Parameter(Mandatory)]
        [hashtable]$ScopedByName,

        # Hashtables from the global Get-JiraField catalogue.
        # Pass empty @{} if the fallback has not been fetched (the function
        # will NOT call Get-JiraField itself; it only resolves from what's given).
        [Parameter(Mandatory)]
        [hashtable]$FallbackById,

        [Parameter(Mandatory)]
        [hashtable]$FallbackByName,

        # The calling cmdlet name, used in error messages.
        [string]$CallerName = $MyInvocation.MyCommand.Name
    )

    # 1. Scoped by exact ID
    if ($ScopedById.ContainsKey($Name)) {
        Write-Debug "[$CallerName] [$Name] resolved via scoped metadata by field ID"
        return $ScopedById[$Name][0]
    }

    # 2. Scoped by numeric custom field ID
    if ($ScopedById.ContainsKey("customfield_$Name")) {
        Write-Debug "[$CallerName] [$Name] resolved via scoped metadata as numerical custom field ID (customfield_$Name)"
        return $ScopedById["customfield_$Name"][0]
    }

    # 3. Scoped by name (unambiguous)
    if ($ScopedByName.ContainsKey($Name) -and $ScopedByName[$Name].Count -eq 1) {
        Write-Debug "[$CallerName] [$Name] resolved via scoped metadata by field name ($($ScopedByName[$Name][0].Id))"
        return $ScopedByName[$Name][0]
    }

    # 4. Scoped by name (ambiguous — terminating)
    if ($ScopedByName.ContainsKey($Name)) {
        $exception = ([System.ArgumentException]"Ambiguously Referenced Parameter")
        $errorId = 'ParameterValue.AmbiguousParameter'
        $errorCategory = 'InvalidArgument'
        $errorTarget = $Name
        $errorItem = New-Object -TypeName System.Management.Automation.ErrorRecord $exception, $errorId, $errorCategory, $errorTarget
        $errorItem.ErrorDetails = "Field name [$Name] in -Fields hashtable ambiguously refers to more than one field in the scoped metadata. Specify the custom field by its ID."
        $PSCmdlet.ThrowTerminatingError($errorItem)
    }

    # 5. Fallback by exact ID
    if ($FallbackById.ContainsKey($Name)) {
        Write-Debug "[$CallerName] [$Name] resolved via global field list by field ID"
        return $FallbackById[$Name][0]
    }

    # 6. Fallback by numeric custom field ID
    if ($FallbackById.ContainsKey("customfield_$Name")) {
        Write-Debug "[$CallerName] [$Name] resolved via global field list as numerical custom field ID (customfield_$Name)"
        return $FallbackById["customfield_$Name"][0]
    }

    # 7. Fallback by name (unambiguous)
    if ($FallbackByName.ContainsKey($Name) -and $FallbackByName[$Name].Count -eq 1) {
        Write-Debug "[$CallerName] [$Name] resolved via global field list by field name ($($FallbackByName[$Name][0].Id))"
        return $FallbackByName[$Name][0]
    }

    # 8. Fallback by name (ambiguous — terminating)
    if ($FallbackByName.ContainsKey($Name)) {
        $exception = ([System.ArgumentException]"Ambiguously Referenced Parameter")
        $errorId = 'ParameterValue.AmbiguousParameter'
        $errorCategory = 'InvalidArgument'
        $errorTarget = $Name
        $errorItem = New-Object -TypeName System.Management.Automation.ErrorRecord $exception, $errorId, $errorCategory, $errorTarget
        $errorItem.ErrorDetails = "Field name [$Name] in -Fields hashtable ambiguously refers to more than one field. Use Get-JiraField for more information, or specify the custom field by its ID."
        $PSCmdlet.ThrowTerminatingError($errorItem)
    }

    # 9. Not found — terminating
    $exception = ([System.ArgumentException]"Invalid value for Parameter")
    $errorId = 'ParameterValue.InvalidFields'
    $errorCategory = 'InvalidArgument'
    $errorTarget = $Name
    $errorItem = New-Object -TypeName System.Management.Automation.ErrorRecord $exception, $errorId, $errorCategory, $errorTarget
    $errorItem.ErrorDetails = "Unable to identify field [$Name] from -Fields hashtable. Use the relevant metadata cmdlet or Get-JiraField for more information."
    $PSCmdlet.ThrowTerminatingError($errorItem)
}
