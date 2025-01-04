function ConvertTo-FlatArray {
    <#
    .SYNOPSIS
    Flattens a nested array into a single-dimensional collection.

    .DESCRIPTION
    The ConvertTo-FlatArray function takes a nested array as input and
    returns a flattened, single-dimensional collection. It processes each element
    of the array recursively to ensure all nested arrays are fully expanded.

    .PARAMETER Array
    Specifies the nested array to be flattened. This parameter is mandatory and
    accepts input from the pipeline.

    .EXAMPLE
    # **Example 1**
    # This example demonstrates how to flatten a simple nested array.
    $nestedArray = @(1, @(2, 3), @(4, @(5, 6)))
    ConvertTo-FlatArray -Array $nestedArray

    .EXAMPLE
    # **Example 2**
    # This example demonstrates how to use the alias to flatten a nested array.
    $nestedArray = @(1, @(2, @(3, 4)), 5)
    $nestedArray | Convert-FlattenArray

    .EXAMPLE
    # **Example 3**
    # This example demonstrates how to handle an empty array within a nested structure.
    $nestedArray = @(1, @(), @(2, @(3, @())))
    ConvertTo-FlatArray -Array $nestedArray

    .OUTPUTS
    System.Object
    Returns each element of the nested array as a single-dimensional collection.

    .NOTES
    Author: Futuremotion
    Website: https://github.com/futuremotiondev
    Date: 12-20-2024
    #>
    [CmdletBinding()]
    [Alias("Flatten-Array")]
    param (
        [Parameter(Mandatory, Position=0, ValueFromPipeline)]
        [System.Collections.IEnumerable] $Array
    )
    process {
        foreach ($item in $Array) {
            if ($item -is [System.Collections.IEnumerable] -and -not ($item -is [String])) {
                # Continue if empty array
                if ($item.Count -eq 0) { continue }
                ConvertTo-FlatArray -Array $item
            } else {
                Write-Output $item
            }
        }
    }
}