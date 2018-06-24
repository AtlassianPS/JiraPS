function Join-Hashtable {
    <#
	.SYNOPSIS
		Combines multiple hashtables into a single table.

	.DESCRIPTION
		Combines multiple hashtables into a single table.
		On multiple identic keys, the last wins.

	.EXAMPLE
		PS C:\> Join-Hashtable -Hashtable $Hash1, $Hash2

		Merges the hashtables contained in $Hash1 and $Hash2 into a single hashtable.
#>
    [CmdletBinding()]
    Param (
        # The tables to merge.
        [Parameter( Mandatory, ValueFromPipeline )]
        [AllowNull()]
        [System.Collections.IDictionary[]]
        $Hashtable
    )
    begin {
        $table = @{ }
    }

    process {
        foreach ($item in $Hashtable) {
            foreach ($key in $item.Keys) {
                $table[$key] = $item[$key]
            }
        }
    }

    end {
        $table
    }
}
