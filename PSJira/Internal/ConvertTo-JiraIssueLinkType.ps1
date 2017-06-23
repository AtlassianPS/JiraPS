function ConvertTo-JiraIssueLinkType {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true,
            Position = 0,
            ValueFromPipeline = $true)]
        [PSObject[]] $InputObject,
        
        [Switch] $ReturnError
    )

    process {
        foreach ($i in $InputObject) {
            if ($i.errorMessages) {
                if ($ReturnError) {
                    $props = @{
                        'ErrorMessages' = $i.errorMessages;
                    }

                    $result = New-Object -TypeName PSObject -Property $props
                    $result.PSObject.TypeNames.Insert(0, 'PSJira.Error')

                    Write-Output $result
                }
            }
            else {
                $props = @{
                    'ID'          = $i.id;
                    'Name'        = $i.name;
                    'InwardText'  = $i.inward;
                    'OutwardText' = $i.outward;
                    'RestUrl'     = $i.self;
                }

                $result = New-Object -TypeName PSObject -Property $props
                $result.PSObject.TypeNames.Insert(0, 'PSJira.IssueLinkType')

                Write-Output $result
            }
        }
    }

    end
    {
    }
}
