function ConvertTo-JiraIssueLinkType {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true,
                   Position = 0,
                   ValueFromPipeline = $true)]
        [PSObject[]] $InputObject
    )

    process
    {
        foreach ($i in $InputObject)
        {
            $obj = [PSCustomObject] @{
                PSTypeName  = 'PSJira.IssueLinkType'
                Id          = $i.id;
                Name        = $i.name;
                InwardText  = $i.inward;
                OutwardText = $i.outward;
                RestUrl     = $i.self;
            }

            Write-Output $obj
        }
    }
}
