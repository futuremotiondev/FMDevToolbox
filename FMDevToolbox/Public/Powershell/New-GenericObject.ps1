function New-GenericObject {
    <#
    .SYNOPSIS
    Creates an object of a generic type. Specifically: Creates an instance of a generic object with specified type parameters and constructor parameters.

    .DESCRIPTION
    The New-GenericObject function allows you to create an instance of a generic type by specifying the base type name,
    the type parameters for the generic type, and any necessary constructor parameters. This is useful when working with
    generic collections or other types that require specific type arguments.

    .PARAMETER TypeName
    Specifies the base name of the generic type to instantiate (e.g., 'System.Collections.Generic.List').

    .PARAMETER TypeParams
    An array of type parameter names to be used in creating the closed generic type (e.g., 'System.String').

    .PARAMETER ConstructorParams
    An array of parameters to pass to the constructor of the closed generic type, if needed.

    .OUTPUTS
    Returns an instance of the specified closed generic type.

    .EXAMPLE
    # **Example 1**
    # This example demonstrates how to create an ObjectModel Collection typed as Int32.
    $list = New-GenericObject System.Collections.ObjectModel.Collection System.Int32

    .EXAMPLE
    # **Example 2**
    # This example demonstrates how to create a Generic dictionary with two types.
    New-GenericObject System.Collections.Generic.Dictionary System.String, System.Int32

    .EXAMPLE
    # **Example 3**
    # This example demonstrates how to create a Generic Dictionary with a Generic List as the second type.
    $secondType = New-GenericObject System.Collections.Generic.List Int32
    New-GenericObject System.Collections.Generic.Dictionary System.String, $secondType.GetType()

    .EXAMPLE
    # **Example 4**
    # This example demonstrates how to create a Generic LinkListNode with a non-default constructor.
    New-GenericObject System.Collections.Generic.LinkedListNode System.Int32 10

    .EXAMPLE
    # **Example 5**
    # This example demonstrates how to create a generic List of strings.
    New-GenericObject -TypeName 'System.Collections.Generic.List' -TypeParams 'System.String'

    .EXAMPLE
    # **Example 6**
    # This example demonstrates how to create a generic Dictionary with string keys and integer values.
    New-GenericObject -TypeName 'System.Collections.Generic.Dictionary' -TypeParams 'System.String', 'System.Int32'

    .EXAMPLE
    # **Example 7**
    # This example demonstrates how to create a generic List of integers with initial capacity.
    New-GenericObject -TypeName 'System.Collections.Generic.List' -TypeParams 'System.Int32' -ConstructorParams 10

    .EXAMPLE
    # **Example 8**
    # This example demonstrates how to create a generic Tuple with two different types.
    New-GenericObject -TypeName 'System.Tuple' -TypeParams 'System.String', 'System.Int32' -ConstructorParams 'Hello', 42

    .EXAMPLE
    # **Example 9**
    # This example demonstrates how to create a generic KeyValuePair with string key and boolean value.
    New-GenericObject -TypeName 'System.Collections.Generic.KeyValuePair' -TypeParams 'System.String', 'System.Boolean' -ConstructorParams 'IsActive', $true

    .EXAMPLE
    # **Example 10**
    # This example demonstrates how to create a generic Stack of double values.
    New-GenericObject -TypeName 'System.Collections.Generic.Stack' -TypeParams 'System.Double'

    .NOTES
    Author: Futuremotion
    Note: Modified version of Lee Holmes' New-GenericObject.ps1 script found here:
          https://www.leeholmes.com/creating-generic-types-in-powershell/
    Website: https://github.com/futuremotiondev
    Date: 01-11-2025
    #>
    param(
        [Parameter(Mandatory,Position=0)]
        [String] $TypeName,
        [Parameter(Mandatory,Position=1)]
        [String[]] $TypeParams,
        [Object[]] $ConstructorParams
    )

    function Resolve-Type {
        param (
            [string] $typeName
        )
        $type = [Type]::GetType($typeName)
        if (-not $type) {
            # Attempt to load the type with assembly-qualified name
            $type = [AppDomain]::CurrentDomain.GetAssemblies() |
                    ForEach-Object { $_.GetType($typeName, $false, $true) } |
                    Where-Object { $_ -ne $null }
        }
        return $type
    }

    try {
        $genericTypeName = $TypeName + '`' + $TypeParams.Count
        $genericType = Resolve-Type $genericTypeName
        if (-not $genericType) {
            throw "Could not find generic type '$genericTypeName'."
        }
    } catch {
        Write-Error "Error resolving generic type: $_"
        return
    }

    $typedParameters = $TypeParams | ForEach-Object {
        $type = Resolve-Type $_
        if (-not $type) { throw "Could not find type parameter '$_'." }
        $type
    }

    try {
        $closedType = $genericType.MakeGenericType($typedParameters)
        if (-not $closedType) {
            throw "Could not make closed type from '$genericTypeName' with parameters '$TypeParams'."
        }
    } catch {
        Write-Error "Error creating closed type: $_"
        return
    }

    if ($null -eq $ConstructorParams) {
        $ConstructorParams = @()
    }

    try {
        ,[Activator]::CreateInstance($closedType, $ConstructorParams)
    } catch {
        Write-Error "Error creating instance of type '$closedType': $_"
    }
}

