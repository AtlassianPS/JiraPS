function ThrowError {
    <#
    .SYNOPSIS
        Utility to throw a terminating errorrecord
    .NOTES
        Thanks to Jaykul:
        https://github.com/PoshCode/Configuration/blob/master/Source/Metadata.psm1
    #>
    [System.Diagnostics.CodeAnalysis.SuppressMessage('PSAvoidOverwritingBuiltInCmdlets', '')] # TODO: fix this
    param
    (
        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [System.Management.Automation.PSCmdlet]
        $Cmdlet = $((Get-Variable -Scope 1 PSCmdlet).Value),

        [Parameter(Mandatory = $true, ParameterSetName = "ExistingException", Position = 1, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
        [Parameter(ParameterSetName = "NewException")]
        [ValidateNotNullOrEmpty()]
        [System.Exception]
        $Exception,

        [Parameter(ParameterSetName = "NewException", Position = 2)]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $ExceptionType = "System.Management.Automation.RuntimeException",

        [Parameter(Mandatory = $true, ParameterSetName = "NewException", Position = 3)]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $Message,

        [Parameter(Mandatory = $false)]
        [System.Object]
        $TargetObject,

        [Parameter(Mandatory = $true, ParameterSetName = "ExistingException", Position = 10)]
        [Parameter(Mandatory = $true, ParameterSetName = "NewException", Position = 10)]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $ErrorId,

        [Parameter(Mandatory = $true, ParameterSetName = "ExistingException", Position = 11)]
        [Parameter(Mandatory = $true, ParameterSetName = "NewException", Position = 11)]
        [ValidateNotNull()]
        [System.Management.Automation.ErrorCategory]
        $Category,

        [Parameter(Mandatory = $true, ParameterSetName = "Rethrow", Position = 1)]
        [System.Management.Automation.ErrorRecord]$ErrorRecord
    )
    process {
        if (!$ErrorRecord) {
            if ($PSCmdlet.ParameterSetName -eq "NewException") {
                if ($Exception) {
                    $Exception = New-Object $ExceptionType $Message, $Exception
                }
                else {
                    $Exception = New-Object $ExceptionType $Message
                }
            }
            $errorRecord = New-Object System.Management.Automation.ErrorRecord $Exception, $ErrorId, $Category, $TargetObject
        }
        $Cmdlet.ThrowTerminatingError($errorRecord)
    }
}
