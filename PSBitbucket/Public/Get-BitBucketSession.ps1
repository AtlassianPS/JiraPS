function Get-BitBucketSession
{
    <#
    .Synopsis
       Obtains a reference to the currently saved BitBucket session
    .DESCRIPTION
       This functio obtains a reference to the currently saved BitBucket session.  This can provide
       a BitBucket session ID, as well as the username used to connect to BitBucket.
    .EXAMPLE
       New-BitBucketSession -Credential (Get-Credential BitBucketUsername)
       Get-BitBucketSession
       Creates a BitBucket session for BitBucketUsername, then obtains a reference to it.
    .INPUTS
       None
    .OUTPUTS
       [PSBitBucket.Session] An object representing the BitBucket session
    #>
    [CmdletBinding()]
    param()

    process
    {
        if ($MyInvocation.MyCommand.Module.PrivateData)
        {
            Write-Debug "[Get-BitBucketSession] Module private data exists"
            if ($MyInvocation.MyCommand.Module.PrivateData.Session)
            {
                Write-Debug "[Get-BitBucketSession] A Session object is saved; outputting"
                Write-Output $MyInvocation.MyCommand.Module.PrivateData.Session
            } else {
                Write-Debug "[Get-BitBucketSession] No Session objects are saved"
                Write-Verbose "No BitBucket sessions have been saved."
            }
        } else {
            Write-Debug "[Get-BitBucketSession] No module private data is defined. No saved sessions exist."
            Write-Verbose "No BitBucket sessions have been saved."
        }
    }
}


