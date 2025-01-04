function ConvertTo-FlatObjectSlav {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory,Position=0)]
        [Object] $obj,
        [Parameter(Position=1)]
        [String] $prefix = ""
    )
    if ($null -eq $obj) { return @{$prefix = "null"} }
    $res = @{}
    Write-Verbose "Prefix supplied to ConvertTo-FlatObjectSlav: $prefix"
    switch -Regex ($obj.GetType().Name) {
        '^(Boolean|String|Int32|Int64|Float|Double)$' {
            $res[$prefix] = $obj
        }
        "Hashtable" {
            foreach ($entry in $obj.GetEnumerator()) {
                $res += ConvertTo-FlatObjectSlav $entry.Value ("$prefix.$($entry.Key)")
            }
        }
        '^(List.*|.+\[\])$' {
            for ($i = 0; $i -lt $obj.Count; $i++) {
                $res += ConvertTo-FlatObjectSlav $obj[$i] ("$prefix[$i]")
            }
        }
    }
    return $res
}