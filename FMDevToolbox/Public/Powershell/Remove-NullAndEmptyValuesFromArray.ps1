function Remove-NullAndEmptyValuesFromArray {
    <#
    .SYNOPSIS
    Removes null and empty values from an array, with options to process
    nested arrays and remove empty objects.

    .DESCRIPTION
    The `Remove-NullAndEmptyValuesFromArray` function processes an input array to remove null or
    empty values. It provides additional options to handle nested arrays, empty PSObjects,
    hashtables, and collections. The function can be customized using switches to control
    which types of empty elements are removed.

    .PARAMETER Array
    Specifies the array to process. This parameter is mandatory and accepts input from the pipeline.

    .PARAMETER ProcessNestedArrays
    Indicates that nested arrays should be processed recursively to remove null and empty values.

    .PARAMETER RemoveEmptyPSObjects
    Indicates that empty PSObjects should be removed from the array.

    .PARAMETER RemoveEmptyHashtables
    Indicates that empty hashtables should be removed from the array.

    .PARAMETER RemoveEmptyCollections
    Indicates that empty collections should be removed from the array.

    .PARAMETER RemoveAllEmpty
    Indicates that all types of empty elements (PSObjects, hashtables, collections) should be removed.

    .INPUTS
    Object
    You can pipe an array of objects to this function.

    .OUTPUTS
    Object[]
    Returns an array with null and empty values removed based on the specified parameters.

    .EXAMPLE
    # **Example 1**
    # This example demonstrates how to remove null and empty strings from a simple array.
    $inputArray = @("Hello", "", $null, "World")
    Remove-NullAndEmptyValuesFromArray -Array $inputArray

    .EXAMPLE
    # **Example 2**
    # This example demonstrates how to process nested arrays to remove null and empty values.
    $nestedArray = @(@("A", $null), @("", "B"), $null)
    Remove-NullAndEmptyValuesFromArray -Array $nestedArray -ProcessNestedArrays

    .EXAMPLE
    # **Example 3**
    # This example demonstrates removing empty PSObjects from an array.
    $objectsArray = @([PSCustomObject]@{}, [PSCustomObject]@{Name="John"}, $null)
    Remove-NullAndEmptyValuesFromArray -Array $objectsArray -RemoveEmptyPSObjects

    .EXAMPLE
    # **Example 4**
    # This example demonstrates removing empty hashtables from an array.
    $hashtableArray = @(@{}, @{Key="Value"}, $null)
    Remove-NullAndEmptyValuesFromArray -Array $hashtableArray -RemoveEmptyHashtables

    .EXAMPLE
    # **Example 5**
    # This example demonstrates removing empty collections from an array.
    $collectionArray = @(New-Object System.Collections.ArrayList, New-Object System.Collections.ArrayList(@(1,2)), $null)
    Remove-NullAndEmptyValuesFromArray -Array $collectionArray -RemoveEmptyCollections

    .EXAMPLE
    # **Example 6**
    # This example demonstrates using the RemoveAllEmpty switch to remove all types of empty elements.
    $complexArray = @("", [PSCustomObject]@{}, @{}, New-Object System.Collections.ArrayList, $null, "Data")
    Remove-NullAndEmptyValuesFromArray -Array $complexArray -RemoveAllEmpty

    .NOTES
    Author: Futuremotion
    Website: https://github.com/futuremotiondev
    Date: 01-11-2025
    #>
    [CmdletBinding()]
    param (
        [Parameter(
            Mandatory,
            ValueFromPipeline,
            ValueFromPipelineByPropertyName,
            Position=0,
            HelpMessage = "The array to remove empty items from."
        )]
        [ValidateNotNullOrEmpty()]
        [Alias("a")]
        [Object] $Array,

        [Parameter(HelpMessage = "Whether to process nested arrays or not.")]
        [ValidateNotNullOrEmpty()]
        [Alias("nested")]
        [Switch] $ProcessNestedArrays,

        [Parameter(HelpMessage = "Whether to remove empty PSObjects or PSCustomObjects.")]
        [ValidateNotNullOrEmpty()]
        [Alias("rmobj")]
        [Switch] $RemoveEmptyPSObjects,

        [Parameter(
            HelpMessage = "Whether to remove empty Hashtables."
        )]
        [ValidateNotNullOrEmpty()]
        [Alias("rmhash")]
        [Switch] $RemoveEmptyHashtables,

        [Parameter(
            HelpMessage = "Whether to remove empty generic collections."
        )]
        [ValidateNotNullOrEmpty()]
        [Alias("rmcol")]
        [Switch] $RemoveEmptyCollections,

        [Parameter(
            HelpMessage = "Whether to remove all empty PSObjects/Hashtables/Generic Collections"
        )]
        [ValidateNotNullOrEmpty()]
        [Alias("rmall")]
        [Switch] $RemoveAllEmpty
    )
    process {
        # Initialize an empty result array
        $result = @()

        # Iterate over each item in the input array
        foreach ($item in $Array) {
            try {
                # Attempt to get the type of the item
                $itemType = $item.GetType()
            }
            catch {
                # If there's an error, set itemType to null
                $itemType = $null
            }

            # Check if the item is not a generic type
            if(-not($itemType.IsGenericType)){
                # Skip null or whitespace strings
                if ($null -eq $item -or [String]::IsNullOrWhiteSpace($item)) {
                    continue
                }
                # Handle nested arrays if the corresponding switch is set
                elseif ($item -is [Array]) {
                    if($PSBoundParameters.ContainsKey('ProcessNestedArrays')){
                        # Recursively process nested arrays
                        $processNestedArraySplat = @{
                            Array                  = $item
                            ProcessNestedArrays    = $true
                            RemoveEmptyPSObjects   = $RemoveEmptyPSObjects
                            RemoveEmptyHashtables  = $RemoveEmptyHashtables
                            RemoveEmptyCollections = $RemoveEmptyCollections
                            RemoveAllEmpty         = $RemoveAllEmpty
                        }
                        $nestedResult = Remove-NullAndEmptyValuesFromArray @processNestedArraySplat
                        if ($nestedResult.Count -gt 0) {
                            $result += ,@($nestedResult)
                        }
                        continue
                    }
                    else {
                        # Add the entire array if not processing nested arrays
                        $result += ,@($item)
                        continue
                    }
                }
                # Remove empty PSObjects if the corresponding switch is set
                elseif (($RemoveEmptyPSObjects -or $RemoveAllEmpty) -and ($item -is [PSCustomObject] -or $item -is [PSObject])) {
                    if (($item.psobject.Properties.Count).Count -eq 0) {
                        continue
                    }
                }
            }
            else {
                # Handle empty collections if the corresponding switch is set
                if($RemoveEmptyCollections -or $RemoveAllEmpty) {
                    if($item.Count -eq 0){
                        continue
                    }
                    if ($null -eq $item) {
                        continue
                    }
                }
            }
            # Add non-empty items to the result array
            $result += $item
        }
        # Return the processed result array
        return ,$result
    }
}

# $EmptyPSObject = [PSCustomObject]@{}
# $PopulatedPSObject = [PSCustomObject]@{
#     Name = "Explorer"
#     Path = "C:\Windows"
#     Type = "Application"
# }

# $EmptyHashtable = @{}
# $PopulatedHashtable = @{
#     Key1 = 'Value1'
#     Key2 = 'Value2'
#     Key3 = 'Value3'
# }
# $testArray = @(
#     "One", "", 2, $EmptyPSObject, @("1",2,"   "), $PopulatedPSObject, $EmptyHashtable, $PopulatedHashtable, "Final", 1, 5, 6, 7
# )
# $NewArray = Remove-NullAndEmptyValuesFromArray -Array $testArray -Verbose


# foreach ($Item in $NewArray) {

#     $ItemIsArray = $false
#     $ItemType = $Item.GetType().FullName | Get-SpectreEscapedText
#     $ItemBaseType = $Item.GetType().BaseType.FullName | Get-SpectreEscapedText

#     if($ItemBaseType -eq "System.Array"){
#         $ItemIsArray = $true
#         $ItemContent = "@({0})" -f ($Item.ForEach({
#             if ($_ -is [string]) { "`"$_`"" } else { $_ }
#         }) -join ", ") | Get-SpectreEscapedText
#     }
#     else{
#         $ItemContent = $Item
#     }

#     if($ItemType -eq 'System.Collections.Hashtable'){
#         $ItemContent = "@{ $($Item.GetEnumerator() | Sort-Object Name | ForEach-Object { '{0} = ''{1}''' -f $_.Key, $_.Value } -join '; ') }"
#     }

#     Write-SpectreHost "[#868B92]Item Content:[/]   [#FFFFFF]$ItemContent[/]"
#     Write-SpectreHost "[#868B92]Item Type:[/]      [#FFFFFF]$ItemType[/]"
#     Write-SpectreHost "[#868B92]Item Base Type:[/] [#FFFFFF]$ItemBaseType[/]"
#     if($ItemIsArray){
#         Write-SpectreHost "[#868B92]Array Count:[/]    [#79AFFB]$($Item.Count)[/]"
#     }
#     Show-HorizontalLineInConsole
# }