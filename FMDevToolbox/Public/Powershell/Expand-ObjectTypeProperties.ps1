function Expand-ObjectTypeProperties {
    <#
    .SYNOPSIS
    Expands and lists the properties of an object's type.

    .DESCRIPTION
    The Expand-ObjectTypeProperties function takes an input object from the pipeline and retrieves all properties of its type. It outputs a custom object containing the property names and their values.

    .PARAMETER InputObject
    Specifies the object whose type properties are to be expanded. This parameter is mandatory and accepts input from the pipeline.

    .EXAMPLE
    # **Example 1**
    # This example demonstrates how to expand properties of a single object.
    Get-Process | Select-Object -First 1 | Expand-ObjectTypeProperties

    .EXAMPLE
    # **Example 2**
    # This example demonstrates how to expand properties of multiple objects in a collection.
    Get-Service | Expand-ObjectTypeProperties

    .EXAMPLE
    # **Example 3**
    # This example demonstrates how to use the function with a custom object.
    $customObject = [PSCustomObject]@{ Name = "Test"; Value = 123 }
    $customObject | Expand-ObjectTypeProperties

    .EXAMPLE
    # **Example 4**
    # This example demonstrates how to handle null or empty objects gracefully.
    $nullObject = $null
    try {
        $nullObject | Expand-ObjectTypeProperties
    } catch {
        Write-Host "Handled null object"
    }

    .EXAMPLE
    # **Example 5**
    # This example demonstrates using the function with a complex object.
    $complexObject = New-Object PSObject -Property @{ Name = "Complex"; Details = @{ SubDetail = "SubValue" } }
    $complexObject | Expand-ObjectTypeProperties

    .EXAMPLE
    # **Example 6**
    # This example demonstrates chaining the function with other cmdlets.
    Get-Process | Where-Object { $_.CPU -gt 100 } | Expand-ObjectTypeProperties

    .OUTPUTS
    Outputs a PSCustomObject for each property of the input object's type, containing the property name and value.

    .NOTES
    Author: Futuremotion
    Website: https://github.com/futuremotiondev
    Date: 01-19-2025
    #>
    param (
        [Parameter(Mandatory,ValueFromPipeline)]
        [ValidateNotNullOrEmpty()]
        [Object[]] $InputObject
    )
    process {
        $typeMembers = $InputObject.GetType() | gm * | where {$_.MemberType -eq 'Property'}
        $typeMembers | % {
            [PSCustomObject][Ordered]@{ Name = $_.Name; Value = $InputObject.GetType().($_.Name) }
        }
    }
}