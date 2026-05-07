function ConvertTo-JiraTypedArray {
    [CmdletBinding()]
    [OutputType([Array])]
    param(
        [Parameter( Mandatory )]
        [Type]
        $Type,

        [Parameter( ValueFromPipeline )]
        [AllowNull()]
        [object]
        $InputObject
    )

    begin {
        $items = [System.Collections.Generic.List[object]]::new()
    }

    process {
        if ($null -eq $InputObject) { return }

        foreach ($item in @($InputObject)) {
            $items.Add($item)
        }
    }

    end {
        $array = [Array]::CreateInstance($Type, $items.Count)

        for ($index = 0; $index -lt $items.Count; $index++) {
            $array[$index] = [System.Management.Automation.LanguagePrimitives]::ConvertTo($items[$index], $Type)
        }

        , $array
    }
}
