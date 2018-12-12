if ($PSVersionTable.PSVersion.Major -lt 6) {
    function ConvertFrom-Json {
        <#
    .SYNOPSIS
        Function to overwrite or be used instead of the native `ConvertFrom-Json` of PowerShell
    .DESCRIPTION
        ConvertFrom-Json implementation does not allow for overriding JSON maxlength.
        The default limit is easy to exceed with large issue lists.
    #>
        [CmdletBinding()]
        param(
            [Parameter( Mandatory, ValueFromPipeline )]
            [Object[]]
            $InputObject,

            [Int]
            $MaxJsonLength = [Int]::MaxValue
        )

        begin {
            function ConvertFrom-Dictionary {
                param(
                    [System.Collections.Generic.IDictionary`2[String, Object]]$InputObject
                )

                process {
                    $returnObject = New-Object PSObject

                    foreach ($key in $InputObject.Keys) {
                        $pairObjectValue = $InputObject[$key]

                        if ($pairObjectValue -is [System.Collections.Generic.IDictionary`2].MakeGenericType([String], [Object])) {
                            $pairObjectValue = ConvertFrom-Dictionary $pairObjectValue
                        }
                        elseif ($pairObjectValue -is [System.Collections.Generic.ICollection`1].MakeGenericType([Object])) {
                            $pairObjectValue = ConvertFrom-Collection $pairObjectValue
                        }

                        $returnObject | Add-Member Noteproperty $key $pairObjectValue -ErrorAction Ignore
                    }

                    return $returnObject
                }
            }

            function ConvertFrom-Collection {
                param(
                    [System.Collections.Generic.ICollection`1[Object]]$InputObject
                )

                process {
                    $returnList = New-Object ([System.Collections.Generic.List`1].MakeGenericType([Object]))
                    foreach ($jsonObject in $InputObject) {
                        $jsonObjectValue = $jsonObject

                        if ($jsonObjectValue -is [System.Collections.Generic.IDictionary`2].MakeGenericType([String], [Object])) {
                            $jsonObjectValue = ConvertFrom-Dictionary $jsonObjectValue
                        }
                        elseif ($jsonObjectValue -is [System.Collections.Generic.ICollection`1].MakeGenericType([Object])) {
                            $jsonObjectValue = ConvertFrom-Collection $jsonObjectValue
                        }

                        $returnList.Add($jsonObjectValue) | Out-Null
                    }

                    return $returnList.ToArray()
                }
            }

            $scriptAssembly = [System.Reflection.Assembly]::LoadWithPartialName("System.Web.Extensions")

            $typeResolver = @"
public class JsonObjectTypeResolver : System.Web.Script.Serialization.JavaScriptTypeResolver
{
	public override System.Type ResolveType(string id)
	{
		return typeof (System.Collections.Generic.Dictionary<string, object>);
	}

	public override string ResolveTypeId(System.Type type)
	{
		return string.Empty;
	}
}
"@

            try {
                Add-Type -TypeDefinition $typeResolver -ReferencedAssemblies $scriptAssembly.FullName
            }
            catch {
                # This is a relatively common error that's harmless unless changing the actual C#
                # code, so it can be ignored. Unfortunately, it's just a plain old System.Exception,
                # so we can't try to catch a specific error type.
                if (-not $_.ToString() -like "*The type name 'JsonObjectTypeResolver' already exists*") {
                    throw $_
                }
            }

            $jsonserial = New-Object System.Web.Script.Serialization.JavaScriptSerializer(New-Object JsonObjectTypeResolver)
            $jsonserial.MaxJsonLength = $MaxJsonLength
        }

        process {
            foreach ($i in $InputObject) {
                $s = $i.ToString()
                if ($s) {
                    $jsonTree = $jsonserial.DeserializeObject($s)

                    if ($jsonTree -is [System.Collections.Generic.IDictionary`2].MakeGenericType([String], [Object])) {
                        $jsonTree = ConvertFrom-Dictionary $jsonTree
                    }
                    elseif ($jsonTree -is [System.Collections.Generic.ICollection`1].MakeGenericType([Object])) {
                        $jsonTree = ConvertFrom-Collection $jsonTree
                    }

                    Write-Output $jsonTree
                }
            }
        }
    }
}
